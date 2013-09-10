require 'rubygems'
require 'rake'
require 'rake/testtask'

task :default => :test
Rake::TestTask.new do |t|
  # t.libs.push "lib"
  t.test_files = FileList['lib/specifications/*spec.rb']
  t.verbose = true
end
