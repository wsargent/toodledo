$: << File.expand_path(File.dirname(__FILE__) + "/../lib")


require 'rubygems'
require 'test/unit'
require 'flexmock/test_unit'
require 'toodledo/session'
require 'yaml'
require 'toodledo/repeat'
require 'toodledo/priority'
require 'toodledo/status'

# 
# This class tests that various handle methods in the session work as they're
# supposed to.
# 

class SessionTest < Test::Unit::TestCase
  
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
    
    assert_equal goal_id, myhash[:goal]
  end
  
  def test_handle_goal_with_id()
    goal_id = 1
    params = { :goal => goal_id }
    myhash = {}

    @session.handle_goal(myhash, params)
        
    assert_equal goal_id, myhash[:goal]
  end
  
  def test_handle_goal_with_obj()
    goal_id = 1
    goal = Toodledo::Goal.new(goal_id, 0, 0, 'goal_name')
    params = { :goal => goal }
    myhash = {}

    @session.handle_goal(myhash, params)
    
    assert_equal goal_id, myhash[:goal]
  end
  
  def test_handle_context_with_obj()
    context_id = 1
    
    context = Toodledo::Context.new(context_id, 'Context Name')
    params = { :context => context}
    myhash = {}
    @session.handle_context(myhash, params)
    
    assert_equal context_id, myhash[:context]
  end
  
  def test_handle_context_with_id()
    context_id = 1
    
    params = { :context => context_id}
    myhash = {}
    @session.handle_context(myhash, params)
    
    assert_equal context_id, myhash[:context]
  end
  
  def test_handle_context_with_name()
    context_id = 1
    myhash = {}
    params = { :context => 'Context Name'}
    context = Toodledo::Context.new(context_id, 'Context Name')
    flexmock(@session, :get_context_by_name => context)
    @session.handle_context(myhash, params)
    
    assert_equal context_id, myhash[:context]
  end
  
  def test_handle_boolean_with_string_true()
    myhash = {}
    params = { :bool => 'true' }
    @session.handle_boolean(myhash, params, :bool)
    
    assert_equal "1", myhash[:bool]
  end
  
  def test_handle_boolean_with_string_false()
    myhash = {}
    params = { :bool => 'false' }
    @session.handle_boolean(myhash, params, :bool)
    
    assert_equal "0", myhash[:bool]
  end
  
  def test_handle_boolean_with_true()
    myhash = {}
    params = { :bool => true }
    @session.handle_boolean(myhash, params, :bool)
    
    assert_equal "1", myhash[:bool]
  end
  
  def test_handle_boolean_with_false()
    myhash = {}
    params = { :bool => false }
    @session.handle_boolean(myhash, params, :bool)
    
    assert_equal "0", myhash[:bool]
  end
  
  def test_handle_folder()

    folder_id = 1
    myhash = {}
    params = { :folder => folder_id }
    @session.handle_folder(myhash, params)
        
    assert_equal folder_id, myhash[:folder]
  end
  
  def test_handle_folder_with_obj()

    folder_id = 1
    folder = Toodledo::Folder.new(folder_id, 0, 0, 'folder_name')
    
    myhash = {}
    params = { :folder => folder }  
    @session.handle_folder(myhash, params)
        
    assert_equal folder_id, myhash[:folder]
  end
  
  
  def test_handle_folder_with_name()

    folder_id = 1
    folder_name = 'folder_name'
    folder = Toodledo::Folder.new(folder_id, 0, 0, folder_name)
    
    flexmock(@session, :get_folder_by_name => folder)
    myhash = {}
    params = { :folder => folder_name }
    @session.handle_folder(myhash, params)
        
    assert_equal folder_id, myhash[:folder]
  end
  
  def test_handle_parent_with_task()
    task_id = 1
    task = Toodledo::Task.new(task_id)
    params = { :parent => task }
    myhash = {}

    @session.handle_parent(myhash, params)
        
    assert_equal task_id, myhash[:parent]
  end
  
  def test_handle_parent_with_id()
    task_id = 1
    params = { :parent => task_id }
    myhash = {}

    @session.handle_parent(myhash, params)
        
    assert_equal task_id, myhash[:parent]
  end
  
  def test_handle_number_with_nil()
    myhash = {}
    params = { :num => nil }
    @session.handle_number(myhash, params, :num)
    
    assert_equal nil, myhash[:num]
  end
  
  def test_handle_number_with_string()
    myhash = {}
    params = { :num => '12345' }
    @session.handle_number(myhash, params, :num)
    
    assert_equal nil, myhash[:num]
  end
  
  def test_handle_number_with_integer()
    myhash = {}
    params = { :num => 12345 }
    @session.handle_number(myhash, params, :num)
    
    assert_equal '12345', myhash[:num]
  end
  
  def test_handle_string_with_nil()
    myhash = {}
    params = { :string => nil }
    @session.handle_string(myhash, params, :string)
    
    assert_equal nil, myhash[:string]
  end
  
  def test_handle_string()
    myhash = {}
    params = { :string => '12345' }
    @session.handle_string(myhash, params, :string)
    
    assert_equal '12345', myhash[:string]
  end
  
  def test_handle_date_with_nil()
    myhash = {}
    params = { :date => nil }
    @session.handle_date(myhash, params, :date)
    
    assert_equal nil, myhash[:date]
  end
  
  def test_handle_date()
    myhash = {}
    params = { :date => Time.local(2011,05,23,14,45,56) }
    @session.handle_date(myhash, params, :date)
    
    assert_equal '2011-05-23', myhash[:date]
  end
  
  def test_handle_date_with_string()
    myhash = {}
    params = { :date => '2011-05-23' }
    @session.handle_date(myhash, params, :date)
    
    assert_equal '2011-05-23', myhash[:date]
  end
  
  def test_handle_time_with_nil()
    myhash = {}
    params = { :time => nil }
    @session.handle_time(myhash, params, :time)
    
    assert_equal nil, myhash[:time]
  end
  
  def test_handle_time()
    myhash = {}
    params = { :time => Time.local(2011,05,23,14,45,56) }
    @session.handle_time(myhash, params, :time)
    
    assert_equal '02:45 PM', myhash[:time]
  end
  
  def test_handle_time_with_string()
    myhash = {}
    params = { :time => '02:45 PM' }
    @session.handle_time(myhash, params, :time)
    
    assert_equal '02:45 PM', myhash[:time]
  end
  
  def test_handle_datetime_with_nil()
    myhash = {}
    params = { :datetime => nil }
    @session.handle_datetime(myhash, params, :datetime)
    
    assert_equal nil, myhash[:datetime]
  end
  
  def test_handle_datetime()
    myhash = {}
    params = { :datetime => Time.local(2011,05,23,14,45,56) }
    @session.handle_datetime(myhash, params, :datetime)
    
    assert_equal '2011-05-23 14:45:56', myhash[:datetime]
  end
  
  def test_handle_datetime_with_string()
    myhash = {}
    params = { :datetime => '2011-05-23 14:45:56' }
    @session.handle_datetime(myhash, params, :datetime)
    
    assert_equal '2011-05-23 14:45:56', myhash[:datetime]
  end
  
  def test_handle_repeat_with_nil()
    myhash = {}
    params = { :repeat => nil }
    @session.handle_repeat(myhash, params)
    
    assert_equal nil, myhash[:repeat]
  end
  
  REPEAT_VALUES = %w{NONE WEEKLY MONTHLY YEARLY DAILY BIWEEKLY BIMONTHLY SEMIANNUALLY QUARTERLY WITH_PARENT}
  
  def test_handle_repeat()
    REPEAT_VALUES.each do |repeat|
      repeat_value = Toodledo::Repeat.const_get(repeat)
      myhash = {}
      params = { :repeat => repeat_value }
      @session.handle_repeat(myhash, params)
    
      assert_equal repeat_value, myhash[:repeat], "does not handle repeat code #{repeat} (value #{repeat_value})"
    end
  end
  
  def test_handle_priority_with_nil()
    myhash = {}
    params = { :priority => nil }
    @session.handle_priority(myhash, params)
    
    assert_equal nil, myhash[:priority]
  end
  
  PRIORITY_VALUES = %w{TOP HIGH MEDIUM LOW NEGATIVE}
  
  def test_handle_priority()
    PRIORITY_VALUES.each do |priority|
      priority_value = Toodledo::Priority.const_get(priority)
      myhash = {}
      params = { :priority => priority_value }
      @session.handle_priority(myhash, params)
    
      assert_equal priority_value, myhash[:priority], "does not handle priority code #{priority} (value #{priority_value})"
    end
  end
  
  def test_handle_status_with_nil()
    myhash = {}
    params = { :status => nil }
    @session.handle_status(myhash, params)
    
    assert_equal nil, myhash[:status]
  end
  
  STATUS_VALUES = %w{NONE NEXT_ACTION ACTIVE PLANNING DELEGATED WAITING HOLD POSTPONED SOMEDAY CANCELLED REFERENCE}

  def test_handle_status()
    STATUS_VALUES.each do |status|
      status_value = Toodledo::Status.const_get(status)
      myhash = {}
      params = { :status => status_value }
      @session.handle_status(myhash, params)
    
      assert_equal status_value, myhash[:status], "does not handle status code #{status} (value #{status_value})"
    end
  end
  
  def test_handle_tag_with_nil()
    myhash = {}
    params = { :tag => nil }
    @session.handle_tag(myhash, params)
    
    assert_equal nil, myhash[:tag]
  end
  
  def test_handle_tag_with_array()
    myhash = {}
    params = { :tag => %w{tag1 tag2 tag3} }
    @session.handle_tag(myhash, params)
    
    assert_equal 'tag1 tag2 tag3', myhash[:tag]
  end
  
  def test_handle_tag_with_string()
    myhash = {}
    params = { :tag => 'tags' }
    @session.handle_tag(myhash, params)
    
    assert_equal 'tags', myhash[:tag]
  end
end