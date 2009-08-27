require 'rubygems'
require 'rake'
require 'spec/rake/spectask'
require 'spec/rake/spectask'

desc "Run rspec with progress format"
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

desc "Run rspec with specdoc format"
task :specdoc do
  options = "--colour --format specdoc --loadby --reverse"
  files = FileList['spec/**/*_spec.rb']
  system("spec #{options} #{files}")
end

task :spec => :check_dependencies
task :default => :spec

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = 'communigate'
    gem.summary = "Interact with CommuniGatePro CLI interface"    
    gem.description = %Q{Library to interact with CommuniGate Pro CLI interface}
    gem.email = "Ricardo.Ruiz@Locaweb.com.br"
    gem.homepage = "http://github.com/rhruiz/communigate-cli"
    gem.authors = ["Ricardo Hermida Ruiz"]
    gem.add_development_dependency "rspec"
  end
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "teste #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
