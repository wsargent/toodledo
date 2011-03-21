
require 'functional_spec_helper'


describe "Call Toodledo" do



  it "should call the server" do

    repository = Toodledo::Repository.connect('userid', 'password')
    folders = repository.get_folders({ :starred => true })
    folders.each do |folder|
      puts folder.to_s
    end

  end


end