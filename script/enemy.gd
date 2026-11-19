extends CharacterBody2D

@export var max_health: int = 3
@export var contact_damage: int = 1
@export var contact_size: Vector2 = Vector2(12.0, 14.0)
@export var contact_offset: Vector2 = Vector2.ZERO

@export_category("Patrulha e visao")
@export var patrol_distance: float = 400.0
@export var patrol_speed: float = 30.0
@export var chase_speed: float = 60.0
@export var detection_radius: float = 200.0
@export var ledge_probe_distance: float = 6.0

@export_category("Recuo ao receber dano")
@export var knockback: Vector2 = Vector2(110.0, -140.0)
@export var knockback_friction: float = 300.0

enum EnemyState { IDLE, HURT, DEAD, PATROL, CHASE }

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D

var health: int = 3
var state: EnemyState = EnemyState.IDLE
var reaction_time_left: float = 0.0
var contact_area: Area2D
var _patrol_origin: Vector2
var _patrol_direction: float = 1.0
var _target: CharacterBody2D


func _ready() -> void:
	health = maxi(1, max_health)
	_patrol_origin = global_position
	remove_from_group("player")
	add_to_group("enemies")
	# Camada 3 para inimigos; detecta somente o terreno na camada 1.
	collision_layer = 4
	collision_mask = 1

	if anim.sprite_frames != null:
		# Cada inimigo ganha sua copia antes de mudar o loop das reacoes.
		anim.sprite_frames = anim.sprite_frames.duplicate() as SpriteFrames
		for animation_name in [&"attack", &"hurt", &"death"]:
			if anim.sprite_frames.has_animation(animation_name):
				anim.sprite_frames.set_animation_loop(animation_name, false)
	anim.animation_finished.connect(_on_animation_finished)
	go_to_idle_state()

	# Adicionar a Area fora da atualizacao da fisica evita "flushing queries".
	call_deferred("create_contact_area")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if state == EnemyState.HURT or state == EnemyState.DEAD:
		# A IA nao sobrescreve o impulso do golpe com a velocidade de patrulha.
		velocity.x = move_toward(velocity.x, 0.0, maxf(knockback_friction, 0.0) * delta)
		move_and_slide()
		reaction_time_left -= delta
		if reaction_time_left <= 0.0:
			finish_reaction()
		return

	_target = find_visible_player()
	if _target != null:
		state = EnemyState.CHASE
		chase_player()
	else:
		state = EnemyState.PATROL
		patrol(delta)
	move_and_slide()
	update_movement_animation()
	damage_touching_player()


func find_visible_player() -> CharacterBody2D:
	var closest: CharacterBody2D = null
	var closest_distance: float = maxf(detection_radius, 0.0)
	for candidate: Node in get_tree().get_nodes_in_group("player"):
		var player := candidate as CharacterBody2D
		if player == null or player.is_queued_for_deletion():
			continue
		if player.has_method("is_dead") and bool(player.call("is_dead")):
			continue
		var distance: float = global_position.distance_to(player.global_position)
		if distance > closest_distance:
			continue
		# O alcance e de 200 pixels em qualquer direcao; paredes bloqueiam a visao.
		var ray := PhysicsRayQueryParameters2D.create(
			global_position + Vector2(0, -4),
			player.global_position + Vector2(0, -4),
			1,
			[get_rid(), player.get_rid()]
		)
		ray.hit_from_inside = true
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		closest = player
		closest_distance = distance
	return closest


