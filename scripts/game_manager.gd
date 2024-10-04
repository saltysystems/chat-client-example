extends Node

const SERVER_IP = "heisenburgers.com"
const ENET_PORT = 4483  # ENet
const WEBSOCKET_PORT = 4433
const WEBSOCKET_SECURE_PORT = 4434
const EPSILON = 0.000001
const RECONCILE_MAX = 5

enum {NOT_CONNECTED, CONNECTED, SESSIONED, JOINED, BUFFERING, PLAYING} 
const state_names = {
	NOT_CONNECTED: "NOT_CONNECTED",
	CONNECTED: "CONNECTED",
	SESSIONED: "SESSIONED",
	JOINED: "JOINED",
	BUFFERING: "BUFFERING",
	PLAYING: "PLAYING"
	}

@export_enum("ENet", "WebSocket", "WebSocket Secure") var net_mode: String = "WebSocket"

var session_id
var session_state = NOT_CONNECTED
var reconnect_token
var handle = ""


func _ready():
	Overworld.server_connected.connect(self._on_server_connect)
	Overworld.server_disconnected.connect(self._on_server_disconnect)
	Overworld.server_session_new.connect(self._on_session_new)


func _on_server_connect() -> void:
	print("Connected to server")
	print("Requesting a new session")
	set_state_connected()
	if reconnect_token:
		print("Rejoining with saved token...")
		Overworld.session_request(reconnect_token)
	else:
		Overworld.session_request()


func _on_session_new(id: int, reconnect_token: PackedByteArray) -> void:
	session_id = id
	reconnect_token = reconnect_token
	set_state_sessioned()
	Overworld.join(handle)


func _on_server_disconnect() -> void:
	if session_state != NOT_CONNECTED:
		print("Disconnected from server")
		set_state_not_connected()


func _next_state(state):
		session_state = state
		print("network state change: " + state_names[session_state])
		#SignalBus.emit_signal("gamestate_change", session_state)


func net_connect(nick):
	handle = nick
	if session_state == NOT_CONNECTED:
		if net_mode == 'ENet':
			Overworld.enet_connect(SERVER_IP, ENET_PORT)
		elif net_mode == 'WebSocket':
			Overworld.ws_connect(SERVER_IP, WEBSOCKET_PORT)
		elif net_mode == 'WebSocket Secure':
			Overworld.wss_connect(SERVER_IP, WEBSOCKET_SECURE_PORT)
	else:
		print("Error: Already connected!")


func net_reconnect():
	# Can happen in any state, I guess.
	try_clean_disconnect()
	await get_tree().create_timer(1).timeout
	set_state_not_connected()
	print("Attempting to reload scene to reconnect...")
	get_tree().reload_current_scene()


func try_clean_disconnect():
	print("Disconnected. Try to clean up locally..")
	if net_mode == 'ENet':
		Overworld.enet_disconnect()
	elif net_mode == 'WebSocket':
		Overworld.ws_disconnect()
	elif net_mode == 'WebSocket Secure':
		Overworld.wss_disconnect()


func set_state_connected():
	_next_state(CONNECTED)


func set_state_sessioned():
	_next_state(SESSIONED)


func set_state_joined():
	_next_state(JOINED)


func set_state_buffering():
	_next_state(BUFFERING)


func set_state_playing():
	_next_state(PLAYING)


func set_state_not_connected():
	_next_state(NOT_CONNECTED)


func state():
	return session_state
