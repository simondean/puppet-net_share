require 'bundler/setup'

require 'rspec/core/rake_task'

task :default => [:spec, :smoke_test]

RSpec::Core::RakeTask.new(:spec)

desc "Run test manifests"
task :smoke_test do
	Dir.glob('tests/**/*.pp').each do |test_manifest|
		puts "Applying test manifest #{test_manifest}"
		success = system(File.join(ENV['ProgramFiles(x86)'], 'Puppet Labs/Puppet/bin/puppet.bat'), 'apply', '--verbose', '--noop', '--detailed-exitcodes', test_manifest)
		raise 'Test manifest failed' unless success
	end
end

desc "Build package"
task :build do
  Dir.glob('modules/*').each do |module_dir|
    puts "Building '#{module_dir}'"
    success = system('bundle', 'exec', 'puppet', 'module', 'build', module_dir)
   	raise 'Build failed' unless success
  end
end

desc "Run acceptance tests"
task :acceptance_test do
  success = system('bundle', 'exec', 'cucumber', '--strict')
  raise 'Build failed' unless success
end
