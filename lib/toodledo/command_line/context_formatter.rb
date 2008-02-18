module Toodledo
  module CommandLine    
    class ContextFormatter
      def format(context)
        return "<#{context.server_id}> -- @[#{context.name}]"
      end
    end    
  end
end
