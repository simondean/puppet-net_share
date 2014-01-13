Puppet::Type.newtype(:net_share) do
  @doc = "Windows network share"

  class CaseInsensitiveProperty < Puppet::Property
    def insync?(is)
      raise Puppet::Error, "Invalid value for attribute '#{name}', must be an array" unless @should.is_a?(Array)

      (is.length == @should.length) and (is.zip(@should).all? { |a, b| property_matches?(a, b) })
    end

    def property_matches?(current, desired)
      current.to_s.casecmp(desired.to_s) == 0
    end
  end

  ensurable

  newparam(:name) do
    desc "Network share name. "
  end

  newproperty(:path) do
    desc "File system path to be shared. Will be auto-required. "
  end

  newproperty(:remark) do
    desc "Comments stored against the share. "
  end

  newproperty(:maximumusers) do
    desc "Maximum number of users that can concurrently access the share. Valid values are 'unlimited' or a number. "

    newvalues(:unlimited, /^[1-9][0-9]*$/)

    munge do |value|
      if value.casecmp('unlimited') == 0
        :unlimited
      else
        value.to_s
      end
    end
  end

  newproperty(:cache) do
    desc "Caching. "

    newvalues(:manual, :documents, :programs, :branchcache, :none)
  end

  newproperty(:permissions, :parent => CaseInsensitiveProperty, :array_matching => :all) do
    desc "An array of permissions. Example: ['computer\\user,full', 'computer\\user2,change', 'computer\\user3,read']"

    munge do |value|
      user, access = value.split(',', 2)
      "#{user.strip},#{access.strip.downcase}"
    end
  end

  autorequire(:file) do
    self[:path]
  end

  validate do
    if self[:ensure] != :absent
      [:path].each do |attribute|
        raise Puppet::Error, "Attribute '#{attribute}' is mandatory" unless self[attribute]
      end
    end
  end
end
