require 'toodledo/priority'

module Toodledo
  
  module CommandLine

    # 
    # Methods to parse a string and identify it as a Toodledo symbol.
    # 
    module ParserHelper
      
      FOLDER_REGEXP = /\*((\w+)|\[(.*?)\])/
  
      GOAL_REGEXP = /\^((\w+)|\[(.*?)\])/
  
      CONTEXT_REGEXP = /\@((\w+)|\[(.*?)\])/
      
      PRIORITY_REGEXP = /!(top|high|medium|low|negative)/
      
      DATE_REGEXP = /\#((\w+)|\[(.*?)\])/
      
      # Note that level must exist at the beginning of the line
      LEVEL_REGEXP = /^(life|medium|short)/
      
      # Don't include level regexp
      REGEXP_LIST = [ 
        FOLDER_REGEXP, 
        GOAL_REGEXP,
        CONTEXT_REGEXP, 
        PRIORITY_REGEXP,
        DATE_REGEXP
      ]
  
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
  
      # Parses a goal in the format ^Goal or ^[Spaced Goal]
      def parse_goal(input)
        match_data = GOAL_REGEXP.match(input)
        return match_data if (match_data == nil)    
        return strip_brackets(match_data[1])
      end
      
      # Parses a date in the format <[2011-03-17]
      def parse_date(input)
        match_data = DATE_REGEXP.match(input)
        return match_data if (match_data == nil)    
        return strip_brackets(match_data[1])
      end
  
      # Parses priority in the format !priority (top, high, medium, low,
      # negative)
      def parse_priority(input)
        match_data = PRIORITY_REGEXP.match(input)
        if (match_data == nil)
          return nil         
        end
        
        p = match_data[1]
        case p
        when 'top'
          return Toodledo::Priority::TOP
        when 'high'
          return Toodledo::Priority::HIGH
        when 'medium'
          return Toodledo::Priority::MEDIUM
        when 'low'
          return Toodledo::Priority::LOW
        when 'negative'
          return Toodledo::Priority::NEGATIVE
        else
          return nil
        end
      end
      
      def parse_level(input)
        match_data = LEVEL_REGEXP.match(input)
        if (match_data == nil)
          return nil         
        end
        
        p = match_data[1]
        case p
        when 'life'
          return Toodledo::Goal::LIFE_LEVEL
        when 'medium'
          return Toodledo::Goal::MEDIUM_LEVEL
        when 'short'
          return Toodledo::Goal::SHORT_LEVEL
        else
          return nil
        end
      end
  
      # Returns the bit after we've looked for *Folder, @Context & ^Goal
      def parse_remainder(line)
        input = line

        # Strip out anything that isn't folder, goal or context.
        for regexp in REGEXP_LIST
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
