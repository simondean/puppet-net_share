def delete_net_share(name)
  if net_share_exists?(name)
    success = system(@net, 'share', name, '/delete')
    raise "Failed to delete share.  Exit code #{$?.exitstatus}" unless success
  end
end

def net_share_exists?(name)
  system(@net, 'share', name)
  success = [0, 2].include?($?.exitstatus)
  raise "Failed to check whether share exists.  Exit code #{$?.exitstatus}" unless success
  $?.exitstatus == 0
end

def create_net_share(name, properties)
  args = [@net, 'share', "#{name}=#{properties[:path]}"]

  properties.each do |name, value|
    case name
      when :path
      when :maximumusers
        if value == 'unlimited'
          args << '/unlimited'
        else
          args << "/shares:#{value}"
        end
      when :permissions
        value.split(';').each do |individual_value|
          args << "/grant:#{individual_value}"
        end
      else
        args << "/#{name}:#{value}"
    end
  end

  success = system(*args)
  raise "failed to create net share" unless success
end

def get_net_share_properties(name)
  properties = {}

  output = `#{@net} share #{name}`

  success = $?.success?
  raise "failed to retrieve net share properties" unless success

  output.lines do |line|
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

def value_to_string(value)
  value = value.join(';') if value.is_a?(Array)
  value.to_s
end

Given /^a "net_share" called "([^"]*)"$/ do |name|
  @net_share_name = name
  @net_share_properties = {}
end

Given /^its "([^"]*)" property is set to "([^"]*)"$/ do |name, value|
  @net_share_properties ||= {}
  @net_share_properties[name.to_sym] = value
end

Given /^that's it$/ do
  delete_net_share @net_share_name
  create_net_share @net_share_name, @net_share_properties
end

When /^puppet has not changed the "([^"]*)" "net_share"$/ do |name|
  @net_share_name = name
  @net_share_properties = get_net_share_properties(name)
end

When /^puppet has left its "([^"]*)" property set to "([^"]*)"$/ do |name, value|
  value_to_string(@net_share_properties[name.to_sym]).should == value
end

When /^puppet has left its "([^"]*)" property matching "([^"]*)"$/ do |name, value|
  value_to_string(@net_share_properties[name.to_sym]).should match value
end