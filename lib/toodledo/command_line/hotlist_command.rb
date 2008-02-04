module Toodledo 
  module CommandLine       
    class HotlistCommand < BaseCommand
      def initialize(client)
        super(client, 'hotlist', false)
        self.short_desc = "Show the hotlist"
        self.description = "Shows the hotlist in Toodledo."
      end
      
      def execute(args)        
        Toodledo.begin do |session|   
          line = args.join(' ')
          client.hotlist(session, line)
        end
      end
    end
  end 
end