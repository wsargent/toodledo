= toodledo

* http://toodledo.rubyforge.org
* mailto:will@tersesystems.com

== DESCRIPTION:

This is a Ruby API and client for http://toodledo.com, a task management 
website. It implements all of the calls from Toodledo's developer API, and 
provides a nice wrapper around the functionality.

The client allows you to work with Toodledo from the command line. It will
work in either interactive or command line mode.

You can also use the client in your shell scripts, or use the API directly
as part of a web application.  Custom private RSS feed?  Want to have the Mac 
read out your top priority?  Input tasks through Quicksilver?  Print out
tasks with a BetaBrite?  It can all happen.

== FEATURES/PROBLEMS:

* Command line client interface
* Interactive client interface
* Fully featured session based API
* Supports Proxy and SSL usage
* Easy configuration and automation (Quicksilver / Scripts / Automator)

== SYNOPSIS:

=== SETUP:

The first thing you should do is open up your browser and go to:

  http://www.toodledo.com/info/api_doc.php

and retrieve your userid.  You will need this for setup.

Build the gem. 'gem build toodledo.gemspec'

Then, install toodledo.  This is either 'gem install toodledo-1.3.6.gem' or 
'sudo gem install toodledo-1.3.6.gem' depending on your platform.

Then, type 'toodledo setup' and enter your userid and password in
the spaces provided.  Then save the file, and you're good to go.

=== COMMAND LINE:
 
You can add tasks.  The simplest form is here:

  toodledo add 'This is a test'
  
But tasks don't have to be simple.  Toodledo has a particularly rich model of 
a task, and allows full GTD type state to be attached to them.  The syntax 
for the client is as follows:

  *Folder
  @Context
  ^Goal
  !Priority
  #Today

You can encase the symbol with square brackets if there is a space involved:

  *[Blue Sky]
  @[Someday / Maybe]
  ^[Write Toodledo Ruby API]
  !top
  #[2011-03-18]
  
Let's use the command line client to list only the tasks you have in the office:

  toodledo tasks '@Office *Action'

Now let's add a task with several symbols:

  toodledo add '*Action @Programming ^[Write Toodledo Ruby API] Write docs'

Now let's add a date:

  toodledo add Write docs #Today

You can also edit tasks, using the task id.  This sets the folder to Someday:

  toodledo edit '*Someday 15934131'

And finally you can complete or delete tasks, again using the task id.

  toodledo complete 15934131
  toodledo delete 15934131

=== INTERACTIVE MODE:

Toodledo also comes with an interactive mode that is used if no arguments are 
found:

  toodledo 
  > add This is a test
  
You can type help at the prompt for a complete list of commands.  The client 
makes for a nice way to enter in tasks as you think of them.

The client will also allow you to set up filters.  Filters are added with
the symbols, so in interactive mode

  filter @Office *Action
  list

Then it produces the same results as:

  toodledo tasks '@Office *Action'

Finally, if you want to write your own scripts, working with Toodledo is very
simple, since it will use the YAML config file:

  require 'rubygems'
  require 'toodledo'
  Toodledo.begin do |session|
    # work with session
  end

If you want to work with the session directly, then you should do
this instead:

  require 'rubygems'
  require 'toodledo'
  session = Session.new(userid, password)
  session.connect()

== REQUIREMENTS:

* A connection to the Internet
* An account to http://toodledo.com
* Your Toodledo userid (see http://www.toodledo.com/info/api_doc.php)
* cmdparse
* highline
* rubygems

== INSTALL:

* sudo gem install toodledo
* toodledo setup (sets up the YAML file with your credentials)
* toodledo

== LICENSE:
		   GPL v3