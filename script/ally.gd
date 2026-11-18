extends CharacterBody2D

## Vazio usa o caminho do prefab como identidade entre os mapas.
@export var ally_id: StringName = &""

var _player: Node2D
var _slot: int = -1
var _rescue_area: Area2D
var _sprite: AnimatedSprite2D
var _jump_queue: Array[Dictionary] = []
var _clock: float = 0.0
var _jump_lag: float = 0.0
var _takeoff_y: float = 0.0
var _active_flight: int = -1
var _active_jump: Dictionary = {}
var _landings: Dictionary = {}

## Diferenca curta entre aliados em saltos parados; correndo, usam o ponto do salto.
@export var jump_stagger: float = 0.06


func _ready() -> void:
	process_physics_priority = 10
	remove_from_group("player")
	add_to_group("allies")
	_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	# O corpo nao bloqueia nem empurra Mush; a Area2D so detecta o contato.
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	_create_rescue_area()
	if _slot >= 0:
		_set_rescue_monitoring(false)
	_play("idle")


func get_ally_id() -> StringName:
	if ally_id != &"":
		return ally_id
	if not scene_file_path.is_empty():
		return StringName(scene_file_path)
	# Um no criado diretamente por codigo ainda pode receber ally_id no Inspector.
	return StringName(name)


func get_party_scene_path() -> String:
	# O gerente persiste o prefab, nunca a referencia ao no da fase anterior.
	return scene_file_path


## Registro compartilhado pelo contato e pela restauracao do gerente.
## Nao reposiciona o aliado nem exige acesso a um autoload especifico.
func follow_player(player: Node2D) -> bool:
	if is_queued_for_deletion() or not is_instance_valid(player):
		return false
	if not player.has_method("register_ally"):
		return false
	if player.has_method("is_dead") and bool(player.call("is_dead")):
		return false
	if _player == player and _slot >= 0:
		return true
	var registered_slot: int = int(player.call("register_ally", self))
	if registered_slot < 0:
		return false
	_disconnect_jump_signal()
	_player = player
	_slot = registered_slot
	_jump_queue.clear()
	_jump_lag = 0.0
	_landings.clear()
	_active_flight = -1
	_active_jump.clear()
	_takeoff_y = global_position.y
	if _player.has_signal("jumped"):
		_player.connect("jumped", _on_player_jumped)
	if _player.has_signal("landed"):
		_player.connect("landed", _on_player_landed)
	# Colide com o terreno, mas nunca empurra Mush ou outro aliado.
	set_deferred("collision_mask", 1)
	add_to_group("rescued_allies")
	_set_rescue_monitoring(false)
	return true


## Use apos limpar os registros do player e reiniciar a trilha no respawn.
## Esta reposicao e explicita: ela nao faz parte do seguimento normal da fila.
func reset_following(player: Node2D, spawn_position: Vector2) -> bool:
	if is_queued_for_deletion() or not is_instance_valid(player):
		return false
	if not player.has_method("register_ally"):
		return false
	if player.has_method("is_dead") and bool(player.call("is_dead")):
		return false
	_disconnect_jump_signal()
	_jump_queue.clear()
	_player = null
	_slot = -1
	remove_from_group("rescued_allies")
	global_position = spawn_position
	velocity = Vector2.ZERO
	show()
	if is_inside_tree():
		reset_physics_interpolation()
	var registered: bool = follow_player(player)
	if not registered:
		_set_rescue_monitoring(true)
	return registered


## O gerente chama isto em copias aguardando no mapa antes de criar a party.
## Um aliado que ja segue alguem nao e descartado por este metodo.
func discard_as_duplicate() -> bool:
	if _slot >= 0 or is_queued_for_deletion():
		return false
	hide()
	set_physics_process(false)
	_set_rescue_monitoring(false)
	queue_free()
	return true


func _set_rescue_monitoring(enabled: bool) -> void:
	if is_instance_valid(_rescue_area):
		# O metodo tambem pode ser chamado dentro de um sinal da fisica.
		_rescue_area.set_deferred("monitoring", enabled)


func _create_rescue_area() -> void:
	var original: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if original == null or original.shape == null:
		push_warning("Aliado sem CollisionShape2D: nao ha forma para detectar o resgate.")
		return
	_rescue_area = Area2D.new()
	_rescue_area.name = "RescueArea"
	_rescue_area.collision_layer = 0
	_rescue_area.collision_mask = 2
	var sensor_shape := CollisionShape2D.new()
	sensor_shape.shape = original.shape.duplicate() as Shape2D
	sensor_shape.transform = original.transform
	_rescue_area.add_child(sensor_shape)
	add_child(_rescue_area)
	_rescue_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _slot >= 0 or not body.is_in_group("player"):
		return
	follow_player(body)


