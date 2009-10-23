require 'rubygems'
require 'rake'
require 'spec/rake/spectask'
require 'spec/rake/spectask'

desc "Run rspec with progress format"
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'lib/specifications'
  spec.spec_files = FileList['lib/specifications/**/*_spec.rb']
end

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'lib/specifications'
  spec.pattern = 'lib/specifications/**/*_spec.rb'
  spec.rcov = true
end

desc "Run rspec with specdoc format"
Spec::Rake::SpecTask.new(:specdoc) do |spec|
  spec.libs << 'lib' << 'lib/specifications'
  spec.spec_opts = ["--colour --format specdoc --loadby --reverse"]
  spec.spec_files = FileList['lib/specifications/**/*_spec.rb']
end

task :default => :spec

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
