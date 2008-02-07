
$: << File.expand_path(File.dirname(__FILE__) + "/../lib")
require 'test/unit'
require 'toodledo'

=begin
  This is a functional test suite that runs against Toodledo and verifies that
  the code all works right.
=end
class ToodledoFunctionalTest < Test::Unit::TestCase
  
  include Toodledo
  
  def setup
    base_url = 'http://www.toodledo.com/api.php'
    
    # (only used for functional testing)
    @email = 'will.sargent+toodledo_ruby_api@gmail.com'
    @user_id = 'td479be708d8bd7'
    @password = 'toodledo'
    
    # proxy = { 'host' => '127.0.0.1', 'port' => '8080'}
    proxy = nil
    
    @session = Session.new(@user_id, @password)
    @session.connect(base_url, proxy)
  end
  
  def teardown
    @session.disconnect()
  end
  
  # Always fails.
  # def test_get_user_id()
  #     user_id = @session.get_user_id(@email, @password)
  #     
  #     assert user_id == @user_id
  # end
  
  def test_add_edit_and_remove_task
    title = 'test_add_task'
    params = {}
    task_id = @session.add_task(title, params)
    assert_not_nil task_id

    tasks = @session.get_tasks()
    assert_not_nil tasks
    assert tasks.length == 1
    task = tasks[0]
    
    assert task.server_id == task_id
    
    # edit the task here
    result = @session.edit_task(task_id, { :note => 'This is a note' })
    assert result == true
    
    result = @session.delete_task(task_id)
    assert result == true
    
    tasks = @session.get_tasks()
    assert tasks.length == 0
  end
  
  #
  # basic context functionality.
  #
  def test_add_and_remove_context
    title = 'test_context'    
    context_id = @session.add_context(title)
    assert_not_nil context_id
  
    contexts = @session.get_contexts()
    assert_not_nil contexts
    assert contexts.length == 1
    context = contexts[0]
    
    assert context.server_id == context_id
    
    result = @session.delete_context(context_id)
    assert result == true
    
    contexts = @session.get_contexts()
    assert contexts.length == 0
  end
  
  #
  # basic goal functionality.
  #
  def test_add_and_remove_goal
    title = 'test_goal'
    goal_id = @session.add_goal(title)
    assert_not_nil goal_id
    
    goals = @session.get_goals()
    assert_not_nil goals
    assert goals.length == 1
    goal = goals[0]
    
    assert goal.server_id == goal_id
    
    result = @session.delete_goal(goal_id)
    assert result == true
    
    goals = @session.get_goals()
    assert goals.length == 0
  end
  
  #
  # Basic folder functionality.
  #
  def test_add_edit_and_remove_folder  
    
    title = 'test_folder'
    folder_id = @session.add_folder(title)
    assert_not_nil folder_id
    
    folders = @session.get_folders()  
    assert_not_nil folders
    assert folders.length == 1
    folder = folders[0]
    
    assert folder.server_id == folder_id
    
    result = @session.edit_folder(folder_id, { :title => 'foo' })
    assert result == true
    
    result = @session.delete_folder(folder_id)
    assert result == true
    
    folders = @session.get_folders()
    assert folders.length == 0
  end
  
  #
  # Date functionality.
  #
  
  #
  # Priority functionality
  #
  
  #
  # Repeat functionality
  #
  
  #
  # Parent functionality
  #
  
  #
  # Length / Duration functionality.
  #
  
  #
  # Completed Before / After functionality
  #
  
  #
  # Modified Before / After functionality
  #
  
  #
  # Tag functionality
  #
  
end
