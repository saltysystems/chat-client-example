extends Control

const ENET_PORT = 4483  # ENet
const WEBSOCKET_PORT = 4433
const WEBSOCKET_SECURE_PORT = 4434

enum state {NOT_CONNECTED, CONNECTED, JOINED, PLAYING}
@export_enum("ENet", "WebSocket", "WebSocket Secure") var net_mode: String = "ENet"
@export var server_address = "<your_ip_or_hostname>"

var session_id
var session_state = state.NOT_CONNECTED
var reconnect_token

@export var handle = "Soandso" + str(randi() % 100)
var users = []

# Called when the node enters the scene tree for the first time.
func _ready():
	Overworld.server_connected.connect(self._on_server_connect)
	Overworld.server_disconnected.connect(self._on_server_disconnect)
	Overworld.server_session_new.connect(self._on_session_new)
	Overworld.server_sync.connect(self._on_sync)
	Overworld.server_channel_msg.connect(self._on_channel_msg)
	net_connect(handle)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Called whenever the ENTER key is pressed on the LineEdit field
func _on_line_edit_text_submitted(new_text):
	Overworld.channel_msg("",new_text)
	$VBoxContainer/LineEdit.text = ""

func _on_server_connect() -> void:
	print("Connected to server")
	print("Requesting a new session")
	session_state = state.CONNECTED
	if reconnect_token:
		print("Rejoining with saved token...")
		Overworld.session_request(reconnect_token)
	else:
		Overworld.session_request()

func _on_session_new(id: int, reconnect_token: PackedByteArray) -> void:
	session_id = id
	reconnect_token = reconnect_token
	session_state = state.JOINED
	$VBoxContainer/HBoxContainer/ChatWindow.text += "[i]Starting a new session: " + str(id) + "[/i]\n"
	Overworld.join(handle)

func _on_server_disconnect() -> void:
	if session_state != state.NOT_CONNECTED:
		print("Disconnected from server")
		session_state = state.NOT_CONNECTED

func _on_sync(handles: Array):
	session_state = state.PLAYING
	redraw_user_list(handles)

func _on_channel_msg(handle: String, msg: String):
	$VBoxContainer/HBoxContainer/ChatWindow.text += "<" + handle + "> " + msg + "\n"

func redraw_user_list(handles):
	$VBoxContainer/HBoxContainer/UserList.text = ""
	for handle in handles:
		$VBoxContainer/HBoxContainer/UserList.text += handle + "\n"

func net_connect(nick):
	handle = nick
	if session_state == state.NOT_CONNECTED:
		if net_mode == 'ENet':
			Overworld.enet_connect(server_address, ENET_PORT)
		elif net_mode == 'WebSocket':
			Overworld.ws_connect(server_address, WEBSOCKET_PORT)
		elif net_mode == 'WebSocket Secure':
			Overworld.wss_connect(server_address, WEBSOCKET_SECURE_PORT)
	else:
		print("Error: Already connected!")

func net_reconnect():
	# Can happen in any state, I guess.
	try_clean_disconnect()
	await get_tree().create_timer(1).timeout
	session_state = state.NOT_CONNECTED
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
