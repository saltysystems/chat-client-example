extends Control

var handle = "Soandso" + str(randi() % 100)
var users = []

# Called when the node enters the scene tree for the first time.
func _ready():
	Overworld.server_session_new.connect(self._on_session_new)
	Overworld.server_sync.connect(self._on_sync)
	Overworld.server_channel_msg.connect(self._on_channel_msg)
	GameManager.net_connect(handle)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Called whenever the ENTER key is pressed on the LineEdit field
func _on_line_edit_text_submitted(new_text):
	Overworld.channel_msg("",new_text)
	$LineEdit.text = ""

func _on_session_new(id, reconnect_token):
	$ChatWindow.text += "[i]Starting a new session: " + str(id) + "[/i]\n"

func _on_sync(handles: Array):
	redraw_user_list(handles)
	
func _on_channel_msg(handle: String, msg: String):
	$ChatWindow.text += "<" + handle + "> " + msg + "\n"

func redraw_user_list(handles):
	$UserList.text = ""
	for handle in handles:
		$UserList.text += handle + "\n"
