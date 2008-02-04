module Toodledo  
  module CommandLine
    class SetupCommand < BaseCommand
      def initialize(client)
        super(client, 'setup', false)
        self.short_desc = "Setup the configuration file"
        self.description = "Creates (and edits) the configuration file for Toodledo."
      end
      
      def execute(args)
        client.setup
      end   
    end
  end
end