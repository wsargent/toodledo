
module Toodledo
  
  module CommandLine
    class ListCommand < CmdParse::Command
       def initialize
         super('list', false)
         self.short_desc = "List tasks"
         self.description = "The interactive command line client."
       end
       
       def execute( args )
        
       end
    end
  end
  
end