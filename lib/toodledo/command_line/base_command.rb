require 'cmdparse'

module Toodledo  
  module CommandLine        
    class BaseCommand < CmdParse::Command      
      def initialize(client, name, subtasks = false)
        super(name, subtasks)
        raise "Nil client!" if (client == nil)
        @client = client        
      end
      
      def client
        return @client
      end
      
      def logger
        return @logger
      end
      
    end
  end
end
  
  
 