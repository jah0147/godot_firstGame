extends Node

const SCORE_FILE = "user://gamedata.cfg"

# --- Game Settings ---
var word_length = 5
var max_guesses = 6
var game_time_limit = 180 # 3 minutes
var word_time_limit = 20  # 20 seconds per word

# --- Game State ---
var secret_word = ""
var current_guess = ""
var current_row = 0
var word_list = []
var game_active = false
var score = 0
var high_score = 0

# --- UI Node References ---
var grid_container
var result_label
var score_label
var high_score_label
var game_time_label
var word_time_label
var overall_game_timer
var per_word_timer

func _ready():
	# Enable processing to update timers in _process
	set_process(true)

	# Get all node references once
	grid_container = get_node("UI/GridContainer")
	result_label = get_node("UI/ResultLabel")
	score_label = get_node("UI/StatsBar/ScoreBox/ScoreLabel")
	high_score_label = get_node("UI/StatsBar/HighScoreBox/HighScoreLabel")
	game_time_label = get_node("UI/StatsBar/GameTimeBox/GameTimeLabel")
	word_time_label = get_node("UI/StatsBar/WordTimeBox/WordTimeLabel")
	overall_game_timer = get_node("OverallGameTimer")
	per_word_timer = get_node("PerWordTimer")

	# Load data and start the game
	load_word_list()
	load_high_score()
	start_new_game()

func _process(delta):
	# Update timer labels every frame for a smooth countdown
	if not overall_game_timer.is_stopped():
		var time_left = overall_game_timer.get_time_left()
		var minutes = floor(time_left / 60)
		var seconds = int(time_left) % 60
		game_time_label.set_text("%d:%02d" % [minutes, seconds])

	if not per_word_timer.is_stopped():
		word_time_label.set_text(str(ceil(per_word_timer.get_time_left())))
	else:
		word_time_label.set_text("0")

# --- Game Flow ---

func start_new_game():
	score = 0
	update_score(0) # Update UI
	high_score_label.set_text(str(high_score))

	overall_game_timer.set_wait_time(game_time_limit)
	overall_game_timer.start()

	next_round()

func next_round():
	current_guess = ""
	current_row = 0
	game_active = true
	result_label.set_text("")

	if word_list.empty():
		end_game("Word list is empty!")
		return

	randomize()
	secret_word = word_list[randi() % word_list.size()]
	print("Secret word (for debugging): " + secret_word)

	generate_grid()

	per_word_timer.set_wait_time(word_time_limit)
	per_word_timer.start()

func end_game(message):
	game_active = false
	overall_game_timer.stop()
	per_word_timer.stop()

	result_label.set_text("GAME OVER! " + message)

	if score > high_score:
		high_score = score
		save_high_score()

	yield(get_tree().create_timer(4.0), "timeout")
	get_tree().change_scene("res://scenes/main_menu.tscn")

func _on_OverallGameTimer_timeout():
	end_game("Time's up!")

# --- Word & Grid Logic ---

func load_word_list():
	var path = "res://assets/words_" + str(word_length) + ".txt"
	var file = File.new()
	if file.open(path, File.READ) == OK:
		while not file.eof_reached():
			var line = file.get_line()
			if not line.empty():
				word_list.append(line.to_lower())
		file.close()
	else:
		print("Error: Could not load word list at " + path)

func generate_grid():
	for child in grid_container.get_children():
		child.queue_free()
	grid_container.set_columns(word_length)
	for i in range(max_guesses * word_length):
		var letter_box = Label.new()
		letter_box.set_text("")
		letter_box.set_align(Label.ALIGN_CENTER)
		letter_box.set_valign(Label.VALIGN_CENTER)
		grid_container.add_child(letter_box)

func _input(event):
	if not game_active or not event is InputEventKey or not event.is_pressed():
		return
	var keycode = event.get_scancode()
	if keycode >= KEY_A and keycode <= KEY_Z and current_guess.length() < word_length:
		current_guess += char(keycode).to_lower()
		update_grid_display()
	elif keycode == KEY_BACKSPACE and current_guess.length() > 0:
		current_guess = current_guess.substr(0, current_guess.length() - 1)
		update_grid_display()
	elif keycode == KEY_ENTER and current_guess.length() == word_length:
		submit_guess()

func update_grid_display():
	for i in range(word_length):
		var letter_box = grid_container.get_child(current_row * word_length + i)
		letter_box.set_text(current_guess[i].to_upper() if i < current_guess.length() else "")

func submit_guess():
	game_active = false # Pause input during check
	per_word_timer.stop()

	var temp_secret = secret_word
	var result_colors = []
	result_colors.resize(word_length)

	# First pass for greens
	for i in range(word_length):
		if current_guess[i] == temp_secret[i]:
			result_colors[i] = Color(0.2, 0.7, 0.2)
			var temp_arr = temp_secret.split("")
			temp_arr[i] = "*"
			temp_secret = temp_arr.join("")
		else:
			result_colors[i] = Color(0.3, 0.3, 0.3)

	# Second pass for yellows
	for i in range(word_length):
		if result_colors[i] == Color(0.3, 0.3, 0.3):
			var pos = temp_secret.find(current_guess[i])
			if pos != -1:
				result_colors[i] = Color(0.8, 0.7, 0.2)
				var temp_arr = temp_secret.split("")
				temp_arr[pos] = "*"
				temp_secret = temp_arr.join("")

	# Apply colors
	for i in range(word_length):
		var letter_box = grid_container.get_child(current_row * word_length + i)
		letter_box.add_color_override("font_color", result_colors[i])

	# Check win/loss for the round
	if current_guess == secret_word:
		result_label.set_text("Correct!")
		var points_earned = 100 + floor(per_word_timer.get_time_left() * 10)
		update_score(score + points_earned)
		yield(get_tree().create_timer(1.5), "timeout")
		next_round()
		return

	current_row += 1
	current_guess = ""

	if current_row >= max_guesses:
		result_label.set_text("No more guesses! The word was: " + secret_word.to_upper())
		yield(get_tree().create_timer(3.0), "timeout")
		next_round()
	else:
		game_active = true # Resume input for next guess
		per_word_timer.start() # Resume timer

# --- Data & UI ---

func update_score(new_score):
	score = new_score
	score_label.set_text(str(score))

func load_high_score():
	var config = ConfigFile.new()
	if config.load(SCORE_FILE) == OK:
		high_score = config.get_value("main", "high_score", 0)
	else:
		high_score = 0

func save_high_score():
	var config = ConfigFile.new()
	config.set_value("main", "high_score", high_score)
	config.save(SCORE_FILE)

func _on_BackButton_pressed():
	get_tree().change_scene("res://scenes/main_menu.tscn")
