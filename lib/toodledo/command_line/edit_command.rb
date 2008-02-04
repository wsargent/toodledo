
module Toodledo
  
  module CommandLine
    class EditCommand < BaseCommand
       def initialize(client)
         super(client, 'edit', false)
         self.short_desc = "Edit a task"
         self.description = "Edits a task in toodledo."
       end
       
      def execute(args)
        Toodledo.begin do |session|       
          line = args.join(' ')
          client.edit_task(session, line)
        end
      end
    end
  end
  
end