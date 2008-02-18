$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'toodledo/command_line/client'
require 'flexmock/test_unit'

module Toodledo
  module CommandLine
    class ClientTest < Test::Unit::TestCase
      
      def setup()
        @client = Client.new()
        
        @session = flexmock('session')
      end
      
      def teardown()
        
      end
      
      def test_folders()
        
        folder = Folder.new(1, 0, 0, 'test folder')
        
        folders = [ folder ]
        @session.should_receive(:get_folders).and_return(folders)
        
        # Run the method.
        @client.folders(@session)        
      end
      
      def test_add_task_with_no_args()
        
        input = 'This is a test'
        args = {:priority=>Priority::LOW}
        
        @session.should_receive(:add_task).with(input, args).and_return 1
        
        @client.add_task(@session, input)
      end
      
      def test_add_task_with_folder()
        
        input = '*Inbasket This is a test'
        
        args = { :priority => Priority::LOW, :folder => "Inbasket" }
        
        @session.should_receive(:add_task).with('This is a test', args).and_return(1)
        
        @client.add_task(@session, input)
      end

      def test_add_task_with_context()
        
        
      end
      
      def test_add_task_with_goal()
        
      end
      
    end
  end
end
