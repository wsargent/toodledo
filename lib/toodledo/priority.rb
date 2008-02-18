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
    
  end
end
