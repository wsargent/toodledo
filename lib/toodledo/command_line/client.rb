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
require 'toodledo/command_line/add_command'
require 'toodledo/command_line/list_command'
require 'toodledo/command_line/edit_command'
require 'toodledo/command_line/hotlist_command'
require 'toodledo/command_line/complete_command'
require 'toodledo/command_line/delete_command'
require 'toodledo/command_line/setup_command'

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
      def set_context_filter(session, input)
        if (input == nil)
          input = ask("Selected context? > ") { |q| q.readline = true }
        end
        
        input.strip!
        
        if (input =~ /^(\d+)$/)
          context = session.get_context_by_id(input)
          if (context != nil)
            @filters[:context] = context.name
          else
            @filters[:context] = input
          end    
        else
          @filters[:context] = input
        end
      end 
      
      #
      # Sets the folder filter.  Subsequent calls to show tasks
      # will only show tasks that are in this folder.
      #
      def set_folder_filter(session, input)
        if (input == nil)
          input = ask("Selected folder? > ") { |q| q.readline = true }
        end
        
        input.strip!
        
        if (input =~ /^(\d+)$/)
          folder = session.get_folder_by_id(input)
          if (folder != nil)
            @filters[:folder] = folder.name
          else
            @filters[:folder] = input
          end    
        else
          @filters[:folder] = input
        end
      end
      
      # Sets the goal filter.  Subsequent calls to show tasks
      # will only show tasks that have this goal.
      #
      def set_goal_filter(session, input)
        if (input == nil)
          input = ask("Selected goal? > ") { |q| q.readline = true }
        end
      
        input.strip!
        
        if (input =~ /^(\d+)$/)
          goal = session.get_goal_by_id(input)
          if (goal != nil)
            @filters[:goal] = goal.name
          else
            @filters[:goal] = input
          end    
        else
          @filters[:goal] = input
        end
      end
      
      # Sets the priority filter.
      def set_priority_filter(session, input)
        if (input == nil)
          input = ask("Selected priority? > ") { |q| q.readline = true }  
        end
        
        input.strip!
        
        if (input =~ /^(\d+)$/)
          value = input.to_i
        else
          value = parse_priority('!' + input.downcase)
        end
        
        if (! Priority.valid?(value))
          print "Unknown priority \"#{input}\" -- (priority must be one of top, high, medium, low, or negative)"
        end
        
        @filters[:priority] = value
      end
      
      #
      # Shows all the filters.
      #
      def list_filters()        
        if (@filters.empty?)
          print "No filters."
          return
        end
        
        @filters.each do |k, v|
          print "#{k}: #{v}\n"
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
      # Shows all the folders for this user.
      #
      def folders(session)
        my_folders = session.get_folders()
        
        my_folders.sort! do |a, b|
          a.name <=> b.name
        end
        
        for folder in my_folders
          print @formatters[:folder].format(folder)
        end
      end
      
      #
      # Shows all the contexts for this user.
      #
      def contexts(session)
        my_contexts = session.get_contexts()
        
        my_contexts.sort! do |a, b|
          a.name <=> b.name
        end
        
        for context in my_contexts
          print @formatters[:context].format(context)
        end
      end
      
      #
      # Shows all the goals for this user.
      #
      def goals(session)
        my_goals = session.get_goals()
        
        my_goals.sort! do |a, b|
          a.level <=> b.level
        end
        
        for goal in my_goals
          print @formatters[:goal].format(goal)
        end
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
      
      # Adds a single task, using toodledo symbols.  This is the most general way to 
      # add a task right now.  If you have symbols which have spaces, then you must
      # encase them in square brackets.  
      #
      # The order of symbols does not matter, but the title must be the last thing
      # on the line.
      #
      # add @[Deep Space] *Action $[For Great Justice] Take off every Zig
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
        
        title = input.strip
        
        goal_id = session.add_goal(title)
        
        print "Goal #{goal_id} added."
      end
      
      def add_folder(session, input)
        
        title = input.strip
        
        folder_id = session.add_folder(title)
        
        print "Folder #{folder_id} added."
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
      def print(line)        
        say line
      end
      
      #
      # Displays the help message.
      #
      def help()
        puts "hotlist -- shows the hotlist\n"
        puts "tasks -- shows tasks ('tasks *Action @Home')"
        puts "list -- does the same as tasks"
        puts 
        puts "add -- adds a task ('add *Action @Home Eat breakfast')"
        puts "edit -- edits a task ('edit *Action 1134')"
        puts "complete -- completes a task ('complete 1234')\n"
        puts "delete -- deletes a task ('delete 1134')"
        puts
        puts "context -- defines a context filter on tasks"
        puts "goal -- defines a goal filter on tasks"
        puts "folder -- defines a folder filter on tasks\n"
        puts "priority -- defines a priority filter on tasks\n"
        puts "unfilter -- removes all filters on tasks\n"
        puts
        puts "folders -- shows all folders\n"
        puts "goals -- shows all goals"
        puts "contexts -- shows all contexts"
        puts
        puts "config -- displays the current configuration"
        puts
        puts "help or ? -- displays this help message\n"
        puts "quit or exit -- Leaves the application"
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
          add_task(session, line)
          
          when /^edit/
          line = clean(/^edit/, input)
          edit_task(session, line)
          
          when /^delete/
          line = clean(/^delete/, input)
          delete_task(session, line)
          
          when /^hotlist/
          line = clean(/^hotlist/, input)
          hotlist(session, line)
          
          when /^complete/
          line = clean(/^complete/, input)
          complete_task(session, line)
          
          when /^tasks/, /^list/
          line = clean(/^(tasks|list)/, input)
          list_tasks(session, line)
          
          when /^folders/
          line = clean(/^folders/, input)
          folders(session)
          
          when /^goals/
          goals(session)
          
          when /^contexts/
          contexts(session)
          
          when /^context/
          line = clean(/^context/, input)
          set_context_filter(session, line)
          
          when /^folder/
          line = clean(/^folder/, input)
          set_folder_filter(session, line)
          
          when /^goal/
          line = clean(/^goal/, input)
          set_goal_filter(session, line)
          
          when /^priority/
          line = clean(/^priority/, input)
          set_priority_filter(session, line)
          
          when /^config/
          show_config(session)
          
          when /^filters/
          list_filters()
          
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
        
        cmd.add_command(AddCommand.new(self))
        cmd.add_command(ListCommand.new(self))
        cmd.add_command(EditCommand.new(self))
        cmd.add_command(CompleteCommand.new(self))
        cmd.add_command(DeleteCommand.new(self))
        cmd.add_command(HotlistCommand.new(self))
        cmd.add_command(SetupCommand.new(self))
                
        cmd.add_command(CmdParse::HelpCommand.new)
        cmd.add_command(CmdParse::VersionCommand.new)
        
        cmd.parse
        
        # Return a good exit status.
        return 0      
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
