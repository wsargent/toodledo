require 'rubygems'

require 'cmdparse'
require 'fileutils'
require 'highline/import'
require 'yaml'

require 'toodledo'
require 'toodledo/command_line/parser_helper'
require 'toodledo/command_line/base_command'
require 'toodledo/command_line/interactive_command'
require 'toodledo/command_line/stdin_command'
require 'toodledo/command_line/setup_command'

# CREATE
require 'toodledo/command_line/add_command'

# READ
require 'toodledo/command_line/hotlist_command'
require 'toodledo/command_line/list_tasks_command'
require 'toodledo/command_line/list_folders_command'
require 'toodledo/command_line/list_contexts_command'
require 'toodledo/command_line/list_goals_command'

# UPDATE
require 'toodledo/command_line/edit_command'
require 'toodledo/command_line/complete_command'

# DELETE
require 'toodledo/command_line/delete_command'

# FORMATTERS
require 'toodledo/command_line/task_formatter'
require 'toodledo/command_line/context_formatter'
require 'toodledo/command_line/folder_formatter'
require 'toodledo/command_line/goal_formatter'

module Toodledo  
  module CommandLine
    
    #
    # The toodledo client.  This provides a command line based client to the 
    # user and gives a good overview of the capabilities of the API as well.
    #
    # Author::    Will Sargent (mailto:will@tersesystems.com)
    # Copyright:: Copyright (c) 2008 Will Sargent
    # License::   GLPL v3
    class Client
      
      include Toodledo::CommandLine::ParserHelper
                
      HOME = ENV["HOME"] || ENV["HOMEPATH"] || File::expand_path("~")
      TOODLEDO_D = File::join(HOME, ".toodledo")
      CONFIG_F = File::join(TOODLEDO_D, "user-config.yml")
      
      # We must use __FILE__ instead of DATA because this is now a library
      # and DATA is relative to $0, not __FILE__.
      CONFIG = File.read(__FILE__).split(/__END__/).last.gsub(/#\{(.*)\}/) { eval $1 }
    
      #
      # Creates the client object.
      #            
      def initialize(userconfig=CONFIG_F, opts={})
        @filters = {}
        @debug = false
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::FATAL
        
        @userconfig = test(?e, userconfig) ? IO::read(userconfig) : CONFIG
        @userconfig = YAML.load(@userconfig).merge(opts)
        @formatters = { 
          :task => TaskFormatter.new,
          :goal => GoalFormatter.new,
          :context => ContextFormatter.new,
          :folder => FolderFormatter.new
        }
      end
      
      def debug?
        return @debug
      end
      
      def debug=(is_debug)
        @debug = is_debug
        if (@debug == true)
          @logger.level = Logger::DEBUG
        else
          @logger.level = Logger::FATAL
        end
      end
            
      def logger
        return @logger
      end
            
      #
      # Invites the user to setup the YAML file.
      #
      def setup
        FileUtils::mkdir_p TOODLEDO_D, :mode => 0700 unless test ?d, TOODLEDO_D
        test ?e, CONFIG_F and FileUtils::mv CONFIG_F, "#{CONFIG_F}.bak"
        config = CONFIG[/\A.*(?=^\# AUTOCONFIG)/m]
        open(CONFIG_F, "w") { |f| f.write config }
    
        edit = (ENV["EDITOR"] || ENV["EDIT"] || "vi") + " '#{CONFIG_F}'"
        system edit or puts "edit '#{CONFIG_F}'"
      end
      
      #
      # Displays the configuration information that the session is
      # currently using.
      #
      def show_config(session)
        base_url = session.base_url
        user_id = session.user_id
        proxy = session.proxy
        
        print "base_url = #{base_url}"    
        print "user_id = #{user_id}"
        print "proxy = #{proxy.inspect}"
      end

      # Sets the context filter.  Subsequent calls to show tasks
      # will only show tasks that have this context.
      # 
      def set_filter(session, input)
        logger.debug("set_filter(#{input})")
        
        input.strip!
        
        context = parse_context(input)
        if (context != nil)
          c = session.get_context_by_name(context)
          if (c == nil)
            print "No such context: #{context}"
            return
          end
          @filters[:context] = c
        end
        
        goal = parse_goal(input)
        if (goal != nil)
          g = session.get_goal_by_name(goal)
          if (g == nil)
            print "No such goal: #{goal}"
            return
          end
          @filters[:goal] = g
        end
        
        folder = parse_folder(input)
        if (folder != nil)
          f = session.get_folder_by_name(folder)
          if (f == nil)
            print "No such folder: #{folder}"
          end
          @filters[:folder] = f
        end
        
        priority = parse_priority(input)
        if (priority != nil)
          @filters[:priority] = priority
        end
        
        if (logger)
          logger.debug("@filters = #{@filters.inspect}")
        end
      end 
      
      #
      # Shows all the filters.
      #
      def list_filters()        
        if (@filters == nil || @filters.empty?)
          print "No filters."
          return
        end
        
        @filters.each do |k, v|
          if (v.respond_to? :name)
            name = v.name
          else
            name = v
          end
          print "#{k}: #{name}\n"
        end
      end
      
      #
      # Clears all the filters.
      #
      def unfilter()
        @filters = {}
        print "Filters cleared.\n"
      end
            
      #
      # Displays the 'hotlist' of tasks.  This shows all the uncompleted items with
      # priority set to 3 or 2.  There's no facility in the API for this, so we have
      # to cheat a bit.  
      #
      # It may be worthwhile to allow the ability to tweak what constitutes a 'hotlist'
      # but that'll come by demand.  Or patches.  Fully documented patches, mmmm.
      #
      def hotlist(session, input)
        logger.debug("hotlist: #{input}")
        
        # See if there's input following the command.
        context = parse_context(input)
        folder = parse_folder(input)
        goal = parse_goal(input)
        priority = parse_priority(input)
        
        params = { :notcomp => true }
        
        # If there are, they override what we have set.
        if (folder != nil)
          params.merge!({ :folder => folder })
        end
        
        if (context != nil)
          params.merge!({ :context => context })
        end
        
        if (goal != nil)
          params.merge!({ :goal => goal })
        end
        
        if (priority != nil)
          params.merge!({ :priority => priority })
        end
              
        tasks = session.get_tasks(params)
        
        # Highest priority first
        tasks.sort! do |a, b|
          b.priority <=> a.priority
        end
        
        # filter on our end.
        # Surprisingly, we can't search for "greater than 0 priority" with the API.
        not_important = Priority::MEDIUM
        
        for task in tasks
          if (task.priority > not_important)
            print @formatters[:task].format(task)
          end
        end
      end
            
      #
      # Lists tasks (subject to any filters that may be present).
      #
      def list_tasks(session, input)
        logger.debug("list_tasks(#{input})")
        
        params = { :notcomp => true }
        
        params.merge!(@filters)
        
        # See if there's input following the 'tasks' command.
        context = parse_context(input)
        folder = parse_folder(input)
        goal = parse_goal(input)
        priority = parse_priority(input)
        
        # If there are, they override what we have set.
        if (folder != nil)
          params.merge!({ :folder => folder })
        end
        
        if (context != nil)
          params.merge!({ :context => context })
        end
        
        if (goal != nil)
          params.merge!({ :goal => goal })
        end
        
        if (priority != nil)
          params.merge!({ :priority => priority })
        end
                
        tasks = session.get_tasks(params)
        
        # Highest priority first
        tasks.sort! do |a, b|
          b.priority <=> a.priority
        end
        
        for task in tasks  
          print @formatters[:task].format(task)
        end
      end
      
      #
      # Lists the goals.  Takes an optional argument of 
      # 'short', 'medium' or 'life'.
      #
      def list_goals(session, input)
        
        input.strip!
        input.downcase!
                
        goals = session.get_goals()
        
        goals.sort! do |a, b|
          a.level <=> b.level
        end
        
        level_filter = nil
        case input
        when 'short'
          level_filter = Goal::SHORT_LEVEL
        when 'medium'
          level_filter = Goal::MEDIUM_LEVEL
        when 'life'
          level_filter = Goal::LIFE_LEVEL
        end
        
        for goal in goals
          if (level_filter != nil && goal.level != level_filter)
            next # skip this goal if it doesn't meet the filter
          end
          print @formatters[:goal].format(goal)
        end
      end
      
      #
      # Lists the contexts.
      #
      def list_contexts(session, input)
        params = { }
        
        contexts = session.get_contexts()
        
        for context in contexts
          print @formatters[:context].format(context)
        end
      end
      
      #
      # Lists the folders.
      #
      def list_folders(session, input)
        params = { }
        
        folders = session.get_folders()
        
        for folder in folders
          print @formatters[:folder].format(folder)
        end
      end
      
      # Adds a single task, using toodledo symbols.  This is the most general way to 
      # add a task right now.  If you have symbols which have spaces, then you must
      # encase them in square brackets.  
      #
      # The order of symbols does not matter, but the title must be the last thing
      # on the line.
      #
      # add @[Deep Space] *Action ^[For Great Justice] Take off every Zig
      #
      # There is no priority handling in this method.  It may be added if there is
      # demand for it.
      def add_task(session, line)        
        context = parse_context(line)
        folder = parse_folder(line)
        goal = parse_goal(line)
        priority = parse_priority(line)
        title = parse_remainder(line)
        
        params = {}
        if (priority != nil)
          params.merge!({ :priority => priority })
        end
        
        if (folder != nil)
          params.merge!({ :folder => folder })
        end
        
        if (context != nil)
          params.merge!({ :context => context })
        end
        
        if (goal != nil)
          params.merge!({ :goal => goal })
        end
        
        # If we got nothing but 'add' then ask for it explicitly.
        if (title == nil)
          title = ask("Task name: ") { |q| q.readline = true }
        end
        
        task_id = session.add_task(title, params)
        
        print "Task #{task_id} added."
      end
      
      def add_context(session, input)
        
        title = input.strip
        
        context_id = session.add_context(title)
        
        print "Context #{context_id} added."
      end
      
      def add_goal(session, input)
        input.strip!
        
        # Assume that a goal is short, medium or life, and
        # don't stick a symbol on it.
        level = parse_level(input)
        if (level == nil)
          level = Toodledo::Goal::SHORT_LEVEL
        else
          input = clean(LEVEL_REGEXP, input)
          input.strip!
        end
        
        goal_id = session.add_goal(input, level)
        
        print "Goal #{goal_id} added."
      end
      
      def add_folder(session, input)
        
        title = input.strip
        
        folder_id = session.add_folder(title)
        
        print "Folder #{folder_id} added."
      end
      
      #
      # Archives a folder.
      #
      def archive_folder(session, line)
        
        line.strip!
        
        folder_id = line
        params = { :archived => 1 }
        session.edit_folder(folder_id, params)
        
        print "Folder #{folder_id} archived."
      end
      
      def archive_goal(session, line)
        # Not implemented!  No way to edit a goal.
      end
      
      #
      # Edits a single task.  This method allows you to change the symbols on a
      # task.  Note that you must specify the ID here.  
      #
      # edit *Action 12345
      def edit_task(session, input)  
        logger.debug("edit_task: #{input.inspect}")
        
        context = parse_context(input)
        folder = parse_folder(input)
        goal = parse_goal(input)
        priority = parse_priority(input)
        task_id = parse_remainder(input)
        
        logger.debug("edit_task: task_id = #{task_id}")
        
        if (task_id == nil)
          task_id = ask("Task ID?: ") { |q| q.readline = true }
        end
        
        task_id.strip!
        
        params = {  }
        
        if (folder != nil)
          params.merge!({ :folder => folder })
        end
        
        if (context != nil)
          params.merge!({ :context => context })
        end
        
        if (goal != nil)
          params.merge!({ :goal => goal })
        end
        
        if (priority != nil)
          params.merge!({ :priority => priority })
        end
        
        session.edit_task(task_id, params)
        
        print "Task #{task_id} edited."
      end
      
      # Masks the task as completed.  Uses a task id as argument.
      #
      # complete 123
      #
      def complete_task(session, line)        
        task_id = line
        
        if (task_id == nil)
          task_id = ask("Task ID?: ") { |q| q.readline = true }  
        end
        
        task_id.strip!
                
        params = { :completed => 1 }
        if (session.edit_task(task_id, params))
          print "Task #{task_id} completed."
        else
          print "Task #{task_id} could not be completed!"      
        end
      end
      
      
      # Deletes a task, using the task id. 
      #
      # delete 123 
      #
      def delete_task(session, line)        
        task_id = line
        
        if (task_id == nil)
          task_id = ask("Task ID?: ") { |q| q.readline = true }
        end
        
        task_id.strip!
        
        if (session.delete_task(task_id))
          print "Task #{task_id} deleted."
        else
          print "Task #{task_id} could not be deleted!"      
        end
      end
      
      def delete_context(session, line)
        id = line
        
        id.strip!
        
        if (session.delete_context(id))
          print "Context #{id} deleted."
        else
          print "Context #{id} could not be deleted!"      
        end
      end

      def delete_goal(session, line)
        id = line
        
        id.strip!
        
        if (session.delete_goal(id))
          print "Goal #{id} deleted."
        else
          print "Goal #{id} could not be deleted!"      
        end
      end

      def delete_folder(session, line)
        id = line
        
        id.strip!
        
        if (session.delete_folder(id))
          print "Folder #{id} deleted."
        else
          print "Folder #{id} could not be deleted!"      
        end
      end
        
      # Prints out a single line.
      def print(line = nil)
        if (line == nil)
          puts
        else
          puts line
        end
      end
      
      #
      # Displays the help message.
      #
      def help()
        print "hotlist      Shows the hotlist"
        print "folders      Shows all folders"
        print "goals        Shows all goals"
        print "contexts     Shows all contexts"
        print "tasks        Shows tasks ('tasks *Action @Home')"
        print 
        print "add          Adds task ('add *Action @Home Eat breakfast')"
        print "  folder     Adds a folder ('add folder MyFolder')"
        print "  context    Adds a context ('add context MyContext')"
        print "  goal       Adds a goal ('add goal MyGoal')"
        print "edit         Edits a task ('edit *Action 1134')"
        print "complete     Completes a task ('complete 1234')"
        print "delete       Deletes a task ('delete 1134')"
        print "  folder     Deletes a folder ('delete folder 1')"
        print "  context    Deletes a context ('delete context 2')"
        print "  goal       Deletes a goal ('delete goal 3')"
        print 
        print "archive      Archives a folder ('archive 1234')"
        print "filter       Defines filters ('filter *Action @Someday')"
        print "unfilter     Removes all filters"
        print "filters      Displays the list of filters"
        print
        print "help or ?    Displays this help message"
        print "quit or exit Leaves the application"
      end
      
      def clean(regexp, input)
        return input.sub(regexp, '')
      end
      
      def execute_command(session, input)    
        case input
          when /^help/, /^\s*\?/
          help()
          
          when /^add/
          line = clean(/^add/, input)
          line.strip!
          case line
          when /folder/
            add_folder(session, clean(/folder/, line))
          when /context/
            add_context(session, clean(/context/, line))
          when /goal/
            add_goal(session, clean(/goal/, line))
          else
            add_task(session, line)
          end
          
          when /^edit/
          line = clean(/^edit/, input)
          edit_task(session, line)
          
          when /^delete/
          line = clean(/^delete/, input)
          line.strip!
          case line
          when /folder/
            delete_folder(session, clean(/folder/, line))
          when /context/
            delete_context(session, clean(/context/, line))
          when /goal/
            delete_goal(session, clean(/goal/, line))
          else
            delete_task(session, line)            
          end
          
          when /^archive/
          archive_folder(session, clean(/^archive/, input))
          
          when /^hotlist/
          line = clean(/^hotlist/, input)
          hotlist(session, line)
          
          when /^complete/
          line = clean(/^complete/, input)
          complete_task(session, line)
          
          when /^tasks/
          line = clean(/^(tasks)/, input)
          list_tasks(session, line)
          
          when /^folders/
          line = clean(/^folders/, input)
          list_folders(session,line)
          
          when /^goals/
          line = clean(/^goals/, input)
          list_goals(session,line)
          
          when /^contexts/
          line = clean(/^contexts/, input)
          list_contexts(session,line)
          
          when /^filters/
          list_filters()
          
          when /^filter/
          line = clean(/^filter/, input)
          set_filter(session, line)
          
          when /^config/
          show_config(session)
          
          when /^unfilter/
          unfilter()
          
          when /debug/
          self.debug = ! self.debug?
          
          when /^quit/, /^exit/
          exit 0
        else
          print "'#{input}' is not a command: type help for a list"
        end
      end
            
      #
      # Runs the client main command.  This is what gets run from 'toodledo'.
      # Ironically doesn't do much except for set up the commands and parse
      # arguments from the command line.  The MainCommand class does the 
      # actual command loop.
      #
      def main()                
        # Set the configuration from the YAML file.
        Toodledo.set_config(@userconfig)
        
        # Set up the command parser.
        graceful_exception = true
        partial_cmd_matching = true
        cmd = CmdParse::CommandParser.new(graceful_exception, partial_cmd_matching)
        cmd.program_name = "toodledo"
        cmd.program_version = Toodledo::VERSION
        
        # Options (must be before help and version are added)
        cmd.options = CmdParse::OptionParserWrapper.new do |opt|
          opt.separator "Global options:"
          opt.on("--debug", "Print debugging information") {|t| self.debug = true }
        end

        # this is the default command if we don't receive any options.
        cmd.add_command(InteractiveCommand.new(self), true)
        
        cmd.add_command(StdinCommand.new(self))
        
        cmd.add_command(AddTaskCommand.new(self))
        
        cmd.add_command(ListTasksCommand.new(self))
        cmd.add_command(ListFoldersCommand.new(self))
        cmd.add_command(ListGoalsCommand.new(self))
        cmd.add_command(ListContextsCommand.new(self))
        
        cmd.add_command(EditCommand.new(self))
        cmd.add_command(CompleteCommand.new(self))
        cmd.add_command(DeleteTaskCommand.new(self))
        cmd.add_command(HotlistCommand.new(self))
        cmd.add_command(SetupCommand.new(self))
                
        cmd.add_command(CmdParse::HelpCommand.new)
        cmd.add_command(CmdParse::VersionCommand.new)
        
        cmd.parse
        
        # Return a good exit status.
        return 0      
      rescue InvalidConfigurationError => e
        logger.debug(e)
        print "The client is missing (or cannot use) the user id or password it needs to connect."
        print "Run 'toodledo setup' and save the file to fix this."
        return -1
      rescue ServerError => e
        print "The server returned a fatal error: #{e.message}"
        return -1
      end      
    end #class    
  end  
end

__END__
#
# The connection to Toodledo.
#
connection:
#
# If you have a Pro account, you can use HTTPS instead of HTTP
  url: http://www.toodledo.com/api.php

# 
# If you are logged in to Toodledo, you should be able to see
# your userid at this URL: 
#
# http://www.toodledo.com/info/api_doc.php
#  
  user_id: 
  
#
# Your password
#
  password: 

#
# Uncomment this section if you are working through a proxy
#
#proxy:
#  host: 
#  port:
#  user:
#  password:
# AUTOCONFIG:
