# Origem: movimento existente adaptado com ajuda de IA (OpenAI/Codex).
extends CharacterBody2D
## Mush: movimento, combate e registro do caminho usado pelos aliados.

signal health_changed(current_health: int, maximum_health: int)
signal damaged(amount: int)
signal died
signal ally_rescued(ally: Node2D, total: int)
signal fell_into_hazard
signal jumped(launch_position: Vector2, vertical_speed: float, horizontal_speed: float, jump_number: int, flight_id: int)
signal landed(landing_position: Vector2, flight_id: int)

enum PlayerState { walk, idle, jump, duck, attack, hurt, dead }

@export_category("Movimento")
@export var speed: float = 100.0
@export var jump_velocity: float = -320.0
@export_range(1, 5) var max_jump_count: int = 2

@export_category("Vida")
@export_range(1, 100) var max_health: int = 5
@export var invulnerability_time: float = 1.0
@export var hurt_time: float = 0.25
@export var knockback: Vector2 = Vector2(110.0, -140.0)
@export var restart_on_death: bool = true
@export var death_restart_delay: float = 1.0
@export var fall_recovery_time: float = 0.35

@export_category("Ataque com galho")
@export_range(1, 100) var attack_damage: int = 1
@export var attack_size: Vector2 = Vector2(22.0, 22.0)
@export var attack_offset: Vector2 = Vector2(17.0, -4.0)
@export_flags_2d_physics var attack_mask: int = 4
## Índices começam em zero: 3 e 4 são os quadros 4 e 5 do golpe.
@export var attack_first_frame: int = 3
@export var attack_last_frame: int = 4

@export_category("Aliados")
@export var ally_spacing: float = 28.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var health: int
var status: PlayerState = PlayerState.idle
var direction: float = 0.0
var jump_count: int = 0

var _invulnerability_left: float = 0.0
var _hurt_left: float = 0.0
var _death_left: float = 0.0
var _attacking: bool = false
var _attack_facing: float = 1.0
var _hit_targets: Array[int] = []
var _attack_shape: RectangleShape2D = RectangleShape2D.new()
var _standing_shape: Shape2D
var _duck_shape: Shape2D
var _standing_position: Vector2
var _standing_modulate: Color
var _allies: Array[Node2D] = []
var _trail = preload("res://script/player_trail.gd").new()
var _session: Node
var _safe_position: Vector2
var _safe_ground_time: float = 0.0
var _respawning: bool = false
var _respawn_left: float = 0.0
var _death_reason: String = "A luz de Mush se apagou."
var _liquid_layers: Array[TileMapLayer] = []
var _flight_id: int = 0


func _ready() -> void:
	add_to_group("player")
	health = max_health
	_standing_modulate = anim.modulate
	_standing_position = collision_shape.position
	_standing_shape = collision_shape.shape.duplicate()
	_duck_shape = _standing_shape.duplicate()
	if _duck_shape is CapsuleShape2D:
		_duck_shape.radius = 5.0
		_duck_shape.height = 10.0
	collision_shape.shape = _standing_shape
	_prepare_animations()
	anim.animation_finished.connect(_on_animation_finished)
	_trail.spacing = ally_spacing
	_trail.follow_speed = speed
	_record_path()
	_safe_position = global_position
	_play(&"idle")
	health_changed.emit(health, max_health)
	var session: Node = get_node_or_null("/root/GameSession")
	if session != null:
		session.call_deferred("attach_player", self)
	_cache_liquid_layers.call_deferred()


