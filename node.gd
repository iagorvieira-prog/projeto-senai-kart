extends Node

signal player_joined(id)
signal player_left(id)

const URL := "ws://127.0.0.1:8080"
#LOL
var socket := WebSocketPeer.new()
var inputs := {}          # id do jogador -> {steer, gas, brake}
var retry := 0.0

func _process(delta: float) -> void:
	socket.poll()          # "puxa as novidades" da conexão; sem isso nada chega
	match socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			while socket.get_available_packet_count() > 0:
				_handle(socket.get_packet().get_string_from_utf8())
		WebSocketPeer.STATE_CLOSED:
			retry -= delta
			if retry <= 0.0:       # tenta (re)conectar a cada 2 s
				retry = 2.0
				inputs.clear()     # sem servidor, ninguém está controlando
				socket = WebSocketPeer.new()
				socket.connect_to_url(URL)

func _handle(text: String) -> void:
	var msg = JSON.parse_string(text)
	if typeof(msg) != TYPE_DICTIONARY:
		return
	var id := int(msg.get("id", 0))
	match str(msg.get("type", "")):
		"join":
			if not inputs.has(id):
				inputs[id] = {"steer": 0.0, "gas": false, "brake": false}
				player_joined.emit(id)
		"leave":
			inputs.erase(id)
			player_left.emit(id)
		"input":
			if not inputs.has(id):
				player_joined.emit(id)
			inputs[id] = {
				"steer": float(msg.get("steer", 0.0)),
				"gas": bool(msg.get("gas", false)),
				"brake": bool(msg.get("brake", false)),
			}
