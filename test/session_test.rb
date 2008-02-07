$: << File.expand_path(File.dirname(__FILE__) + "/../lib")
require 'test/unit'
require 'flexmock/test_unit'
require 'toodledo'

#
# This class tests that various handle methods in the session 
# work as they're supposed to.
#
class SessionTest < Test::Unit::TestCase

  def setup    
    @session = Toodledo::Session.new('userid', 'password')    
    
    # mock out the get_token & call methods.
    flexmock(@session, :get_token => 'token')
    
    @session.connect()
  end
  
  def teardown
    @session.disconnect()
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
  
#  handle_number
#  handle_boolean
#  handle_string
#  handle_date
#  handle_time
#  handle_datetime
#  handle_parent
#  handle_folder
#  handle_context
#  handle_repeat
#  handle_priority


end