#
# The top level Toodledo module.
#
module Toodledo

  # Required for gem  
  VERSION = '2.0.0'

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
  #      "url" => "http://www.toodledo.com/api.php",
  #      "user_id" => "<your user id>",
  #      "password" => "<your password>"
  #    }
  #  }
  #  Toodledo.set_config(config)
  #  Toodledo.begin do |session|
  #    session.add_task('foo')
  #  end
  #
  def self.begin(config, logger = nil)
    proxy = config['proxy']
          
    connection = config['connection']
    user_id = connection['user_id']
    password = connection['password']
    app_id = connection['app_id'] || 'ruby_app'

    session = Session.new(user_id, password, logger, app_id)
    session.connect(proxy)
    
    if (block_given?)
      yield(session)
    end
    
    session.disconnect()
  end  
end

require 'toodledo/invalid_configuration_error'
require 'toodledo/status'
require 'toodledo/task'
require 'toodledo/context'
require 'toodledo/goal'
require 'toodledo/folder'
require 'toodledo/repeat'
require 'toodledo/priority'
require 'toodledo/network'
