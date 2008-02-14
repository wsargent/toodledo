module Toodledo  
  module CommandLine
    class CompleteCommand < BaseCommand
      def initialize(client)
        super(client, 'complete', false)
        self.short_desc = "Complete a task"
        self.description = "Completes a task in Toodledo."
      end
      
      def execute(args)
        
        Toodledo.begin(client.logger) do |session|            
          line = args.join(' ')
          client.complete_task(session, line)
        end
        
        return 0
      rescue ItemNotFoundError => e
        puts e.message
        return -1
      end       
    end
  end  
end