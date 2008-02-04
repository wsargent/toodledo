
module Toodledo  
  module CommandLine
    class AddCommand < BaseCommand
      
      include Toodledo::CommandLine::ParserHelper
      
      def initialize(client)
        super(client, 'add', false)
        self.short_desc = "Add a task"
        self.description = "Adds a task to Toodledo"
      end
      
      def execute(args)
        return if (args == nil)
        
        Toodledo.begin do |session|            
          line = args.join(' ')
          client.add_task(session, line)
        end
      end      
    end
  end  
end