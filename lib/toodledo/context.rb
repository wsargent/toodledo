module Toodledo
  
  class Context
    
    def initialize(id, name)
      @id = id
      @name = name
    end
    
    NO_CONTEXT = Context.new(0, "No Context")
    
    attr_reader :name
    
    def server_id
      return @id
    end
    
    def to_s()
      return "@[#{name}]"
    end
    
  end
  
end