func patrol(delta: float) -> void:
	var half_range: float = maxf(patrol_distance, 0.0) * 0.5
	if half_range <= 0.0 or patrol_speed <= 0.0:
		velocity.x = 0.0
		return
	var left_limit: float = _patrol_origin.x - half_range
	var right_limit: float = _patrol_origin.x + half_range
	if global_position.x >= right_limit and _patrol_direction > 0.0:
		_patrol_direction = -1.0
	elif global_position.x <= left_limit and _patrol_direction < 0.0:
		_patrol_direction = 1.0
	if not can_walk_toward(_patrol_direction):
		_patrol_direction *= -1.0
	if not can_walk_toward(_patrol_direction):
		velocity.x = 0.0
		return
	# Limitar o passo evita ultrapassar a extremidade mesmo em FPS baixo.
	var remaining: float = right_limit - global_position.x if _patrol_direction > 0.0 else global_position.x - left_limit
	velocity.x = _patrol_direction * minf(patrol_speed, maxf(remaining, 0.0) / maxf(delta, 0.0001))


func chase_player() -> void:
	var distance_x: float = _target.global_position.x - global_position.x
	var direction: float = signf(distance_x)
	if absf(distance_x) <= 2.0 or not can_walk_toward(direction):
		velocity.x = 0.0
		return
	velocity.x = direction * maxf(chase_speed, 0.0)


func can_walk_toward(direction: float) -> bool:
	if is_zero_approx(direction):
		return false
	if is_on_wall() and get_wall_normal().x * direction < -0.1:
		return false
	if not is_on_floor() or body_shape.shape == null:
		return true
	# Procurar chao alem da frente do corpo evita cair na agua durante a ronda.
	var rectangle: Rect2 = body_shape.shape.get_rect()
	var ahead_x: float = body_shape.position.x + direction * (rectangle.size.x * 0.5 + maxf(ledge_probe_distance, 0.0))
	var foot_y: float = body_shape.position.y + rectangle.end.y
	var from: Vector2 = to_global(Vector2(ahead_x, foot_y - 4.0))
	var to: Vector2 = to_global(Vector2(ahead_x, foot_y + 12.0))
	var ray := PhysicsRayQueryParameters2D.create(from, to, 1, [get_rid()])
	return not get_world_2d().direct_space_state.intersect_ray(ray).is_empty()


func update_movement_animation() -> void:
	if absf(velocity.x) > 0.1:
		anim.flip_h = velocity.x < 0.0
		if has_animation(&"walk"):
			anim.play(&"walk")
		elif has_animation(&"idle"):
			anim.play(&"idle")
	elif has_animation(&"idle"):
		anim.play(&"idle")


func take_damage(amount: int, source_position: Vector2) -> bool:
	# Um golpe so e aceito se estiver vivo e fora da reacao anterior.
	if amount <= 0 or state == EnemyState.HURT or state == EnemyState.DEAD:
		return false

	health = maxi(0, health - amount)
	# O corpo recua para o lado oposto a origem, sem mudar a posicao diretamente.
	anim.flip_h = source_position.x < global_position.x
	var away: float = signf(global_position.x - source_position.x)
	if is_zero_approx(away):
		away = 1.0 if anim.flip_h else -1.0
	velocity = Vector2(away * absf(knockback.x), knockback.y)
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
	contact_area.collision_mask = 18
	contact_area.monitoring = true
	contact_area.monitorable = false
	var contact_shape := CollisionShape2D.new()
	var damage_shape := RectangleShape2D.new()
	damage_shape.size = contact_size
	contact_shape.shape = damage_shape
	contact_shape.position = body_shape.position + contact_offset
	contact_area.add_child(contact_shape)
	add_child(contact_area)


func damage_touching_player() -> void:
	# Checa todo passo de fisica: a invulnerabilidade pertence ao jogador.
	if state == EnemyState.HURT or state == EnemyState.DEAD or not is_instance_valid(contact_area):
		return
	for body in contact_area.get_overlapping_bodies():
		if not is_instance_valid(body) or body.is_queued_for_deletion():
			continue
		if body.has_method("is_dead") and bool(body.call("is_dead")):
			continue
		if (body.is_in_group("player") or body.is_in_group("rescued_allies")) and body.has_method("take_damage"):
			body.call("take_damage", contact_damage, global_position)
