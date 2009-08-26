require 'rake'
require 'spec/rake/spectask'

desc "Run rspec with progress format"
task :default do
  options = "--colour --format progress --loadby --reverse"
  files = FileList['spec/**/*_spec.rb']
  system("spec #{options} #{files}")
end

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('rcov') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
  t.rcov_opts = ['--no-html', '-T', '-exclude', 'spec']
end

desc "Run rspec with specdoc format"
task :specdoc do
  options = "--colour --format specdoc --loadby --reverse"
  files = FileList['spec/**/*_spec.rb']
  system("spec #{options} #{files}")
end

begin
  require 'jeweler'
  project_name = 'communigate'
  Jeweler::Tasks.new do |gem|
    gem.name = project_name
    gem.summary = "Interact with CommuniGatePro CLI interface"
    gem.email = "ricardo.ruiz@locaweb.com.br"
    gem.homepage = "http://github.com/rhruiz/#{project_name}"
    gem.authors = ["Ricardo Hermida Ruiz"]
  end
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
