module Toodledo
  
  #
  # A read only representation of a context.
  #
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
    
    
    # 
    # Parses the context of an element.
    #
    def self.parse(session, el)
      id = el.attributes['id']
      name = el.text
      context = Context.new(id, name)
      return context
    end
    
    def to_xml()
      return "<context id=\"#{@id}\">#{@name}</context>"
    end
  end
  
end