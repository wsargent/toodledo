$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'toodledo/command_line/client'
require 'flexmock/test_unit'

module Toodledo
  module CommandLine
    class ClientTest < Test::Unit::TestCase
      
      def setup()
        client = Client.new()
        
        # Set up a partial mock so we can override :print
        @client = flexmock(client)        
        @session = flexmock('session')
      end
      
      def test_set_priority_filter()        
        # We don't want an error message printed out here.
        @client.should_receive(:print).never
        @client.set_priority_filter(@session, 'top')        
      end
      
      def test_set_priority_filter_with_invalid_options()
        @client.should_receive(:print).with('Unknown priority "foo" -- (priority must be one of top, high, medium, low, or negative)')        
        @client.set_priority_filter(@session, 'foo')        
      end
      
      def test_folders()        
        folder = Folder.new(1, 0, 0, 'test folder')
        
        folders = [ folder ]
        @session.should_receive(:get_folders).and_return(folders)
        @client.should_receive(:print).with('<1> -- *[test folder]')
        
        # Run the method.
        @client.folders(@session)        
      end
      
      def test_contexts()        
        context = Context.new(1, 'test context')
        
        contexts = [ context ]
        @session.should_receive(:get_contexts).and_return(contexts)
        @client.should_receive(:print).with('<1> -- @[test context]')
        
        # Run the method.
        @client.contexts(@session)        
      end
      
      def test_goals()        
        goal = Goal.new(1, 0, 0, 'test goal')
        
        goals = [ goal ]
        @session.should_receive(:get_goals).and_return(goals)
        @client.should_receive(:print).with('<1> -- ^[test goal]')
        
        # Run the method.
        @client.goals(@session)        
      end
      
      def test_contexts()
        
        context = Context.new(1, 'test context')
        
        contexts = [ context ]
        @session.should_receive(:get_contexts).and_return(contexts)
        @client.should_receive(:print).with('<1> -- @[test context]')
        
        # Run the method.
        @client.contexts(@session)        
      end
      
      def test_add_task_with_no_args()
        
        input = 'This is a test'
        args = {}
        
        @session.should_receive(:add_task).with(input, args).and_return 1
        @client.should_receive(:print).with('Task 1 added.')
        @client.add_task(@session, input)
      end
      
      def test_add_task_with_folder()
        
        input = '*Inbasket This is a test'
        
        args = { :folder => "Inbasket" }
        
        @session.should_receive(:add_task).with('This is a test', args).and_return(1)
        @client.should_receive(:print).with('Task 1 added.')
        @client.add_task(@session, input)
      end

      def test_add_task_with_context()
        
        input = '@Home This is a test'
        
        args = { :context => "Home" }
        
        @session.should_receive(:add_task).with('This is a test', args).and_return(1)
        @client.should_receive(:print).with('Task 1 added.')
        
        @client.add_task(@session, input)
      end
      
      def test_add_task_with_goal()
        
        input = '^Goal This is a test'
        
        args = { :goal => "Goal" }
        
        @session.should_receive(:add_task).with('This is a test', args).and_return(1)
        @client.should_receive(:print).with('Task 1 added.')
        
        @client.add_task(@session, input)
      end
      
      def test_add_task_with_priority()
        
        input = '!top This is a test'
        
        args = { :priority => Priority::TOP }
        
        @session.should_receive(:add_task).with('This is a test', args).and_return(1)
        @client.should_receive(:print).with('Task 1 added.')
        
        @client.add_task(@session, input)
      end
      
      def test_list_tasks_with_nothing()
        
        params = {
          :priority => Priority::LOW,
          :title => 'foo',
          :folder => Folder::NO_FOLDER,
          :context => Context::NO_CONTEXT,
          :goal => Goal::NO_GOAL,
          :repeat => Repeat::NONE
        }
        task = Task.new(1234, params)
        tasks = [ task ]
        @session.should_receive(:get_tasks).and_return(tasks)
        @client.should_receive(:print).with('<1234> -- !low foo')
        
        input = ''
        @client.list_tasks(@session, input)
      end
      
      
      def test_list_tasks_with_everything()
        
        params = {
          :priority => Priority::LOW,
          :title => 'foo',
          :folder => Folder.new(1234, 0, 0, 'test folder'),
          :context => Context.new(345, 'test context'),
          :goal => Goal.new(342341, 0, 0, 'test goal'),
          :repeat => Repeat::BIWEEKLY,
          :tag => 'some tag'
        }
        task = Task.new(1234, params)
        tasks = [ task ]
        @session.should_receive(:get_tasks).and_return(tasks)
        @client.should_receive(:print).with('<1234> -- !low *[test folder] @[test context] ^[test goal] repeat[biweekly] tag[some tag] foo')
        
        input = ''
        @client.list_tasks(@session, input)
      end
      
    end
  end
end