func _physics_process(delta: float) -> void:
	var was_on_floor: bool = is_on_floor()
	var starting_flight: int = _flight_id
	_update_invulnerability(delta)
	if is_dead():
		velocity = Vector2.ZERO
		_death_left -= delta
		if restart_on_death and _death_left <= 0.0:
			restart_on_death = false
			if is_instance_valid(_session):
				_session.call_deferred("show_game_over", self, _death_reason)
			else:
				get_tree().call_deferred("reload_current_scene")
		return
	if _respawning:
		velocity = Vector2.ZERO
		_respawn_left -= delta
		if _respawn_left <= 0.0:
			_respawning = false
		return

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jump_count = 0

	if _hurt_left > 0.0:
		_hurt_left = maxf(0.0, _hurt_left - delta)
		velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
		status = PlayerState.hurt
		_play(&"hurt")
	else:
		_read_movement()
		if Input.is_action_just_pressed("attack") and not _attacking:
			start_attack()

	move_and_slide()
	if is_on_floor() and not was_on_floor:
		landed.emit(global_position, _flight_id)
	elif was_on_floor and not is_on_floor() and _flight_id == starting_flight:
		# Cair de uma borda tambem abre um voo, mesmo sem apertar pular.
		_flight_id += 1
	var liquid: String = _liquid_at_feet()
	if not liquid.is_empty():
		fall_into_hazard(liquid)
		return
	if _attacking:
		status = PlayerState.attack
		# Consultar na física evita alterar colisões dentro de sinais de animação.
		if anim.frame >= attack_first_frame and anim.frame <= attack_last_frame:
			_hit_enemies()
	elif _hurt_left <= 0.0:
		_update_movement_animation()
	_record_path()
	_update_safe_ground(delta)


func _read_movement() -> void:
	direction = Input.get_axis("left", "right")
	if not _attacking:
		if direction < 0.0:
			anim.flip_h = true
		elif direction > 0.0:
			anim.flip_h = false

	var ducking: bool = Input.is_action_pressed("duck") and is_on_floor() and not _attacking
	_set_ducking(ducking)
	# O golpe firma o pé no chão; no ar ainda é possível controlar o salto.
	velocity.x = direction * speed if not ducking and not (_attacking and is_on_floor()) else 0.0
	if Input.is_action_just_pressed("jump") and not ducking:
		# Cair de uma borda já consome o salto normal, restando o salto extra.
		if not is_on_floor() and jump_count == 0:
			jump_count = 1
		if jump_count < max_jump_count:
			jump_count += 1
			velocity.y = jump_velocity
			if jump_count == 1:
				_flight_id += 1
			jumped.emit(global_position, jump_velocity, velocity.x, jump_count, _flight_id)


func _set_ducking(ducking: bool) -> void:
	collision_shape.shape = _duck_shape if ducking else _standing_shape
	if ducking and _standing_shape is CapsuleShape2D:
		# A base dos pés continua no mesmo lugar quando a cápsula encolhe.
		collision_shape.position = _standing_position + Vector2(0, (_standing_shape.height - 10.0) / 2.0)
	else:
		collision_shape.position = _standing_position


func _update_movement_animation() -> void:
	if not is_on_floor():
		status = PlayerState.jump
		_play(&"falling" if velocity.y > 0.0 else &"jump")
	elif Input.is_action_pressed("duck"):
		status = PlayerState.duck
		_play(&"duck")
	elif absf(velocity.x) > 0.1:
		status = PlayerState.walk
		_play(&"walk")
	else:
		status = PlayerState.idle
		_play(&"idle")


func start_attack() -> bool:
	if is_dead() or _respawning or _hurt_left > 0.0 or _attacking:
		return false
	_set_ducking(false)
	_attacking = true
	_attack_facing = -1.0 if anim.flip_h else 1.0
	_hit_targets.clear()
	status = PlayerState.attack
	anim.stop()
	_play(&"attack")
	return true


func _hit_enemies() -> void:
	_attack_shape.size = attack_size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _attack_shape
	query.transform = Transform2D(0.0, to_global(Vector2(attack_offset.x * _attack_facing, attack_offset.y)))
	query.collision_mask = attack_mask
	query.collide_with_areas = true
	query.exclude = [get_rid()]
	for hit: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 32):
		var target := hit["collider"] as Node
		# Aceita tanto o corpo do inimigo quanto uma Area2D filha dele.
		while target != null and not target.has_method("take_damage"):
			target = target.get_parent()
		if target == null or target == self or not target.is_in_group("enemies"):
			continue
		var target_id: int = target.get_instance_id()
		if target_id in _hit_targets:
			continue
		_hit_targets.append(target_id)
		target.call("take_damage", attack_damage, global_position)


