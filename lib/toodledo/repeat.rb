# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

module Toodledo
  class Repeat
    
    NONE = 0
    WEEKLY = 1
    MONTHLY = 2
    YEARLY = 3
    DAILY = 4
    BIWEEKLY = 5
    BIMONTHLY = 6
    SEMIANNUALLY = 7
    QUARTERLY = 8
    
    REPEAT_ARRAY = [
      NONE,
      WEEKLY,
      MONTHLY,
      YEARLY,
      DAILY,
      BIWEEKLY,
      BIMONTHLY,
      SEMIANNUALLY,
      QUARTERLY
    ]
    
    def self.each
      REPEAT_ARRAY.each{|value| yield(value)}
    end
    
    def self.valid?(input)
      for repeat in REPEAT_ARRAY
        if (repeat == input) 
          return true
        end
      end
      return false
    end
  end
end
