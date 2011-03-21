
module Toodledo::Network::Helper


  ############################################################################
  # Helper methods follow.
  #
  # These methods will convert the appropriate format for talking to the
  # Toodledo server.  They do not parse the XML that comes back from the
  # server.
  ############################################################################


  # escape the & character as %26 and the ; character as %3B.
  # throws an exception if input is nil.
  def escape_text(input)
    raise "Nil input" if (input == nil)
    return input.to_s if (! input.kind_of? String)

    output_string = input.gsub('&', '%26')
    output_string = output_string.gsub(';', '%3B')
    return output_string
  end

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
    when Fixnum
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

  # Handles the status parameter
  def handle_status(myhash, params)
    status = params[:status]

    return if (status == nil)

    if (! Status.valid?(status))
      raise "Invalid status value: #{status}"
    end

    myhash.merge!({ :status => status })
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