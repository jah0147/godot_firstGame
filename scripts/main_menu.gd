extends Control

func _ready():
	pass

func _on_SinglePlayerButton_pressed():
	get_tree().change_scene("res://scenes/game.tscn")

func _on_MultiplayerButton_pressed():
	get_tree().change_scene("res://scenes/multiplayer_lobby.tscn")

func _on_SettingsButton_pressed():
	get_tree().change_scene("res://scenes/settings_menu.tscn")

func _on_QuitButton_pressed():
	get_tree().quit()
