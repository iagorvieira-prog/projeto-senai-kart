
extends SpringArm3D

@export var distancia_camera: float = 6.0
@export var altura_camera: float = 2.5
@export var suavidade_rotacao: float = 4.0

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	spring_length = distancia_camera
	position.y = altura_camera

	camera.position = Vector3.ZERO
	camera.rotation = Vector3.ZERO

func _physics_process(delta: float) -> void:
	var carro := get_parent() as CharacterBody3D
	if carro == null:
		return

	# O carro aponta para +X; a câmera fica atrás, no -X local.
	var angulo_alvo: float = carro.global_rotation.y - PI / 2.0
	var peso: float = 1.0 - exp(-suavidade_rotacao * delta)

	global_rotation.y = lerp_angle(
		global_rotation.y,
		angulo_alvo,
		peso
	)
