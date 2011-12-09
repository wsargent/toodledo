require 'toodledo/priority'

module Toodledo
  
  module CommandLine

    # 
    # Methods to parse a string and identify it as a Toodledo symbol.
    # 
    module ParserHelper
      
      # TODO These regexps are highly repetitive. Refactor
      FOLDER_REGEXP = /\*((\w+)|\[(.*?)\])/
  
      GOAL_REGEXP = /\^((\w+)|\[(.*?)\])/
  
      CONTEXT_REGEXP = /\@((\w+)|\[(.*?)\])/
      
      PRIORITY_REGEXP = /!(top|high|medium|low|negative|-1|0|1|2|3)/
      
      DATE_REGEXP = /\#(([^\[]\S*)|\[(.*?)\])/
      
      TAGS_REGEXP = /\%((\w+)|\[(.*?)\])/
      
      STAR_REGEXP = /\*\s+|\*$/

      # Note that level must exist at the beginning of the line
      LEVEL_REGEXP = /^(life|medium|short)/
      
      # Don't include level regexp
      REGEXP_LIST = [ 
        FOLDER_REGEXP, 
        STAR_REGEXP,
        GOAL_REGEXP,
        CONTEXT_REGEXP, 
        PRIORITY_REGEXP,
        DATE_REGEXP,
        TAGS_REGEXP
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
      
      # Parses a date in the format #[2011-03-17]
      def parse_date(input)
        match_data = DATE_REGEXP.match(input)
        return match_data if (match_data == nil)    
        return strip_brackets(match_data[1])
      end
      
      # Parses a list of tags in the format %[tag1 tag2 tag3]
      # TODO Allow %tag1, tag2, tag3 ? (This is the format Toodledo's Twitter client uses)
      def parse_tag(input)
        match_data = TAGS_REGEXP.match(input)
        return match_data if (match_data == nil)    
        return strip_brackets(match_data[1]).split(/\s+/)
      end
  
      # Parses priority in the format !priority (top, high, medium, low,
      # negative)
      # TODO Refactor using data-driven design
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
        when '-1'
          return Toodledo::Priority::NEGATIVE
        when '0'
          return Toodledo::Priority::LOW
        when '1'
          return Toodledo::Priority::MEDIUM
        when '2'
          return Toodledo::Priority::HIGH
        when '3'
          return Toodledo::Priority::TOP

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
  
      def parse_star(input)
        match_data = STAR_REGEXP.match(input)
        if (match_data == nil)
          return false
        else
          return true
        end
      end         


      # Returns the bit after we've looked for *Folder, @Context & ^Goal & star
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
