# 
# 
# 
module Toodledo
  
  #
  # Thrown when the session's configuration is invalid.
  #
  class InvalidConfigurationError < RuntimeError
    def initialize(msg = nil)
      super(msg)
    end
  end
end
