
class Player
	def retrieve_code_pegs (board)
		board.code_pegs
	end

	def place_pegs (board)
		chosen_code = []
		pegs = retrieve_code_pegs(board)
		while (chosen_code.length < 4) 
			puts "Enter a colour from the following choices"
			puts pegs.to_s
			peg = gets.chomp
			while !pegs.include?(peg)
				puts "Please enter a valid peg"
				peg = gets.chomp
			end
			chosen_code.push(peg)
		end

		if check_response(chosen_code)
			return chosen_code
		else 
			return place_pegs(board)
		end
	end

	def check_response (response)
		begin 
			retries ||= 0
			puts "You have chosen: " + response.to_s
			puts "Are you happy with this code? (y/n)"
			answer = gets.chomp
			if ["y","yes","Y","Yes"].include?(answer)
				return true
			elsif ["n","no","N","No"].include?(answer)
				return false
			else 
				raise "Invalid answer given"
			end
		rescue
			puts "Please enter a valid answer (yes/no)"
			retry if (retries += 1) < 3
			puts "Invalid answer entered, accepting response"
			return true
		end

	end
end

class Codebreaker < Player
	attr_accessor :guesses

	def initialize
		@guesses = []
	end

	def place_pegs(board)
		return_val = super(board)
		guesses.push(return_val) if return_val != nil
		puts
		puts "guesses = " + self.guesses.to_s
	end
end

class Codemaker < Player
	attr_accessor :code

	def initialize 
		@code = []
	end

	def give_feedback (guess)

	end

	##
	def place_pegs(board)
		self.code = super(board)
	end

	def judge_guess (guess_to_copy)
		# puts "GUESS " + guess_to_copy.to_s
		# puts "CODE " + self.code.to_s
		code = []
		self.code.each {|el| code.push(el)}
		guess = []
		guess_to_copy.each {|el| guess.push(el)}
		n_black_pegs = 0
		n_white_pegs = 0
		i = 0
		while i < guess.length
			if guess[i] == code[i]
				n_black_pegs += 1
				code[i] = "guessed"
				guess[i] = "used"
			end
			i+=1
		end

		i = 0
		while i < guess.length
			j = 0
			while j < code.length
				if (guess[i] == code[j])
					n_white_pegs += 1
					code[j] = "guessed"
					break
				end
				j+=1
			end
			i+=1
		end

		return {:black => n_black_pegs, :white => n_white_pegs, :empty => 4-n_black_pegs-n_white_pegs}
	end
end

class Board
	attr_reader :code_pegs, :feedback_pegs

	def  initialize
		@code_pegs = ["yellow", "green", "blue", "red", "purple", "brown"]
		@feedback_pegs = ["black", "white"]
	end

	def print_board (maker, breaker)
		puts
		puts "BOARD"
		breaker.guesses.each_with_index {|guess, index| puts "Guess #{index}: #{guess.to_s}  ||||  #{print_feedback(maker.judge_guess(guess))}" }
		60.times {print "-"}
		puts
	end

	def print_feedback(feedback_pegs)
		matches = ""
		partials = ""
		empties = ""
		feedback_pegs[:black].times {matches += "black "}
		feedback_pegs[:white].times {partials += "white "}
		feedback_pegs[:empty].times {partials += "----- "}
		return matches + partials + empties
	end

end

class Game 
	attr_accessor :goes, :winner
	@@game_length = 12

	def initialize 
		@goes = 0
		@winner = ""
	end

	def play_intro
		start_hash = 20
		12.times do |index| 
			(start_hash+(index*3)).times do
				print "#"
				sleep(0.01)
			end
			puts
		end
		sleep(1.5)
		"MASTERMIND".split("").each_with_index do |el, index| 
			puts(" "*index + el)
		end
		"MASTERMIN".split("").reverse.each_with_index do |el, index| 
			puts(" "*(8-index) + el)
			sleep(0.5)
		end
		sleep(3)
		start_hash = 56
		12.times do |index|
			(start_hash - (index*3)).times do
				print "#"
				sleep(0.01)
			end
			puts
		end
	end

	def initiate_game (board, maker)
		maker.place_pegs(board)
		20.times {puts}
		print "The codemaker has decided the secret code"
		20.times {puts}
		3.times do 
			print "."
			sleep(0.8)
		end
		10.times {puts}
		puts "Let the game commence!"
		10.times {puts}
		sleep(1.5)
	end

	def self.game_length
        @@game_length
    end

	def game_loop (board, maker, breaker)
		gameOver = false
		while !gameOver
			breaker.place_pegs(board)
			board.print_board(maker, breaker)
			if (maker.judge_guess(breaker.guesses.last)[:black] == 4)
				self.winner = "codebreaker"
				gameOver = true
			end
			if (self.goes == Game.game_length)
				self.winner = "codemaker"
				gameOver = true
			end
			self.goes += 1
		end
	end

	def game_over_sequence
		20.times {puts}
		puts "The #{self.winner} wins in #{self.goes} tries!"
		puts "Here is the final board:"
	end

	def play_game (board, maker, breaker)
		self.initiate_game(board, maker)
		self.play_intro
		self.game_loop(board, maker, breaker)
		self.game_over_sequence
		board.print_board(maker, breaker)
	end

end

game = Game.new
board = Board.new
breaker = Codebreaker.new
maker = Codemaker.new

game.play_game(board, maker, breaker)