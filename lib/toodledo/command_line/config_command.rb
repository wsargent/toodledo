module Toodledo  
  module CommandLine
    class ConfigCommand < BaseCommand
      def initialize(client)
        super(client, 'config', false)
        self.short_desc = "Shows configuration options"
        #self.description = "The interactive command line client."
      end
      
      def execute( args )
        
      end   
    end
  end
end