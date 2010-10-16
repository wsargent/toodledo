
module Toodledo
  
  #
  # Thrown when a call to the server fails.
  #
  class ServerError < StandardError
  
  end
  
  #
  # Thrown when a call to a server returns 'Invalid ID number'
  #
  class ItemNotFoundError < ServerError
  
  end
  
  # Thrown when the key is invalid (usually because we're using an old key or 
  # the expiration timed out for some reason)
  class InvalidKeyError < ServerError
    
  end
  
  # Thrown when no key is specified at all.
  class NoKeySpecifiedError < ServerError
    
  end
  
  # Thrown when too many requests have been made.
  class ExcessiveTokenRequestsError < ServerError
    
  end
  
end
