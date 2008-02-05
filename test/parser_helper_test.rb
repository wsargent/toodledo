require 'test/unit'
require 'toodledo/command_line/parser_helper'

#
# Tests the parser helper
#
class ParserHelperTest < Test::Unit::TestCase
  
  include Toodledo::CommandLine::ParserHelper
  
  def test_find_context
    
    input = "*Folder @Context $Goal"
    
    context = parse_context(input)
    
    assert(context == 'Context', "Context not found")
  end

  def test_find_harder_context
    
    input = "@[Harder Context] *[Harder Folder] $[Harder Goal]"
    
    context = parse_context(input)
        
    assert(context == 'Harder Context', "Context not found")
  end

  def test_find_folder
    input = "*Folder @Context $Goal"
    
    folder = parse_folder(input)
    
    assert(folder == 'Folder', "Folder not found")
  end

  def test_find_harder_folder
    
    input = "@[Harder Context] *[Harder Folder] $[Harder Goal]"
    
    folder = parse_folder(input)
    
    assert(folder == 'Harder Folder', "Folder not found")
  end
  
  def test_find_goal
    input = "*Folder @Context $Goal"
    
    goal = parse_goal(input)
    
    assert(goal == 'Goal', "Value not found")
  end
  
  def test_find_harder_goal  
    input = "@[Harder Context] *[Harder Folder] $[Harder Goal]"
       
    goal = parse_goal(input)
       
    assert(goal == 'Harder Goal', "Value not found")
  end
  
  
end