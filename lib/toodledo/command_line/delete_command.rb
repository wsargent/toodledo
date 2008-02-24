
module Toodledo
  module CommandLine
    
    class DeleteCommand < CmdParse::Command
      def initialize(client)
        super('delete', true)
        self.short_desc = "Deletes a context"
        
        self.add_command(DeleteContextCommand.new(client))
        self.add_command(DeleteGoalCommand.new(client))
        self.add_command(DeleteFolderCommand.new(client))
        
        self.add_command(DeleteTaskCommand.new(client), true)
      end

    end
    
    class DeleteContextCommand < BaseCommand
      def initialize(client)
        super(client, 'context', false)
        self.short_desc = "Deletes a context"
      end

      def execute(args)       
        Toodledo.begin(client.logger) do |session|            
          line = args.join(' ')
          client.delete_context(session, line)
        end
        
        return 0
      rescue ItemNotFoundError => e
        puts e.message
        return -1
      end
    end
    
    class DeleteFolderCommand < BaseCommand
      def initialize(client)
        super(client, 'folder', false)
        self.short_desc = "Deletes a folder"
      end

      def execute(args)       
        Toodledo.begin(client.logger) do |session|            
          line = args.join(' ')
          client.delete_folder(session, line)
        end
        
        return 0
      rescue ItemNotFoundError => e
        puts e.message
        return -1
      end
    end
    
    class DeleteGoalCommand < BaseCommand
      def initialize(client)
        super(client, 'goal', false)
        self.short_desc = "Deletes a goal"
      end

      def execute(args)       
        Toodledo.begin(client.logger) do |session|            
          line = args.join(' ')
          client.delete_goal(session, line)
        end
        
        return 0
      rescue ItemNotFoundError => e
        puts e.message
        return -1
      end
    end
    
    class DeleteTaskCommand < BaseCommand
      def initialize(client)
        super(client, 'delete', false)
        self.short_desc = "Deletes a task"
        self.description = "Deletes a task from Toodledo."
      end

      def execute(args)       
        Toodledo.begin(client.logger) do |session|            
          line = args.join(' ')
          client.delete_task(session, line)
        end
        
        return 0
      rescue ItemNotFoundError => e
        puts e.message
        return -1
      end
    end
    
    
  end
end