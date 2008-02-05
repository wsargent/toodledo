module Toodledo
  
  #
  # A read only representation of a Goal.
  #
  class Goal
    
    def initialize(id, level, contributes_id, name)    
      @id = id
      @level = level
      @contributes_id = contributes_id
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
    
    def to_xml()
      return "<goal id=\"#{@id}\" level=\"#{@level}\" contributes=\"#{@contributes.server_id}\" name=\"#{@name}\">"
    end
    
    def to_s()
      msg = "$[#{name}]"
      #if (contributes != NO_GOAL)
      #  msg += " (Contributes to: #{contributes.name})"
      #end
      return msg
    end
  end
  
end