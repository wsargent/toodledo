$: << File.expand_path(File.dirname(__FILE__) + "/../lib")

require 'test/unit'
require 'toodledo'
require 'toodledo/command_line/parser_helper'


#
# Tests the parser helper
#
class ParserHelperTest < Test::Unit::TestCase
  
  include Toodledo
  include Toodledo::CommandLine::ParserHelper
  
  def test_find_context
    
    input = "blah blah blah *Folder @Context ^Goal"
    
    context = parse_context(input)
    
    assert(context == 'Context', "Context not found")
  end

  def test_find_harder_context
    
    input = "@[Harder Context] *[Harder Folder] ^[Harder Goal] blah blah blah"
    
    context = parse_context(input)
        
    assert(context == 'Harder Context', "Context not found")
  end

  def test_find_folder
    input = "*Folder @Context ^Goal blah blah blah"
    
    folder = parse_folder(input)
    
    assert(folder == 'Folder', "Folder not found")
  end

  def test_find_harder_folder
    
    input = "Some Text @[Harder Context] *[Harder Folder] ^[Harder Goal]"
    
    folder = parse_folder(input)
    
    assert(folder == 'Harder Folder', "Folder not found")
  end

  def test_find_duedate
    input = "<duedate @Context ^Goal blah blah blah"
    
    duedate = parse_date(input)
    
    assert(duedate == 'duedate', "duedate not found")
  end

  # TODO Separate parse_date from parse_duedate?
  def test_find_harder_duedate
    
    input = "Some Text @[Harder Context] <[Harder duedate] ^[Harder Goal]"
    
    duedate = parse_date(input)
    
    assert(duedate == 'Harder duedate', "duedate not found")
  end

  def test_find_tag
    input = "%tag @Context ^Goal blah blah blah"
    
    tag = parse_tag(input)
    
    assert(tag == ['tag'], "tag not found")
  end

  def test_find_harder_tag
    
    input = "Some Text @[Harder Context] %[Harder tag] ^[Harder Goal]"
    
    tag = parse_tag(input)
    
    assert(tag == ['Harder','tag'], "tag not found")
  end
  
  def test_find_goal
    input = "*Folder @Context ^Goal wefawef wefawefawfe"
    
    goal = parse_goal(input)
    
    assert(goal == 'Goal', "Value not found")
  end
  
  def test_find_harder_goal  
    input = "@[Harder Context] *[Harder Folder] ^[Harder Goal] Some text"
       
    goal = parse_goal(input)
       
    assert(goal == 'Harder Goal', "Value not found")
  end
  
  def test_find_priority_with_top
    input = "!top I AM VERY IMPORTANT!"
       
    priority = parse_priority(input)
       
    assert(priority == Priority::TOP, "Value not found")
  end
    
  def test_find_priority_with_high
    input = "!high I am high priority."
       
    priority = parse_priority(input)
       
    assert_equal(Priority::HIGH, priority, "Value not found")
  end
    
  def test_find_priority_with_medium
    input = "!medium I am medium priority."
       
    priority = parse_priority(input)
       
    assert_equal(Priority::MEDIUM, priority, "Value not found")
  end
  
  def test_find_priority_with_low
    input = "!low I am low priority."
       
    priority = parse_priority(input)
       
    assert_equal(Priority::LOW, priority, "Value not found")
  end
  
  def test_find_priority_with_negative
    input = "!negative I am negative priority."
       
    priority = parse_priority(input)
       
    assert_equal(Priority::NEGATIVE, priority, "Value not found")
  end
  
  def test_find_level_with_life()
    
    input = 'life This is my goal'
    level = parse_level(input)
    
    assert_equal(Goal::LIFE_LEVEL, level, 'level not found')
  end
  
  def test_find_level_with_medium()
    
    input = 'medium This is my goal'
    level = parse_level(input)
    
    assert_equal(Goal::MEDIUM_LEVEL, level, 'level not found')
  end
  
  def test_find_level_with_short()
    
    input = 'short This is my goal'
    level = parse_level(input)
    
    assert_equal(Goal::SHORT_LEVEL, level, 'level not found')
  end
  
end