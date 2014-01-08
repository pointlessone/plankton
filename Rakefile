require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new("spec") do |c|
  c.rspec_opts = "-t ~slow"
end

desc "Run slow RSpec code examples"
RSpec::Core::RakeTask.new("spec:slow") do |c|
  c.rspec_opts = "-t slow"
end
