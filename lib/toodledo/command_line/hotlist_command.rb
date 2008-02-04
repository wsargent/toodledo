module Toodledo 
  module CommandLine       
    class HotlistCommand < BaseCommand
      def initialize(client)
        super(client, 'hotlist', false)
        self.short_desc = "Show the hotlist"
        #self.description = "The interactive command line client."
      end
      
      def execute( args )        
        Toodledo.begin do |session|            
          if (client.debug? == true)
            session.debug = true            
          end
          
          hotlist(session)
        end        
      end   
      
      #
      # Run the hotlist command.
      #
      def hotlist(session)                    
        # Surprisingly, we can't search for "greater than 0 priority" with the API.
        not_important = 1
        params = { :notcomp => true }
        tasks = session.get_tasks(params)
        
        # Highest priority first
        tasks.sort! do |a, b|
          b.priority <=> a.priority
        end
        
        # filter on our end.
        for task in tasks
          if (task.priority > not_important)
            puts "<#{task.server_id}> -- #{task}\n"
          end
        end  
      end
    end
  end 
end