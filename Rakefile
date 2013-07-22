require "bundler/gem_tasks"

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  warn "rspec not available"
end

if RUBY_PLATFORM == "java"
  task :cane do
    # Do nothing on JRuby
  end
else
  begin
    require 'cane/rake_task'

    desc "Run cane to check quality metrics"
    Cane::RakeTask.new(:cane) do |cane|
      cane.canefile = ".cane"
    end
  rescue LoadError
    warn "cane not available, quality task not provided."
  end
end

task :default => [:spec, :cane]