## Retorna true apenas quando o dano foi aceito. Inimigos devem chamar este método.
func take_damage(amount: int, source_position: Vector2 = Vector2.INF) -> bool:
	if amount <= 0 or is_dead() or _respawning or _invulnerability_left > 0.0:
		return false
	health = maxi(0, health - amount)
	_invulnerability_left = invulnerability_time
	_attacking = false
	_set_ducking(false)
	health_changed.emit(health, max_health)
	damaged.emit(amount)
	if health == 0:
		_die()
		return true
	_hurt_left = hurt_time
	status = PlayerState.hurt
	var push_direction: float = 1.0 if anim.flip_h else -1.0
	if source_position.is_finite():
		push_direction = signf(global_position.x - source_position.x)
		if is_zero_approx(push_direction):
			push_direction = 1.0 if anim.flip_h else -1.0
	velocity = Vector2(push_direction * knockback.x, knockback.y)
	anim.stop()
	_play(&"hurt")
	return true


func heal(amount: int) -> void:
	if amount <= 0 or is_dead():
		return
	health = mini(max_health, health + amount)
	health_changed.emit(health, max_health)


func is_dead() -> bool:
	return status == PlayerState.dead


func is_attacking() -> bool:
	return _attacking


func _die() -> void:
	status = PlayerState.dead
	_attacking = false
	velocity = Vector2.ZERO
	_death_left = death_restart_delay
	anim.modulate = _standing_modulate
	# Mush ainda não tem uma animação death cadastrada: hurt é a alternativa.
	_play(&"death" if anim.sprite_frames.has_animation(&"death") else &"hurt")
	died.emit()


func _update_invulnerability(delta: float) -> void:
	_invulnerability_left = maxf(0.0, _invulnerability_left - delta)
	anim.modulate = _standing_modulate
	if _invulnerability_left > 0.0 and not is_dead():
		anim.modulate.a *= 0.35 if int(_invulnerability_left * 12.0) % 2 == 0 else 1.0


func _on_animation_finished() -> void:
	if anim.animation == &"attack" and _attacking:
		_attacking = false
		_update_movement_animation()


func _play(animation_name: StringName) -> void:
	if anim.sprite_frames.has_animation(animation_name):
		anim.play(animation_name)
	else:
		anim.play(&"jump" if not is_on_floor() else &"idle")


func _prepare_animations() -> void:
	# Cada instância tem seus próprios ajustes, sem alterar o recurso dos aliados.
	anim.sprite_frames = anim.sprite_frames.duplicate(true)
	# map2 e map_secret ainda têm cópias antigas do player. Acrescentamos somente
	# os estados novos nelas, sem trocar a cena nem redesenhar o mapa.
	_add_missing_strip(&"attack", "Attack", 18.0)
	_add_missing_strip(&"hurt", "Hurt", 5.0)
	_add_missing_strip(&"falling", "Falling", 5.0)
	for animation_name: StringName in [&"attack", &"hurt", &"death"]:
		if anim.sprite_frames.has_animation(animation_name):
			anim.sprite_frames.set_animation_loop(animation_name, false)


func _add_missing_strip(animation_name: StringName, file_name: String, fps: float) -> void:
	if anim.sprite_frames.has_animation(animation_name):
		return
	var texture := load("res://sprites/personagens_v2/mush/%s (32 x 32).png" % file_name) as Texture2D
	anim.sprite_frames.add_animation(animation_name)
	anim.sprite_frames.set_animation_speed(animation_name, fps)
	anim.sprite_frames.set_animation_loop(animation_name, false)
	for column in range(texture.get_width() / 32):
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(column * 32, 0, 32, 32)
		anim.sprite_frames.add_frame(animation_name, frame)


func register_ally(ally: Node2D) -> int:
	if is_dead():
		return -1
	var previous_slot: int = _allies.find(ally)
	if previous_slot >= 0:
		return previous_slot
	var slot: int = _trail.add_follower(ally.global_position)
	if slot < 0:
		return -1
	_allies.append(ally)
	ally_rescued.emit(ally, _allies.size())
	return slot


func get_follow_sample(slot: int) -> Dictionary:
	return _trail.sample(slot)


func _record_path() -> void:
	_trail.record(global_position, velocity, anim.flip_h, is_on_floor(), status == PlayerState.duck)


func restore_session(session: Node, saved_health: int) -> void:
	_session = session
	health = clampi(saved_health, 1, max_health)
	health_changed.emit(health, max_health)


