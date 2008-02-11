module Toodledo 
  module CommandLine       
    class HotlistCommand < BaseCommand
      def initialize(client)
        super(client, 'hotlist', false)
        self.short_desc = "Show the hotlist"
        self.description = "Shows the hotlist in Toodledo."
      end
      
      def execute(args)  
        if (client.debug?)
          logger = Logger.new(STDOUT)
          logger.level = Logger::DEBUG
        end
        
        Toodledo.begin(logger) do |session|   
          line = args.join(' ')
          client.hotlist(session, line)
        end
      end
    end
  end 
end