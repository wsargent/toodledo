module Toodledo
  module CommandLine    
    class FolderFormatter      
      def format(folder)
        return "<#{folder.server_id}> -- *[#{folder.name}]"
      end
    end    
  end
end
