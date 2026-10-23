extends CharacterBody3D


# ===== CONFIGURAÇÕES =====
@export var velocidade_maxima: float = 30.0
@export var velocidade_reversa: float = 8.0
@export var aceleracao: float = 8.0
@export var forca_freio: float = 25.0
@export var velocidade_curva: float = 1.8
@export var sensibilidade_direcao: float = 1.0
@export var gravidade: float = 20.0

# ID do jogador enviado pelo servidor.
@export var id_jogador: int = 1

# ===== CONTROLES =====
var direcao_celular: float = 0.0
var acelerador_celular: float = 0.0
var freio_celular: float = 0.0
var velocidade_atual: float = 0.0


func _physics_process(delta: float) -> void:
	ler_controles_celular()

	# Controles do teclado.
	var direcao_teclado: float = Input.get_axis("left", "right")
	var gas_teclado: float = Input.get_action_strength("forward")
	var freio_teclado: float = Input.get_action_strength("back")

	var direcao: float = direcao_celular
	var gas: float = acelerador_celular
	var freio: float = freio_celular

	# O teclado substitui o celular quando usado.
	if direcao_teclado != 0.0:
		direcao = direcao_teclado

	if gas_teclado > 0.0:
		gas = gas_teclado

	if freio_teclado > 0.0:
		freio = freio_teclado

	direcao = clampf(
		direcao * sensibilidade_direcao, -1.0, 1.0
	)
	gas = clampf(gas, 0.0, 1.0)
	freio = clampf(freio, 0.0, 1.0)

	# ===== ACELERAÇÃO, FREIO E RÉ =====
	if freio > 0.0:
		if velocidade_atual > 0.1:
			# Freia enquanto avança.
			velocidade_atual = move_toward(
				velocidade_atual,
				0.0,
				forca_freio * freio * delta
			)
		else:
			# Dá ré quando parado ou já em ré.
			velocidade_atual = move_toward(
				velocidade_atual,
				-velocidade_reversa * freio,
				aceleracao * delta
			)

	elif gas > 0.0:
		if velocidade_atual < -0.1:
			# Para antes de voltar a acelerar para frente.
			velocidade_atual = move_toward(
				velocidade_atual,
				0.0,
				forca_freio * delta
			)
		else:
			velocidade_atual = move_toward(
				velocidade_atual,
				velocidade_maxima * gas,
				aceleracao * delta
			)

	else:
		velocidade_atual = move_toward(
			velocidade_atual,
			0.0,
			aceleracao * 0.35 * delta
		)

	# ===== DIREÇÃO =====
	var fator_velocidade: float = clampf(
		abs(velocidade_atual) / velocidade_maxima,
		0.0,
		1.0
	)

	var sentido: float = 1.0
	if velocidade_atual < 0.0:
		sentido = -1.0

	rotate_y(
		-direcao
		* velocidade_curva
		* fator_velocidade
		* sentido
		* delta
	)

	# A frente do modelo é +X local.
	var frente: Vector3 = global_transform.basis.x.normalized()

	velocity.x = frente.x * velocidade_atual
	velocity.z = frente.z * velocidade_atual

	# ===== GRAVIDADE E COLISÕES =====
	if not is_on_floor():
		velocity.y -= gravidade * delta
	else:
		velocity.y = 0.0

	move_and_slide()


func ler_controles_celular() -> void:
	# PhoneInput deve estar configurado como Autoload.
	if not PhoneInput.inputs.has(id_jogador):
		direcao_celular = 0.0
		acelerador_celular = 0.0
		freio_celular = 0.0
		return

	var dados: Dictionary = PhoneInput.inputs[id_jogador]

	# O servidor envia steer numérico e gas/brake booleanos.
	direcao_celular = clampf(
		float(dados.get("steer", 0.0)), -1.0, 1.0
	)

	acelerador_celular = (
		1.0 if bool(dados.get("gas", false)) else 0.0
	)

	freio_celular = (
		1.0 if bool(dados.get("brake", false)) else 0.0
	)


func definir_direcao(valor: float) -> void:
	direcao_celular = clampf(valor, -1.0, 1.0)


func definir_acelerador(valor: float) -> void:
	acelerador_celular = clampf(valor, 0.0, 1.0)


func definir_freio(valor: float) -> void:
	freio_celular = clampf(valor, 0.0, 1.0)


func soltar_controles() -> void:
	direcao_celular = 0.0
	acelerador_celular = 0.0
	freio_celular = 0.0
