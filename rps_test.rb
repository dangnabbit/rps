#!/usr/bin/env ruby

require './rps'
require 'test/unit'

class RPSTest < Test::Unit::TestCase
  def setup
    File.open("test_history_1.txt", "w") {|f| f.write("123123123123123")}
    File.open("test_history_2.txt", "w") {|f| f.write("1252314g")}
    File.open("test_history_3.txt", "w") {|f| f.write("")}
    @rps = RockPaperScissors.new
  end

  def teardown
    (1..5).each do |i|
      if File.exists?("test_history_#{i}.txt")
        File.delete("test_history_#{i}.txt")
      end
    end
  end

  def setup_output
    # clear and capture stdout before starting
    @output = StringIO.new
    $stdout = @output
  end

  def test_import_history
    # normal looking history file
    setup_output()
    h = @rps.import_history("test_history_1.txt")
    assert_equal( 15, h.length )
    assert( /15 bits of history/ =~ @output.string )

    # should filter out garbage from this file
    # and print a message saying so
    setup_output()
    h = @rps.import_history("test_history_2.txt")
    assert_equal( 5, h.length )
    assert( /garbage/ =~ @output.string )

    # empty history file - should say there's no history
    setup_output()
    h = @rps.import_history("test_history_3.txt")
    assert_equal( 0, h.length )
    assert( /No history found/ =~ @output.string )
  end

  def test_export_history
    setup_output()
    history = [1,3,2,2,1,3,2,1]
    @rps.export_history("test_history_4.txt", history)
    assert_equal( "", @output.string )
    written = File.open("test_history_4.txt", "r") {|f| f.readline}
    assert_equal( "13221321", written )

    setup_output()
    # use nonexistent directory to force failure, warn if directory actually exists
    if Dir.exists?("/doesnotexist")
      omit('WARNING: directory /doesnotexist actually exists. Get rid of that before you run this test again.')
    else
      assert_raise do
        @rps.export_history("/doesnotexist/test_history_5.txt", history)
      end
    end
  end

  def test_ai_choose
    # guessing randomly with no history or less
    setup_output()
    history = []
    assert( (1..3).include?(@rps.ai_choose(history)) )
    assert( /randomly/ =~ @output.string )

    # guessing randomly with 2 history or less
    setup_output()
    history = [1,3]
    assert( (1..3).include?(@rps.ai_choose(history)) )
    assert( /randomly/ =~ @output.string )

    # shouldn't be guessing randomly here
    setup_output()
    history = [1,3,2,1,3,2,3,3]
    assert( /randomly/ !~ @output.string )

    # previous throw was a 3 (history.last), based on our pattern AI should choose scissors/3
    # (2 came twice after a 3, 3 came once, 1 never came - 2 == paper, scissors wins)
    assert_equal( 3, @rps.ai_choose(history) )
  end

  def test_who_won
    # cycle through all 9 possible combos and make sure the right one wins/ties each time
    # 1 == rock, 2 == paper, 3 == scissors
    # playing computer or human should not affect results
    (1..3).each do |c1|
      (1..3).each do |c2|
        if c1 == c2
          assert_equal( 0, @rps.who_won(c1, c2, true) )
          assert_equal( 0, @rps.who_won(c1, c2, false) )
        elsif c1 == c2 + 1 || (c1 == 1 && c2 == 3)
          assert_equal( 1, @rps.who_won(c1, c2, true) )
          assert_equal( 1, @rps.who_won(c1, c2, false) )
        else
          assert_equal( 2, @rps.who_won(c1, c2, true) )
          assert_equal( 2, @rps.who_won(c1, c2, false) )
        end
      end
    end
  end
end

