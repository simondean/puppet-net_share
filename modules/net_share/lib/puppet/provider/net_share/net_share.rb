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
  end

  def exists?
    @property_hash[:ensure] != :absent
  end

  def create
    execute_create
    @property_hash[:ensure] = :present
  end

  def destroy
    execute_delete
    @property_hash[:ensure] = :absent
  end

  def flush
    execute_flush
    @property_hash.clear
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

    output.each do |line|
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
          if value = 'No limit'
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
          properties[:permissions] << "#{user.strip},#{access.strip.downcase}"
      end
    end

    properties
  end

  def execute_create
    args = ['share', "#{resource[:name]}=#{resource[:path]}"]

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

          @property_hash[name] = value
        end
      end
    end

    net(*args)
  end

  def execute_delete
    net('share', resource[:name], '/delete')
  end

  def execute_flush
    if @resource[:ensure] != :absent
      execute_delete
      execute_create
    end
  end
end