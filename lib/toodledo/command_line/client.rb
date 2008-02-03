require 'rubygems'
require 'cmdparse'
require 'highline/import'

require 'toodledo/command_line/parser_helper'

require 'toodledo/command_line/main_command'
require 'toodledo/command_line/add_command'
require 'toodledo/command_line/list_command'
require 'toodledo/command_line/edit_command'
require 'toodledo/command_line/complete_command'
require 'toodledo/command_line/delete_command'

module Toodledo
  
  module CommandLine
    
    #
    # The toodledo client.  This provides a command line based client to the 
    # user and gives a good overview of the capabilities of the API as well.
    #
    # Note that this client does not add or delete goals, folders, or contexts.
    # 
    class Client
      
      def main()
        
        # Set up the command parser.
        cmd = CmdParse::CommandParser.new(true, true)
        cmd.program_name = "toodledo"
        cmd.program_version = Toodledo::VERSION
        cmd.add_command(CmdParse::HelpCommand.new)
        cmd.add_command(CmdParse::VersionCommand.new)
        
        cmd.add_command(MainCommand.new, true) # this is the default
        
        cmd.add_command(AddCommand.new)
        cmd.add_command(ListCommand.new)
        cmd.add_command(EditCommand.new)
        cmd.add_command(CompleteCommand.new)
        cmd.add_command(DeleteCommand.new)
        
        cmd.options = CmdParse::OptionParserWrapper.new do |opt|
          opt.separator "Global options:"
          opt.on("--verbose", "Be verbose when outputting info") {|t| @verbose = true }
        end
        
        cmd.parse
        
        # Return a good exit status.
        return 0      
      end
      
    end #class
    
  end
  
end