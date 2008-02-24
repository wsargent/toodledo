# 
# 
# 
 

module Toodledo  
  module CommandLine
    
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

  end
end