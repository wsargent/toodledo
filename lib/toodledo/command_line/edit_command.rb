
module Toodledo
  
  module CommandLine
    class EditCommand < BaseCommand
       def initialize(client)
         super(client, 'edit', false)
         self.short_desc = "Edit a task"
         self.description = "Edits a task in toodledo."
       end
       
      def execute(args)
        Toodledo.begin(client.logger) do |session|       
          line = args.join(' ')
          return client.edit_task(session, line)
        end
        
        return 0
      rescue ItemNotFoundError => e
        puts e.message
        return -1
      end
    end
  end
  
end