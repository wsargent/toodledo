require 'toodledo/command_line/parser_helper'
require 'logger'

module Toodledo
  
  module CommandLine
    # Runs the stdin client.
    class StdinCommand < BaseCommand
      
      def initialize(client)
        super(client, 'stdin', false)
        self.short_desc = "Takes standard input"
        self.description = "Useful for pipes and redirected files"
      end
      
      def execute(args)
        Toodledo.begin(client.logger) do |session|
          $stdin.each do |line|
            line.strip!
            
            if (line == nil || line.empty?) 
              return 0
            end
            
            client.execute_command(session, line)
          end
        end
      end
    end
  end
end
