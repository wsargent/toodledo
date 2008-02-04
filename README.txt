toodledo
    by Will Sargent
    http://toodledo.rubyforge.org

== DESCRIPTION:

This is a Ruby API and client for http://toodledo.com, a task management 
website. It implements all of the calls from Toodledo's developer API, and 
provides a nice wrapper around the functionality.

The client allows you to work with Toodledo from the command line. It will
work in either interactive or command line mode.

You can also use the client in your shell scripts, or use the API directly
as part of a web application.

== FEATURES/PROBLEMS:

* Command line client interface
* Interactive client interface
* Fully featured session based API
* Supports Proxy and SSL usage
* PROBLEM: Priority support is weak
* PROBLEM: Due Date support is weak

== SYNOPSIS:
 
  Toodledo has a particularly rich model of a task, and allows full GTD
  type state to be attached to them.  The client syntax for the client
  is as follows:

  *Folder
  @Context
  $Goal
  
  You can encase the symbol with square brackets if there is a space
  involved:
  
  *[Blue Sky]
  @[Someday / Maybe]
  $[Write Toodledo Ruby API]

  The client will also allow you to filter by symbols.
    
  * in
  * complete
  * hotlist
  
  Let's use the command line client to list only the tasks you have in the office:
  
  toodledo list '@Office *Action'
  
  Now let's add a task with several symbols:
  
  toodledo add '*Action @Programming $[Write Toodledo Ruby API] Write documentation'

  If you want to write your own scripts, working with Toodledo is very
  simple, since it will use the YAML config file:

  require 'toodledo'
  Toodledo.begin do |session|
    # work with session
  end
  
  If you want to work with the session directly, then you should do
  this instead:
  
  require 'toodledo/session'
  session = Session.new(userid, password)
  session.connect()

== REQUIREMENTS:

* A connection to the Internet
* An account to http://toodledo.com
* Your Toodledo userid (see http://www.toodledo.com/info/api_doc.php)
* Ruby

== INSTALL:

* sudo gem install toodledo
* toodledo setup
* toodledo

== LICENSE:
