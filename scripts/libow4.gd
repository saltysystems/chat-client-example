extends Node

const Overworld_pb = preload('overworld_pb.gd')
const Chat_pb = preload('chat_pb.gd')

var _enet_peer = ENetMultiplayerPeer.new()
var _ws_peer = WebSocketPeer.new()
var _ws_connected = false

@export var session: Dictionary
@export var rejoin_token: PackedByteArray

var debug = false

var mode

###########################################################################
#  Constants
###########################################################################

enum transport_mode {
	WEBSOCKET,
	ENET
}

# These are merely aliases for convenience. We should not leak Protobuf
# details to the consumer of the library

# via chat_pb
# via overworld_pb


###########################################################################
#  Signals
###########################################################################

signal server_connected()
signal server_disconnected()

signal server_channel_msg(handle,text)
signal server_session_pong(latency)
signal server_session_beacon(id)
signal server_session_new(id,reconnect_token)
signal server_sync(handles)


###########################################################################
#  Prefixes
###########################################################################

# Prefixes determine how to route packages to the correct protobuf library
const Prefix = {
	CHAT = [0,101], # 0x65
	OVERWORLD = [0,100], # 0x64
}


###########################################################################
#  Router 
###########################################################################

func route(packet):
	var opcode = Array(packet.slice(0,2)) # Is this costly?
	var payload = []
	if packet.size() > 2:
		payload = packet.slice(2)
	match opcode:
		Prefix.CHAT:
			_server_chat(payload)
		Prefix.OVERWORLD:
			_server_overworld(payload)
		_:
			print("[WARNING] Unknown opcode from the server:" + str(opcode))


###########################################################################
#  Payload unmarshalling (server packets)
###########################################################################

# Submsgs
func unpack_chat(object):
	if object.has_join():
		if debug:
			print('[DEBUG] Processing a join packet')
		var d = {}
		d = unpack_join(object.get_join())
		emit_signal('server_join',d['handle'])
	elif object.has_part():
		if debug:
			print('[DEBUG] Processing a part packet')
		var d = {}
		d = unpack_part(object.get_part())
		emit_signal('server_part',)
	elif object.has_channel_msg():
		if debug:
			print('[DEBUG] Processing a channel_msg packet')
		var d = {}
		d = unpack_channel_msg(object.get_channel_msg())
		emit_signal('server_channel_msg',d['handle'], d['text'])
	elif object.has_sync():
		if debug:
			print('[DEBUG] Processing a sync packet')
		var d = {}
		d = unpack_sync(object.get_sync())
		emit_signal('server_sync',d['handles'])

func unpack_join(object):
	if typeof(object) == TYPE_ARRAY and object != []:
		var array = []
		for obj in object:
			var handle
			if obj.has_handle():
				handle = obj.get_handle()
			else:
				handle = null
			var dict = {'handle': handle, }
			array.append(dict)
		return array
	elif typeof(object) == TYPE_ARRAY and object == []:
		return []
	else:
		if object: 
			var handle
			if object.has_handle():
				handle = object.get_handle()
			else:
				handle = null
			var dict = {'handle': handle, }
			return dict
		else:
			return {}
func unpack_part(object):
	if typeof(object) == TYPE_ARRAY and object != []:
		var array = []
		for obj in object:
			var dict = {}
			array.append(dict)
		return array
	elif typeof(object) == TYPE_ARRAY and object == []:
		return []
	else:
		if object: 
			var dict = {}
			return dict
		else:
			return {}
func unpack_channel_msg(object):
	if typeof(object) == TYPE_ARRAY and object != []:
		var array = []
		for obj in object:
			var text
			if obj.has_text():
				text = obj.get_text()
			else:
				text = null
			var handle
			if obj.has_handle():
				handle = obj.get_handle()
			else:
				handle = null
			var dict = {'handle': handle, 'text': text, }
			array.append(dict)
		return array
	elif typeof(object) == TYPE_ARRAY and object == []:
		return []
	else:
		if object: 
			var text
			if object.has_text():
				text = object.get_text()
			else:
				text = null
			var handle
			if object.has_handle():
				handle = object.get_handle()
			else:
				handle = null
			var dict = {'handle': handle, 'text': text, }
			return dict
		else:
			return {}
