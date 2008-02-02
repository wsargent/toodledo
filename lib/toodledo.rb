# Load all the other files in.
require 'yaml'
require 'toodledo/server_error'
require 'toodledo/item_not_found_error'
require 'toodledo/task'
require 'toodledo/context'
require 'toodledo/goal'
require 'toodledo/folder'
require 'toodledo/session'

module Toodledo

  # Required for gem  
  VERSION = '0.0.1'
  
  @@config_file = "~/.toodledo"

  @@config = nil

  # Returns the configuration object.  
  #
  # If set_config has been called before this method, then this
  # method returns the config that was passed in there.  If not,
  # then this method will expand the path of config_file (set by
  # default to "~/.toodledo") and read the contents of that file
  # into a YAML object.
  def self.get_config()
    if (@@config == nil)
    
      config_path = File.expand_path(@@config_file)
      if (! File.exist?(config_path))
        raise "Configuration file #{config_path} does not exist!"
      end

      @@config = YAML.load(File.open(config_path))
    end
    
    return @@config
  end
  
  #
  # Sets the configuration file.  Need not be a full path. 
  #
  def self.set_config_file(config_file)
    @@config_file = config_file
  end
  
  # Sets the configuration explicitly.  Useful when you
  # want to specifically set the configuration without
  # using the file system.
  def self.set_config(override_config)
    @@config = override_config
  end
  

  #
  # Provides a convenient way of connecting and running a session.
  # 
  # This method will use the default Toodledo.config method to get
  # the user_id and password to connect
  #
  # Session.begin do |session|
  #   session.add_task('foo')
  # end
  #
  def self.begin()
    config = Toodledo.get_config()
          
    proxy = config['proxy']
          
    connection = config['connection']
    base_url = connection['url']
    user_id = connection['user_id']
    password = connection['password']
    
    session = Session.new(user_id, password)

    base_url = Session::DEFAULT_API_URL if (base_url == nil)
    session.connect(base_url, proxy)
    
    if (block_given?)
      yield(session)
    end
    
    session.disconnect()
  end
  
end