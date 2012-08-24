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
    desc "Network share name"
  end

  newproperty(:path)
  newproperty(:remark)

  newproperty(:maximumusers) do
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
    newvalues(:manual, :documents, :programs, :branchcache, :none)
  end

  newproperty(:permissions, :parent => CaseInsensitiveProperty, :array_matching => :all) do
    munge do |value|
      value.collect do |item|
        user, access = item.split(',', 2)
        "#{user.strip},#{access.strip.downcase}"
      end
    end
  end

  #autorequire(:file) do
  #  self[:path]
  #end

  validate do
    if self[:ensure] != :absent
      [:path].each do |attribute|
        raise Puppet::Error, "Attribute '#{attribute}' is mandatory" unless self[attribute]
      end
    end
  end
end
