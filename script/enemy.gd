# Origem: elaborado com ajuda de IA (OpenAI/Codex).
# Esporim desta etapa: fica parado, recebe golpes e causa dano por contato.
extends CharacterBody2D

@export var max_health: int = 3
@export var contact_damage: int = 1

enum EnemyState { IDLE, HURT, DEAD }

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D

var health: int = 3
var state: EnemyState = EnemyState.IDLE
var reaction_time_left: float = 0.0
var contact_area: Area2D


func _ready() -> void:
	health = maxi(1, max_health)
	remove_from_group("player")
	add_to_group("enemies")
	# Camada 3 para inimigos; detecta somente o terreno na camada 1.
	collision_layer = 4
	collision_mask = 1

	if anim.sprite_frames != null:
		# Cada inimigo ganha sua copia antes de mudar o loop das reacoes.
		anim.sprite_frames = anim.sprite_frames.duplicate() as SpriteFrames
		for animation_name in [&"hurt", &"death"]:
			if anim.sprite_frames.has_animation(animation_name):
				anim.sprite_frames.set_animation_loop(animation_name, false)
	anim.animation_finished.connect(_on_animation_finished)
	go_to_idle_state()

	# Adicionar a Area fora da atualizacao da fisica evita "flushing queries".
	call_deferred("create_contact_area")


func _physics_process(delta: float) -> void:
	# Sem patrulha ou perseguicao nesta etapa; o corpo so recebe gravidade.
	velocity.x = 0.0
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

	if state == EnemyState.IDLE:
		damage_touching_player()
	else:
		# O tempo tambem encerra a reacao caso o sinal nao seja emitido.
		reaction_time_left -= delta
		if reaction_time_left <= 0.0:
			finish_reaction()


func take_damage(amount: int, source_position: Vector2) -> bool:
	# Um golpe so e aceito se estiver vivo e fora da reacao anterior.
	if amount <= 0 or state != EnemyState.IDLE:
		return false

	health = maxi(0, health - amount)
	# Vira o desenho para a origem do golpe, sem mover o corpo.
	anim.flip_h = source_position.x < global_position.x
	if health == 0:
		state = EnemyState.DEAD
		reaction_time_left = play_reaction(&"death", 0.8)
		if is_instance_valid(contact_area):
			contact_area.set_deferred("monitoring", false)
	else:
		state = EnemyState.HURT
		reaction_time_left = play_reaction(&"hurt", 0.35)
	return true


func go_to_idle_state() -> void:
	state = EnemyState.IDLE
	reaction_time_left = 0.0
	if has_animation(&"idle"):
		anim.play(&"idle")


func play_reaction(animation_name: StringName, fallback_time: float) -> float:
	if not has_animation(animation_name):
		return fallback_time
	anim.play(animation_name)
	anim.frame = 0
	anim.frame_progress = 0.0

	# Soma as duracoes dos quadros, respeitando FPS e Speed Scale.
	var frames: SpriteFrames = anim.sprite_frames
	var fps: float = frames.get_animation_speed(animation_name) * absf(anim.speed_scale)
	if fps <= 0.0:
		return fallback_time
	var frame_units: float = 0.0
	for frame_index in range(frames.get_frame_count(animation_name)):
		frame_units += frames.get_frame_duration(animation_name, frame_index)
	return maxf(0.05, frame_units / fps) + 0.1


func has_animation(animation_name: StringName) -> bool:
	return anim.sprite_frames != null \
		and anim.sprite_frames.has_animation(animation_name) \
		and anim.sprite_frames.get_frame_count(animation_name) > 0


func _on_animation_finished() -> void:
	if state == EnemyState.HURT and anim.animation == &"hurt":
		finish_reaction()
	elif state == EnemyState.DEAD and anim.animation == &"death":
		finish_reaction()


func finish_reaction() -> void:
	if state == EnemyState.HURT:
		go_to_idle_state()
	elif state == EnemyState.DEAD:
		set_physics_process(false)
		queue_free()


func create_contact_area() -> void:
	if state == EnemyState.DEAD or is_queued_for_deletion():
		return
	if body_shape.shape == null:
		push_warning("Esporim: falta uma forma no CollisionShape2D.")
		return

	contact_area = Area2D.new()
	contact_area.name = "ContactDamage"
	contact_area.collision_layer = 0
	contact_area.collision_mask = 2
	contact_area.monitoring = true
	contact_area.monitorable = false
	var contact_shape := CollisionShape2D.new()
	contact_shape.shape = body_shape.shape.duplicate() as Shape2D
	contact_shape.transform = body_shape.transform
	contact_area.add_child(contact_shape)
	add_child(contact_area)


func damage_touching_player() -> void:
	# Checa todo passo de fisica: a invulnerabilidade pertence ao jogador.
	if state != EnemyState.IDLE or not is_instance_valid(contact_area):
		return
	for body in contact_area.get_overlapping_bodies():
		if not is_instance_valid(body) or body.is_queued_for_deletion():
			continue
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.call("take_damage", contact_damage, global_position)
