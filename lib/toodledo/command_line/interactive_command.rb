require 'toodledo/command_line/parser_helper'
require 'logger'

module Toodledo
  
  module CommandLine
    # Runs the interactive client.
    class InteractiveCommand < BaseCommand
      
      def initialize(client)
        super(client, 'interactive', false)
        self.short_desc = "Interactive client"
        self.description = "The interactive command line client."
      end
      
      def execute(args)
        Toodledo.begin(client.logger) do |session|
          command_loop(session)
        end
      end
      
      def command_loop(session)
        loop do
          begin
            input = ask("> ") do |q|
              q.readline = true
            end
            
            input.strip!
            
            client.execute_command(input)            
          rescue Toodledo::ItemNotFoundError => infe
            puts "Item not found: #{infe}"
          rescue Toodledo::ServerError => se
            puts "Server Error: #{se}"
          rescue RuntimeError => re
            puts "Error: #{re}"      
          end
        end # loop    
      end      
    end
  end
end
