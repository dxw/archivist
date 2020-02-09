$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require "dotenv/tasks"

begin
  require "rspec/core/rake_task"

  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

begin
  require "standard/rake"
rescue LoadError
end

require "archivist"

task default: %i[spec standard]

namespace :archivist do
  task configure: :dotenv do
    Archivist.configure
  end
end
