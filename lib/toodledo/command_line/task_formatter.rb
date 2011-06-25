
module Toodledo
  module CommandLine    
    class TaskFormatter
      
      # Formats the task for a command line.
      def format(task)
        fancyp = '!' + readable_priority(task.priority)
  
        msg = "<#{task.server_id}> -- #{fancyp}"
  
        # TODO Only include [ ] if needed
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
          msg += " <[#{task.duedatemodifier}:#{task.duedate.strftime(fmt)}]"
        end
        
        if (task.startdate != nil)
          fmt = '%m/%d/%Y'
          msg += " startdate[#{task.startdate.strftime(fmt)}]"
        end
        
        if (task.status != Status::NONE)
          msg += " status[#{readable_status(task.status)}]"
        end
        
        if (task.star)
          msg += " starred"
        end
  
        if (task.tag != nil)
          msg += " %[#{task.tag}]"
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
      
      # TODO Refactor using symbols -- so much simpler to convert
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
      
      #
      # Returns a string matching the numeric repeat code.
      #
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
      
      #
      # Return a readable status given the numeric code.
      #
      def readable_status(status)
        case status
        when Status::NONE
          'none'
        when Status::NEXT_ACTION
          'Next Action'
        when Status::ACTIVE
          'Active'
        when Status::PLANNING
          'Planning'
        when Status::DELEGATED
          'Delegated'
        when Status::WAITING
          'Waiting'
        when Status::HOLD
          'Hold'
        when Status::POSTPONED
          'Postponed'
        when Status::SOMEDAY
          'Someday'
        when Status::CANCELLED
          'Cancelled'
        when Status::REFERENCE
          'Reference'
        end
      end
    end
  end
end