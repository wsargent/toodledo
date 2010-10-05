
module Toodledo
  
  #
  # Thrown when a call to the server fails.
  #
  class ServerError < StandardError
  
  end
  
  # Thrown when the key is invalid (usually because we're using an old key or 
  # the expiration timed out for some reason)
  class InvalidKeyError < ServerError
    
  end
  
end
