Given /^a "directory" called "([^"]*)"$/ do |name|
  FileUtils.rm_rf name if File.exist? name
  FileUtils.mkdir_p name
end