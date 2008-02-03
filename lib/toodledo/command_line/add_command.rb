
module Toodledo
  
  module CommandLine
    class AddCommand < CmdParse::Command
      def initialize
        super('add', false)
        self.short_desc = "Add a task"
        self.description = "The interactive command line client."
      end
       
      def execute( args )

      end
    end
  end
  
end