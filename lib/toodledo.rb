# = toodledo.rb

require 'digest/md5'
require 'uri'
require 'open-uri'
require 'rexml/document'

=begin
  TODO Move to more of an activerecord model.
  
  task = Task.new()
  
  task.save!
  task.delete!
  task.update!
  
  tasks = Task.find_by_context()
  
  Goal.find_by_name()
  goal.save!
  goal.delete!
  goal.update!
  
  contexts = Context.find_by_name()
  context.save!
  context.delete!
  context.update!
  
  Should use the session behind the scenes.
=end
module Toodledo

  BASE_API_URL = 'http://www.toodledo.com/api.php'
 
  VERSION = '0.0.1'

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
    :medium =>1,
    :high => 2,
    :top =>3    
  }
  
  @debug_flag = false
    
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
  
  # Returns a parsable URI object from the base API URL and the parameters.
  def get_url(method, params)
    url_string = URI.escape(BASE_API_URL + '?method=' + method + params)
    return URI.parse(url_string)
  end
  
  # escape the & character as %26 and the ; character as %3B.
  def escape_text(input)
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
  def get_user_id(email, password)
    raise "Nil email" if (email == nil)
    raise "Nil password" if (password == nil)
    
    params = { :email => email, :pass => password }
    result = call('getUserid', params)  
    return result.text
  end
    
  # The toodledo session
  class Session
    
    include Toodledo
    
    @folders = nil
    
    @contexts = nil
    
    @goals = nil
        
    # Creates a new session, using the given user name and password.
    def initialize(user_id, password)
      raise "Nil user_id" if (user_id == nil)
      raise "Nil password" if (password == nil)
      
      session_token = get_token(user_id)
      key = md5(md5(password).to_s + session_token + user_id);
      @key = key
    end
    
    ############################################################################
    # Tasks
    ############################################################################

    def get_tasks(params={})
      
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
        tasks.push(task)
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
      
      myhash = {:title => title}      
      myhash.merge!(params)
      
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
      
      result = call('addTask', myhash, @key)
          
      return result.text
    end
    
    def edit_task
      
    end
    
    def delete_task
    
    end    

    ############################################################################
    # Contexts
    ############################################################################
    
    def get_context_by_name(context_name)
      if (@contexts_by_name == nil)
        get_contexts(true)  
      end
      
      context = @contexts_by_name[context_name.downcase]
      return context
    end
    
    def get_context_by_id(context_id)
      if (@contexts_by_id == nil)
        get_contexts(true)  
      end
      
      context = @contexts_by_id[context_id]
      return context      
    end
        
    def get_contexts(flush = false)
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
    
    def add_context
      
    end
    
    def delete_context
      
    end
    
    ############################################################################
    # Goals
    ############################################################################
    
    # Downcased internally for ease of use.
    def get_goal_by_name(goal_name)
      if (@goals_by_name == nil)
        get_goals(true)
      end

      goal = @goals_by_name[goal_name.downcase]
      return goal
    end
    
    def get_goal_by_id(goal_id)
      if (@goals_by_id == nil)
        get_goals(true)
      end
      
      goal = @goals_by_id[goal_id]
      return goal
    end
    
    def get_goals(flush = false)
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
         level = el.attributes['level']
         contributes = el.attributes['contributes']
         name = el.text
         goal = Goal.new(id, level, contributes, name)
         goals.push(goal)
         goals_by_id[id] = goal
         goals_by_name[name.downcase] = goal
      }
      @goals = goals
      @goals_by_name = goals_by_name
      @goals_by_id = goals_by_id
      return goals
    end
    
    def add_goal
      
    end
    
    def delete_goal
      
    end
    
    ############################################################################
    # Folders
    ############################################################################
    
    #
    # Gets the folder by the name.  The folder is lowercased internally for ease
    # of use.
    def get_folder_by_name(folder_name)
      if (@folders_by_name == nil)
        get_folders(true)
      end
      
      return @folders_by_name[folder_name.downcase]
    end
    
    def get_folder_by_id(folder_id)
      if (@folders_by_id == nil)
        get_folders(true)
      end
      
      return @folders_by_id[folder_id]
    end
    
    def get_folders(flush = false)
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
    
    def add_folder
      
    end
    
    def delete_folder
      
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
    
      # XXX Let priority be a number from -1 to 3
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
  
  ############################################################################
  # 
  #
  class Task   
    # <task>
    #   <id>1234</id>
    #   <parent>1122</parent>
    #   <children>0</children>
    #   <title>Buy Milk</title>
    #   <tag>After work</tag>
    #   <folder>123</folder>
    #   <context id="123">Home</context>
    #   <goal id="123">Get a Raise</goal>
    #   <added>2006-01-23</added>
    #   <modified>2006-01-25 05:12:45</modified>
    #   <duedate modifier=""></duedate>
    #   <duetime>2:00pm</duetime>
    #   <completed>2008-01-20</completed>
    #   <repeat>1</repeat>
    #   <priority>2</priority>
    #   <length>20</length>
    #   <timer>0</timer>
    #   <note></note>
    # </task>
    attr_reader :parent_id, :children_ids, :title, :tag, :folder_id, :folder
    attr_reader :context_id, :context
    attr_reader :goal_id, :goal
    attr_reader :added, :modified
    attr_reader :duedate, :duetime
    attr_reader :repeat, :priority, :length, :timer, :note
    
    def server_id
      return @id
    end
      
    def initialize(id, params = {})
      @id = id

      @title = params[:title]
      @parent_id = params[:parent]
      @children_ids = params[:children]
      @folder_id = params[:folder_id]
      @folder = params[:folder]
      @context_id = params[:context_id]
      @context = params[:context]
      @goal_id = params[:goal_id]      
      @goal = params[:goal]
      
      # XXX handle date
      @added = params[:added]
      @modified = params[:modified]
      @duedate = params[:duedate]      
      @duetime = params[:duetime]
      
      # completed is a date
      @completed = params[:completed]
      @repeat = params[:repeat]
      @priority = params[:priority]
      @length = params[:length]
      @timer = params[:timer]
      @note = params[:note]

      # Map from the provided parameters 
    end
    
    def completed?
      return @completed != nil
    end
    
    def is_parent?
      return ! (@children_ids == nil || @children_ids.empty?)
    end
    
    def to_s()
      return "#{@title}"
    end

    def inspect()
      return <<-HERE
       <task>
          <id>#{@id}</id>
         	<parent>#{@parent_id}</parent>
       		<children>#{@children_ids}</children>
       		<title>#{@title}</title>
       		<tag>#{@tag}</tag>
       		<folder>#{@folder_id}</folder>
       		<context id="#{@context_id}">#{@context}</context>
       		<goal id="#{@goal_id}">#{@goal}</goal>
       		<added>#{@added}</added>
       		<modified>#{@modified}</modified>
       		<duedate modifier="">#{@duedate}</duedate>
       		<duetime>#{@duetime}</duetime>
       		<completed>#{@completed}</completed>
       		<repeat>#{@repeat}</repeat>
       		<priority>#{@priority}</priority>
       		<length>#{@length}</length>
       		<timer>#{@timer}</timer>
       		<note>#{@note}</note>
       </task>
      HERE
    end
    
  end
  
  ############################################################################
  # 
  #
  class Goal
    
    attr_reader :level, :contributes, :name
    
    def initialize(id, level, contributes, name)    
      @id = id
      @level = level
      @contributes = contributes
      @name = name
    end
    
    def server_id
      return @id
    end
    
    def inspect()
      return "<goal id=\"#{@id}\" level=\"#{@level}\" contributes=\"#{contributes}\" name=\"#{name}\">"
    end
    
    def to_s()
      return @name
    end
  end
  
  class Folder
    
    attr_reader :is_private, :archived, :name
    
    def server_id
      return @id
    end
    
    def is_private?
      return @is_private == 1
    end
    
    def archived?
      return @archived == 1
    end
        
    def initialize(id, is_private, archived, name)
      @id = id
      @is_private = is_private
      @archived = archived
      @name = name
    end
    
    def to_s()
      return @name
    end
  end
  
  ############################################################################
  # 
  #
  class Context
    
    attr_reader :name
    
    def server_id
      return @id
    end
    
    def initialize(id, name)
      @id = id
      @name = name
    end
    
    def to_s()
      return @name
    end
  end
end


