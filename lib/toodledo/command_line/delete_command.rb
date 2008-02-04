
module Toodledo
  module CommandLine
    class DeleteCommand < BaseCommand
      def initialize(client)
        super(client, 'delete', false)
        self.short_desc = "Deletes a task"
        self.description = "Deletes a task from Toodledo."
      end

      def execute(args)
        Toodledo.begin do |session|            
          line = args.join(' ')
          client.delete_task(session, line)
        end
      end
    end
  end
end