func _physics_process(delta: float) -> void:
	_clock += delta
	if _slot < 0 or not is_instance_valid(_player):
		velocity = Vector2.ZERO
		_play("idle")
		return
	if _player.has_method("is_dead") and bool(_player.call("is_dead")):
		velocity = Vector2.ZERO
		_jump_queue.clear()
		_play("idle")
		return
	if not _player.has_method("get_follow_sample"):
		return
	var result: Dictionary = _player.call("get_follow_sample", _slot)
	if result.is_empty():
		return
	# A trilha so escolhe para onde andar. A altura nunca e copiada/teleportada.
	var target: Vector2 = result["position"]
	var walking_speed: float = float(_player.get("speed"))
	var maximum_speed: float = walking_speed * 1.25 if is_on_floor() else walking_speed
	velocity.x = clampf((target.x - global_position.x) / delta, -maximum_speed, maximum_speed)
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0
	_apply_pending_jump(walking_speed)
	_help_reach_landing(walking_speed, target.x, delta)
	move_and_slide()
	if _sprite == null:
		return
	if absf(velocity.x) > 0.1:
		_sprite.flip_h = velocity.x < 0.0
	if not is_on_floor():
		if velocity.y > 0.0:
			_play("falling", "fall", "jump")
		else:
			_play("jump", "idle")
	elif bool(result.get("ducking", false)):
		_play("duck", "idle")
	elif absf(velocity.x) > 0.1:
		_play("walk", "idle")
	else:
		_play("idle")


func _disconnect_jump_signal() -> void:
	if is_instance_valid(_player) and _player.has_signal("jumped"):
		if _player.is_connected("jumped", _on_player_jumped):
			_player.disconnect("jumped", _on_player_jumped)
	if is_instance_valid(_player) and _player.has_signal("landed"):
		if _player.is_connected("landed", _on_player_landed):
			_player.disconnect("landed", _on_player_landed)


func _on_player_jumped(launch_position: Vector2, vertical_speed: float, horizontal_speed: float, jump_number: int, flight_id: int) -> void:
	_jump_queue.append({
		"time": _clock,
		"position": launch_position,
		"vertical_speed": vertical_speed,
		"horizontal_speed": horizontal_speed,
		"number": jump_number,
		"flight": flight_id,
	})


func _on_player_landed(landing_position: Vector2, flight_id: int) -> void:
	_landings[flight_id] = landing_position
	# Os ultimos aliados ainda podem estar no salto anterior de Mush.
	for previous: int in _landings.keys():
		if previous < flight_id - 8:
			_landings.erase(previous)


func _apply_pending_jump(walking_speed: float) -> void:
	if _jump_queue.is_empty():
		return
	var jump: Dictionary = _jump_queue[0]
	var elapsed: float = _clock - float(jump["time"])
	var launch: Vector2 = jump["position"]
	var ready: bool = false
	if int(jump["number"]) > 1:
		# O segundo impulso conserva o intervalo do pulo duplo de Mush.
		ready = elapsed + 0.0001 >= _jump_lag
	elif absf(float(jump["horizontal_speed"])) < 0.1:
		# Pular parado nao faz a fila andar ate o x do jogador.
		ready = elapsed + 0.0001 >= jump_stagger * float(_slot + 1)
	else:
		var travel_delay: float = float(_player.get("ally_spacing")) * float(_slot + 1) / maxf(walking_speed, 1.0)
		var precise_launch: bool = _needs_launch_point(jump)
		var toward_launch: float = signf(float(jump["horizontal_speed"]))
		if precise_launch and (launch.x - global_position.x) * toward_launch > 2.0:
			# Mesmo que Mush ja tenha parado do outro lado, atravessar exige
			# chegar a borda correta; o atraso nao substitui esse deslocamento.
			velocity.x = toward_launch * walking_speed
		# Perto de um precipicio, decolar do mesmo lugar evita pular cedo demais.
		# Se Mush parar antes desse ponto, a fila ainda pula sem ficar esperando.
		ready = absf(global_position.x - launch.x) <= 2.0 or (not precise_launch and elapsed >= travel_delay + 0.15)
	if not ready:
		return
	if int(jump["number"]) == 1:
		_jump_lag = elapsed
		_takeoff_y = global_position.y
		_active_flight = int(jump["flight"])
		_active_jump = jump
	velocity.y = float(jump["vertical_speed"])
	_jump_queue.pop_front()