func get_rescued_allies() -> Array[Node2D]:
	return _allies.duplicate()


## Uma entrada em água/lava desconta uma vida. A proteção de golpes não
## anula uma nova queda; _respawning impede cobrar duas vezes a mesma queda.
func fall_into_hazard(reason: String = "Água ou lava") -> bool:
	if is_dead() or _respawning:
		return false
	if is_instance_valid(_session) and bool(_session.get("transitioning")):
		return false
	_respawning = true
	_respawn_left = fall_recovery_time
	_attacking = false
	_hurt_left = 0.0
	velocity = Vector2.ZERO
	health = maxi(0, health - 1)
	fell_into_hazard.emit()
	health_changed.emit(health, max_health)
	damaged.emit(1)
	if health == 0:
		_death_reason = "%s esgotou as forças de Mush." % reason
		_die()
	else:
		_invulnerability_left = invulnerability_time
		_play(&"hurt")
		_respawn_at_safe_ground.call_deferred()
	return true


func _respawn_at_safe_ground() -> void:
	if is_dead():
		return
	_set_ducking(false)
	global_position = _safe_position
	reset_physics_interpolation()
	velocity = Vector2.ZERO
	jump_count = 0
	status = PlayerState.idle
	_safe_ground_time = 0.0
	# Um teleporte de recuperação não deve entrar no caminho da fila.
	var rescued: Array[Node2D] = _allies.duplicate()
	_allies.clear()
	_trail.reset(global_position, Vector2.ZERO, anim.flip_h, true, false)
	for ally: Node2D in rescued:
		if is_instance_valid(ally):
			ally.call("reset_following", self, _safe_position)
	# A câmera é independente do Mush; reposicioná-la evita exibir o fundo do poço.
	for camera: Node in get_tree().get_nodes_in_group("player_camera"):
		if camera is Camera2D:
			camera.global_position = global_position
			camera.reset_smoothing()


func _update_safe_ground(delta: float) -> void:
	if not is_on_floor() or _hurt_left > 0.0 or status == PlayerState.duck:
		_safe_ground_time = 0.0
		return
	# Os três apoios evitam salvar um retorno na quina de um precipício.
	var foot_y: float = _standing_position.y + _standing_shape.get_rect().end.y
	for offset_x: float in [-6.0, 0.0, 6.0]:
		var from: Vector2 = global_position + Vector2(offset_x, foot_y - 3.0)
		var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 7), 1, [get_rid()])
		if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			_safe_ground_time = 0.0
			return
	_safe_ground_time += delta
	if _safe_ground_time >= 0.12:
		_safe_position = global_position


func _cache_liquid_layers() -> void:
	var level: Node = get_tree().current_scene
	if level == null:
		return
	for node: Node in level.find_children("*", "TileMapLayer", true, false):
		_liquid_layers.append(node as TileMapLayer)


func _liquid_at_feet() -> String:
	# Lê os tiles que você já pintou: não cria nem move células do mapa.
	# Em chão firme, água desenhada atrás do terreno não conta como uma queda.
	if is_on_floor():
		return ""
	var foot_y: float = _standing_position.y + _standing_shape.get_rect().end.y - 2.0
	for layer: TileMapLayer in _liquid_layers:
		if not is_instance_valid(layer) or layer.tile_set == null or not layer.enabled:
			continue
		for offset_x: float in [-4.0, 0.0, 4.0]:
			var point: Vector2 = global_position + Vector2(offset_x, foot_y)
			var cell: Vector2i = layer.local_to_map(layer.to_local(point))
			var source_id: int = layer.get_cell_source_id(cell)
			if source_id < 0:
				continue
			var source := layer.tile_set.get_source(source_id) as TileSetAtlasSource
			if source == null or source.texture == null:
				continue
			var file: String = source.texture.resource_path.get_file().to_lower()
			if "lava" in file:
				return "A lava"
			if "water" in file:
				return "A água"
			var atlas: Vector2i = layer.get_cell_atlas_coords(cell)
			if "tropics_entities" in file and atlas in [Vector2i(12, 5), Vector2i(12, 6)]:
				return "A água"
	return ""
