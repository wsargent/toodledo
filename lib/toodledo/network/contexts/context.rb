
class Toodledo::Network::Contexts::Context


    ############################################################################
    # Contexts
    ############################################################################

    #
    # Returns the context with the given name.
    #
    def get_context_by_name(context_name)
      logger.debug("get_context_by_name(#{context_name})") if logger

      if (@contexts_by_name == nil)
        get_contexts(true)
      end

      context = @contexts_by_name[context_name.downcase]
      return context
    end

    #
    # Returns the context with the given id.
    #
    def get_context_by_id(context_id)
      logger.debug("get_context_by_id(#{context_id})") if logger

      if (@contexts_by_id == nil)
        get_contexts(true)
      end

      context = @contexts_by_id[context_id]
      return context
    end

    #
    # Gets the array of contexts.
    #
    def get_contexts(flush = false)
      logger.debug("get_contexts(#{flush})") if logger
      return @contexts unless (flush || @contexts == nil)

      result = call('getContexts', {}, @key)
      contexts_by_name = {}
      contexts_by_id = {}
      contexts = []

      result.elements.each { |el|
        context = Context.parse(self, el)
        contexts << context
        contexts_by_id[context.server_id] = context
        contexts_by_name[context.name.downcase] = context
      }
      @contexts_by_id = contexts_by_id
      @contexts_by_name = contexts_by_name
      @contexts = contexts
      return contexts
    end

    #
    # Adds the context to Toodledo, with the title.
    #
    def add_context(title)
      logger.debug("add_context(#{title})") if logger
      raise "Nil title" if (title == nil)

      result = call('addContext', { :title => title }, @key)

      flush_contexts()

      return result.text
    end

    #
    # Deletes the context from Toodledo, using the id.
    #
    def delete_context(id)
      logger.debug("delete_context(#{id})") if logger
      raise "Nil id" if (id == nil)

      result = call('deleteContext', { :id => id }, @key)

      flush_contexts();

      return (result.text == '1')
    end

    #
    # Deletes the cached contexts.
    #
    def flush_contexts()
      logger.debug('flush_contexts()') if logger

      @contexts_by_id = nil
      @contexts_by_name = nil
      @contexts = nil
    end


end