func _help_reach_landing(walking_speed: float, formation_x: float, delta: float) -> void:
	if _active_flight < 0:
		return
	var shape: CollisionShape2D = $CollisionShape2D
	var foot_y: float = shape.position.y + shape.shape.get_rect().end.y
	var landing: Vector2 = _landings.get(_active_flight, Vector2(_player.global_position.x, _takeoff_y))
	if not _active_jump.is_empty() and _needs_launch_point(_active_jump):
		# Numa travessia, o alvo da fila pode ficar do lado anterior do buraco.
		# O curso deste voo permanece no pouso gravado, inclusive durante a subida.
		if not is_on_floor() or velocity.y < 0.0 or not _has_landing_support(global_position.x, landing.y, foot_y):
			velocity.x = clampf((landing.x - global_position.x) / delta, -walking_speed, walking_speed)
			return
		if not _can_walk_back_to_formation(formation_x, landing, foot_y):
			# Ja no destino, aguardar a fila abrir em vez de voltar para o vao.
			# Terminar de entrar na plataforma evita oscilar na quina da capsula.
			velocity.x = clampf((landing.x - global_position.x) / delta, -walking_speed, walking_speed)
			return
	if is_on_floor() or velocity.y <= 0.0:
		return
	var landing_y: float = landing.y + foot_y + 6.0
	var from: Vector2 = global_position + Vector2(0, foot_y - 2.0)
	if from.y >= landing_y:
		return
	var ray := PhysicsRayQueryParameters2D.create(from, Vector2(from.x, landing_y), 1, [get_rid()])
	if get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
		# Se o espaco normal da fila ainda esta sobre o vao, continuar ate a
		# plataforma em velocidade normal, em vez de cair ou saltar de posicao.
		var remaining: float = landing.x - global_position.x
		if absf(remaining) > 2.0:
			velocity.x = signf(remaining) * walking_speed


func _has_landing_support(x: float, landing_y: float, foot_y: float) -> bool:
	var from := Vector2(x, landing_y - 2.0)
	var ray := PhysicsRayQueryParameters2D.create(from, Vector2(x, landing_y + foot_y + 8.0), 1, [get_rid()])
	return not get_world_2d().direct_space_state.intersect_ray(ray).is_empty()


func _can_walk_back_to_formation(formation_x: float, landing: Vector2, foot_y: float) -> bool:
	# O alvo pode estar sobre o chao da margem oposta: verificar somente o
	# ponto final nao basta. Todo o trecho de volta precisa ter apoio.
	var steps: int = maxi(1, ceili(absf(landing.x - formation_x) / 8.0))
	for step: int in range(steps + 1):
		var x: float = lerpf(landing.x, formation_x, float(step) / float(steps))
		if not _has_landing_support(x, landing.y, foot_y):
			return false
	return true


func _needs_launch_point(jump: Dictionary) -> bool:
	if jump.has("precise_launch"):
		return bool(jump["precise_launch"])
	var flight: int = int(jump["flight"])
	if not _landings.has(flight):
		return false
	var landing: Vector2 = _landings[flight]
	var launch: Vector2 = jump["position"]
	if absf(landing.y - launch.y) > 8.0:
		jump["precise_launch"] = true
		return true
	var shape: CollisionShape2D = $CollisionShape2D
	var foot_y: float = shape.position.y + shape.shape.get_rect().end.y
	var steps: int = maxi(1, ceili(absf(landing.x - launch.x) / 8.0))
	for step: int in range(1, steps + 1):
		var x: float = lerpf(launch.x, landing.x, float(step) / float(steps))
		var from := Vector2(x, launch.y + foot_y - 3.0)
		var ray := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 10), 1, [get_rid()])
		ray.hit_from_inside = true
		if get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			jump["precise_launch"] = true
			return true
	jump["precise_launch"] = false
	return false


func _play(animation: StringName, fallback: StringName = &"idle", last_fallback: StringName = &"idle") -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var chosen: StringName = animation
	if not _sprite.sprite_frames.has_animation(chosen):
		chosen = fallback
	if not _sprite.sprite_frames.has_animation(chosen):
		chosen = last_fallback
	if _sprite.sprite_frames.has_animation(chosen) and _sprite.animation != chosen:
		_sprite.play(chosen)
	elif _sprite.sprite_frames.has_animation(chosen) and not _sprite.is_playing():
		_sprite.play(chosen)
