extends Control

# This script is a placeholder for multiplayer functionality.
# It demonstrates where to put the networking code.

var name_edit
var address_edit

func _ready():
	name_edit = get_node("CenterContainer/NameEdit")
	address_edit = get_node("CenterContainer/AddressEdit")

func _on_HostButton_pressed():
	print("Host button pressed!")
	var player_name = name_edit.get_text()
	if player_name == "":
		player_name = "The Host"

	# --- Example Networking Code (for future implementation) ---
	# var net = NetworkedMultiplayerENet.new()
	# net.create_server(12345, 4) # Port, max players
	# get_tree().set_network_peer(net)

	# After hosting, you would typically add the player to a player list
	# and then load the game scene for everyone.
	# For example:
	# get_tree().change_scene("res://scenes/game_multiplayer.tscn")

	# For now, we'll just print a message.
	print("Hosting not implemented yet.")


func _on_JoinButton_pressed():
	print("Join button pressed!")
	var player_name = name_edit.get_text()
	if player_name == "":
		player_name = "A Player"
	var ip_address = address_edit.get_text()

	# --- Example Networking Code (for future implementation) ---
	# var net = NetworkedMultiplayerENet.new()
	# net.create_client(ip_address, 12345) # IP, Port
	# get_tree().set_network_peer(net)

	# The game would then start automatically when the host starts it.

	# For now, we'll just print a message.
	print("Joining not implemented yet.")

func _on_BackButton_pressed():
	get_tree().change_scene("res://scenes/main_menu.tscn")
