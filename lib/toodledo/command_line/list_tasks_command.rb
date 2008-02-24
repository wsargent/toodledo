
module Toodledo  
  module CommandLine
    
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
    
    
  end
end