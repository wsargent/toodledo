
module Toodledo  
  module CommandLine
    
    #
    # Lists tasks, contexts, folders, goals.
    #
    class ListCommand < CmdParse::Command
      
       def initialize(client)
        super('list', true)
        self.short_desc = "List tasks, contexts, folders or goals."
        
        self.add_command(ListTasksCommand.new(client), true)
        self.add_command(ListContextsCommand.new(client))
        self.add_command(ListFoldersCommand.new(client))
        self.add_command(ListGoalsCommand.new(client))
      end
    end
    
    #
    # Lists the tasks.
    #
    class ListTasksCommand < BaseCommand
      def initialize(client)
        super(client, 'tasks', false)
        self.short_desc = "List tasks"
        self.description = "Lists the tasks in Toodledo."
      end
      
      def execute(args)
        
        Toodledo.begin(client.logger) do |session|            
          line = args.join(' ')
          return client.list_tasks(session, line)
        end
        
        return 0
      end
    end
    
    #
    # List Contexts
    #
    class ListContextsCommand < BaseCommand
      def initialize(client)
        super(client, 'contexts', false)
        self.short_desc = "List contexts"
        self.description = "Lists the contexts in Toodledo."
      end
      
      def execute(args)
        
        Toodledo.begin(client.logger) do |session|            
          line = args.join(' ')
          return client.list_contexts(session, line)
        end
        
        return 0
      end
    end
    
    #
    # List Goals
    #
    class ListGoalsCommand < BaseCommand
      def initialize(client)
        super(client, 'goals', false)
        self.short_desc = "List goals"
        self.description = "Lists the goals in Toodledo."
      end
      
      def execute(args)
        
        Toodledo.begin(client.logger) do |session|            
          line = args.join(' ')
          return client.list_goals(session, line)
        end
        
        return 0
      end
    end
    
    #
    # List Folders
    #
    class ListFoldersCommand < BaseCommand
      def initialize(client)
        super(client, 'folders', false)
        self.short_desc = "List folders"
        self.description = "Lists the folders in Toodledo."
      end
      
      def execute(args)
        
        Toodledo.begin(client.logger) do |session|            
          line = args.join(' ')
          return client.list_folders(session, line)
        end
        
        return 0
      end
    end
    
  end
end