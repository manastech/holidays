require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_spec.rb']
end

task :default => :test
