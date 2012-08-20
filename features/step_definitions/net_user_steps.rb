def delete_user(name)
  if user_exists?(name)
    success = system(@net, 'user', name, '/delete')
    raise "Failed to delete user.  Exit code #{$?.exitstatus}" unless success
  end
end

def user_exists?(name)
  system(@net, 'user', name)
  success = [0, 2].include?($?.exitstatus)
  raise "Failed to check whether user exists.  Exit code #{$?.exitstatus}" unless success
  $?.exitstatus == 0
end

def create_user(name)
  success = system(@net, 'user', name, '/add', '/active:no')
  raise "Failed to add user.  Exit code #{$?.exitstatus}" unless success
end

Given /^a user called "([^"]*)"$/ do |name|
  delete_user name
  create_user name
end