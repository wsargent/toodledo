
module Toodledo
  
  module CommandLine

    #
    # Methods to parse a string and identify it as a Toodledo symbol.
    #
    module ParserHelper
  
      FOLDER_REGEXP = /\*((\w+)|\[(.*?)\])/
  
      GOAL_REGEXP = /\$((\w+)|\[(.*?)\])/
  
      CONTEXT_REGEXP = /\@((\w+)|\[(.*?)\])/
  
      # Parses a context in the format @Context or @[Spaced Context]
      def parse_context(input)
        match_data = CONTEXT_REGEXP.match(input)
        return nil if (match_data == nil)    
        return strip_brackets(match_data[1])
      end
  
      # Parses a folder in the format *Folder or *[Spaced Folder]
      def parse_folder(input)
        match_data = FOLDER_REGEXP.match(input)    
        return match_data if (match_data == nil)
        return strip_brackets(match_data[1])
      end
  
      # Parses a goal in the format $Goal or $[Spaced Goal]
      def parse_goal(input)
        match_data = GOAL_REGEXP.match(input)
        return match_data if (match_data == nil)    
        return strip_brackets(match_data[1])
      end
  
      # Returns the bit after we've looked for *Folder, @Context & $Goal
      def parse_remainder(line)    
        
        input = line

        # Strip out anything that isn't folder, goal or context.
        for regexp in [ FOLDER_REGEXP, GOAL_REGEXP, CONTEXT_REGEXP]
          input = input.sub(regexp, '')
        end
    
        input.strip!
    
        return input
      end
  
      # Strips a string of [ and ] characters
      def strip_brackets(inword)    
        return inword.gsub(/\[|\]/, '')
      end
    end
  end
end
