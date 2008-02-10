module Toodledo
  
  #
  # A read only representation of a Task.  This has some sugar in it to return
  # relevant Context, Folder and Goal objects instead of their underlying ids.
  #
  class Task   
    #--
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
    #++
    attr_reader :parent_id, :children_ids, :title, :tag
    attr_reader :added, :modified, :completed
    attr_reader :duedate, :duetime, :duedatemodifier
    attr_reader :repeat, :priority, :length, :timer, :note
    
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
      
    def initialize(id, params = {})
      @id = id

      @title = params[:title]
      
      @parent_id = params[:parent].to_i
      
      # Handle the children.
      # XXX parse out multiple children.
      @children_ids = params[:children]
      
      # The folder, context and goals are parsed out from 
      # get_tasks() call into the appropriate object.
      @folder = params[:folder]
      @context = params[:context]      
      @goal = params[:goal]

      @added = params[:added]
      @modified = params[:modified]

      @duedate = params[:duedate]
      @duedatemodifier = params[:duedatemodifier]      
      @duetime = params[:duetime]
      
      @completed = params[:completed]
      @repeat = params[:repeat]
      
      @priority = params[:priority].to_i
      
      @length = params[:length]
      @timer = params[:timer]
      @note = params[:note]
    end
    
    def parse_duedate(date)
      
      
      
    end
    
    def completed?
      return @completed != nil
    end
    
    def is_parent?
      return ! (@children_ids == nil || @children_ids.empty?)
    end
    
    def to_s()
      if (priority == -1)
        fancyp = 'v'
      elsif (priority == 0)
        fancyp = '~'
      else
        fancyp = '!' * priority
      end
      return "#{fancyp} *[#{folder.name}] @[#{context.name}] #{title}"      
    end

    def to_xml()
      return <<-HERE
<task>
  <id>#{@id}</id>
  <parent>#{@parent_id}</parent>
  <children>#{@children_ids}</children>
  <title>#{@title}</title>
  <tag>#{@tag}</tag>
  <folder>#{@folder.server_id}</folder>
  <context id="#{@context.server_id}">#{@context.name}</context>
  <goal id="#{@goal.server_id}">#{@goal.name}</goal>
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
  
end