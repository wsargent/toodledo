require 'rubygems'
require 'cmdparse'
require 'highline/import'

module Toodledo
  
  module CommandLine
    
    
    #
    # The toodledo client.  This provides a command line based client to the 
    # user and gives a good overview of the capabilities of the API as well.
    #
    # Note that this client does not add or delete goals, folders, or contexts.
    # 
    class Client
      
      FOLDER_REGEXP = /\*((\w+)|\[(.*?)\])/
      
      GOAL_REGEXP = /\$((\w+)|\[(.*?)\])/
      
      CONTEXT_REGEXP = /\@((\w+)|\[(.*?)\])/
      
      # Toodledo config (will create .toodledo file with specs)
      def config
        
      end
      
      # Parses a context in the format @Context or @[Spaced Context]
      def parse_context(input)
        match_data = CONTEXT_REGEXP.match(input)
        return nil if (match_data == nil)    
        return strip_brackets(match_data[1])
      end
      
      # Parses a folder in the format *Folder or *[Spaced Folder]
      def parse_folder(input)
        match_data = FOLDER_REGEXP.match(input)    
        return match_data if (match_data == nil)
        return strip_brackets(match_data[1])
      end
      
      # Parses a goal in the format $Goal or $[Spaced Goal]
      def parse_goal(input)
        match_data = GOAL_REGEXP.match(input)
        return match_data if (match_data == nil)    
        return strip_brackets(match_data[1])
      end
      
      # Returns the bit after we've looked for *Folder, @Context & $Goal
      def parse_remainder(input)    
        biggest_pos = 0
        for regexp in [ FOLDER_REGEXP, GOAL_REGEXP, CONTEXT_REGEXP]
          match = regexp.match(input)
          next if (match == nil)
          re_end = match.end(0)
          biggest_pos = re_end if (biggest_pos < re_end)
        end
        
        return input[(biggest_pos+1)..input.length]
      end
      
      # Strips a string of [ and ] characters
      def strip_brackets(inword)    
        return inword.gsub(/\[|\]/, '')
      end
      
      # Sets the context filter.  Subsequent calls to show tasks
      # will only show tasks that have this context.
      # 
      def set_context_filter(session, input)
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
        puts "Filters cleared.\n"
      end
      
      
      #
      # Shows all the folders for this user.
      #
      def folders(session)
        folders = session.get_folders()
        
        folders.sort! do |a, b|
          a.name <=> b.name
        end
        
        for folder in folders
          puts "<#{folder.server_id}> -- #{folder}\n"
        end
      end
      
      #
      # Shows all the contexts for this user.
      #
      def contexts(session)
        contexts = session.get_contexts()
        
        contexts.sort! do |a, b|
          a.name <=> b.name
        end
        
        for context in contexts
          puts "<#{context.server_id}> -- #{context}\n"
        end
      end
      
      #
      # Shows all the goals for this user.
      #
      def goals(session)
        goals = session.get_goals()
        
        goals.sort! do |a, b|
          a.level <=> b.level
        end
        
        for goal in goals
          puts "<#{goal.server_id}> -- #{goal}\n"
        end
      end
      
      #
      # Displays the 'hotlist' of tasks.  This shows all the uncompleted items with
      # priority set to 3 or 2.  There's no facility in the API for this, so we have
      # to cheat a bit.
      #
      def hotlist(session, input)
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
      def add_task(session, input)
        
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
        
        success = session.edit_task(task_id, params)
        
        puts "Task #{task_id} added."
      end
      
      # Masks the task as completed.  Uses a task id as argument.
      #
      # complete 123
      #
      def complete_task(session, input)
        regexp = /\s*\w+\s*(.*)/
        md = regexp.match(input)
        task_id = md[1]
        
        if (task_id == nil)
          task_id = ask("Task ID?: ") { |q| q.readline = true }  
        end
        
        params = { :completed => 1 }
        if (session.edit_task(task_id, params))
          puts "Task #{task_id} completed."
        else
          puts "Task #{task_id} could not be completed!"      
        end
      end
      
      # Deletes a task, using the task id. 
      #
      # delete 123 
      #
      def delete_task(session, input)
        regexp = /\s*\w+\s*(.*)/
        md = regexp.match(input)
        task_id = md[1]
        
        if (task_id == nil)
          task_id = ask("Task ID?: ") { |q| q.readline = true }
        end
        
        if (session.delete_task(task_id))
          puts "Task #{task_id} deleted."
        else
          puts "Task #{task_id} could not be deleted!"      
        end
      end
      
      #
      # Displays the help message.
      #
      def help()
        puts "hotlist -- shows the hotlist (important and top priorities)\n"
        puts "tasks -- shows tasks ('tasks $[World Peace] *MyFolder' -- filters also apply)"
        puts 
        puts "in -- adds a task to *Inbasket, ignoring other symbols"
        puts "add -- adds a task ('add *Action @Home Eat breakfast')"
        puts "edit -- edits a task ('edit *Action 1134' will move 1134 to Action folder)"
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
        puts "help or ? -- displays this help message\n"
        puts "quit or exit -- Leaves the application"
      end
      
      def command_loop(session)
        loop do
          begin
            input = ask("> ") do |q|
              q.readline = true
            end
            
            case input
              when /config/
              config()
              when /^\s*help/, /^\s*\?/
              help()
              when /^\s*add/
              add_task(session, input)
              when /^\s*edit/
              edit_task(session, input)
              when /^\s*delete/
              delete_task(session, input)
              when /^\s*hotlist/
              hotlist(session, input)
              when /^\s*complete/
              complete_task(session, input)
              when /^\s*tasks/
              list_tasks(session, input)
              when /^\s*folders/
              folders(session)
              when /^\s*goals/
              goals(session)
              when /^\s*contexts/
              contexts(session)
              when /^\s*context/
              set_context_filter(session, input)
              when /^\s*folder/
              set_folder_filter(session, input)
              when /^\s*goal/
              set_goal_filter(session, input)
              when /^\s*priority/
              set_priority_filter(session)
              when /^\s*filters/
              list_filters()
              when /^\s*unfilter/
              unfilter()
              when /^\s*in/
              inbasket(session, input)
              when /^\s*quit/, /^\s*exit/
              break;
            else
              puts "'#{input}' is not a command: type help for a list"
            end
          rescue Toodledo::ItemNotFoundError => infe
            puts "Item not found: #{infe}"
          rescue Toodledo::ServerError => se
            puts "Server Error: #{se}"
          rescue RuntimeError => re
            puts "Error: #{re}"      
          end
        end # loop    
      end
      
      #
      # Kicks off the main command loop.
      #
      def main()
        @filters = {}
        
        Toodledo.begin do |session|
          # session.debug = true
          command_loop(session)
        end  
      end
      
      # Return a good exit status.
      return 0
    end #class
    
    
  end
  
end