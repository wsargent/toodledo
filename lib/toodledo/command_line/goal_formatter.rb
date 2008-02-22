require 'toodledo/goal'

module Toodledo
  module CommandLine
    class GoalFormatter
      def format(goal)
        msg = "<#{goal.server_id}> -- #{readable_level(goal.level)} ^[#{goal.name}]"
        if (goal.contributes != Goal::NO_GOAL)
          msg += " (Contributes to: ^[#{goal.contributes.name}])"
        end
        return msg
      end
      
      def readable_level(level)
        case level
        when Goal::LIFE_LEVEL
          return 'life'
        when Goal::MEDIUM_LEVEL
          return 'medium'
        when Goal::SHORT_LEVEL
          return 'short'
        end
      end
    end 
  end
end