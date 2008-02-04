require 'rubygems'
require 'cmdparse'
require 'highline/import'
require 'logger'

require 'toodledo/command_line/parser_helper'
require 'toodledo/command_line/base_command'
require 'toodledo/command_line/main_command'
require 'toodledo/command_line/add_command'
require 'toodledo/command_line/list_command'
require 'toodledo/command_line/edit_command'
require 'toodledo/command_line/hotlist_command'
require 'toodledo/command_line/complete_command'
require 'toodledo/command_line/delete_command'

module Toodledo
  
  module CommandLine
    
    #
    # The toodledo client.  This provides a command line based client to the 
    # user and gives a good overview of the capabilities of the API as well.
    # 
    class Client
      
      include Toodledo::CommandLine::ParserHelper
            
      def initialize()
        @filters = {}
        @verbose = false        
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::ERROR
      end
      
      def debug?        
        return (@logger.level == Logger::DEBUG)
      end
      
      def debug=(is_debug)
        if (is_debug == true)          
          @logger.level = Logger::DEBUG
        else
          @logger.level = Logger::ERROR
        end
      end
      
      def verbose?
        return @verbose
      end
      
      def verbose=(is_verbose)
        @verbose = is_verbose
      end
      
      def logger
        return @logger        
      end
      
      # Sets the context filter.  Subsequent calls to show tasks
      # will only show tasks that have this context.
      # 
      def set_context_filter(session, input)
        session.debug = debug?
        
        regexp = /\s*context\s*(.*)/
        md = regexp.match(input)
        input = md[1]
        
        if (input == nil)
          input = ask("Selected context? > ") { |q| q.readline = true }
        end
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
        session.debug = debug?
        
        regexp = /\s*folder\s*(.*)/
        md = regexp.match(input)
        input = md[1]
        
        if (input == nil)
          input = ask("Selected folder? > ") { |q| q.readline = true }
        end
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
        session.debug = debug?
        
        regexp = /\s*goal\s*(.*)/
        md = regexp.match(input)
        input = md[1]
        
        if (input == nil)
          input = ask("Selected goal? > ") { |q| q.readline = true }
        end
        
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
      
      # Sets the context filter.  Subsequent calls to show tasks
      # will only show tasks that have this context.
      #
      def set_priority_filter(session, input)
        session.debug = debug?
        
        input = ask("Selected priority? > ") { |q| q.readline = true }  
        
        # XXX Should look for 'high' / 'medium' / 'low' and convert
        
        @filters[:priority] = input
      end
      
      #
      # Shows all the filters.
      #
      def list_filters()        
        if (@filters.empty?)
          puts "No filters."
          return
        end
        
        @filters.each do |k, v|
          puts "#{k}: #{v}\n"
        end
      end
      
      #
      # Clears all the filters.
      #
      def unfilter()
        @filters = {}
        puts "Filters cleared.\n" if (verbose?)
      end
      
      
      #
      # Shows all the folders for this user.
      #
      def folders(session)
        session.debug = debug?
        
        my_folders = session.get_folders()
        
        my_folders.sort! do |a, b|
          a.name <=> b.name
        end
        
        for folder in my_folders
          puts "<#{folder.server_id}> -- #{folder}\n"
        end
      end
      
      #
      # Shows all the contexts for this user.
      #
      def contexts(session)
        session.debug = debug?
        
        my_contexts = session.get_contexts()
        
        my_contexts.sort! do |a, b|
          a.name <=> b.name
        end
        
        for context in my_contexts
          puts "<#{context.server_id}> -- #{context}\n"
        end
      end
      
      #
      # Shows all the goals for this user.
      #
      def goals(session)
        session.debug = debug?
        
        my_goals = session.get_goals()
        
        my_goals.sort! do |a, b|
          a.level <=> b.level
        end
        
        for goal in my_goals
          puts "<#{goal.server_id}> -- #{goal}\n"
        end
      end
      
      #
      # Displays the 'hotlist' of tasks.  This shows all the uncompleted items with
      # priority set to 3 or 2.  There's no facility in the API for this, so we have
      # to cheat a bit.
      #
      def hotlist(session, input)
        session.debug = debug?
        
        # Surprisingly, we can't search for "greater than 0 priority" with the API.
        not_important = 1
        params = { :notcomp => true }
        tasks = session.get_tasks(params)
        
        # Highest priority first
        tasks.sort! do |a, b|
          b.priority <=> a.priority
        end
        
        # filter on our end.
        for task in tasks
          if (task.priority > not_important)
            puts "<#{task.server_id}> -- #{task}\n"
          end
        end
      end
      
      # Dumps something into the inbasket folder.  Does NO matching for toodledo symbols.
      def inbasket(session, input)
        session.debug = debug?
        
        # The title is the rest of the line, if it exists.
        regexp = /\s*in\s*(.*)/
        md = regexp.match(input)
        title = md[1] if (md != nil)
        if (title == nil)
          title = ask("Task name: ") { |q| q.readline = true }
        end
        
        params = { :folder => "Inbasket", :priority => "medium" }
        result = session.add_task(title, params)
        
        puts "Task <#{result}> added."
      end
      
      def list_tasks(session, input)
        session.debug = debug?
        
        params = { :notcomp => true }
        
        params.merge!(@filters)
        
        # See if there's input following the 'tasks' command.
        context = parse_context(input)
        folder = parse_folder(input)
        goal = parse_goal(input)
        
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
        
        tasks = session.get_tasks(params)
        
        # Highest priority first
        tasks.sort! do |a, b|
          b.priority <=> a.priority
        end
        
        for task in tasks  
          puts "<#{task.server_id}> -- #{task}\n"
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
        session.debug = debug?
        
        context = parse_context(line)
        folder = parse_folder(line)
        goal = parse_goal(line)
        title = parse_remainder(line)
        
        # XXX priority handling is kinda neglected right now...
        params = { :priority => "medium" }
        
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
        
        puts "Task #{task_id} added."
      end
      
      #
      # Edits a single task.  This method allows you to change the symbols on a
      # task.  Note that you must specify the ID here.  
      #
      # edit *Action 12345
      def edit_task(session, input)
        session.debug = debug?
        
        context = parse_context(input)
        folder = parse_folder(input)
        goal = parse_goal(input)
        task_id = parse_remainder(input)
        
        params = {  }
        
        if (task_id == nil)
          task_id = ask("Task ID?: ") { |q| q.readline = true }
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
        
        session.edit_task(task_id, params)
        
        puts "Task #{task_id} added." if (verbose?)
      end
      
      # Masks the task as completed.  Uses a task id as argument.
      #
      # complete 123
      #
      def complete_task(session, input)
        session.debug = debug?
        
        regexp = /\s*\w+\s*(.*)/
        md = regexp.match(input)
        task_id = md[1]
        
        if (task_id == nil)
          task_id = ask("Task ID?: ") { |q| q.readline = true }  
        end
        
        params = { :completed => 1 }
        if (session.edit_task(task_id, params))
          puts "Task #{task_id} completed." if (verbose?)
        else
          puts "Task #{task_id} could not be completed!"      
        end
      end
      
      # Deletes a task, using the task id. 
      #
      # delete 123 
      #
      def delete_task(session, line)
        session.debug = debug?
        
        task_id = line
        
        if (task_id == nil)
          task_id = ask("Task ID?: ") { |q| q.readline = true }
        end
        
        if (session.delete_task(task_id))
          puts "Task #{task_id} deleted." if (verbose?)
        else
          puts "Task #{task_id} could not be deleted!"      
        end
      end
      
      def main()
        
        # Set up the command parser.
        graceful_exception = true
        partial_cmd_matching = true
        cmd = CmdParse::CommandParser.new(graceful_exception, partial_cmd_matching)
        cmd.program_name = "toodledo"
        cmd.program_version = Toodledo::VERSION
        
        # Options (must be before help and version are added)
        cmd.options = CmdParse::OptionParserWrapper.new do |opt|
          opt.separator "Global options:"
          opt.on("--verbose", "Be verbose when outputting info") {|t| self.verbose = true }
          opt.on("--debug", "Print debugging information") {|t| self.debug = true }
        end
        
        # this is the default command if we don't receive any options.
        cmd.add_command(MainCommand.new(self), true)
        
        cmd.add_command(AddCommand.new(self))
        cmd.add_command(ListCommand.new(self))
        cmd.add_command(EditCommand.new(self))
        cmd.add_command(CompleteCommand.new(self))
        cmd.add_command(DeleteCommand.new(self))
        cmd.add_command(HotlistCommand.new(self))
        # cmd.add_command(ConfigCommand.new(self))
        
        cmd.add_command(CmdParse::HelpCommand.new)
        cmd.add_command(CmdParse::VersionCommand.new)
        
        cmd.parse
        
        # Return a good exit status.
        return 0      
      end
      
    end #class
    
  end
  
end