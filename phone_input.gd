
extends Node

signal player_joined(id)
signal player_left(id)

const URL := "ws://127.0.0.1:8080"

var socket := WebSocketPeer.new()
var inputs: Dictionary = {}
var retry: float = 0.0
var conectado: bool = false


func _ready() -> void:
	print("TESTE: PhoneInput iniciou!")
	conectar_servidor()


func conectar_servidor() -> void:
	socket = WebSocketPeer.new()
	conectado = false

	var erro: Error = socket.connect_to_url(URL)

	if erro != OK:
		print("Erro ao conectar ao servidor: ", erro)
	else:
		print("Tentando conectar ao servidor WebSocket...")


func _process(delta: float) -> void:
	socket.poll()

	var estado := socket.get_ready_state()

	if estado == WebSocketPeer.STATE_OPEN:
		if not conectado:
			conectado = true
			print("PhoneInput conectado ao servidor WebSocket!")

		while socket.get_available_packet_count() > 0:
			var mensagem: String = socket.get_packet().get_string_from_utf8()
			_handle(mensagem)

	elif estado == WebSocketPeer.STATE_CLOSED:
		if conectado:
			conectado = false
			print("WebSocket desconectado.")

		retry -= delta

		if retry <= 0.0:
			retry = 2.0
			conectar_servidor()


func _handle(text: String) -> void:
	var msg = JSON.parse_string(text)

	if typeof(msg) != TYPE_DICTIONARY:
		print("Mensagem JSON inválida: ", text)
		return

	var id: int = int(msg.get("id", 0))
	var tipo: String = str(msg.get("type", ""))

	match tipo:
		"join":
			if id <= 0:
				return

			if not inputs.has(id):
				inputs[id] = {
					"steer": 0.0,
					"gas": false,
					"brake": false
				}

				player_joined.emit(id)
				print("Jogador conectado: ", id)

		"leave":
			if inputs.has(id):
				inputs.erase(id)
				player_left.emit(id)
				print("Jogador desconectado: ", id)

		"input":
			if id <= 0:
				print("ID de jogador inválido: ", id)
				return

			if not inputs.has(id):
				inputs[id] = {
					"steer": 0.0,
					"gas": false,
					"brake": false
				}

				player_joined.emit(id)
				print("Jogador identificado pelos controles: ", id)

			inputs[id] = {
				"steer": clampf(float(msg.get("steer", 0.0)), -1.0, 1.0),
				"gas": bool(msg.get("gas", false)),
				"brake": bool(msg.get("brake", false))
			}

			print("Controles do jogador ", id, ": ", inputs[id])

		_:
			print("Tipo de mensagem desconhecido: ", tipo)
