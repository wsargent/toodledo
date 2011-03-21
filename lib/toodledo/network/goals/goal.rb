
class Toodledo::Network::Goals::Goal


    ############################################################################
    # Goals
    ############################################################################

    #
    # Returns the goal with the given name.  Case insensitive.
    #
    def get_goal_by_name(goal_name)
      logger.debug("get_goal_by_name(#{goal_name})") if logger
      if (@goals_by_name == nil)
        get_goals(true)
      end

      goal = @goals_by_name[goal_name.downcase]
      return goal
    end

    #
    # Returns the goal with the given id.
    #
    def get_goal_by_id(goal_id)
      logger.debug("get_goal_by_id(#{goal_id})") if logger
      if (@goals_by_id == nil)
        get_goals(true)
      end

      goal = @goals_by_id[goal_id]
      return goal
    end

    #
    # Returns the array of goals.
    #
    def get_goals(flush = false)
      logger.debug("get_goals(#{flush})") if logger
      return @goals unless (flush || @goals == nil)

      result = call('getGoals', {}, @key)

      goals_by_name = {}
      goals_by_id = {}
      goals = []
      result.elements.each do |el|
         goal = Goal.parse(self, el)
         goals << goal
         goals_by_id[goal.server_id] = goal
         goals_by_name[goal.name.downcase] = goal
      end

      # Loop through and make sure we've got a reference for every contributing
      # goal.
      for goal in goals
        next if (goal.contributes_id == Goal::NO_GOAL.server_id)
        parent_goal = goals_by_id[goal.contributes_id]
        goal.contributes = parent_goal
      end

      @goals = goals
      @goals_by_name = goals_by_name
      @goals_by_id = goals_by_id
      return goals
    end

    #
    # Adds a new goal with the given title, the level (short to long term) and
    # the contributing goal id.
    #
    def add_goal(title, level = 0, contributes = 0)
      logger.debug("add_goal(#{title}, #{level}, #{contributes})") if logger
      raise "Nil title" if (title == nil)

      params = { :title => title, :level => level, :contributes => contributes }
      result = call('addGoal', params, @key)

      flush_goals()

      return result.text
    end

    #
    # Delete the goal with the given id.
    #
    def delete_goal(id)
      logger.debug("delete_goal(#{id})") if logger
      raise "Nil id" if (id == nil)

      result = call('deleteGoal', { :id => id }, @key)

      flush_goals()

      return (result.text == '1')
    end

    #
    # Nils the cached goals.
    #
    def flush_goals()
      logger.debug('flush_goals()') if logger

      @goals = nil
      @goals_by_name = nil
      @goals_by_id = nil
    end

end