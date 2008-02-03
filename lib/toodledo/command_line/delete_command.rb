
module Toodledo
  module CommandLine
    class DeleteCommand < CmdParse::Command
      def initialize
        super('delete', false)
        self.short_desc = "Deletes a task"
        self.description = "This command deletes a task from Toodledo."
      end

      def execute( args )

      end
    end
  end
end