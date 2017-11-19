#!/usr/bin/env ruby

class RockPaperScissors
  # generic chooser for our intro and rps selection prompts
  def choose(text, max_choice, pnum=nil)
    max_choice = max_choice.to_i
    if max_choice < 1
      raise "Bad value for available choices: #{max_choice}"
    end

    valid_choices = (1..max_choice)
    choice = 0
    first_run = true

    if pnum
      # using gsub! here modifies the reference, not the value, so don't do that
      text = text.gsub(/\<pnum\>/, pnum.to_s)
    end

    while !valid_choices.include?(choice)
      if !first_run
        puts "\nSorry, that's not a valid choice."
      else
        first_run = false
      end

      print text + "--> "
      choice = gets.chomp.to_i
    end

    return choice
  end

  def ai_choose(history)
    # not enough history to make a choice
    if history.length <= 2
      puts "\nI don't know enough about you, so I'm guessing randomly here..."
      return rand(3) + 1
    end

    next_throw = [0,0,0,0]
    previous_throw = history.last
    # try to predict what the next choice will be based on the previous throw
    # TODO: can make this more accurate by modifying it to include longer stretches of previous
    # throws once a lot of history has been established
    (0..history.length-2).each do |i|
      if history[i] == previous_throw
        next_throw[history[i+1]] += 1
      end
    end

    # the index of the highest value is the most likely one the player will throw
    # so return what will beat that (note that in ties we pick the lowest one always)
    likely_throw = next_throw.each_with_index.max[1] + 1
    return likely_throw > 3 ? 1 : likely_throw
  end

  def who_won(c1, c2, play_computer)
    # remember 1 = rock, 2 = paper, 3 = scissors
    if c1 == c2
      puts "\nIt's a tie!"
      return 0
    elsif c1 == c2 + 1 || (c1 == 1 && c2 == 3)
      puts play_computer ? "\nYou win!" : "\nPlayer 1 wins!"
      return 1
    else
      puts play_computer ? "\nI win!" : "\nPlayer 2 wins!"
      return 2
    end
  end

  # TODO: history will get unwieldy after lots and lots of throws (ie millions)
  # consider making this a database in 2.0
  def import_history(history_file)
    history = []
    # make sure file exists and it's > 0 size...
    if File.size?(history_file)
      puts "\nReading history so I can know my opponent..."
      line = File.open(history_file) {|f| f.readline}
      line.chomp!
      junk_found = false

      line.split(//).each do |h|
        if ['1','2','3'].include?(h)
          history.push(h.to_i)
        else
          junk_found = true
        end
      end

      if junk_found
        puts "There was some garbage in my history file, I kept what I could."
      end

      puts "Done importing #{history.length} bits of history!"
    else
      puts "\nNo history found, guess I have to learn as I go!"
    end

    return history
  end

  def export_history(history_file, h)
    File.open(history_file, "w") {|f| f.write(h.join)}
  end

  def play
    scores = [0, 0, 0]
    descriptions = ['Rock', 'Paper', 'Scissors']
    history_file = "history.txt"

    intro = "Welcome to Rock/Paper/Scissors!\n"
    intro += "Who would you like to play against today?\n"
    intro += "\t1) Me! (The computer)\n\t2) Another human\n"

    mode = choose(intro, 2)
    play_computer = mode == 1

    if play_computer
      history = import_history(history_file)
    end

    continue = true
    selector = "\nPlayer <pnum>, choose your weapon!\n"
    selector += "\t1) Rock\n\t2) Paper\n\t3) Scissors\n"

    while continue
      c1 = choose(selector, 3, 1)
      c2 = play_computer ? ai_choose(history) : choose(selector, 3, 2)

      # figure out who won and tell the player(s)
      winner = who_won(c1, c2, play_computer)
      scores[winner] += 1

      if play_computer
        puts "You chose #{descriptions[c1-1]}, I chose #{descriptions[c2-1]}."
        puts "The score so far is Me: #{scores[2]}, You: #{scores[1]}, with #{scores[0]} ties."
        history.push(c1)
      else
        puts "Player 1 chose #{descriptions[c1-1]}, player 2 chose #{descriptions[c2-1]}."
        puts "The score so far is Player 1: #{scores[1]}, Player 2: #{scores[2]}, with #{scores[0]} ties."
      end

      print "Play again? (Y/n) "
      if gets.chomp.downcase == 'n'
        continue = false
        if play_computer
          puts "Saving our history for future reference..."
          export_history(history_file, history)
          puts "Done!"
        end
        puts "\nOK, goodbye!"
      end
    end
  end

end

if __FILE__ == $0
  RockPaperScissors.new.play()
end

