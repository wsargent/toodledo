
require 'toodledo/repeat'
require 'toodledo/priority'
require 'date'

module Toodledo

  # 
  # A read only representation of a Task.  This has some sugar in it to return
  # relevant Context, Folder and Goal objects instead of their underlying ids.
  # 
  class Task

    # Indicates that this task can only be completed on the given duedate. See
    # http://www.toodledo.com/info/help.php?sel=42
    ONLY = '='

    # Indicates that the earliest the task can be completed is the duedate. See
    # http://www.toodledo.com/info/help.php?sel=42
    EARLIEST = '<'

    # Indicates that the task's duedate is optional. See
    # http://www.toodledo.com/info/help.php?sel=42
    OPTIONAL = '?'
    
    attr_reader :parent_id, :parent, :title, :tag
    attr_reader :added, :modified, :completed
    attr_reader :duedate, :duedatemodifier
    attr_reader :repeat, :priority 
    attr_reader :length, :timer 
    attr_reader :note
    
    # as of 3.90
    attr_reader :status
    attr_reader :startdate
    attr_reader :star

    def server_id
      return @id
    end

    def context
      return @context
    end

    def folder
      return @folder
    end

    def goal
      return @goal
    end
    
    def num_children
      return @num_children
    end

    def initialize(id, params = {})
      @id = id

      @title = params[:title]
      @tag = params[:tag]

      @parent_id = params[:parent_id]
      @parent = params[:parent]
      @num_children = params[:num_children]

      # The folder, context and goals are parsed out from get_tasks() call into
      # the appropriate object.
      @folder = params[:folder]
      @context = params[:context]
      @goal = params[:goal]

      @added = params[:added]
      @modified = params[:modified]
      @completed = params[:completed]
      
      @duedate = params[:duedate]
      @duedatemodifier = params[:duedatemodifier]
      @duetime = params[:duetime]

      @repeat = params[:repeat]

      @priority = params[:priority]

      @length = params[:length]
      @timer = params[:timer]
      @note = params[:note]
      
      @startdate = params[:startdate]
      @status = params[:status]
      @star = params[:star]
    end

    def completed?
      return @completed != nil
    end

    def is_parent?
      return ! (@num_children == nil || @num_children == 0)
    end

  end

end
