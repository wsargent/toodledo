
module Toodledo
  
  module CommandLine
    class EditCommand < BaseCommand
       def initialize(client)
         super(client, 'edit', false)
         self.short_desc = "Edit a task"
         self.description = "Edits a task in toodledo."
       end
       
      def execute(args)
        if (client.debug?)
          logger = Logger.new(STDOUT)
          logger.level = Logger::DEBUG
        end
        
        Toodledo.begin(logger) do |session|       
          line = args.join(' ')
          client.edit_task(session, line)
        end
      end
    end
  end
  
end