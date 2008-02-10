require 'toodledo/command_line/parser_helper'
require 'logger'

module Toodledo
  
  module CommandLine
    # Runs the interactive client.
    class MainCommand < BaseCommand
      
      def initialize(client)
        super(client, 'interactive', false)
        self.short_desc = "Interactive client"
        self.description = "The interactive command line client."        
      end
      
      def execute(args)        
        if (client.debug?)
          logger = Logger.new(STDOUT)
          logger.level == Logger::DEBUG
        end
        
        Toodledo.begin(logger) do |session|            
          command_loop(session)
        end
      end
      
      #
      # Displays the help message.
      #
      def help()
        puts "hotlist -- shows the hotlist\n"
        puts "tasks -- shows tasks ('tasks $[World Peace] *MyFolder' -- filters also apply)"
        puts "list -- does the same as tasks"
        puts 
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
        puts "config -- displays the current configuration"
        puts
        puts "help or ? -- displays this help message\n"
        puts "quit or exit -- Leaves the application"
      end
      
      def clean(regexp, input)
        return input.sub(regexp, '')
      end
      
      def command_loop(session)
        loop do
          begin
            input = ask("> ") do |q|
              q.readline = true
            end
            
            input.strip!
            
            case input
              when /^help/, /^\s*\?/
              help()
              
              when /^add/
              line = clean(/^add/, input)
              client.add_task(session, line)
              
              when /^edit/
              line = clean(/^edit/, input)
              client.edit_task(session, line)
              
              when /^delete/
              line = clean(/^delete/, input)
              client.delete_task(session, line)
              
              when /^hotlist/
              line = clean(/^hotlist/, input)
              client.hotlist(session, line)
              
              when /^complete/
              line = clean(/^complete/, input)
              client.complete_task(session, line)
              
              when /^tasks/, /^list/
              line = clean(/^(tasks|list)/, input)
              client.list_tasks(session, line)
              
              when /^folders/
              line = clean(/^folders/, input)
              client.folders(session)
              
              when /^goals/
              client.goals(session)
              
              when /^contexts/
              client.contexts(session)
              
              when /^context/
              line = clean(/^context/, input)
              client.set_context_filter(session, line)
              
              when /^folder/
              line = clean(/^folder/, input)
              client.set_folder_filter(session, line)
              
              when /^goal/
              line = clean(/^goal/, input)
              client.set_goal_filter(session, line)
              
              when /^priority/
              line = clean(/^priority/, input)
              client.set_priority_filter(session, line)
              
              when /^config/
              client.show_config(session)
              
              when /^filters/
              client.list_filters()
              
              when /^unfilter/
              client.unfilter()
              
              when /^quit/, /^exit/
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
      
    end
    
  end
end