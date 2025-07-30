extends Control

func _ready():
	pass

func _on_SinglePlayerButton_pressed():
	get_tree().change_scene("res://scenes/game.tscn")

func _on_MultiplayerButton_pressed():
	print("Multiplayer button pressed - Not implemented yet")
	# This will eventually lead to the multiplayer lobby.
	# get_tree().change_scene("res://scenes/multiplayer_lobby.tscn")

func _on_SettingsButton_pressed():
	get_tree().change_scene("res://scenes/settings_menu.tscn")

func _on_QuitButton_pressed():
	get_tree().quit()
