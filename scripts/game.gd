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

# --- Power-Up Data & State ---
var weak_powerups = ["x2_bonus", "add_time"]
var medium_powerups = ["time_reset", "magnifier"]
var strong_powerups = ["bomb", "skip_word"]

var powerup_slots = [
	{"state": "recharging", "powerup": null, "tier": "weak", "cooldown": 5},
	{"state": "recharging", "powerup": null, "tier": "medium", "cooldown": 10},
	{"state": "recharging", "powerup": null, "tier": "medium", "cooldown": 10},
	{"state": "recharging", "powerup": null, "tier": "strong", "cooldown": 20}
]
var is_x2_bonus_active = false

# --- UI Node References ---
var grid_container
var result_label
var score_label
var high_score_label
var game_time_label
var word_time_label
var overall_game_timer
var per_word_timer
var powerup_name_labels = []
var powerup_status_labels = []
var powerup_timers = []

func _ready():
	set_process(true)

	# Get all node references
	grid_container = get_node("UI/GridContainer")
	result_label = get_node("UI/ResultLabel")
	score_label = get_node("UI/StatsBar/ScoreBox/ScoreLabel")
	high_score_label = get_node("UI/StatsBar/HighScoreBox/HighScoreLabel")
	game_time_label = get_node("UI/StatsBar/GameTimeBox/GameTimeLabel")
	word_time_label = get_node("UI/StatsBar/WordTimeBox/WordTimeLabel")
	overall_game_timer = get_node("OverallGameTimer")
	per_word_timer = get_node("PerWordTimer")
	for i in range(4):
		var slot_num = i + 1
		powerup_name_labels.append(get_node("UI/PowerUpBar/PowerUpSlot" + str(slot_num) + "/VBoxContainer/NameLabel"))
		powerup_status_labels.append(get_node("UI/PowerUpBar/PowerUpSlot" + str(slot_num) + "/VBoxContainer/StatusLabel"))
		powerup_timers.append(get_node("PowerUpTimer" + str(slot_num)))

	load_word_list()
	load_high_score()
	start_new_game()

func _process(delta):
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
	update_score(0)
	high_score_label.set_text(str(high_score))
	overall_game_timer.set_wait_time(game_time_limit)
	overall_game_timer.start()
	for i in range(4):
		powerup_slots[i].state = "recharging"
		powerup_timers[i].set_wait_time(powerup_slots[i].cooldown)
		powerup_timers[i].start()
		update_powerup_display(i)
	next_round()

func next_round():
	current_guess = ""
	current_row = 0
	game_active = true
	is_x2_bonus_active = false
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
	if keycode >= KEY_1 and keycode <= KEY_4:
		activate_powerup(keycode - KEY_1)

func update_grid_display():
	for i in range(word_length):
		var letter_box = grid_container.get_child(current_row * word_length + i)
		letter_box.set_text(current_guess[i].to_upper() if i < current_guess.length() else "")

func submit_guess():
	game_active = false
	per_word_timer.stop()
	var temp_secret = secret_word
	var result_colors = []
	result_colors.resize(word_length)
	for i in range(word_length):
		if current_guess[i] == temp_secret[i]:
			result_colors[i] = Color(0.2, 0.7, 0.2)
			var temp_arr = temp_secret.split("")
			temp_arr[i] = "*"
			temp_secret = temp_arr.join("")
		else:
			result_colors[i] = Color(0.3, 0.3, 0.3)
	for i in range(word_length):
		if result_colors[i] == Color(0.3, 0.3, 0.3):
			var pos = temp_secret.find(current_guess[i])
			if pos != -1:
				result_colors[i] = Color(0.8, 0.7, 0.2)
				var temp_arr = temp_secret.split("")
				temp_arr[pos] = "*"
				temp_secret = temp_arr.join("")
	for i in range(word_length):
		var letter_box = grid_container.get_child(current_row * word_length + i)
		letter_box.add_color_override("font_color", result_colors[i])
	if current_guess == secret_word:
		result_label.set_text("Correct!")
		var points_earned = 100 + floor(per_word_timer.get_time_left() * 10)
		if is_x2_bonus_active:
			points_earned *= 2
			is_x2_bonus_active = false
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
		game_active = true
		per_word_timer.start()

# --- Power-Up Logic ---
func _on_PowerUpTimer_timeout(slot_index):
	var tier = powerup_slots[slot_index].tier
	var new_powerup
	if tier == "weak":
		new_powerup = weak_powerups[randi() % weak_powerups.size()]
	elif tier == "medium":
		new_powerup = medium_powerups[randi() % medium_powerups.size()]
	elif tier == "strong":
		new_powerup = strong_powerups[randi() % strong_powerups.size()]
	powerup_slots[slot_index].state = "ready"
	powerup_slots[slot_index].powerup = new_powerup
	update_powerup_display(slot_index)

func activate_powerup(slot_index):
	if not game_active or powerup_slots[slot_index].state != "ready":
		return
	var powerup_name = powerup_slots[slot_index].powerup
	print("Activating power-up: " + powerup_name)
	powerup_slots[slot_index].state = "recharging"
	powerup_slots[slot_index].powerup = null
	powerup_timers[slot_index].start()
	update_powerup_display(slot_index)
	match powerup_name:
		"x2_bonus":
			is_x2_bonus_active = true
			result_label.set_text("x2 Points Active!")
		"add_time":
			per_word_timer.set_wait_time(per_word_timer.get_time_left() + 10)
			result_label.set_text("+10s Word Time!")
		"time_reset":
			per_word_timer.set_wait_time(word_time_limit)
			result_label.set_text("Word Timer Reset!")
		"magnifier":
			var revealed_indices = []
			for i in range(word_length):
				var letter_box = grid_container.get_child(current_row * word_length + i)
				if letter_box.has_color_override("font_color") and letter_box.get_custom_color("font_color") == Color(0.2, 0.7, 0.2):
					revealed_indices.append(i)
			var unrevealed_indices = []
			for i in range(word_length):
				if not i in revealed_indices:
					unrevealed_indices.append(i)
			if not unrevealed_indices.empty():
				var index_to_reveal = unrevealed_indices[randi() % unrevealed_indices.size()]
				var letter_box = grid_container.get_child(current_row * word_length + index_to_reveal)
				letter_box.set_text(secret_word[index_to_reveal].to_upper())
				letter_box.add_color_override("font_color", Color(0.2, 0.7, 0.2))
		"bomb":
			for i in range(word_length):
				var letter_box = grid_container.get_child(current_row * word_length + i)
				letter_box.set_text(secret_word[i].to_upper())
			current_guess = secret_word
			result_label.set_text("BOMB! Word revealed!")
		"skip_word":
			result_label.set_text("Word skipped!")
			yield(get_tree().create_timer(1.0), "timeout")
			next_round()

# --- Data & UI ---
func update_score(new_score):
	score = new_score
	score_label.set_text(str(score))

func update_powerup_display(slot_index):
	var slot = powerup_slots[slot_index]
	var name_label = powerup_name_labels[slot_index]
	var status_label = powerup_status_labels[slot_index]
	if slot.state == "ready":
		name_label.set_text(slot.powerup.replace("_", " ").to_upper())
		status_label.set_text("Ready! (" + str(slot_index + 1) + ")")
	else: # Recharging
		name_label.set_text("---")
		status_label.set_text("Recharging...")

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
