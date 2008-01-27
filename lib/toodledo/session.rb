require 'digest/md5'
require 'uri'
require 'open-uri'
require 'rexml/document'

module Toodledo

  #
  # The Session.  This is responsible for calling to the server
  # and handling most functionality.
  #
  class Session
    
    BASE_API_URL = 'http://www.toodledo.com/api.php'

    USER_AGENT = "Toodledo Ruby Client (#{VERSION})"
    
    REPEAT_MAP = {
        :none => 0,
        :weekly => 1,
        :monthly => 2,
        :yearly => 3,
        :daily => 4,
        :biweekly => 5,
        :bimonthly => 6,
        :semiannually => 7,
        :quarterly => 8        
    }

    PRIORITY_MAP = {
      :negative => -1,
      :low => 0,
      :medium => 1,
      :high => 2,
      :top => 3    
    }
    
    @debug_flag = false

    @folders = nil
  
    @contexts = nil
  
    @goals = nil

    def debug?
      return @debug_flag    
    end

    def debug=(debug_flag)
      @debug_flag = debug_flag
    end

    def log(message)
      time = Time.now
      date_format = time.strftime("%Y-%m-%d %H:%M:%S.") + time.usec.to_s
      puts "[#{date_format}] #{message}"
    end
      
    # Creates a new session, using the given user name and password.
    # throws exception if user_id or password are nil.
    def initialize(user_id, password)
      raise "Nil user_id" if (user_id == nil)
      raise "Nil password" if (password == nil)
    
      @user_id = user_id
      @password = password
    end
    
    # Connects to the server, asking for a new key that's good for an hour.
    def connect()
      log("connect()") if (debug?)

      # XXX It looks like get_user_id doesn't work reliably.  It always
      # returns 1 even when we pass in a valid email and password.
      # @user_id = get_user_id(@email, @password)
      # log("user_id = #{@user_id}, #{@email} #{@password}")

      if (@user_id == '1')
        raise "No matching user_id found"
      end
      
      if (@user_id == '0')
        raise "Server says we have a blank email or password"
      end
 
      session_token = get_token(@user_id)
      key = md5(md5(@password).to_s + session_token + @user_id);
      
      @key = key
      @start_time = Time.now      
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
      
      credentials = config['credentials']
      user_id = credentials['user_id']
      password = credentials['password']
      
      session = Session.new(user_id, password)
      session.connect()
      
      if (block_given?)
        yield(session)
      end
      
      session.disconnect()
    end
    
    # Disconnects from the server.
    def disconnect()
      log("disconnect()") if (debug?)
      @key = nil
      @start_time = nil
    end

    # Returns true if the session has expired.
    def expired?
      #log("expired?") too annoying
      
      # The key is only good for an hour.  If it's been over an hour, 
      # then we count it as expired.
      return true if (@start_time == nil)
      return (Time.now - @start_time > (60 * 60))
    end

    # Returns a parsable URI object from the base API URL and the parameters.
    def get_url(method, params)
      url_string = URI.escape(BASE_API_URL + '?method=' + method + params)
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

      # Break all the parameters down into key=value seperated by semi colons
      stringified_params = (key != nil) ? ';key=' + key : ''

      params.each { |k, v| 
        stringified_params += ';' + k.to_s + '=' + escape_text(v) 
      }
      url = get_url(method, stringified_params)

      start_time = Time.now    
      if (debug?) 
        log("call[#{method}] request: " + url.to_s)
      end

      # If it's been more than an hour, then ask for a new key.
      if (@key != nil && expired?)
        log("call[#{method}] connection expired, reconnecting...")
        disconnect() # ensures that key == nil, which is crucial to avoid an endless loop...
        connect()
      end

      body = url.read

      end_time = Time.now
      doc = REXML::Document.new body

      if (debug?)
        log("call[#{method}] response: " + doc.to_s)
        log("call[#{method}] time: " + (end_time - start_time).to_s + ' seconds')
      end

      root_node = doc.root
      if (root_node.name == 'error')
        raise "Server error: " + root_node.text  
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

    # Returns the user id.
    
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

    def get_tasks(params={})
      log("get_tasks(#{params})") if (debug?)
      myhash = {}
    
      # * title : A text string up to 255 characters. Boolean operators do not work yet, 
      #   so your search will be for a single phrase. Please encode the & character as %26 and the ; character as %3B.
      handle_string(myhash, params, :title)
    
      # If the folder is a string, then we assume we're supposed to find out what
      # the id is.
      handle_folder(myhash, params)
    
      # Context handling
      handle_context(myhash, params)
    
      # Goal handling
      handle_goal(myhash, params)
    
      # duedate handling.  Take either a string or a Time object.'YYYY-MM-DD'
      handle_duedate(myhash, params)
    
      # duetime handling.  Take either a string or a Time object. 
      handle_time(myhash, params, :duetime)
    
      # repeat: use the map to change from the symbol to the raw numeric value.
      handle_repeat(myhash, params)
   
      # priority use the map to change from the symbol to the raw numeric value.
      handle_priority(myhash, params)
          
      # * parent : This is used to Pro accounts that have access to subtasks. Set this to the id number of the parent task and 
      # you will get its subtasks. The default is 0, which is a special number that returns tasks that do not have a parent.
      handle_parent(myhash, params)
    
      # * shorter : An integer representing minutes. This is used for finding tasks with a duration that is shorter than the specified number of minutes.
      handle_number(myhash, params, :shorter)
    
      # * longer : An integer representing minutes. This is used for finding tasks with a duration that is longer than the specified number of minutes.
      handle_number(myhash, params, :longer)
    
      # * before : A date formated as YYYY-MM-DD. Used to find tasks with due-dates before this date.
      handle_date(myhash, params, :before)
    
      # * after : A date formated as YYYY-MM-DD. Used to find tasks with due-dates after this date.
      handle_date(myhash, params, :after)
    
      # * modbefore : A date-time formated as YYYY-MM-DD HH:MM:SS. Used to find tasks with a modified date and time before this dateand time.
      handle_datetime(myhash, params, :modbefore)
    
      # * modafter : A date-time formated as YYYY-MM-DD HH:MM:SS. Used to find tasks with a modified date and time after this dateand time.
      handle_datetime(myhash, params, :modafter)
    
      # * compbefore : A date formated as YYYY-MM-DD. Used to find tasks with a completed date before this date.
      handle_date(myhash, params, :compbefore)
    
      # * compafter : A date formated as YYYY-MM-DD. Used to find tasks with a completed date after this date.
      handle_date(myhash, params, :compafter)
    
      # * notcomp : Set to 1 to omit completed tasks. Omit variable, or set to 0 to retrieve both completed and uncompleted tasks.
      handle_boolean(myhash, params, :notcomp)
    
      result = call('getTasks', myhash, @key)
      tasks = []
      # There's probably a cleverer way of doing this.  Oh well.
      result.elements.each { |el| 
        id = el.elements['id'].text
        folder_id = el.elements['folder'].text
        folder = get_folder_by_id(folder_id);
      
        goal_id = el.elements['goal'].attributes['id']
        goal = get_goal_by_id(goal_id)

        context_id = el.elements['context'].attributes['id']
        context = get_context_by_id(context_id)
      
        params = {
           :parent => el.elements['id'].text,
           :children => el.elements['children'].text,
           :title => el.elements['title'].text,
           :tag => el.elements['tag'].text,
           :folder_id => folder_id,
           :folder => folder,
           :context_id => context_id,
           :context => context,
           :goal_id => goal_id,
           :goal => goal,
           :added => el.elements['added'].text,
           :modified => el.elements['modified'].text,
           :duedate => el.elements['duedate'].text,
           :completed => el.elements['completed'].text,
           :repeat => el.elements['repeat'].text,
           :priority => el.elements['priority'].text,
           :length => el.elements['length'].text,
           :timer => el.elements['timer'].text,
           :note => el.elements['note'].text,
        }
        task = Task.new(id, params)
        tasks << task
      }
      return tasks
    end
  
    # Adds a task to Toodledo.
    #
    # Required Parameters:
    # title: a String.  This is the only required property.
    #
    # Optional Parameters:
    # tag: a String
    # folder: folder id or String matching the folder name
    # context: context id or String matching the context name
    # goal: goal id or String matching the Goal Name
    # duedate: Time or String object "YYYY-MM-DD" }
    # duetime: Time or String object "MM:SS p"}    
    # parent: parent id }
    # repeat: one of { :none, :weekly, :monthly :yearly :daily :biweekly, :bimonthly, :semiannually, :quarterly }
    # length: a Number, number of minutes
    # priority: one of { :negative, :low, :medium, :high, :top }
    #
    # Returns: the id of the added task as a String.
    def add_task(title, params={})
      log("add_task(#{title}, #{params})") if (debug?)
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
      handle_duedate(myhash, params)
    
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
    # * title : A text string up to 255 characters representing the name of the task. Please encode the & character as %26 and the ; character as %3B.
    # * tag : A text string up to 64 characters. Please encode the & character as %26 and the ; character as %3B.
    # * folder : The id number of the folder (as returned from addFolder or getFolders). A value of 0 will set the task to "No Folder".
    # * context : The id number of the context (as returned from getContexts). A value of 0 will set the task to "No Context".
    # * goal : The id number of the goal (as returned from getGoals). A value of 0 will set the task to "No Goal".
    # * completed : A boolean value (0 or 1) that describes if this task is completed or not.
    # * duedate : A date formated as YYYY-MM-DD with an optional modifier attached to the front. Examples: "2007-01-23" , "=2007-01-23" , ">2007-01-23". To unset the date, set it to '0000-00-00'.
    # * duetime : A date formated as HH:MM MM. Examples: 12:34 am, 4:56 pm. To unset the value, set it to 0.
    # * repeat : An integer that represents how the tasks will repeat.
    #       o 0 = No Repeat
    #       o 1 = Weekly
    #       o 2 = Monthly
    #       o 3 = Yearly
    #       o 4 = Daily
    #       o 5 = Biweekly
    #       o 6 = Bimonthly
    #       o 7 = Semiannually
    #       o 8 = Quarterly
    # * length : An integer representing the number of minutes that the task will take to complete.
    # * priority : An integer that represents the priority.
    #       o -1 = Negative
    #       o 0 = Low
    #       o 1 = Medium
    #       o 2 = High
    #       o 3 = Top
    # * note : A text string. Please encode the & character as %26 and the ; character as %3B.
    #   
    def edit_task(id, params = {})
      log("edit_task(#{id}, #{params})") if (debug?)
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
      handle_duedate(myhash, params)

      # duetime handling.  Take either a string or a Time object. 
      handle_time(myhash, params, :duetime)

      # parent handling.
      handle_parent(myhash, params)

      # repeat: use the map to change from the symbol to the raw numeric value.
      handle_repeat(myhash, params)

      # priority use the map to change from the symbol to the raw numeric value.
      handle_priority(myhash, params)
  
      handle_string(myhash, params, :note)
    
      result = call('editTask', myhash, @key)
    
      return (result.text == '1')
    end
  
    def delete_task(id)
      log("delete_task(#{id})") if (debug?)
      raise "Nil id" if (id == nil)
      
      result = call('deleteTask', { :id => id }, @key)
      
      return (result.text == '1')
    end    

    ############################################################################
    # Contexts
    ############################################################################
  
    def get_context_by_name(context_name)
      log("get_context_by_name(#{context_name})") if (debug?)
      
      if (@contexts_by_name == nil)
        get_contexts(true)  
      end
    
      context = @contexts_by_name[context_name.downcase]
      return context
    end
  
    def get_context_by_id(context_id)
      log("get_context_by_id(#{context_id})") if (debug?)
    
      if (@contexts_by_id == nil)
        get_contexts(true)  
      end
    
      context = @contexts_by_id[context_id]
      return context      
    end
      
    def get_contexts(flush = false)
      log("get_contexts(#{flush})") if (debug?)
      return @contexts unless (flush || @contexts == nil)
      
      result = call('getContexts', {}, @key)
      contexts_by_name = {} 
      contexts_by_id = {}    
      contexts = []
      # should return something like      
      # <contexts>
      #   <context id="123">Work</context>
      #   <context id="456">Home</context>
      #   <context id="789">Car</context>
      # </contexts>
      result.elements.each { |el|
        id = el.attributes['id']
        name = el.text
        context = Context.new(id, name)
        contexts.push(context)
        contexts_by_id[id] = context
        contexts_by_name[name.downcase] = context
      }
      @contexts_by_id = contexts_by_id
      @contexts_by_name = contexts_by_name
      @contexts = contexts
      return contexts
    end
  
    # title: takes the title (limit of 32 characters)
    # returns the context id.
    def add_context(title)
      log("add_context(#{title})") if (debug?)
      raise "Nil title" if (title == nil)
      
      result = call('addContext', { :title => title }, @key)
      
      flush_contexts()
      
      return result.text
    end
  
    def delete_context(id)
      log("delete_context(#{id})") if (debug?)
      raise "Nil id" if (id == nil)
      
      result = call('deleteContext', { :id => id }, @key)
      
      flush_contexts();
      
      return (result.text == '1')
    end
    
    def flush_contexts()
      log('flush_contexts()') if (debug?)

      @contexts_by_id = nil
      @contexts_by_name = nil
      @contexts = nil
    end
  
    ############################################################################
    # Goals
    ############################################################################
  
    # Downcased internally for ease of use.
    def get_goal_by_name(goal_name)
      log("get_goal_by_name(#{goal_name})") if (debug?)
      if (@goals_by_name == nil)
        get_goals(true)
      end

      goal = @goals_by_name[goal_name.downcase]
      return goal
    end
  
    def get_goal_by_id(goal_id)
      log("get_goal_by_id(#{goal_id})") if (debug?)
      if (@goals_by_id == nil)
        get_goals(true)
      end
    
      goal = @goals_by_id[goal_id]
      return goal
    end
  
    def get_goals(flush = false)
      log("get_goals(#{flush})") if (debug?)
      return @goals unless (flush || @goals == nil)
     
      result = call('getGoals', {}, @key)
   
      # <goals>
      #   <goal id="123" level="0" contributes="0">Get a Raise</goal>
      #   <goal id="456" level="0" contributes="0">Lose Weight</goal>
      #   <goal id="789" level="1" contributes="456">Exercise regularly</goal>
      # </goals>
      goals_by_name = {}
      goals_by_id = {}
      goals = []
      result.elements.each { |el| 
         id = el.attributes['id']
         level = el.attributes['level'].to_i
         contributes_id = el.attributes['contributes']
         name = el.text
         goal = Goal.new(id, level, contributes_id, name)
         goals << goal
         goals_by_id[id] = goal
         goals_by_name[name.downcase] = goal
      }
      
      # Loop through and make sure we've got a reference for every contributing goal.
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
      
    # title : A text string up to 255 characters.
    # level : The integer 0, 1 or 2 specifying the level. The default is 0. (0=lifetime, 1=long-term, 2=short-term)
    # contributes : The id number returned from the "getGoals" API call for the higher level goal that this goal contributes to.
    def add_goal(title, level = 0, contributes = 0)
      log("add_goal(#{title}, #{level}, #{contributes})") if (debug?)
      raise "Nil title" if (title == nil)

      result = call('addGoal', { :title => title, :level => level, :contributes => contributes }, @key)
      
      flush_goals()

      return result.text
    end
  
    def delete_goal(id)
      log("delete_goal(#{id})") if (debug?)
      raise "Nil id" if (id == nil)
      
      result = call('deleteGoal', { :id => id }, @key)
      
      flush_goals()
      
      return (result.text == '1')
    end
    
    def flush_goals()
      log('flush_goals()') if (debug?)
      
      @goals = nil
      @goals_by_name = nil
      @goals_by_id = nil
    end
  
    ############################################################################
    # Folders
    ############################################################################
  
    #
    # Gets the folder by the name.  The folder is lowercased internally for ease
    # of use.
    def get_folder_by_name(folder_name)
      log("get_folders_by_name(#{folder_name})") if (debug?)
      raise "Nil folder name" if (folder_name == nil)
      
      if (@folders_by_name == nil)
        get_folders(true)
      end
    
      return @folders_by_name[folder_name.downcase]
    end
  
    def get_folder_by_id(folder_id)
      log("get_folder_by_id(#{folder_id})") if (debug?)
      raise "Nil folder_id" if (folder_id == nil)
      
      if (@folders_by_id == nil)
        get_folders(true)
      end
    
      return @folders_by_id[folder_id]
    end
  
    # Gets all the folders.
    def get_folders(flush = false)
      log("get_folders(#{flush})") if (debug?)
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
          id = el.attributes['id']
          is_private = el.attributes['private']
          archived = el.attributes['archived']
          name = el.text
          folder = Folder.new(id, is_private, archived, name)
          folders.push(folder)
          folders_by_name[name.downcase] = folder # lowercase the key search
          folders_by_id[id] = folder
      }
      @folders = folders
      @folders_by_name = folders_by_name
      @folders_by_id = folders_by_id
      return @folders
    end
  
    # * title : A text string up to 32 characters.
    # * private : A boolean value (0 or 1) that describes if this folder can be shared. A value of 1 means that this folder is private.
    # return the folder id of the new item.
    def add_folder(title, is_private = 1)
      log("add_folder(#{title}, #{is_private})") if (debug?)
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
    
    def flush_folders()      
      log("flush_folders()") if (debug?)
      
      @folders = nil
      @folders_by_name = nil
      @folders_by_id = nil      
    end
    
    # * id : The id number of the folder to edit.
    # * title : A text string up to 32 characters.
    # * private : A boolean value (0 or 1) that describes if this folder can be shared. A value of 1 means that this folder is private.
    # * archived : A boolean value (0 or 1) that describes if this folder is archived.
    def edit_folder(id, params = {})
      log("edit_folder(#{id}, #{params})") if (debug?)
      raise "Nil id" if (id == nil)
      
      myhash = { :id => id }
      
      handle_string(myhash, params, :title)
      
      handle_boolean(myhash, params, :private)
      
      handle_boolean(myhash, params, :archived)
      
      result = call('editFolder', myhash, @key)
      
      flush_folders()
      
      return (result.text == '1')
    end
  
    # id : The folder id.
    def delete_folder(id)
      log("delete_folder(#{id})") if (debug?)
      raise "Nil id" if (id == nil)
      
      result = call('deleteFolder', { :id => id }, @key)
      
      flush_folders()
      
      return (result.text == '1')
    end
  
    ############################################################################
    # Protected methods follow
    ############################################################################
  
    protected
  
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
      if (value != nil)
        if (value.kind_of? TrueClass)
          myhash.merge!({ symbol => value.to_s})          
        elsif (value.kind_of? FalseClass)
          myhash.merge!({ symbol => value.to_s})
        else
          myhash.merge!({ symbol => value })
        end
      end
    end

    # Generic version
    def handle_string(myhash, params, symbol)
      value = params[symbol]
      if (value != nil)
        myhash.merge!({ symbol => value })
      end
    end
  
    # Generic version
    def handle_date(myhash, params, symbol)
      value = params[symbol]
      if (value != nil)
        if (value.kind_of? Time)
          myhash.merge!({ symbol => value.strftime('%Y-%m-%d')})
        else
          myhash.merge!({ symbol => value })          
        end
      end
    end
  
    # Generic version
    def handle_time(myhash, params, symbol)
      value = params[symbol]
      if (value != nil)
        if (value.kind_of? Time)
          myhash.merge!({ symbol => value.strftime('%H:%M %p')})
        else
          myhash.merge!({ symbol => value })                      
        end
      end
    end

    def handle_datetime(myhash, params, symbol)
      # YYYY-MM-DD HH:MM:SS
      value = params[symbol]
      if (value != nil)
        if (value.kind_of? Time)
          myhash.merge!({ symbol => value.strftime('%Y-%m-%d %H:%M:%S')})
        else
          myhash.merge!({ symbol => value })                      
        end
      end
    end
  
    #
    def handle_parent(myhash, params)
      parent = params[:parent]
      if (parent != nil)        
        myhash.merge!({ :parent => parent })
      end 
    end

    def handle_folder(myhash, params)      
      folder = params[:folder]
      if (folder != nil)        
        if (folder.kind_of? String)
          folder_obj = get_folder_by_name(folder)
          raise "No folder found with name #{folder}" if (folder_obj == nil)  
          myhash.merge!({ :folder => folder_obj.server_id })
        end
      end 
    end

    def handle_context(myhash, params)
      context = params[:context]
      if (context != nil)
        if (context.kind_of? String)
          context_obj = get_context_by_name(context)
          myhash.merge!({ :context => context_obj.server_id })
        end
      end      
    end

    def handle_goal(myhash, params)
      goal = params[:goal]
      if (goal != nil)
        if (goal.kind_of? String)
          goal_obj = get_goal_by_name(goal)
          myhash.merge!({ :goal => goal_obj.server_id })
        end
      end
    end
  
    # XXX add special logic to handle duedate modifiers
    def handle_duedate(myhash, params)
      handle_date(myhash, params, :duedate)
    end
  
    def handle_duetime(myhash, params)
      handle_time(myhash, params, :duetime)
    end

    def handle_repeat(myhash, params)
      repeat = params[:repeat]
      if (repeat != nil)        
        if (repeat.kind_of? Symbol)
          repeat = REPEAT_MAP[repeat]
        elsif (repeat.kind_of? String)
          repeat = repeat.intern
          validate_symbol(repeat, REPEAT_MAP.keys)
          repeat = REPEAT_MAP[repeat.intern]
        else
          possible_values = REPEAT_MAP.keys.join(", ")
          raise ":repeat must be one of the following: " + possible_values
        end
    
        repeat = REPEAT_MAP[params[:repeat]]
        myhash.merge!({ :repeat => repeat })
      end
    end

    def handle_priority(myhash, params)
      priority = params[:priority]
      if (priority != nil)
        if (priority.kind_of? Symbol)        
          priority = PRIORITY_MAP[priority]          
        elsif (priority.kind_of? String) 
          priority = priority.intern
          validate_symbol(priority, PRIORITY_MAP.keys)
          priority = PRIORITY_MAP[priority]        
        elsif (priority.kind_of? Fixnum)
          raise "Invalid priority: #{priority}" if (priority < -1 || priority > 3)
        end
        myhash.merge!({ :priority => priority })
      end      
    end
 
    #  Hashes the input string and returns a string hex digest.
    def md5(input_string)
      return Digest::MD5.hexdigest(input_string)
    end
  
    def validate_symbol(symbol, possible_keys)
        if (! possible_keys.include?(symbol))
          possible_values = possible_keys.keys.join(", ")
          raise "symbol must be one of the following: " + possible_values
        end
    end
  end
end