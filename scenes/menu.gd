extends Control

@export var Address = "127.0.0.1"
@export var port = 8000
var peer

func _ready() -> void:
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)

func _on_host_button_down() -> void:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 2)
	if error != OK:
		print("cannot host " + error)
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	# allows peer to be the host, i.e. letting host play the game
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for players")
	send_player_info(multiplayer.get_unique_id())
	
func _on_join_button_down() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(Address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)

# Called on server/clients
func _player_connected(id):
	print("Player " + str(id) + " connected")

# Called on server/clients
func _player_disconnected(id):
	print("Player " + str(id) + " disconnected")
	GameManager.Players.erase(id)

# Called from clients
func _connected_to_server():
	print("Connected to server")
	send_player_info.rpc_id(1, multiplayer.get_unique_id())

@rpc("any_peer")
func send_player_info(id):
	if not GameManager.Players.has(id):
		GameManager.Players[id] = {
			"id": id,
			"score": 0
		}
	if multiplayer.is_server():
		for i in GameManager.Players:
			send_player_info.rpc(GameManager.Players[i].id)

@rpc("any_peer", "call_local")
func start_game():
	var scene = load("res://scenes/game.tscn").instantiate()
	get_tree().root.add_child(scene)

# Called from clients
func _connection_failed():
	print("Disconnected from server")



func _on_start_game_button_down() -> void:
	start_game.rpc()