func unpack_sync(object):
	if typeof(object) == TYPE_ARRAY and object != []:
		var array = []
		for obj in object:
			var handles = obj.get_handles()
			var dict = {'handles': handles, }
			array.append(dict)
		return array
	elif typeof(object) == TYPE_ARRAY and object == []:
		return []
	else:
		if object: 
			var handles = object.get_handles()
			var dict = {'handles': handles, }
			return dict
		else:
			return {}

func unpack_overworld(object):
	if object.has_session_request():
		if debug:
			print('[DEBUG] Processing a session_request packet')
		var d = {}
		d = unpack_session_request(object.get_session_request())
		emit_signal('server_session_request',d['reconnect_token'])
	elif object.has_session_new():
		if debug:
			print('[DEBUG] Processing a session_new packet')
		var d = {}
		d = unpack_session_new(object.get_session_new())
		emit_signal('server_session_new',d['id'], d['reconnect_token'])
	elif object.has_session_beacon():
		if debug:
			print('[DEBUG] Processing a session_beacon packet')
		var d = {}
		d = unpack_session_beacon(object.get_session_beacon())
		emit_signal('server_session_beacon',d['id'])
	elif object.has_session_ping():
		if debug:
			print('[DEBUG] Processing a session_ping packet')
		var d = {}
		d = unpack_session_ping(object.get_session_ping())
		emit_signal('server_session_ping',d['id'])
	elif object.has_session_pong():
		if debug:
			print('[DEBUG] Processing a session_pong packet')
		var d = {}
		d = unpack_session_pong(object.get_session_pong())
		emit_signal('server_session_pong',d['latency'])

func unpack_session_request(object):
	if typeof(object) == TYPE_ARRAY and object != []:
		var array = []
		for obj in object:
			var reconnect_token
			if obj.has_reconnect_token():
				reconnect_token = obj.get_reconnect_token()
			else:
				reconnect_token = null
			var dict = {'reconnect_token': reconnect_token, }
			array.append(dict)
		return array
	elif typeof(object) == TYPE_ARRAY and object == []:
		return []
	else:
		if object: 
			var reconnect_token
			if object.has_reconnect_token():
				reconnect_token = object.get_reconnect_token()
			else:
				reconnect_token = null
			var dict = {'reconnect_token': reconnect_token, }
			return dict
		else:
			return {}
func unpack_session_new(object):
	if typeof(object) == TYPE_ARRAY and object != []:
		var array = []
		for obj in object:
			var reconnect_token = obj.get_reconnect_token()
			var id = obj.get_id()
			var dict = {'id': id, 'reconnect_token': reconnect_token, }
			array.append(dict)
		return array
	elif typeof(object) == TYPE_ARRAY and object == []:
		return []
	else:
		if object: 
			var reconnect_token = object.get_reconnect_token()
			var id = object.get_id()
			var dict = {'id': id, 'reconnect_token': reconnect_token, }
			return dict
		else:
			return {}
func unpack_session_beacon(object):
	if typeof(object) == TYPE_ARRAY and object != []:
		var array = []
		for obj in object:
			var id = obj.get_id()
			var dict = {'id': id, }
			array.append(dict)
		return array
	elif typeof(object) == TYPE_ARRAY and object == []:
		return []
	else:
		if object: 
			var id = object.get_id()
			var dict = {'id': id, }
			return dict
		else:
			return {}
func unpack_session_ping(object):
	if typeof(object) == TYPE_ARRAY and object != []:
		var array = []
		for obj in object:
			var id = obj.get_id()
			var dict = {'id': id, }
			array.append(dict)
		return array
	elif typeof(object) == TYPE_ARRAY and object == []:
		return []
	else:
		if object: 
			var id = object.get_id()
			var dict = {'id': id, }
			return dict
		else:
			return {}
