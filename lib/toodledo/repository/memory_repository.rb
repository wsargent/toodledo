require File.expand_path('../../toodledo')

class Toodledo::Repository::MemoryRepository

  include Toodledo::Network

  def connect(userid, password)
    @userid = userid
    @password = password

    @session = Session.new(@user, password)
  end

  def sync

  end

  def get_folders(options = {:deleted => false})

    # Look at our internal proxy to see if we have anything...

    # No, we don't.  Go get folder data.
    command = Toodledo::Network::Folders::Get.new
    folders = session.execute(command)

    # Put the result into the local data structure...

    folders
  end

  private

  def session
    if (@session.expired?)
      @session.disconnect()
    end

    @session = Session.new(@user, password)
    @session
  end

end