module Toodledo  
  module CommandLine
    
    #
    # List Tasks By Context
    #
    class ListTasksByContextCommand < BaseCommand
      def initialize(client)
        super(client, 'nested', false)
        self.short_desc = "List tasks by context"
        self.description = "Lists the tasks grouped by context."
      end
      
      def execute(args)
        
        Toodledo.begin(client.logger) do |session|            
          line = args.join(' ')
          return client.list_tasks_by_context(session, line)
        end
        
        return 0
      end
    end

  end
end