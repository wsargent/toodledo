
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

    # TODO Repetitious. Refactor
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

    # Returns a hash containing :id and :stamp, a timestamp showing when the task was deleted.
    #
    # <task>
    #  <id>12345</id>
    #  <stamp>2008-02-25 07:46:42</stamp>
    #  </task>
    #  <task>
    #  <id>67890</id>
    #  <stamp>2008-03-12 14:11:12</stamp>
    #  </task>
    #  
    def self.parse_deleted(session, el)      
      id = el.elements['id'].text
      stamp = el.elements['stamp'].text

      fmt = Session::DATETIME_FORMAT
      deleted_stamp = DateTime.strptime(stamp, fmt)
      
      return { :id => id, :stamp => deleted_stamp }
    end

    # Parses a task element and returns a new Task.
    def self.parse(session, el)

      # #-- <task>
      #   <id>1234</id>
      #   <parent>1122</parent>
      #   <children>0</children>
      #   <title>Buy Milk</title>
      #   <tag>After work</tag> # Actually, this counts as two tags
      #   <folder>123</folder>
      #   <context id="123">Home</context>
      #   <goal id="123">Get a Raise</goal>
      #   <added>2006-01-23</added>
      #   <modified>2006-01-25 05:12:45</modified>
      #   <duedate modifier="=">2006-01-25</duedate>
      #   <duetime>2:00pm</duetime>
      #   <completed>2008-01-20</completed>
      #   <repeat>1</repeat>
      #   <priority>2</priority>
      #   <length>20</length>
      #   <timer onfor=''>0</timer>
      #   <note></note>
      #   <startdate></startdate>
      #   <status>0</status>
      #   <star></star>
      # </task> #++

      id = el.elements['id'].text

      folder_id = el.elements['folder'].text
      folder = session.get_folder_by_id(folder_id);
      if (folder == nil)
        folder = Folder::NO_FOLDER
      end

      goal_id = el.elements['goal'].attributes['id']
      goal = session.get_goal_by_id(goal_id)
      if (goal == nil)
        goal = Goal::NO_GOAL
      end

      context_id = el.elements['context'].attributes['id']
      context = session.get_context_by_id(context_id)
      if (context == nil)
        context = Context::NO_CONTEXT
      end

      duedatemodifier = nil
      duedate = el.elements['duedate'].text

      if (duedate != nil)
        duedatemodifier = el.elements['duedate'].attribute('modifier')
        duetime = el.elements['duetime'].text
        if (duetime != nil)
          duedate += " #{duetime}"
          fmt = Session::DATE_FORMAT + ' ' + Session::TIME_FORMAT
          duedate = DateTime.strptime(duedate, fmt)
        else
          fmt = Session::DATE_FORMAT
          duedate = DateTime.strptime(duedate, fmt)
        end
      end

      added = el.elements['added'].text
      if (added != nil)
        added = Date.strptime(added, Session::DATE_FORMAT)
      end

      modified = el.elements['modified'].text
      if (modified != nil)
        modified = DateTime.strptime(modified, Session::DATETIME_FORMAT)
      end

      completed = el.elements['completed'].text
      if (completed != nil)
        completed = Date.strptime(completed, Session::DATE_FORMAT)
      end

      repeat = el.elements['repeat'].text.to_i
      
      priority = el.elements['priority'].text.to_i

      # Only set a parent if it's not the 'empty parent'.
      parent_id_el = el.elements['parent']
      if (parent_id_el != nil)
        parent_id = parent_id_el.text
        if parent_id == '0'
          parent_id = nil
        else
          parent_id = parent_id.to_i
          parent = session.get_task_by_id(parent_id)
        end
      else 
        parent_id = nil
      end
      
      # This is actually the NUMBER of children.  Two children returns 2.
      num_children = el.elements['children'].text.to_i
      
      title = el.elements['title'].text
      
      tag = el.elements['tag'].text
      if tag == '0'
        tag = nil
      elsif tag
        tag = tag.split(/\s+/)
      end
      
      length = el.elements['length'].text
      length = nil if (length == '0')
      
      timer = el.elements['timer'].text
      timer = nil if (timer == '0')
      
      note = el.elements['note'].text
      note = nil if (note == '0')
      
      startdate = el.elements['startdate'].text
      if (startdate != nil)
        startdate = Date.strptime(startdate, Session::DATE_FORMAT)
      end
      
      status = el.elements['status'].text.to_i
      status = Status::NONE if (status == 0)
      
      star = (el.elements['star'].text.to_i == 1)
      
      params = {
        :parent_id => parent_id,
        :parent => parent,
        :num_children => num_children,
        :title => title,
        :tag => tag,
        :folder => folder,
        :context => context,
        :goal => goal,
        :added => added,
        :modified => modified,
        :duedate => duedate,
        :duedatemodifier => duedatemodifier,
        :completed => completed,
        :repeat => repeat,
        :priority => priority,
        :length => length,
        :timer => timer,
        :note => note,
        :startdate => startdate,
        :status => status,
        :star => star
      }
      return Task.new(id, params)
    end

    def to_xml()
      # XXX Need to make this be contextual. #<task>
      #  <id>#{@id}</id>
      #  <parent>#{@parent_id}</parent>
      #  <children>#{@children}</children>
      #  <title>#{@title}</title>
      #  <tag>#{@tag.join(' ')}</tag>
      #  <folder>#{@folder.server_id}</folder>
      #  <context id="#{@context.server_id}">#{@context.name}</context>
      #  <goal id="#{@goal.server_id}">#{@goal.name}</goal>
      #  <added>#{@added}</added>
      #  <modified>#{@modified}</modified>
      #  <duedate modifier="@duedatemodifier">#{@duedate.strftime(Session::DATE_FORMAT)}</duedate>
      #  <duetime>#{@duedate.strftime(Session::TIME_FORMAT)}</duetime>
      #  <completed>#{@completed}</completed>
      #  <repeat>#{@repeat}</repeat>
      #  <priority>#{@priority}</priority>
      #  <length>#{@length}</length>
      #  <timer>#{@timer}</timer>
      #  <note>#{@note}</note>
      # #</task>
      return 'implement me!'
    end

  end

end
