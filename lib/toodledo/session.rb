require 'toodledo'

require 'digest/md5'
require 'uri'
require 'net/http'
require 'net/https'
require 'openssl/ssl'
require 'rexml/document'
require 'logger'

module Toodledo
  
  #
  # The Session.  This is responsible for calling to the server
  # and handling most functionality.
  #
  class Session
    
    DEFAULT_API_URL = 'http://www.toodledo.com/api.php'

    USER_AGENT = "Ruby/#{Toodledo::VERSION} (#{RUBY_PLATFORM})"
    
    HEADERS = {
      'User-Agent' => USER_AGENT
    }
    
    EXPIRATION_TIME_IN_SECS = 60 * 60
    
    DATE_FORMAT = '%Y-%m-%d'
    
    DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S'
    
    TIME_FORMAT = '%I:%M %p'
    
    attr_accessor :logger 
      
    attr_reader :base_url, :user_id, :proxy

    # Creates a new session, using the given user name and password.
    # throws exception if user_id or password are nil.
    def initialize(user_id, password, logger = nil)
      raise "Nil user_id" if (user_id == nil)
      raise "Nil password" if (password == nil)
    
      @user_id = user_id
      @password = password
      
      @folders = nil
      @contexts = nil
      @goals = nil
      @key = nil
      @folders_by_id = nil
      @goals_by_id = nil
      @contexts_by_id = nil
      
      @logger = logger
    end
    
    #  Hashes the input string and returns a string hex digest.
    def md5(input_string)
      return Digest::MD5.hexdigest(input_string)
    end
  
    # Connects to the server, asking for a new key that's good for an hour.
    # Optionally takes a base URL as a parameter.  Defaults to DEFAULT_API_URL.
    def connect(base_url = DEFAULT_API_URL, proxy = nil)
      logger.debug("connect(#{base_url}, #{proxy.inspect})") if logger

      # XXX It looks like get_user_id doesn't work reliably.  It always
      # returns 1 even when we pass in a valid email and password.
      # @user_id = get_user_id(@email, @password)
      # logger.debug("user_id = #{@user_id}, #{@email} #{@password}")

      if (@user_id == '1')
        raise "No matching user_id found"
      end
      
      if (@user_id == '0')
        raise "Server says we have a blank email or password"
      end
      
      # Set the base URL.
      @base_url = base_url
      
      # Get the proxy information if it exists.
      @proxy = proxy
      
      session_token = get_token(@user_id)
      key = md5(md5(@password).to_s + session_token + @user_id);
      
      @key = key
      @start_time = Time.now      
    end
    
    # Disconnects from the server.
    def disconnect()
      logger.debug("disconnect()") if logger
      @key = nil
      @start_time = nil
      @base_url = nil
      @proxy = nil
    end

    # Returns true if the session has expired.
    def expired?
      #logger.debug("expired?") too annoying
      
      # The key is only good for an hour.  If it's been over an hour, 
      # then we count it as expired.
      return true if (@start_time == nil)
      return (Time.now - @start_time > EXPIRATION_TIME_IN_SECS)
    end

    # Returns a parsable URI object from the base API URL and the parameters.
    def make_uri(method, params)
      url_string = URI.escape(@base_url + '?method=' + method + params)
      return URI.parse(url_string)
    end

    # escape the & character as %26 and the ; character as %3B.
    # throws an exception if input is nil.
    def escape_text(input)
      raise "Nil input" if (input == nil)
      return input.to_s if (! input.kind_of? String)
      
      output_string = input.gsub('&', '%26')
      output_string = output_string.gsub(';', '%3B')
      return output_string
    end

    # Calls Toodledo with the method name, the parameters and the session key.
    # Returns the text inside the document root, if any.
    def call(method, params, key = nil)  
      raise 'Nil method' if (method == nil)
      raise 'Nil params' if (params == nil)
      raise 'Wrong type of params' if (! params.kind_of? Hash)
      raise 'Wrong method type' if (! method.kind_of? String)

      if (@base_url == nil)
        raise 'Must call connect() before this method'        
      end

      # Break all the parameters down into key=value seperated by semi colons
      stringified_params = (key != nil) ? ';key=' + key : ''

      params.each { |k, v| 
        stringified_params += ';' + k.to_s + '=' + escape_text(v) 
      }
      url = make_uri(method, stringified_params)

      # If it's been more than an hour, then ask for a new key.
      if (@key != nil && expired?)
        logger.debug("call(#{method}) connection expired, reconnecting...") if logger

        # Save the connection information (we'll need it)
        base_url = @base_url
        proxy = @proxy
        disconnect() # ensures that key == nil, which is crucial to avoid an endless loop...
        connect(base_url, proxy)
      end

      # Establish the proxy
      if (@proxy != nil)
        logger.debug("call(#{method}) establishing proxy...") if logger
        
        proxy_host = @proxy['host']
        proxy_port = @proxy['port']
        proxy_user = @proxy['user']
        proxy_password = @proxy['password']
        
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
            
      if logger
        logger.debug("call(#{method}) request: #{url.path}?#{url.query}#{url.fragment}")
      end
      start_time = Time.now
      
      # make the call
      response = http.request_get(url.request_uri, HEADERS)
      body = response.body

      # body = url.read
      end_time = Time.now
      doc = REXML::Document.new body

      if logger
        logger.debug("call(#{method}) response: " + doc.to_s)
        logger.debug("call(#{method}) time: " + (end_time - start_time).to_s + ' seconds')
      end

      root_node = doc.root
      if (root_node.name == 'error')
        error_text = root_node.text
        if (error_text == 'Invalid ID number')
          raise Toodledo::ItemNotFoundError.new(error_text)
        else
          raise Toodledo::ServerError.new(error_text)
        end
      end

      return root_node
    end

    # Gets the token method, given the id.
    def get_token(user_id)
      raise "Nil user_id" if (user_id == nil)

      params = { :userid => user_id }
      result = call('getToken', params)    
      return result.text
    end

    # Returns the user id.  As far as I can tell, this method is broken 
    # and always returns false.
    #
    # If the userid comes back as 0, it means that either the email 
    # or password that you sent was blank. If the userid comes back as 1, 
    # it means that the lookup failed. A valid userid will always be a 
    # 15 or 16 character hexadecimal string.
    def get_user_id(email, password)
      raise "Nil email" if (email == nil)
      raise "Nil password" if (password == nil)

      params = { :email => email, :pass => password }
      result = call('getUserid', params)  
      return result.text
    end

    ############################################################################
    # Tasks
    ############################################################################

    #
    # Gets tasks that meet the criteria given in params.  Available criteria is
    # as follows:

    # *  title:
    # *  folder:
    # *  context:
    # *  goal:
    # *  duedate:
    # *  duetime
    # *  repeat:
    # *  priority:
    # *  parent:
    # *  shorter:    
    # *  longer:    
    # * before 
    # * after 
    # * modbefore
    # * modafter  
    # * compbefore 
    # * compafter 
    # * notcomp 
    #
    # Returns an array of tasks.  This information is never cached.
    def get_tasks(params={})
      logger.debug("get_tasks(#{params.inspect})") if logger
      myhash = {}
    
      # * title : A text string up to 255 characters.
      handle_string(myhash, params, :title)
    
      # If the folder is a string, then we assume we're supposed to find out what
      # the id is.
      handle_folder(myhash, params)
    
      # Context handling
      handle_context(myhash, params)
    
      # Goal handling
      handle_goal(myhash, params)
    
      # duedate handling.  Take either a string or a Time object.'YYYY-MM-DD'
      # This does not need special handling, because if it's not a time object
      # then we don't pass through anything at all.
      handle_date(myhash, params, :duedate)
    
      # duetime handling.  Take either a string or a Time object. 
      handle_time(myhash, params, :duetime)
    
      # repeat: takes in an integer in the proper range..
      handle_repeat(myhash, params)
   
      # priority: takes in an integer in the proper range.
      handle_priority(myhash, params)
          
      # * parent : This is used to Pro accounts that have access to subtasks. 
      # Set this to the id number of the parent task and you will get its 
      # subtasks. The default is 0, which is a special number that returns 
      # tasks that do not have a parent.
      handle_parent(myhash, params)
    
      # * shorter : An integer representing minutes. This is used for finding 
      # tasks with a duration that is shorter than the specified number of minutes.
      handle_number(myhash, params, :shorter)
    
      # * longer : An integer representing minutes. This is used for finding 
      # tasks with a duration that is longer than the specified number of minutes.
      handle_number(myhash, params, :longer)
    
      # * before : A date formated as YYYY-MM-DD. Used to find tasks with
      # due-dates before this date.
      handle_date(myhash, params, :before)
    
      # * after : A date formated as YYYY-MM-DD. Used to find tasks with 
      # due-dates after this date.
      handle_date(myhash, params, :after)
    
      # * modbefore : A date-time formated as YYYY-MM-DD HH:MM:SS. Used to find 
      # tasks with a modified date and time before this dateand time.
      handle_datetime(myhash, params, :modbefore)
    
      # * modafter : A date-time formated as YYYY-MM-DD HH:MM:SS. Used to find 
      # tasks with a modified date and time after this dateand time.
      handle_datetime(myhash, params, :modafter)
    
      # * compbefore : A date formated as YYYY-MM-DD. Used to find tasks with a
      # completed date before this date.
      handle_date(myhash, params, :compbefore)
    
      # * compafter : A date formated as YYYY-MM-DD. Used to find tasks with a 
      # completed date after this date.
      handle_date(myhash, params, :compafter)
    
      # * notcomp : Set to 1 to omit completed tasks. Omit variable, or set to 0
      # to retrieve both completed and uncompleted tasks.
      handle_boolean(myhash, params, :notcomp)
    
      result = call('getTasks', myhash, @key)
      tasks = []
      result.elements.each do |el| 
        task = Task.parse(self, el)
        tasks << task
      end
      return tasks
    end
  
    # Adds a task to Toodledo.
    #
    # Required Parameters:
    #   title: a String.  This is the only required property.
    #
    # Optional Parameters:
    #   tag: a String
    #   folder: folder id or String matching the folder name
    #   context: context id or String matching the context name
    #   goal: goal id or String matching the Goal Name
    #   duedate: Time or String object "YYYY-MM-DD".  If this is a string, it 
    #   may take an optional modifier.
    #   duetime: Time or String object "MM:SS p"}    
    #   parent: parent id }
    #   repeat: one of { :none, :weekly, :monthly :yearly :daily :biweekly, 
    #         :bimonthly, :semiannually, :quarterly }
    #   length: a Number, number of minutes
    #   priority: one of { :negative, :low, :medium, :high, :top }
    #
    # Returns: the id of the added task as a String.
    def add_task(title, params={})
      logger.debug("add_task(#{title}, #{params.inspect})") if logger
      raise "Nil id" if (title == nil)
    
      myhash = {:title => title}      
      
      handle_string(myhash, params, :tag)
    
      # If the folder is a string, then we assume we're supposed to find out what
      # the id is.
      handle_folder(myhash, params)
    
      # Context handling
      handle_context(myhash, params)
    
      # Goal handling
      handle_goal(myhash, params)
    
      # duedate handling.  Take either a string or a Time object.'YYYY-MM-DD'
      handle_date(myhash, params, :duedate)
    
      # duetime handling.  Take either a string or a Time object. 
      handle_time(myhash, params, :duetime)
    
      # parent handling.
      handle_parent(myhash, params)
    
      # repeat: use the map to change from the symbol to the raw numeric value.
      handle_repeat(myhash, params)
   
      # priority use the map to change from the symbol to the raw numeric value.
      handle_priority(myhash, params)

      handle_string(myhash, params, :note)
    
      result = call('addTask', myhash, @key)
        
      return result.text
    end
       
    # * id : The id number of the task to edit.
    # * title : A text string up to 255 characters representing the name of the task.
    # * folder : The id number of the folder.
    # * context : The id number of the context.
    # * goal : The id number of the goal. 
    # * completed : true or false.
    # * duedate : A date formatted as YYYY-MM-DD with an optional modifier
    #   attached to the front. Examples: "2007-01-23" , "=2007-01-23" ,
    #   ">2007-01-23". To unset the date, set it to '0000-00-00'.
    # * duetime : A date formated as HH:MM MM.
    # * repeat : Use the REPEAT_MAP with the relevant symbol here.
    # * length : An integer representing the number of minutes that the task will take to complete.
    # * priority : Use the PRIORITY_MAP with the relevant symbol here.
    # * note : A text string.  
    def edit_task(id, params = {})
      logger.debug("edit_task(#{id}, #{params.inspect})") if logger
      raise "Nil id" if (id == nil)
      
      myhash = { :id => id }
      
      handle_string(myhash, params, :tag)

      # If the folder is a string, then we assume we're supposed to find out what
      # the id is.
      handle_folder(myhash, params)

      # Context handling
      handle_context(myhash, params)

      # Goal handling
      handle_goal(myhash, params)

      # duedate handling.  Take either a string or a Time object.'YYYY-MM-DD'
      handle_date(myhash, params, :duedate)

      # duetime handling.  Take either a string or a Time object. 
      handle_time(myhash, params, :duetime)

      # parent handling.
      handle_parent(myhash, params)
      
      # Handle completion.
      handle_boolean(myhash, params, :completed)

      # repeat: use the map to change from the symbol to the raw numeric value.
      handle_repeat(myhash, params)

      # priority use the map to change from the symbol to the raw numeric value.
      handle_priority(myhash, params)
  
      handle_string(myhash, params, :note)
    
      result = call('editTask', myhash, @key)
    
      return (result.text == '1')
    end
  
    #
    # Deletes the task, using the task id.
    #
    def delete_task(id)
      logger.debug("delete_task(#{id})") if logger
      raise "Nil id" if (id == nil)
    
      result = call('deleteTask', { :id => id }, @key)
    
      return (result.text == '1')    
    end    

    ############################################################################
    # Contexts
    ############################################################################
  
    #
    # Returns the context with the given name.
    #
    def get_context_by_name(context_name)
      logger.debug("get_context_by_name(#{context_name})") if logger
      
      if (@contexts_by_name == nil)
        get_contexts(true)  
      end
    
      context = @contexts_by_name[context_name.downcase]
      return context
    end
  
    #
    # Returns the context with the given id.
    #
    def get_context_by_id(context_id)
      logger.debug("get_context_by_id(#{context_id})") if logger
    
      if (@contexts_by_id == nil)
        get_contexts(true)  
      end
    
      context = @contexts_by_id[context_id]
      return context      
    end
    
    #
    # Gets the array of contexts.
    #
    def get_contexts(flush = false)
      logger.debug("get_contexts(#{flush})") if logger
      return @contexts unless (flush || @contexts == nil)
      
      result = call('getContexts', {}, @key)
      contexts_by_name = {} 
      contexts_by_id = {}    
      contexts = []
      
      result.elements.each { |el|
        context = Context.parse(self, el)
        contexts << context
        contexts_by_id[context.server_id] = context
        contexts_by_name[context.name.downcase] = context
      }
      @contexts_by_id = contexts_by_id
      @contexts_by_name = contexts_by_name
      @contexts = contexts
      return contexts
    end
  
    # 
    # Adds the context to Toodledo, with the title.
    #
    def add_context(title)
      logger.debug("add_context(#{title})") if logger
      raise "Nil title" if (title == nil)
      
      result = call('addContext', { :title => title }, @key)
      
      flush_contexts()
      
      return result.text
    end
  
    #
    # Deletes the context from Toodledo, using the id.
    #
    def delete_context(id)
      logger.debug("delete_context(#{id})") if logger
      raise "Nil id" if (id == nil)
      
      result = call('deleteContext', { :id => id }, @key)
      
      flush_contexts();
      
      return (result.text == '1')
    end
    
    #
    # Deletes the cached contexts.
    #
    def flush_contexts()
      logger.debug('flush_contexts()') if logger

      @contexts_by_id = nil
      @contexts_by_name = nil
      @contexts = nil
    end
  
    ############################################################################
    # Goals
    ############################################################################
  
    #
    # Returns the goal with the given name.  Case insensitive.
    #
    def get_goal_by_name(goal_name)
      logger.debug("get_goal_by_name(#{goal_name})") if logger
      if (@goals_by_name == nil)
        get_goals(true)
      end

      goal = @goals_by_name[goal_name.downcase]
      return goal
    end
  
    #
    # Returns the goal with the given id.
    #
    def get_goal_by_id(goal_id)
      logger.debug("get_goal_by_id(#{goal_id})") if logger
      if (@goals_by_id == nil)
        get_goals(true)
      end
    
      goal = @goals_by_id[goal_id]
      return goal
    end
  
    #
    # Returns the array of goals.
    #
    def get_goals(flush = false)
      logger.debug("get_goals(#{flush})") if logger
      return @goals unless (flush || @goals == nil)
     
      result = call('getGoals', {}, @key)
   
      goals_by_name = {}
      goals_by_id = {}
      goals = []
      result.elements.each do |el|        
         goal = Goal.parse(self, el)
         goals << goal
         goals_by_id[goal.server_id] = goal
         goals_by_name[goal.name.downcase] = goal
      end
      
      # Loop through and make sure we've got a reference for every contributing 
      # goal.
      for goal in goals
        next if (goal.contributes_id == Goal::NO_GOAL.server_id)
        parent_goal = goals_by_id[goal.contributes_id]
        goal.contributes = parent_goal
      end
      
      @goals = goals
      @goals_by_name = goals_by_name
      @goals_by_id = goals_by_id
      return goals
    end
      
    # 
    # Adds a new goal with the given title, the level (short to long term) and 
    # the contributing goal id.
    #
    def add_goal(title, level = 0, contributes = 0)
      logger.debug("add_goal(#{title}, #{level}, #{contributes})") if logger
      raise "Nil title" if (title == nil)

      params = { :title => title, :level => level, :contributes => contributes }
      result = call('addGoal', params, @key)
      
      flush_goals()

      return result.text
    end
  
    #
    # Delete the goal with the given id.
    #
    def delete_goal(id)
      logger.debug("delete_goal(#{id})") if logger
      raise "Nil id" if (id == nil)
      
      result = call('deleteGoal', { :id => id }, @key)
      
      flush_goals()
      
      return (result.text == '1')
    end
    
    #
    # Nils the cached goals.
    #
    def flush_goals()
      logger.debug('flush_goals()') if logger
      
      @goals = nil
      @goals_by_name = nil
      @goals_by_id = nil
    end
  
    ############################################################################
    # Folders
    ############################################################################
  
    #
    # Gets the folder by the name.  Case insensitive.
    def get_folder_by_name(folder_name)
      logger.debug("get_folders_by_name(#{folder_name})") if logger
      raise "Nil folder name" if (folder_name == nil)
      
      if (@folders_by_name == nil)
        get_folders(true)
      end
    
      return @folders_by_name[folder_name.downcase]
    end
  
    # 
    # Gets the folder with the given id.
    #
    def get_folder_by_id(folder_id)
      logger.debug("get_folder_by_id(#{folder_id})") if logger
      raise "Nil folder_id" if (folder_id == nil)
      
      if (@folders_by_id == nil)
        get_folders(true)
      end
    
      return @folders_by_id[folder_id]
    end
  
    # Gets all the folders.
    def get_folders(flush = false)
      logger.debug("get_folders(#{flush})") if logger
      return @folders unless (flush || @folders == nil)
    
      result = call('getFolders', {}, @key)      
      # <folders>
      #   <folder id="123" private="0" archived="0">Shopping</folder>
      #   <folder id="456" private="0" archived="0">Home Repairs</folder>
      #   <folder id="789" private="0" archived="0">Vacation Planning</folder>
      #   <folder id="234" private="0" archived="0">Chores</folder>
      #   <folder id="567" private="1" archived="0">Work</folder>
      # </folders>
      folders = []
      folders_by_name = {}
      folders_by_id = {}
      result.elements.each { |el| 
          folder = Folder.parse(self, el)
          folders.push(folder)
          folders_by_name[folder.name.downcase] = folder # lowercase the key search
          folders_by_id[folder.server_id] = folder
      }
      @folders = folders
      @folders_by_name = folders_by_name
      @folders_by_id = folders_by_id
      return @folders
    end
  
    # Adds a folder.
    # * title : A text string up to 32 characters.
    # * private : A boolean value that describes if this folder can be shared.  
    # 
    # Returns the id of the newly added folder.
    def add_folder(title, is_private = 1)
      logger.debug("add_folder(#{title}, #{is_private})") if logger
      raise "Nil title" if (title == nil)
      
      if (is_private.kind_of? TrueClass)
        is_private = 1
      elsif (is_private.kind_of? FalseClass)
        is_private = 0
      end
      
      myhash = { :title => title, :private => is_private}
      
      result = call('addFolder', myhash, @key)
      
      flush_folders()
      
      return result.text
    end
    
    #
    # Nils out the cached folders.
    #
    def flush_folders()      
      logger.debug("flush_folders()") if logger
      
      @folders = nil
      @folders_by_name = nil
      @folders_by_id = nil      
    end
    
    # Edits a folder.
    # * id : The id number of the folder to edit.
    # * title : A text string up to 32 characters.
    # * private : A boolean value (0 or 1) that describes if this folder can be 
    #   shared. A value of 1 means that this folder is private.
    # * archived : A boolean value (0 or 1) that describes if this folder is archived.
    #
    # Returns true if the edit was successful.
    def edit_folder(id, params = {})
      logger.debug("edit_folder(#{id}, #{params.inspect})") if logger
      raise "Nil id" if (id == nil)
      
      myhash = { :id => id }
      
      handle_string(myhash, params, :title)
      
      handle_boolean(myhash, params, :private)
      
      handle_boolean(myhash, params, :archived)
      
      result = call('editFolder', myhash, @key)
      
      flush_folders()
      
      return (result.text == '1')
    end
  
    # Deletes the folder with the id.
    # id : The folder id.
    #
    # Returns true if the delete was successful. 
    def delete_folder(id)
      logger.debug("delete_folder(#{id})") if logger
      raise "Nil id" if (id == nil)
      
      result = call('deleteFolder', { :id => id }, @key)
      
      flush_folders()
      
      return (result.text == '1')
    end
  
    ############################################################################
    # Helper methods follow.
    # 
    # These methods will convert the appropriate format for talking to the
    # Toodledo server.  They do not parse the XML that comes back from the
    # server.
    ############################################################################
  
    def handle_number(myhash, params, symbol)
      value = params[symbol]
      if (value != nil)
        if (value.kind_of? FixNum)
          myhash.merge!({ symbol => value.to_s})
        end
      end        
    end
  
    def handle_boolean(myhash, params, symbol)
      value = params[symbol]
      if (value == nil)
        return
      end
      
      case value
      when TrueClass, FalseClass
        bool = (value == true) ? '1' : '0'           
      when String
        bool = ('true' == value.downcase) ? '1' : '0' 
      when FixNum
        bool = (value == 1) ? '1' : '0'
      else
        bool = value
      end
      
      myhash.merge!({ symbol => bool }) 
    end

    def handle_string(myhash, params, symbol)
      value = params[symbol]
      if (value != nil)
        myhash.merge!({ symbol => value })
      end
    end
  
    def handle_date(myhash, params, symbol)
      value = params[symbol]
      if (value == nil)
        return
      end
      
      case value
      when Time
        value = value.strftime('%Y-%m-%d')    
      end
      
      myhash.merge!({ symbol => value }) 
    end
  
    def handle_time(myhash, params, symbol)      
      value = params[symbol]
      if (value == nil)
        return
      end
      
      case value
      when Time
        value = value.strftime(TIME_FORMAT) 
      end
      
      myhash.merge!({ symbol => value })
    end

    # Handles a generic date time value.
    def handle_datetime(myhash, params, symbol)
      # YYYY-MM-DD HH:MM:SS
      value = params[symbol]
      if (value == nil)
        return
      end
      
      case value
      when Time
        value = value.strftime(DATETIME_FORMAT)     
      end
      
      myhash.merge!({ symbol => value })                              
    end
    
    # Handles the parent task object.  Only takes a task object or id.
    def handle_parent(myhash, params)
      parent = params[:parent]
      if (parent == nil)        
        return
      end
      
      parent_id = nil
      case parent
      when Task
        parent_id = parent.server_id
      else
        parent_id = parent
      end
      
      myhash.merge!({ :parent => parent_id })
    end

    # Handles a folder (in the form of a folder name, object or id) and puts
    # the folder_id in  myhash.
    def handle_folder(myhash, params)      
      folder = params[:folder]
      if (folder == nil) 
        return
      end
      
      folder_id = nil
      case folder
      when String
        folder_obj = get_folder_by_name(folder)
        if (folder_obj == nil)
          raise Toodledo::ItemNotFoundError.new("No folder found with name #{folder}")   
        end
        folder_id = folder_obj.server_id
      when Folder
        folder_id = folder.server_id
      else
        folder_id = folder
      end
      
      myhash.merge!({ :folder => folder_id })          
    end

    # Takes in a context (in the form of a string, a Context object or 
    # a context id) and adds it to myhash as a context_id.
    def handle_context(myhash, params)
      context = params[:context]
      if (context == nil)
        return 
      end      
      
      case context
      when String
        context_obj = get_context_by_name(context)
        if (context_obj == nil)
          raise Toodledo::ItemNotFoundError.new("No context found with name '#{context}'")
        end
        context_id = context_obj.server_id
      when Context
        context_id = context.server_id
      else
        context_id = context
      end
      
      myhash.merge!({ :context => context_id })
    end

    # Takes a goal (as a goal title, a goal object or a goal id) and sets it
    # in myhash.
    def handle_goal(myhash, params)
      goal = params[:goal]
      if (goal == nil)
        return
      end

      case goal
      when String
        goal_obj = get_goal_by_name(goal)
        if (goal_obj == nil)
          raise Toodledo::ItemNotFoundError.new("No goal found with name '#{goal}'")
        end
        goal_id = goal_obj.server_id
      when Goal
        goal_id = goal.server_id
      else
        goal_id = goal
      end
      
      # Otherwise, assume it's a number.
      myhash.merge!({ :goal => goal_id })
    end

    # Handles the repeat parameter.
    def handle_repeat(myhash, params)
      repeat = params[:repeat]
      
      if (repeat == nil)   
        return
      end
      
      if (! Repeat.valid?(repeat))
        raise "Invalid repeat value: #{repeat}"
      end
      
      myhash.merge!({ :repeat => repeat })
    end

    # Handles the priority.  This must be one of several values.
    def handle_priority(myhash, params)
      priority = params[:priority]
      
      if (priority == nil)
        return nil
      end

      if (! Priority.valid?(priority))
        raise "Invalid priority value: #{priority}"
      end
      
      myhash.merge!({ :priority => priority })        
    end
   
  end
end



