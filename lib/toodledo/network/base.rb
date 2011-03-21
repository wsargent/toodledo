
require 'json'

class Toodledo::Network::Base

  def initialize(logger = nil)
    @logger = logger
  end

  def call(method, params, proxy = null)

    if logger
      logger.debug("call(#{method}) request: #{url.path}?#{url.query}#{url.fragment}")
    end

    raise 'Nil method' if (method == nil)
    raise 'Nil params' if (params == nil)
    raise 'Wrong type of params' if (! params.kind_of? Hash)
    raise 'Wrong method type' if (! method.kind_of? String)

    # Break all the parameters down into key=value seperated by semi colons
    stringified_params = (key != nil) ? ';key=' + key : ''

    params.each { |k, v|
      stringified_params += ';' + k.to_s + '=' + escape_text(v)
    }
    url = make_uri(method, stringified_params)

    # Establish the proxy
    if (proxy != nil)
      logger.debug("call(#{method}) establishing proxy...") if logger

      proxy_host = proxy['host']
      proxy_port = proxy['port']
      proxy_user = proxy['user']
      proxy_password = proxy['password']

      if (proxy_user == nil || proxy_password == nil)
        http = Net::HTTP::Proxy(proxy_host, proxy_port).new(url.host, url.port)
      else
        http = Net::HTTP::Proxy(proxy_host, proxy_port, proxy_user, proxy_password).new(url.host, url.port)
      end
    else
      http = Net::HTTP.new(url.host, url.port)
    end

    if (url.scheme == 'https')
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.use_ssl = true
    end


    # make the call
    response = http.request_get(url.request_uri, HEADERS)
    unless response
      raise Toodledo::ServerError.new("No HTTP response found from request #{url.path}");
    end
    body = response.body

    # body = url.read
    end_time = Time.now

    root_node = JSON.parse(response)

    return root_node
  end

end