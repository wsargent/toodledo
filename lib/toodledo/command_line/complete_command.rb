
module Toodledo
  
  module CommandLine
    class CompleteCommand < CmdParse::Command
       def initialize
         super('complete', false)
         self.short_desc = "Complete a task"
         #self.description = "The interactive command line client."
       end

       def execute( args )

       end       
    end
  end
  
end