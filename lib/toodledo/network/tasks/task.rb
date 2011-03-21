

class Toodledo::Network::Tasks::Task



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
    # * star
    # * status
    # * startdate
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

      # startbefore:
      handle_date(myhash, params, :startbefore)

      # startafter:
      handle_date(myhash, params, :startafter)

      # star
      handle_boolean(myhash, params, :star)

      # status
      handle_status(myhash, params)

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

    #
    # Gets a single task by its id, and returns the task.
    #
    def get_task_by_id(id)
      result = call('getTasks', {:id => id}, @key)
      result.elements.each do |el|
        task = Task.parse(self, el)
        return task
      end
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

      # Add the start date if it's been added.
      handle_date(myhash, params, :startdate)

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

      # Handle the star.
      handle_boolean(myhash, params, :star)

      # Handle the status date.
      handle_status(myhash, params)

      # Handle the note.
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

      # Handle star
      handle_boolean(myhash, params, :star)

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

    #
    # Returns deleted tasks.
    #
    #   after: a datetime object that indicates the start date after which deletes should be shown.
    #
    def get_deleted(after )
      logger.debug("get_deleted(#{after})") if logger

      formatted_after = after.strftime(Session::DATETIME_FORMAT)
      result = call('getDeleted', { :after => formatted_after }, @key)
      deleted_tasks = []
      result.elements.each do |el|
        deleted_task = Task.parse_deleted(self, el)
        deleted_tasks << deleted_task
      end
      return deleted_tasks
    end

end