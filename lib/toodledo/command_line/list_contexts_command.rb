# 
# 
# 
 
module Toodledo  
  module CommandLine
    

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
   
  end
end 