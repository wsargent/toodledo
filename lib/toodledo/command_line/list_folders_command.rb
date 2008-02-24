# 
# 
# 
 

module Toodledo  
  module CommandLine
    
    
    #
    # List Folders
    #
    class ListFoldersCommand < BaseCommand
      def initialize(client)
        super(client, 'folders', false)
        self.short_desc = "List folders"
        self.description = "Lists the folders in Toodledo."
      end
      
      def execute(args)
        
        Toodledo.begin(client.logger) do |session|            
          line = args.join(' ')
          return client.list_folders(session, line)
        end
        
        return 0
      end
    end
   
  end
end    