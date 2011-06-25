$: << File.expand_path(File.dirname(__FILE__) + "/../lib")


require 'rubygems'
require 'test/unit'
require 'flexmock/test_unit'
require 'toodledo/session'
require 'yaml'

# 
# This class tests that various handle methods in the session work as they're
# supposed to.
# 
class SessionTest < Test::Unit::TestCase
  
  CONFIG_FILE = ENV['HOME'] + '/.toodledo/user-config.yml'

  def setup
    @session = Toodledo::Session.new('userid', 'password')    
    
    # mock out the get_token & call methods.
    mock_connection(@session)
    
    @session.connect()
  end
  
  def mock_connection(session)
    flexmock(session, :get_token => 'token')
    flexmock(session, :get_server_info => {:token_expires=>4*60.0})
  end
  
  def teardown
    @session.disconnect()
  end
  
  def test_handle_app_id_in_session
    new_sess = Toodledo::Session.new('userid', 'password', nil, 'appid')
    mock_connection(new_sess)
    new_sess.connect()
    assert_not_nil new_sess.app_id
  end


  def test_handle_goal_with_name()
    params = { :goal => 'goal_name' }
    myhash = {}
    
    goal_id = 1
    goal = Toodledo::Goal.new(goal_id, 0, 0, 'goal_name')
    flexmock(@session, :get_goal_by_name => goal)
    @session.handle_goal(myhash, params)
    
    assert myhash[:goal] == goal_id
  end
  
  def test_handle_goal_with_id()
    goal_id = 1
    params = { :goal => goal_id }
    myhash = {}

    @session.handle_goal(myhash, params)
        
    assert myhash[:goal] == goal_id
  end
  
  def test_handle_goal_with_obj()
    goal_id = 1
    goal = Toodledo::Goal.new(goal_id, 0, 0, 'goal_name')
    params = { :goal => goal }
    myhash = {}

    @session.handle_goal(myhash, params)
    
    assert myhash[:goal] == goal_id
  end
  
  def test_handle_context_with_obj()
    context_id = 1
    
    context = Toodledo::Context.new(context_id, 'Context Name')
    params = { :context => context}
    myhash = {}
    @session.handle_context(myhash, params)
    
    assert myhash[:context] == context_id
  end
  
  def test_handle_context_with_id()
    context_id = 1
    
    params = { :context => context_id}
    myhash = {}
    @session.handle_context(myhash, params)
    
    assert myhash[:context] == context_id
  end
  
  def test_handle_context_with_name()
    context_id = 1
    myhash = {}
    params = { :context => 'Context Name'}
    context = Toodledo::Context.new(context_id, 'Context Name')
    flexmock(@session, :get_context_by_name => context)
    @session.handle_context(myhash, params)
    
    assert myhash[:context] == context_id
  end
  
  def test_handle_boolean_with_string_true()
    myhash = {}
    params = { :bool => 'true' }
    @session.handle_boolean(myhash, params, :bool)
    
    assert myhash[:bool] == "1"
  end
  
  def test_handle_boolean_with_string_false()
    myhash = {}
    params = { :bool => 'false' }
    @session.handle_boolean(myhash, params, :bool)
    
    assert myhash[:bool] == "0"
  end
  
  def test_handle_boolean_with_true()
    myhash = {}
    params = { :bool => true }
    @session.handle_boolean(myhash, params, :bool)
    
    assert myhash[:bool] == "1"
  end
  
  def test_handle_boolean_with_false()
    myhash = {}
    params = { :bool => false }
    @session.handle_boolean(myhash, params, :bool)
    
    assert myhash[:bool] == "0"
  end
  
  def test_handle_folder()

    folder_id = 1
    myhash = {}
    params = { :folder => folder_id }
    @session.handle_folder(myhash, params)
        
    assert myhash[:folder] == folder_id
  end
  
  def test_handle_folder_with_obj()

    folder_id = 1
    folder = Toodledo::Folder.new(folder_id, 0, 0, 'folder_name')
    
    myhash = {}
    params = { :folder => folder }  
    @session.handle_folder(myhash, params)
        
    assert myhash[:folder] == folder_id
  end
  
  
  def test_handle_folder_with_name()

    folder_id = 1
    folder_name = 'folder_name'
    folder = Toodledo::Folder.new(folder_id, 0, 0, folder_name)
    
    flexmock(@session, :get_folder_by_name => folder)
    myhash = {}
    params = { :folder => folder_name }
    @session.handle_folder(myhash, params)
        
    assert myhash[:folder] == folder_id
  end
  
  def test_handle_parent_with_task()
    task_id = 1
    task = Toodledo::Task.new(task_id)
    params = { :parent => task }
    myhash = {}

    @session.handle_parent(myhash, params)
        
    assert myhash[:parent] == task_id
  end
  
  def test_handle_parent_with_id()
    task_id = 1
    params = { :parent => task_id }
    myhash = {}

    @session.handle_parent(myhash, params)
        
    assert myhash[:parent] == task_id
  end
  
  
  
  #  handle_number
  #  handle_string
  #  
  #  handle_date
  #  handle_time
  #  handle_datetime
  #  
  #  handle duedate
  #  handle duetime
  #  
  #  handle_repeat
  #  handle_priority
  #  handle_tag


end