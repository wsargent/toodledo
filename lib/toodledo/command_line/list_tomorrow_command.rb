
module Toodledo  
  module CommandLine
    
    #
    # Lists the tasks.
    #
    class ListTomorrowCommand < BaseCommand
      def initialize(client)
        super(client, 'tomorrow', false)
        self.short_desc = "Tomorrow's tasks"
        self.description = "Lists tasks for tomorrow in Toodledo."
      end
      
      def execute(args)
	line = args.join(' ')        
 
        Toodledo.begin(client.logger) do |session|            
          return client.list_tomorrow_tasks(session, line)
        end
        
        return 0
      end
    end
    
    
  end
end