func unpack_session_pong(object):
	if typeof(object) == TYPE_ARRAY and object != []:
		var array = []
		for obj in object:
			var latency = obj.get_latency()
			var dict = {'latency': latency, }
			array.append(dict)
		return array
	elif typeof(object) == TYPE_ARRAY and object == []:
		return []
	else:
		if object: 
			var latency = object.get_latency()
			var dict = {'latency': latency, }
			return dict
		else:
			return {}


# Unmarshall
func _server_chat(packet):
	var m = Chat_pb.chat.new()
	var result_code = m.from_bytes(packet)
	if result_code != Chat_pb.PB_ERR.NO_ERRORS:
		print('[CRITICAL] Error decoding new chat packet')
		return
	unpack_chat(m)
func _server_overworld(packet):
	var m = Overworld_pb.overworld.new()
	var result_code = m.from_bytes(packet)
	if result_code != Overworld_pb.PB_ERR.NO_ERRORS:
		print('[CRITICAL] Error decoding new overworld packet')
		return
	unpack_overworld(m)


###########################################################################
#  Payload marshalling (client packets)
###########################################################################

# Marshall submsgs
func pack_sync(obj, ref):
	ref.set_handles(obj.handles)

func pack_channel_msg(obj, ref):
	ref.set_text(obj.text)
	ref.set_handle(obj.handle)

func pack_part(obj, ref):
	pass
func pack_join(obj, ref):
	ref.set_handle(obj.handle)

func pack_chat(obj, ref):
	ref.set_msg(obj.msg)


func pack_session_pong(obj, ref):
	ref.set_latency(obj.latency)

func pack_session_ping(obj, ref):
	ref.set_id(obj.id)

func pack_session_beacon(obj, ref):
	ref.set_id(obj.id)

func pack_session_new(obj, ref):
	ref.set_reconnect_token(obj.reconnect_token)
	ref.set_id(obj.id)

func pack_session_request(obj, ref):
	ref.set_reconnect_token(obj.reconnect_token)

func pack_overworld(obj, ref):
	ref.set_msg(obj.msg)



# Marshall 
func channel_msg(handle = null, text = ''):
	var m = Chat_pb.chat.new()
	var n = m.new_channel_msg()
	text=text
	if text:
		n.set_text(text)
	handle=handle
	if handle:
		n.set_handle(handle)
	var payload = m.to_bytes()
	_send_message(payload, Prefix.CHAT, 'reliable', 0)
	if debug:
		print('[INFO] Send a channel_msg packet')

func session_ping(id: int):
	var m = Overworld_pb.overworld.new()
	var n = m.new_session_ping()
	n.set_id(id)
	var payload = m.to_bytes()
	_send_message(payload, Prefix.OVERWORLD, 'reliable', 0)
	if debug:
		print('[INFO] Send a session_ping packet')

func session_request(reconnect_token = null):
	var m = Overworld_pb.overworld.new()
	var n = m.new_session_request()
	reconnect_token=reconnect_token
	if reconnect_token:
		n.set_reconnect_token(reconnect_token)
	var payload = m.to_bytes()
	_send_message(payload, Prefix.OVERWORLD, 'reliable', 0)
	if debug:
		print('[INFO] Send a session_request packet')

func join(handle = ''):
	var m = Chat_pb.chat.new()
	var n = m.new_join()
	handle=handle
	if handle:
		n.set_handle(handle)
	var payload = m.to_bytes()
	_send_message(payload, Prefix.CHAT, 'reliable', 0)
	if debug:
		print('[INFO] Send a join packet')

func part():
	var m = Chat_pb.chat.new()
	var n = m.new_part()
	var payload = m.to_bytes()
	_send_message(payload, Prefix.CHAT, 'reliable', 0)
	if debug:
		print('[INFO] Send a part packet')



############################################################################
# Various other utility and initialization functions
############################################################################

func _ready():
	# Automatically reply to beacons
	server_session_beacon.connect(self._on_session_beacon)

