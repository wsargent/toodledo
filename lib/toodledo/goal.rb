module Toodledo
  
  #
  # A read only representation of a Goal.
  #
  class Goal
    
    LIFE_LEVEL = 0
    
    MEDIUM_LEVEL = 1
    
    SHORT_LEVEL = 2
    
    LEVEL_ARRAY = [ LIFE_LEVEL, MEDIUM_LEVEL, SHORT_LEVEL ]
    
    def self.valid?(input)
      for level in LEVEL_ARRAY
        if (level == input)
          return true
        end
      end
      return false
    end
    
    def initialize(id, level, contributes_id, name)    
      @id = id
      @level = level
      @contributes_id = contributes_id
      @contributes = nil
      @name = name
    end
    
    NO_GOAL = Goal.new(0, 0, 0, "No goal")
    
    attr_reader :level, :contributes_id, :name
    
    def contributes
      if (@contributes == nil)
        return NO_GOAL
      end
      return @contributes
    end
    
    def contributes=(parent_goal)
      @contributes = parent_goal
    end
    
    def server_id
      return @id
    end

  end
  
end