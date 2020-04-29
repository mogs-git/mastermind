
module GameLogic
	def self.judge_guess (master_code, _guess)
		# puts "GUESS " + guess_to_copy.to_s
		# puts "CODE " + self.code.to_s
		code = []
		master_code.each {|el| code.push(el)}
		guess = []
		_guess.each {|el| guess.push(el)}

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

class HumanPlayer
	attr_accessor :guesses, :code, :code_pegs

	def initialize board
		@guesses = []
		@code
		@code_pegs = retrieve_code_pegs (board)
	end

	def retrieve_code_pegs (board)
		board.code_pegs
	end

	def get_code (other_player) 
		self.code = other_player.code
	end

	def select_pegs
		chosen_code = []

		while (chosen_code.length < 4) 
			puts "Enter a colour from the following choices"
			puts self.code_pegs.to_s
			peg = gets.chomp
			while !self.code_pegs.include?(peg)
				puts "Please enter a valid peg"
				peg = gets.chomp
			end
			chosen_code.push(peg)
		end

		chosen_code
	end	

	def place_pegs 
		chosen_code = select_pegs

		if check_response(chosen_code)
			guesses.push(chosen_code)
		else 
			return place_pegs
		end
	end

	def create_code 
		self.code = place_pegs 
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

class ComputerPlayer
	attr_accessor :code, :guesses, :code_pegs, :pegs_to_try, :promising_pegs, :last_peg_tried, :feedback_history, :peg_counter

	def initialize (board)
		@code 
		@guesses = []
		@code_pegs = get_pegs(board)
		@pegs_to_try = @code_pegs
		@peg_counter = set_peg_counter
		@promising_pegs = []
		@feedback_history = []
	end

	def create_code
		self.code = []
		4.times {self.code.push(self.code_pegs.sample(1)[0])} 
	end

	def get_code (other_player) 
		self.code = other_player.code
	end

	def get_feedback 
		first_guess = (self.guesses == [])
		
		if first_guess 
			return {:black => 0, :white => 0, :empty => 4}
		else 
			return GameLogic::judge_guess(self.code, self.guesses.last)
		end
	end

	def get_pegs (board)
		@code_pegs = board.code_pegs
	end

	def set_peg_counter
		peg_counter = {}
		self.code_pegs.each {|peg| peg_counter[peg] = 0}
		peg_counter
	end

	def place_pegs
		feedback = get_feedback

		new_pegs_found = (feedback[:white] + feedback[:black]) - self.peg_counter.values.reduce {|total, current| total+=current}
		puts "new pegs found #{new_pegs_found}"
		new_pegs_found.times do 
			self.promising_pegs.push(self.last_peg_tried)
			self.peg_counter[self.last_peg_tried] += 1
		end

		guess = []
		self.promising_pegs.each {|peg| guess.push(peg)}

		if (feedback[:black] == 4) 
			gameOver = true
		elsif (feedback[:empty] == 0)
			guess = self.promising_pegs.shuffle
			while (guesses.any?{|guess_iter| guess_iter == guess}) 
				guess = self.promising_pegs.shuffle
			end
		elsif (feedback[:empty] == 4) 
			while guess.length < 4
				peg_chosen = self.pegs_to_try.first
				guess.push(peg_chosen)
			end
			self.last_peg_tried = self.pegs_to_try.shift
		else 
			while guess.length < 4
				guess.push(self.pegs_to_try.first)
			end
			self.last_peg_tried = self.pegs_to_try.shift
		end
		
		self.guesses.push(guess)
		self.feedback_history.push(get_feedback)

		# puts self.guesses.to_s
		# puts self.feedback_history.to_s
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
		breaker.guesses.each_with_index {|guess, index| puts "Guess #{index}: #{guess.to_s}  ||||  #{print_feedback(GameLogic::judge_guess(maker.code, guess))}" }
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
	attr_accessor :goes, :winner, :game_over, :board
	@@game_length = 12

	def initialize 
		@goes = 0
		@winner = ""
		@game_over = false
		@board = create_board
	end

	def create_board
		Board.new
	end

	def choose_game_type
		puts "Please choose which type of game to play: "
		puts "1: Human codebreaker vs Human codemaker"
		puts "2: Human codebreaker vs Computer codemaker"
		puts "3: Computer codebreaker vs Human codemaker"
		puts "4: Computer codebreaker vs Computer codemaker"
		selection = gets.chomp
		while !(1..4).to_a.map{|el| el.to_s}.include?(selection)
			puts "Please enter 1, 2, 3 or 4"
			selection = gets.chomp
		end

		return selection
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

	def initiate_game
		case choose_game_type
		when "1"
			maker = HumanPlayer.new self.board
			breaker = HumanPlayer.new self.board
		when "2"
			maker = ComputerPlayer.new self.board
			breaker = HumanPlayer.new self.board
		when "3"
			maker = HumanPlayer.new self.board
			breaker = ComputerPlayer.new self.board
		when "4"
			maker = ComputerPlayer.new self.board
			breaker = ComputerPlayer.new self.board
		end

		maker.create_code
		breaker.get_code (maker)
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
		return {:maker => maker, :breaker => breaker}
	end

	def self.game_length
        @@game_length
    end

	def game_loop
		players = initiate_game
		maker = players[:maker]
		breaker = players[:breaker]	
		while !self.game_over
			self.board.print_board(maker, breaker)
			breaker.place_pegs
			# puts ("code: " + maker.code.to_s)
			# puts ("guesses: " + breaker.guesses.to_s)
			# puts ("feedback: " + GameLogic::judge_guess(maker.code, breaker.guesses.last).to_s)
			if (GameLogic::judge_guess(maker.code, breaker.guesses.last)[:black] == 4)
				self.winner = "codebreaker"
				self.game_over = true
			end
			if (self.goes == Game.game_length)
				self.winner = "codemaker"
				self.game_over = true
			end
			self.goes += 1
		end

		game_over_sequence(maker, breaker)
	end

	def game_over_sequence(maker, breaker)
		20.times {puts}
		puts "The #{self.winner} wins in #{self.goes} tries!"
		puts "Here is the final board:"
		self.board.print_board(maker, breaker)
	end

	def play_game 
		self.game_loop
	end

end

game = Game.new
game.play_game