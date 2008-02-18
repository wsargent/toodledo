
module Toodledo
  module CommandLine
    class GoalFormatter
      def format(goal)
        msg = "<#{goal.server_id}> -- ^[#{goal.name}]"
        #if (goal.contributes != Goal::NO_GOAL)
        #  msg += " (Contributes to: #{goal.contributes.name})"
        #end
        return msg
      end
    end 
  end
end