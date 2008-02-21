
module Toodledo  
  module CommandLine
    
    #
    # Adds commands
    #
    class AddCommand < CmdParse::Command
      def initialize(client)
        super('add', true)
        self.short_desc = 'Adds an object'
        
        self.add_command(AddTaskCommand.new(client), true)
        self.add_command(AddFolderCommand.new(client))
        self.add_command(AddGoalCommand.new(client))
        self.add_command(AddContextCommand.new(client))
      end
    end
    
    #
    # Adds a folder from the command
    #
    class AddFolderCommand < BaseCommand
      
      include Toodledo::CommandLine::ParserHelper
      
      def initialize(client)
        super(client, 'folder', false)
        self.short_desc = "Add a folder"
        self.description = "Adds a folder to Toodledo"
      end
      
      def execute(args)
        return if (args == nil)                
        Toodledo.begin(client.logger) do |session|            
          line = args.join(' ')
          client.add_folder(session, line)
        end
          
        return 0
      rescue ItemNotFoundError => e
        puts e.message
        return -1
      end 
    end
    
    #
    # Adds a goal from the command line
    #
    class AddGoalCommand < BaseCommand
      
      include Toodledo::CommandLine::ParserHelper
      
      def initialize(client)
        super(client, 'goal', false)
        self.short_desc = "Add a goal"
        self.description = "Adds a goal to Toodledo"
      end
      
      def execute(args)
        return if (args == nil)                
        Toodledo.begin(client.logger) do |session|            
          line = args.join(' ')
          client.add_goal(session, line)
        end
          
        return 0
      rescue ItemNotFoundError => e
        puts e.message
        return -1
      end 
    end
    
    # 
    # Adds a context from the command line
    #
    class AddContextCommand < BaseCommand
     
      def initialize(client)
        super(client, 'context', false)
        self.short_desc = "Adds context"
        self.description = "Adds a context to Toodledo"
      end
       
      def execute(args)
        return if (args == nil)                
        Toodledo.begin(client.logger) do |session|            
          line = args.join(' ')
          client.add_context(session, line)
        end
          
        return 0
      rescue ItemNotFoundError => e
        puts e.message
        return -1
      end 
    end
    
    #
    # Adds a task from the command line.
    #
    class AddTaskCommand < BaseCommand
      
      def initialize(client)
        super(client, 'task', false)
        self.short_desc = "Add a task"
        self.description = "Adds a task to Toodledo"
      end
      
      def execute(args)
        return if (args == nil)                
        Toodledo.begin(client.logger) do |session|            
          line = args.join(' ')
          client.add_task(session, line)
        end
          
        return 0
      rescue ItemNotFoundError => e
        puts e.message
        return -1
      end      
    end
  end  
end