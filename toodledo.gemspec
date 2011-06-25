# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{toodledo}
  s.version = "1.3.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Will Sargent"]
  s.date = %q{2010-10-05}
  s.default_executable = %q{toodledo}
  s.description = %q{== DESCRIPTION:

This is a Ruby API and client for http://toodledo.com, a task management 
website. It implements all of the calls from Toodledo's developer API, and 
provides a nice wrapper around the functionality.

The client allows you to work with Toodledo from the command line. It will
work in either interactive or command line mode.

You can also use the client in your shell scripts, or use the API directly
as part of a web application.  Custom private RSS feed?  Want to have the Mac 
read out your top priority?  Input tasks through Quicksilver?  Print out
tasks with a BetaBrite?  It can all happen.}
  s.email = %q{will@tersesystems.com}
  s.executables = ["toodledo"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = [
       "History.txt", 
       "Manifest.txt", 
       "README.txt",
       "Rakefile",
       "bin/toodledo", 
       "lib/toodledo.rb", 
       "lib/toodledo/command_line/add_command.rb", 
       "lib/toodledo/command_line/base_command.rb", 
       "lib/toodledo/command_line/client.rb", 
       "lib/toodledo/command_line/complete_command.rb", 
       "lib/toodledo/command_line/context_formatter.rb", 
       "lib/toodledo/command_line/delete_command.rb", 
       "lib/toodledo/command_line/edit_command.rb",
       "lib/toodledo/command_line/folder_formatter.rb", 
       "lib/toodledo/command_line/goal_formatter.rb", 
       "lib/toodledo/command_line/hotlist_command.rb", 
       "lib/toodledo/command_line/interactive_command.rb",
       "lib/toodledo/command_line/list_contexts_command.rb",
       "lib/toodledo/command_line/list_folders_command.rb", 
       "lib/toodledo/command_line/list_goals_command.rb",
       "lib/toodledo/command_line/list_tasks_by_context_command.rb",
       "lib/toodledo/command_line/list_tasks_command.rb",
       "lib/toodledo/command_line/parser_helper.rb",
       "lib/toodledo/command_line/setup_command.rb",
       "lib/toodledo/command_line/stdin_command.rb",
       "lib/toodledo/command_line/task_formatter.rb", 
       "lib/toodledo/context.rb",
       "lib/toodledo/folder.rb", 
       "lib/toodledo/goal.rb", 
       "lib/toodledo/invalid_configuration_error.rb",
       "lib/toodledo/priority.rb", 
       "lib/toodledo/repeat.rb",
       "lib/toodledo/server_error.rb",
       "lib/toodledo/session.rb", 
       "lib/toodledo/status.rb",
       "lib/toodledo/task.rb",
       "test/client_test.rb",
       "test/parser_helper_test.rb",
       "test/session_test.rb", 
       "test/toodledo_functional_test.rb"
  ]
  s.homepage = %q{http://gemcutter.org/gems/toodledo}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{toodledo}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{A command line client and API to Toodledo}
  s.test_files = ["test/client_test.rb", "test/parser_helper_test.rb", "test/session_test.rb", "test/toodledo_functional_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<cmdparse>, [">= 0"])
      s.add_runtime_dependency(%q<highline>, [">= 0"])
      s.add_development_dependency(%q<rubyforge>, [">= 2.0.4"])
      s.add_development_dependency(%q<flexmock>, [">= 0"])
      s.add_development_dependency(%q<hoe>, [">= 2.6.2"])
    else
      s.add_dependency(%q<cmdparse>, [">= 0"])
      s.add_dependency(%q<highline>, [">= 0"])
      s.add_dependency(%q<rubyforge>, [">= 2.0.4"])
      s.add_dependency(%q<flexmock>, [">= 0"])
      s.add_dependency(%q<hoe>, [">= 2.6.2"])
    end
  else
    s.add_dependency(%q<cmdparse>, [">= 0"])
    s.add_dependency(%q<highline>, [">= 0"])
    s.add_dependency(%q<rubyforge>, [">= 2.0.4"])
    s.add_dependency(%q<flexmock>, [">= 0"])
    s.add_dependency(%q<hoe>, [">= 2.6.2"])
  end
end
