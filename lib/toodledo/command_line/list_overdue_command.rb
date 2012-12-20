
module Toodledo  
  module CommandLine
    
    #
    # Lists the tasks.
    #
    class ListOverdueCommand < BaseCommand
      def initialize(client)
        super(client, 'overdue', false)
        self.short_desc = "Overdue tasks"
        self.description = "Lists overdue tasks in Toodledo."
      end
      
      def execute(args)
	line = args.join(' ')        
        Toodledo.begin(client.logger) do |session|            
          return client.list_overdue_tasks(session, line)
        end
        
        return 0
      end
    end
    
    
  end
end
