module Toodledo 
  module CommandLine       
    class HotlistCommand < BaseCommand
      def initialize(client)
        super(client, 'hotlist', false)
        self.short_desc = "Show the hotlist"
        self.description = "Shows the hotlist in Toodledo."
      end
      
      def execute(args)        
        Toodledo.begin(client.logger) do |session|   
          line = args.join(' ')
          client.hotlist(session, line)
        end
        
        return 0
      end
    end
  end 
end