func enet_connect(ip: String, port: int):
	print("[INFO] Connecting via ENet to ", ip)
	var _err = _enet_peer.create_client(ip, port, 4)
	mode = transport_mode.ENET
	# Set mode to ZLIB
	_enet_peer.host.compress(ENetConnection.COMPRESS_ZLIB)
	
func enet_disconnect():
	for peer in _enet_peer.host.get_peers():
		print("Peer: " + str(peer))
		peer.peer_disconnect()
	_enet_peer.close()
	mode = null
	emit_signal("server_disconnected")

# Take the host and whether or not its a TLS conncetion
func ws_connect(address: String, port: int = 4433):
	var url = "ws://" + address + ":" + str(port) + "/ws"
	print("[INFO] Connecting via WebSocket to ", url)
	_websocket_connect(url)
	
func ws_disconnect():
	_websocket_close()
	mode = null
	
func wss_connect(address: String, port: int = 4434):
	var url = "wss://" + address + ":" + str(port) + "/ws"
	print("[INFO] Connecting via WebSocketSecure to ", url)
	_websocket_connect(url)

func wss_disconnect():
	_websocket_close()

func _websocket_connect(url):
	_ws_peer.connect_to_url(url)
	mode = transport_mode.WEBSOCKET

func _websocket_close():
	_ws_peer.close()

func _send_message(payload, opcode, qos, channel):
	# Create a new packet starting with opcode, append the message if it exists,
	# then send it across the websocket or ENet connection.
	# Set the peer mode
	var peer
	if mode == transport_mode.WEBSOCKET:
		var packet = [] + opcode
		peer = _ws_peer
		# Construct the packet
		if payload.is_empty() != true:
			# Append the payload to the packet if it's nonempty
			packet.append_array(payload)
		peer.send(packet)
	elif mode == transport_mode.ENET:
		var packet = [] + opcode # TODO: Workaround
		peer = _enet_peer
		for p in peer.host.get_peers():
			# TODO: Thread channel and packet type through
			if payload.is_empty() != true:
				packet.append_array(payload)
			var flag
			match qos:
				"reliable":
					flag = ENetPacketPeer.FLAG_RELIABLE
				"unreliable":
					flag = ENetPacketPeer.FLAG_UNRELIABLE_FRAGMENT
				"unsequenced":
					flag = ENetPacketPeer.FLAG_UNSEQUENCED
			p.send(channel, packet, flag)

func _process(_delta):
	if mode == transport_mode.WEBSOCKET:
		_ws_peer.poll()
		var state = _ws_peer.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			if _ws_connected == false:
				emit_signal("server_connected")
				_ws_connected = true
			while _ws_peer.get_available_packet_count():
				var packet = _ws_peer.get_packet()
				route(packet)
		elif state == WebSocketPeer.STATE_CLOSING:
			# Keep polling to achieve proper close.
			pass
		elif state == WebSocketPeer.STATE_CLOSED:
			_ws_connected = false
			emit_signal("server_disconnected")
	elif mode == transport_mode.ENET:
		var p = _enet_peer.host.service() # Check for packets
		if p[0] == ENetConnection.EVENT_CONNECT:
			emit_signal("server_connected")
		elif p[0] == ENetConnection.EVENT_DISCONNECT:
			emit_signal("server_disconnected")
		elif p[0] == ENetConnection.EVENT_RECEIVE:
			var packet = p[1].get_packet()
			route(packet)

############################################################################
#  Signal Handlers
############################################################################

func _closed(was_clean = false):
	# was_clean will tell you if the disconnection was correctly notified
	# by the remote peer before closing the socket.
	print("Closed, clean: ", was_clean)
	set_process(false)

func _connected(proto = ""):
	# This is called on connection, "proto" will be the selected WebSocket
	# sub-protocol (which is optional)
	print("Connected with protocol: ", proto)

##func _on_data():
##	var packet = _ws_client.get_peer(1).get_packet()
##	route(packet)

func _on_session_beacon(id):
	# Used for latency measurements
	session_ping(id)
