#
# The possible values for the status field of a task.
#
class Status
  
    NONE = 0
    NEXT_ACTION = 1
    ACTIVE = 2
    PLANNING = 3
    DELEGATED = 4
    WAITING = 5
    HOLD = 6
    POSTPONED = 7
    SOMEDAY = 8
    CANCELLED = 9
    REFERENCE = 10
      
    STATUS_ARRAY = [
      NONE,
      NEXT_ACTION,
      ACTIVE,
      PLANNING,
      DELEGATED,
      WAITING,
      HOLD,
      POSTPONED,
      SOMEDAY,
      CANCELLED,
      REFERENCE
    ]
    
    def self.each
      STATUS_ARRAY.each{|value| yield(value)}
    end
    
    def self.valid?(input)
      for status in STATUS_ARRAY
        if (status == input) 
          return true
        end
      end
      return false
    end
end
