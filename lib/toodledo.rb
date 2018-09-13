#
# The top level Toodledo module.  This does very little that is
# interesting.  You probably want to look at Toodledo::Session
#

require 'toodledo/version'

module Toodledo

  VERSION = ::Toodledo::Version::VERSION

  # Returns the configuration object.
  def self.get_config()
    return @@config
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
  # The following will do most everything you want, assuming you've set
  # the config correctly:
  #
  #  require 'rubygems'
  #  require 'toodledo'
  #  require 'yaml'
  #  config = {
  #    "connection" => { 
  #      "url" => "https://www.toodledo.com/api.php",
  #      "user_id" => "<your user id>",
  #      "password" => "<your password>"
  #    }
  #  }
  #  Toodledo.set_config(config)
  #  Toodledo.begin do |session|
  #    session.add_task('foo')
  #  end
  #
  def self.begin(logger = nil)
    config = Toodledo.get_config()
          
    proxy = config['proxy']
          
    connection = config['connection']
    base_url = connection['url']
    user_id = connection['user_id']
    password = connection['password']
    app_id = connection['app_id'] || 'ruby_app'

    session = Session.new(user_id, password, logger, app_id)

    base_url = Session::DEFAULT_API_URL if (base_url == nil)
    session.connect(base_url, proxy)
    
    if (block_given?)
      yield(session)
    end
    
    session.disconnect()
  end  
end

require 'toodledo/server_error'
require 'toodledo/invalid_configuration_error'
require 'toodledo/status'
require 'toodledo/task'
require 'toodledo/context'
require 'toodledo/goal'
require 'toodledo/folder'
require 'toodledo/repeat'
require 'toodledo/priority'
require 'toodledo/session'
