

class Toodledo::Network::Account::Token < Toodledo::Network::Base


  def url
    "/account/token.php"
  end

  #  Hashes the input string and returns a string hex digest.
  def md5(input_string)
    return Digest::MD5.hexdigest(input_string)
  end


  # Connects to the server, asking for a new key that's good for an hour.
  # Optionally takes a base URL as a parameter.  Defaults to DEFAULT_API_URL.
  def execute(base_url = DEFAULT_API_URL, proxy = nil)
    logger.debug("connect(#{base_url}, #{proxy.inspect})") if logger

    # XXX It looks like get_user_id doesn't work reliably.  It always
    # returns 1 even when we pass in a valid email and password.
    # @user_id = get_user_id(@email, @password)
    # logger.debug("user_id = #{@user_id}, #{@email} #{@password}")

    if (@user_id == '1')
      raise InvalidConfigurationError.new("Invalid user_id")
    end

    if (@user_id == '0')
      raise InvalidConfigurationError.new("Invalid password")
    end

    # Set the base URL.
    @base_url = base_url

    # Get the proxy information if it exists.
    @proxy = proxy

    session_token = get_token(@user_id, @app_id)
    key = md5(md5(@password).to_s + session_token + @user_id);


  end


end