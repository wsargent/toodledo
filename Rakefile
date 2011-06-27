# -*- ruby -*-

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
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
    EOF
    gem.homepage = "http://github.com/wsargent/toodledo"
    gem.authors = ["Will Sargent"]

    gem.executables = [ 'toodledo' ]

    gem.add_dependency('cmdparse')
    gem.add_dependency('highline')

    gem.add_development_dependency('flexmock')
  end

  # Set up publishing to rubygems.
  #Jeweler::RubygemsDotOrgTasks.new

  # To publish to gemcutter, do the following...
  # rake gemcutter:release
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Cannot load jeweler"
end

# vim: syntax=Ruby
