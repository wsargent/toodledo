require 'toodledo'

require 'digest/md5'
require 'uri'
require 'net/http'
require 'net/https'
require 'openssl/ssl'
require 'rexml/document'
require 'logger'
require 'fileutils'

module Toodledo
  
  #
  # The Session.  This is responsible for calling to the server
  # and handling most functionality.
  #
  class Session

    DATE_FORMAT = '%Y-%m-%d'

    DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S'

    TIME_FORMAT = '%I:%M %p'

    INVALID_KEY_MESSAGE = 'key did not validate'
    NO_KEY_SPECIFIED_MESSAGE = 'No Key Specified'
    EXCESSIVE_TOKEN_MESSAGE = 'Excessive API token requests over the last 1 hour.  This user is temporarily blocked.'

    DEFAULT_API_URL = 'http://api.toodledo.com/2'

    USER_AGENT = "Ruby/#{Toodledo::VERSION} (#{RUBY_PLATFORM})"

    INVALID_ID_MESSAGE = 'Invalid ID number'

    # Make file expiration be 4 hours.
    FILE_EXPIRATION_TIME_IN_SECS = (60 * 60 * 4)


    HEADERS = {
      'User-Agent' => USER_AGENT,
      'Connection' => 'keep-alive',
      'Keep-Alive' => '300'
    }

    attr_accessor :logger
    
    attr_reader :base_url, :user_id, :proxy, :app_id

    def execute(command)

      command.call()

    end

    # Creates a new session, using the given user name and password.
    # throws InvalidConfigurationError if user_id or password are nil.
    def initialize(user_id, password, logger = nil, app_id = nil)
      raise InvalidConfigurationError.new("Nil user_id") if (user_id == nil)
      raise InvalidConfigurationError.new("Nil password") if (password == nil)
    
      @user_id = user_id
      @password = password
      @app_id = app_id

      @logger = logger
    end

    def find_expiration_time(expiration_in_mins)
      # Expiration time is measured in minutes, i.e. 49.4
      exp_mins = expiration_in_mins.to_i # drop the fractional bit
      @start_time + (exp_mins * 60)
    end

    # Returns true if the session has expired.
    def expired?
      logger.debug("Expiration time #{@expiration_time} ") if logger
      current_time = Time.now
      has_expired = (@expiration_time != nil) && (current_time > @expiration_time)
      if (has_expired)
        logger.debug("Expiration time #{@expiration_time} > current time #{current_time}, expired == true") if logger
      end
      has_expired
    end

    def reconnect(base_url, proxy)
      disconnect()
      connect(base_url, proxy)
    end


    # Gets the token method, given the id.
    def get_token(user_id, app_id)
      raise "Nil user_id" if (user_id == nil || user_id.empty?)

      # If there is no token file, or the token file is out of date, pull in
      # a fresh token from the server and write it to the file system.
      token = read_token(user_id)
      unless token
        token = get_uncached_token(user_id, app_id)
        write_token(user_id, token)
      end

      return token
    end

    # Reads a token from the file system, if the given user_id exists and the
    # token is not too old.
    def read_token(user_id)
      token_path = get_token_file(user_id)
      unless token_path
        logger.debug("read_token: no token found for #{user_id.inspect}, returning nil") if logger
        return nil
      end

      if is_too_old(token_path)
        File.delete(token_path)
        return nil
      end

      token = File.read(token_path)
      token
    end

    # Returns true if the file is more than an hour old, false otherwise.
    def is_too_old(token_path)
      last_modified_time = File.new(token_path).mtime.to_i
      expiration_time = Time.now.to_i - FILE_EXPIRATION_TIME_IN_SECS
      too_old_by = last_modified_time - expiration_time

      logger.debug "is_too_old: expires in #{too_old_by} seconds" if logger

      return too_old_by < 0
    end

    # Gets there full path of the token file.
    def get_token_file(user_id)
      tokens_dir = get_tokens_directory
      token_path = File.expand_path(File.join(tokens_dir, user_id))
      unless File.exist?(token_path)
        return nil
      end
      token_path
    end

    # Make sure that there is a ".toodledo/tokens" directory.
    def get_tokens_directory
      toodledo_dir = "~/.toodledo"
      tokens_path = File.expand_path(File.join(toodledo_dir, "tokens"))
      FileUtils.mkdir_p tokens_path
      tokens_path
    end

    # Writes the token file to the filesystem.
    def write_token(user_id, token)
      logger.debug("write_token: user_id = #{user_id.inspect}, token = #{token.inspect}") if logger
      token_path = File.expand_path(File.join(get_tokens_directory(), user_id))
      File.open(token_path, 'w') {|f| f.write(token) }
    end

    # Calls the server to get a token.
    def get_uncached_token(user_id, app_id)
      params = { :userid => user_id }
      params.merge!({:appid => app_id}) unless app_id.nil?
      result = call('getToken', params)

      return result.text
    end

  end

end



