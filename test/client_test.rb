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

      def test_set_filter()
        # We don't want an error message printed out here.
        @client.should_receive(:print).never
        @client.set_filter(@session, '!top')
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

      def test_add_task_with_duedate()

        input = '<2011-03-04 This is a test'

        args = { :duedate => "2011-03-04" }

        @session.should_receive(:add_task).with('This is a test', args).and_return(1)
        @client.should_receive(:print).with('Task 1 added.')
        @client.add_task(@session, input)
      end

      def test_add_task_with_single_tag()

        input = '%tag This is a test'

        args = { :tag => %w{tag} }

        @session.should_receive(:add_task).with('This is a test', args).and_return(1)
        @client.should_receive(:print).with('Task 1 added.')
        @client.add_task(@session, input)
      end

      def test_add_task_with_multiple_tags()

        input = '%[tag1 tag2] This is a test'

        args = { :tag => %w{tag1 tag2} }

        @session.should_receive(:add_task).with('This is a test', args).and_return(1)
        @client.should_receive(:print).with('Task 1 added.')
        @client.add_task(@session, input)
      end
      
      def test_add_folder()
        input = 'name'
        
        id = '1234'
        @session.should_receive(:add_folder).with(input).and_return(id)
        @client.should_receive(:print).with('Folder 1234 added.')
        
        @client.add_folder(@session, input)
      end
      
      def test_add_context()
        input = 'name'
        
        id = '1234'
        @session.should_receive(:add_context).with(input).and_return(id)
        @client.should_receive(:print).with('Context 1234 added.')
        
        @client.add_context(@session, input)
      end
      
      def test_add_goal()
        input = 'name'
        
        id = '1234'
        level = Goal::SHORT_LEVEL
        @session.should_receive(:add_goal).with(input, level).and_return(id)
        @client.should_receive(:print).with('Goal 1234 added.')
        
        @client.add_goal(@session, input)
      end
 
      def test_list_tasks_with_nothing()

        params = {
          :priority => Priority::LOW,
          :title => 'foo',
          :folder => Folder::NO_FOLDER,
          :context => Context::NO_CONTEXT,
          :goal => Goal::NO_GOAL,
          :status => Status::NONE,
          :repeat => Repeat::NONE
        }
        task = Task.new(1234, params)
        tasks = [ task ]
        @session.should_receive(:get_tasks).and_return(tasks)
        @client.should_receive(:print).with('<1234> -- !low foo')

        input = ''
        @client.list_tasks(@session, input)
      end


      # TODO Is this really everything? What about duedate?
      def test_list_tasks_with_everything()

        params = {
          :priority => Priority::LOW,
          :title => 'foo',
          :folder => Folder.new(1234, 0, 0, 'test folder'),
          :context => Context.new(345, 'test context'),
          :goal => Goal.new(342341, 0, 0, 'test goal'),
          :repeat => Repeat::BIWEEKLY,
          :status => Status::NEXT_ACTION,
          :tag => 'some tag',
          :star => true
        }
        task = Task.new(1234, params)
        tasks = [ task ]
        @session.should_receive(:get_tasks).and_return(tasks)
        @client.should_receive(:print).with('<1234> -- !low *[test folder] @[test context] ^[test goal] repeat[biweekly] status[Next Action] starred %[some tag] foo')

        input = ''
        @client.list_tasks(@session, input)
      end
      
      def test_list_tasks_by_context()
        context = Context.new(345, 'test context')
        folder = Folder.new(1234, 0, 0, 'test folder')
        
        params = {
          :priority => Priority::LOW,
          :title => 'foo',
          :folder => folder,
          :goal => Goal::NO_GOAL,
          :repeat => Repeat::NONE,
          :status => Status::NONE,
          :context => context
        }
        task = Task.new(1234, params)
        tasks = [ task ]
        contexts = [ context ]
        @session.should_receive(:get_contexts).and_return(contexts)
        @session.should_receive(:get_tasks).and_return(tasks)
        @client.should_receive(:print).with('test context')
        @client.should_receive(:print).with('  <1234> -- !low *[test folder] @[test context] foo')
        
        input = ''
        @client.list_tasks_by_context(@session, input)        
      end

      def test_list_contexts()
        context = Context.new(1234, 'Context')
        contexts = [ context ]
        @session.should_receive(:get_contexts).and_return(contexts)
        @client.should_receive(:print).with('<1234> -- @[Context]')

        input = ''
        @client.list_contexts(@session, input)
      end
      
      def test_list_goals()
        goals = [ Goal.new(1234, Goal::LIFE_LEVEL, 0, 'Name') ]
        @session.should_receive(:get_goals).and_return(goals)
        @client.should_receive(:print).with('<1234> -- life ^[Name]')
        
        input = ''
        @client.list_goals(@session, input)
      end
        
      def test_list_folders()
        folders = [ Folder.new(1234, 0, 0, 'Name') ]
        @session.should_receive(:get_folders).and_return(folders)
        @client.should_receive(:print).with('<1234> -- *[Name]')
        
        input = ''
        @client.list_folders(@session, input)
      end
      
      def test_archive_folder()
        
        @session.should_receive(:edit_folder).and_return(true)
        @client.should_receive(:print).with('Folder 234 archived.')
        
        input = '234'
        @client.archive_folder(@session, input)
      end
      
    end
  end
end
