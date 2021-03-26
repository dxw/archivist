$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require "dotenv/tasks"

begin
  require "rspec/core/rake_task"

  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

require "archivist"

task default: %i[spec prettier]

task :prettier do
  exec("bundle exec rbprettier --write '**/*.*' Rakefile Gemfile")
end

namespace :archivist do
  task configure: :dotenv do
    Archivist.configure
  end

  task archive_channels: %i[dotenv configure] do
    Archivist::ArchiveChannels.new.run
  end
end
