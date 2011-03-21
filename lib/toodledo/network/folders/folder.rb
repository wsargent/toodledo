
class Toodledo::Network::Folders::Folder



    ############################################################################
    # Folders
    ############################################################################

    #
    # Gets the folder by the name.  Case insensitive.
    def get_folder_by_name(folder_name)
      logger.debug("get_folders_by_name(#{folder_name})") if logger
      raise "Nil folder name" if (folder_name == nil)

      if (@folders_by_name == nil)
        get_folders(true)
      end

      return @folders_by_name[folder_name.downcase]
    end

    #
    # Gets the folder with the given id.
    #
    def get_folder_by_id(folder_id)
      logger.debug("get_folder_by_id(#{folder_id})") if logger
      raise "Nil folder_id" if (folder_id == nil)

      if (@folders_by_id == nil)
        get_folders(true)
      end

      return @folders_by_id[folder_id]
    end

    # Gets all the folders.
    def get_folders(flush = false)
      logger.debug("get_folders(#{flush})") if logger
      return @folders unless (flush || @folders == nil)

      result = call('getFolders', {}, @key)
      # <folders>
      #   <folder id="123" private="0" archived="0">Shopping</folder>
      #   <folder id="456" private="0" archived="0">Home Repairs</folder>
      #   <folder id="789" private="0" archived="0">Vacation Planning</folder>
      #   <folder id="234" private="0" archived="0">Chores</folder>
      #   <folder id="567" private="1" archived="0">Work</folder>
      # </folders>
      folders = []
      folders_by_name = {}
      folders_by_id = {}
      result.elements.each { |el|
          folder = Folder.parse(self, el)
          folders.push(folder)
          folders_by_name[folder.name.downcase] = folder # lowercase the key search
          folders_by_id[folder.server_id] = folder
      }
      @folders = folders
      @folders_by_name = folders_by_name
      @folders_by_id = folders_by_id
      return @folders
    end

    # Adds a folder.
    # * title : A text string up to 32 characters.
    # * private : A boolean value that describes if this folder can be shared.
    #
    # Returns the id of the newly added folder.
    def add_folder(title, is_private = 1)
      logger.debug("add_folder(#{title}, #{is_private})") if logger
      raise "Nil title" if (title == nil)

      if (is_private.kind_of? TrueClass)
        is_private = 1
      elsif (is_private.kind_of? FalseClass)
        is_private = 0
      end

      myhash = { :title => title, :private => is_private}

      result = call('addFolder', myhash, @key)

      flush_folders()

      return result.text
    end

    #
    # Nils out the cached folders.
    #
    def flush_folders()
      logger.debug("flush_folders()") if logger

      @folders = nil
      @folders_by_name = nil
      @folders_by_id = nil
    end

    # Edits a folder.
    # * id : The id number of the folder to edit.
    # * title : A text string up to 32 characters.
    # * private : A boolean value (0 or 1) that describes if this folder can be
    #   shared. A value of 1 means that this folder is private.
    # * archived : A boolean value (0 or 1) that describes if this folder is archived.
    #
    # Returns true if the edit was successful.
    def edit_folder(id, params = {})
      logger.debug("edit_folder(#{id}, #{params.inspect})") if logger
      raise "Nil id" if (id == nil)

      myhash = { :id => id }

      handle_string(myhash, params, :title)

      handle_boolean(myhash, params, :private)

      handle_boolean(myhash, params, :archived)

      result = call('editFolder', myhash, @key)

      flush_folders()

      return (result.text == '1')
    end

    # Deletes the folder with the id.
    # id : The folder id.
    #
    # Returns true if the delete was successful.
    def delete_folder(id)
      logger.debug("delete_folder(#{id})") if logger
      raise "Nil id" if (id == nil)

      result = call('deleteFolder', { :id => id }, @key)

      flush_folders()

      return (result.text == '1')
    end

end