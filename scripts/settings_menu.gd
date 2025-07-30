extends Control

const SETTINGS_FILE = "user://settings.cfg"
var config = ConfigFile.new()

func _ready():
	load_settings()

	var music_slider = get_node("SettingsContainer/MusicVolumeSlider")
	var game_slider = get_node("SettingsContainer/GameVolumeSlider")
	var sfx_slider = get_node("SettingsContainer/SfxVolumeSlider")
	var font_options = get_node("SettingsContainer/FontOptions")

	# Apply loaded settings to the UI controls
	music_slider.set_value(config.get_value("audio", "music_volume", 100))
	game_slider.set_value(config.get_value("audio", "game_volume", 100))
	sfx_slider.set_value(config.get_value("audio", "sfx_volume", 100))

	# Populate font options (with placeholders for now)
	font_options.clear()
	font_options.add_item("Pixel Operator")
	font_options.add_item("Future Font 1")
	font_options.add_item("Future Font 2")

	# Select the current font in the dropdown
	var current_font = config.get_value("visuals", "font", "res://assets/fonts/PixelOperator8.ttf")
	if current_font == "res://assets/fonts/PixelOperator8.ttf":
		font_options.select(0)
	# In a real scenario, you'd have more robust logic here
	# For now, this is a placeholder.

func load_settings():
	# Load settings from file, or create with defaults if it doesn't exist
	var err = config.load(SETTINGS_FILE)
	if err != OK:
		print("Settings file not found. Creating with defaults.")
		config.set_value("audio", "music_volume", 100)
		config.set_value("audio", "game_volume", 100)
		config.set_value("audio", "sfx_volume", 100)
		config.set_value("visuals", "font", "res://assets/fonts/PixelOperator8.ttf")
		config.set_value("visuals", "font_size", 16)
		config.set_value("visuals", "font_color", Color(1,1,1))
		save_settings()

func save_settings():
	config.save(SETTINGS_FILE)

# --- Signal Handlers ---

func _on_MusicVolumeSlider_value_changed(value):
	config.set_value("audio", "music_volume", value)
	save_settings()

func _on_GameVolumeSlider_value_changed(value):
	config.set_value("audio", "game_volume", value)
	save_settings()

func _on_SfxVolumeSlider_value_changed(value):
	config.set_value("audio", "sfx_volume", value)
	save_settings()

func _on_FontOptions_item_selected(id):
	var font_path = "res://assets/fonts/PixelOperator8.ttf" # Default
	if id == 0:
		font_path = "res://assets/fonts/PixelOperator8.ttf"
	# Add more conditions here when new fonts are added
	config.set_value("visuals", "font", font_path)
	save_settings()

func _on_BackButton_pressed():
	get_tree().change_scene("res://scenes/main_menu.tscn")
