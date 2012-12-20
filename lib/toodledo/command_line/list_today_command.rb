
module Toodledo  
  module CommandLine
    
    #
    # Lists the tasks.
    #
    class ListTodayCommand < BaseCommand
      def initialize(client)
        super(client, 'today', false)
        self.short_desc = "Today's tasks"
        self.description = "Lists tasks for today in Toodledo."
      end
      
      def execute(args)
	line = args.join(' ')        
        Toodledo.begin(client.logger) do |session|            
          return client.list_today_tasks(session, line)
        end
        
        return 0
      end
    end
    
    
  end
end
