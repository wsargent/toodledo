module Toodledo
  
  #
  # A priority enum.
  #
  class Priority
    
    NEGATIVE = -1
    
    LOW = 0
    
    MEDIUM = 1
    
    HIGH = 2
    
    TOP = 3
    
    PRIORITY_ARRAY = [ TOP, HIGH, MEDIUM, LOW, NEGATIVE ]
    
    def self.each
      PRIORITY_ARRAY.each{|value| yield(value)}
    end
    
    def self.valid?(input)
      for priority in PRIORITY_ARRAY
        if input == priority
          return true
        end        
      end
      return false
    end
    
    def self.convert(input)
      case input 
      when 'negative'
        return Priority::NEGATIVE
      when 'low'
        return Priority::LOW
      when 'medium'
        return Priority::MEDIUM
      when 'high'
        return Priority::HIGH
      when 'top'
        return Priority::TOP
      else
        raise ArgumentError.new("Unknown priority: #{input}") 
      end
    end
    
  end
end
