# -*- ruby -*-

require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  require 'lib/toodledo/version'
  Jeweler::Tasks.new do |gem|
    gem.version = Toodledo::Version::VERSION

    # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
    gem.name = "toodledo"
    gem.author = 'Will Sargent'
    gem.email = 'will.sargent@gmail.com'
    gem.summary = 'A command line client and API to Toodledo'
    gem.description = <<-EOF
This is a Ruby API and client for http://toodledo.com, a task management
website. It implements all of the calls from Toodledo's developer API, and
provides a nice wrapper around the functionality.

The client allows you to work with Toodledo from the command line. It will
work in either interactive or command line mode.

You can also use the client in your shell scripts, or use the API directly
as part of a web application.  Custom private RSS feed?  Want to have the Mac
read out your top priority?  Input tasks through Quicksilver?  Print out
tasks with a BetaBrite?  It can all happen.

Check it out: http://aosekai.net/2011/09/quickly-add-new-task-to-toodledo-with-alfred/
    EOF
    gem.homepage = "http://github.com/wsargent/toodledo"
    gem.authors = ["Will Sargent"]

    gem.executables = [ 'toodledo' ]

    gem.add_dependency('cmdparse')
    gem.add_dependency('highline')

    gem.add_development_dependency('flexmock')
  end

  # Set up publishing to rubygems.
  Jeweler::RubygemsDotOrgTasks.new
rescue LoadError
  puts "Cannot load jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "toodledo #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

# vim: syntax=Ruby
