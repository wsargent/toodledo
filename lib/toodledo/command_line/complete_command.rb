module Toodledo  
  module CommandLine
    class CompleteCommand < BaseCommand
      def initialize(client)
        super(client, 'complete', false)
        self.short_desc = "Complete a task"
        self.description = "Completes a task in Toodledo."
      end
      
      def execute( args )
        # Parse the command line arguments
        return if (args == nil)
        
        Toodledo.begin do |session|            
          line = args.join(' ')
          client.complete_task(session, line)
        end
      end       
    end
  end  
end