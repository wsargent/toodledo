
module Toodledo
  module CommandLine    
    class TaskFormatter
      
      # Formats the task for a command line.
      def format(task)
        fancyp = '!' + readable_priority(task.priority)
  
        msg = "<#{task.server_id}> -- #{fancyp}"
  
        if (task.folder != Folder::NO_FOLDER)
          msg += " *[#{task.folder.name}]"
        end
  
        if (task.context != Context::NO_CONTEXT)
          msg += " @[#{task.context.name}]"
        end
  
        if (task.goal != Goal::NO_GOAL)
          msg += " ^[#{task.goal.name}]"
        end
  
        if (task.repeat != Repeat::NONE)
          msg += " repeat[#{readable_repeat(task.repeat)}]"
        end
  
        if (task.duedate != nil)
          fmt = '%m/%d/%Y %I:%M %p'
          msg += " \#[#{task.duedatemodifier}#{task.duedate.strftime(fmt)}]"
        end
  
        if (task.tag != nil)
          msg += " tag[#{task.tag}]"
        end
        
        if (task.parent_id != nil)
          msg += " parent[#{task.parent.title}]"
        end
  
        if (task.length != nil)
          msg += " length[#{task.length}]"
        end
        
        if (task.timer != nil)
          msg += " timer[#{task.timer}]"
        end
        
        if (task.num_children != nil && task.num_children > 0)
          msg += " children[#{task.num_children}]"
        end
        
        msg += " #{task.title}"
              
        if (task.note != nil)
          msg += "\n      #{task.note}"
        end
  
        return msg
      end
      
      def readable_priority(priority)
        case priority
          when Priority::TOP
            return 'top'
          when Priority::HIGH
            return 'high'
          when Priority::MEDIUM
            return 'medium'
          when Priority::LOW
            return 'low'
          when Priority::NEGATIVE
            return 'negative'
          else
            return ''
        end
      end
      
      def readable_repeat(repeat)
        case repeat
        when Repeat::NONE
          ''
        when Repeat::WEEKLY
          "weekly"
        when Repeat::MONTHLY
          "monthly"
        when Repeat::YEARLY
          "yearly"
        when Repeat::DAILY
          "daily"
        when Repeat::BIWEEKLY
          "biweekly"
        when Repeat::BIMONTHLY
          "bimonthly"
        when Repeat::SEMIANNUALLY
          "semiannually"
        when Repeat::QUARTERLY
          "quarterly"
        else
          ''
        end
      end
    end
  end
end