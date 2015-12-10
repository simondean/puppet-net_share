Puppet::Type.type(:net_share).provide(:net_share) do
	desc "Windows network share"

  confine     :operatingsystem => :windows
  defaultfor  :operatingsystem => :windows

  commands :net => File.join(ENV['SystemRoot'] || 'c:/windows', 'system32/net.exe')

  mk_resource_methods

  # Match resources to providers where the resource name matches the provider name
  def self.prefetch(resources)
    resources.each do |name, resource|
      provider = new(query(name))

      if provider
        resource.provider = provider
      else
        resource.provider = new(:ensure => :absent)
      end
    end
  end

  def initialize(*args)
    super

    # Make a duplicate of the properties so we can compare them during a flush
    @initial_properties = @property_hash.dup
  end

  def exists?
    @property_hash[:ensure] != :absent
  end

  def create
    @property_hash[:ensure] = :present
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  def flush
    if @property_hash[:ensure] != :absent
      if @initial_properties[:ensure] != :absent
        info "deleting and recreating net_share '#{name}'"
        execute_delete
      end

      execute_create
    else
      execute_delete
    end

    @property_hash.clear
    @initial_properties.clear
  end

  private
  def self.query(name)
    cmd = [command(:net), 'share', name]
    output = execute(cmd, { :failonfail => false })

    properties = {}
    properties[:name] = name

    if $?.exitstatus == 2
      properties[:ensure] = :absent
      return properties
    elsif $?.exitstatus != 0
      raise ExecutionFailure, "Execution of '#{cmd.join(' ')}' returned #{$?.exitstatus}: #{output}"
    end

    properties[:ensure] = :present

    output.each_line do |line|
      break if line.rstrip.length == 0

      last_name = name
      name = line[0..17].rstrip
      value = line[18..-1].rstrip

      if name.length == 0
        name = last_name
      end

      case name
        when 'Path'
          properties[:path] = value
        when 'Remark'
          properties[:remark] = value
        when 'Maximum users'
          if value == 'No limit'
            properties[:maximumusers] = :unlimited
          else
            properties[:maximumusers] = value.to_i
          end
        when 'Caching'
          case value
            when 'Caching disabled'
              value = :none
            when 'Manual caching of documents'
              value = :manual
            when 'Automatic caching of documents'
              value = :documents
            when 'Automatic caching of programs and documents'
              value = :programs
            else
              raise Puppet::Error, "Unrecognised Caching value '#{value}'"
          end

          properties[:cache] = value
        when 'Permission'
          properties[:permissions] ||= []

          user, access = value.split(',', 2)
          permission = "#{user.strip},#{access.strip.downcase}"

          properties[:permissions] << permission
      end
    end

    properties
  end

  def execute_create
    net(*(['share', "#{resource[:name]}=#{resource[:path]}"] + get_property_args()))
  end

  def execute_delete
    net('share', resource[:name], '/delete')
  end

  def get_property_args()
    args = []

    self.class.resource_type.validproperties.each do |name|
      if name != :ensure
        value = @resource.should(name)

        unless value.nil?
          case name
            when :path
            when :remark
              args << "/remark:#{value}"
            when :maximumusers
              if value == :unlimited
                args << "/unlimited"
              else
                args << "/users:#{value}"
              end
            when :cache
              args << "/cache:#{value}"
            when :permissions
              value.each do |user_permissions|
                args << "/grant:#{user_permissions}"
              end
            else
              raise Puppet::Error, "Unrecognised property '#{name}'"
          end
        end

        @property_hash[name] = value
      end
    end

    args
  end
end
