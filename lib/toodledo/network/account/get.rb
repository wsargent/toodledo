

class Toodledo::Network::Account::Get


    # Returns the information associated with this account.
    #
    #   pro : Whether or not the user is a Pro member. You need to know this if you want to use subtasks.
    #   dateformat : The user's prefered format for representing dates. (0=M D, Y, 1=M/D/Y, 2=D/M/Y, 3=Y-M-D)
    #   timezone : The number of half hours that the user's timezone is offset from the server's timezone. A value of -4 means that the user's timezone is 2 hours earlier than the server's timezone.
    #   hidemonths : If the task is due this many months into the future, the user wants them to be hidden.
    #   hotlistpriority : The priority value above which tasks should appear on the hotlist.
    #   hotlistduedate : The due date lead-time by which tasks should will appear on the hotlist.
    #   lastaddedit: last time this was edited
    #   lastdelete:
    def execute()
      result = call(url, {}, @key)

      pro = (result.elements['pro'].text.to_i == 1) ? true : false

      #<lastaddedit>2008-01-24 12:26:45</lastaddedit>
      #<lastdelete>2008-01-23 15:45:55</lastdelete>
      fmt = DATETIME_FORMAT

      lastaddedit = result.elements['lastaddedit'].text
      if (lastaddedit != nil)
        last_modified_date = DateTime.strptime(lastaddedit, fmt)
      else
        last_modified_date = nil
      end

      lastdelete = result.elements['lastdelete'].text
      if (lastdelete != nil)
        logger.debug("lastdelete = #{lastdelete}") if logger
        last_deleted_date = DateTime.strptime(lastdelete, fmt)
      else
        last_deleted_date = nil
      end

      hash = {
        :userid => result.elements['userid'].text,
        :alias => result.elements['alias'].text,
        :pro => pro,
        :dateformat => result.elements['dateformat'].text.to_i,
        :timezone => result.elements['timezone'].text.to_i,
        :hidemonths => result.elements['hidemonths'].text.to_i,
        :hotlistpriority => result.elements['hotlistpriority'].text.to_i,
        :hotlistduedate => result.elements['hotlistduedate'].text.to_i,
        :lastaddedit => last_modified_date,
        :lastdelete => last_deleted_date
      }

      return hash
    end


end