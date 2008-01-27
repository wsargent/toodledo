module Toodledo
  
  
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
    attr_reader :parent_id, :children_ids, :title, :tag
    attr_reader :folder_id
    attr_reader :context_id
    attr_reader :goal_id
    attr_reader :added, :modified
    attr_reader :duedate, :duetime
    attr_reader :repeat, :priority, :length, :timer, :note
    
    def server_id
      return @id
    end
      
    def context
      if (@context == nil)
        return Context::NO_CONTEXT
      end
      return @context
    end
    
    def folder
      if (@folder == nil)
        return Folder::NO_FOLDER
      end
      return @folder
    end
    
    def goal
      if (@goal == nil)
        return Goal::NO_GOAL
      end
      return @goal
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
      
      # XXX completed is a date
      @completed = params[:completed]
      @repeat = params[:repeat]
      # priority should be a fix_num
      @priority = params[:priority].to_i
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
      if (priority == -1)
        fancyp = 'v'
      elsif (priority == 0)
        fancyp = '~'
      else
        fancyp = '!' * priority
      end
      return "#{fancyp} *[#{folder.name}] @[#{context.name}] #{title}"      
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
  
  
end