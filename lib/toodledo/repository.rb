require File.expand_path('../../toodledo')

require 'repository/memory_repository'

module Toodledo::Repository

  def self.connect(userid, password)
    return @@repository if (@@repository)

    @@repository = MemoryRepository.new(userid, password)
    @@repository
  end

end