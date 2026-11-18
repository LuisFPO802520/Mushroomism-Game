# Origem: elaborado com ajuda de IA (OpenAI/Codex).
# Guarda o caminho horizontal da fila. Altura e pouso pertencem a fisica do aliado.
extends RefCounted

var spacing: float = 28.0
var follow_speed: float = 100.0

const MAX_FOLLOWERS: int = 5
const MAX_SAMPLES: int = 2048
const JOIN_SPEED: float = 140.0
const EPSILON: float = 0.0001

var _points: Array[Dictionary] = []
var _followers: Array[Dictionary] = []
var _distance: float = 0.0
var _tick: int = 0
var _step_seconds: float = 1.0 / 60.0
var _head_step: float = 0.0
var _last_position: Vector2 = Vector2.ZERO


## O respawn/troca de mapa precisa de uma origem nova, sem ligar os dois lugares.
## Limpa tambem os slots: o player deve recadastrar sua party depois deste reset.
func reset(position: Vector2, velocity: Vector2 = Vector2.ZERO, facing_left: bool = false, grounded: bool = true, ducking: bool = false) -> void:
	_points.clear()
	_followers.clear()
	_distance = 0.0
	_tick = 0
	_head_step = 0.0
	_last_position = position
	record(position, velocity, facing_left, grounded, ducking)


func record(position: Vector2, velocity: Vector2, facing_left: bool, grounded: bool, ducking: bool) -> void:
	_tick += 1
	_step_seconds = Engine.time_scale / float(maxi(Engine.physics_ticks_per_second, 1))
	# Subir nao deve consumir a distancia entre os personagens da fila.
	_head_step = 0.0 if _points.is_empty() else absf(position.x - _last_position.x)
	_last_position = position
	if not _points.is_empty() and _head_step > EPSILON:
		_distance += _head_step
	var point: Dictionary = {
		"position": position,
		"velocity": velocity,
		"facing_left": facing_left,
		"grounded": grounded,
		"ducking": ducking,
		"distance": _distance,
	}
	if _points.is_empty():
		_points.append(point)
		# Pode haver um contato no primeiro passo, antes da primeira amostra.
		for follower in _followers:
			follower["entry_position"] = position
			follower["entry_distance"] = _distance
			follower["cursor"] = _distance
	elif _head_step <= EPSILON:
		# Esperar parado nao cria milhares de copias do mesmo ponto.
		_points[_points.size() - 1] = point
	else:
		_points.append(point)
	_trim_history()


func add_follower(position: Vector2) -> int:
	if _followers.size() >= MAX_FOLLOWERS:
		return -1
	var entry: Vector2 = position if _points.is_empty() else _points.back()["position"]
	var initial: Dictionary = {
		"position": position,
		"velocity": Vector2.ZERO,
		"facing_left": false,
		"grounded": true,
		"ducking": false,
		"waiting": true,
		"joining": false,
	}
	_followers.append({
		"entry_position": entry,
		"entry_distance": _distance,
		"cursor": _distance,
		"joined": false,
		"last_tick": -1,
		"output": initial,
	})
	# Slots comecam em zero; o primeiro aliado fica a uma distancia spacing.
	return _followers.size() - 1


func sample(slot: int) -> Dictionary:
	if slot < 0 or slot >= _followers.size():
		return {}
	var follower: Dictionary = _followers[slot]
	if int(follower["last_tick"]) == _tick:
		return follower["output"].duplicate()
	if _points.is_empty():
		return _hold(slot)

	# Atualizar o antecessor primeiro evita depender da ordem dos nos na cena.
	var predecessor: Dictionary = {}
	if slot > 0:
		sample(slot - 1)
		predecessor = _followers[slot - 1]
	var gap: float = maxf(spacing, 1.0)
	var target: float = _distance - float(slot + 1) * gap
	if not predecessor.is_empty():
		if not bool(predecessor["joined"]):
			return _hold(slot)
		target = minf(target, float(predecessor["cursor"]) - gap)

	if not bool(follower["joined"]):
		var entry_distance: float = float(follower["entry_distance"])
		if target < entry_distance - EPSILON:
			return _hold(slot)
		if entry_distance < float(_points.front()["distance"]) - EPSILON:
			return _hold(slot)
		return _join(slot)

	var cursor: float = float(follower["cursor"])
	if cursor < float(_points.front()["distance"]) - EPSILON:
		# Protecao de buffer: conservar a posicao em vez de saltar para outro lugar.
		return _hold(slot)
	target = maxf(cursor, target)
	# Nao existe recuperacao acelerada ate o pouso: o aliado pula por conta propria.
	var next_cursor: float = minf(target, cursor + follow_speed * 1.25 * _step_seconds)
	next_cursor = minf(next_cursor, _distance)
	var result: Dictionary = _point_at(next_cursor)
	result["waiting"] = next_cursor <= cursor + EPSILON
	result["joining"] = false
	if bool(result["waiting"]):
		result["velocity"] = Vector2.ZERO
	follower["cursor"] = next_cursor
	return _save(slot, result)


func _join(slot: int) -> Dictionary:
	var follower: Dictionary = _followers[slot]
	var old: Dictionary = follower["output"]
	var from: Vector2 = old["position"]
	var entry: Vector2 = follower["entry_position"]
	# Este conector usa apenas a pequena distancia do contato, nao um ponto
	# antigo atras da fila. O ponto de entrada fica fixo enquanto ele se aproxima.
	var position: Vector2 = from.move_toward(entry, JOIN_SPEED * _step_seconds)
	var movement: Vector2 = position - from
	var result: Dictionary = old.duplicate()
	result["position"] = position
	result["velocity"] = movement / _step_seconds if _step_seconds > EPSILON else Vector2.ZERO
	result["waiting"] = movement.length_squared() <= EPSILON * EPSILON
	result["joining"] = true
	if absf(movement.x) > EPSILON:
		result["facing_left"] = movement.x < 0.0
	if position.distance_to(entry) <= EPSILON:
		follower["joined"] = true
		result = _point_at(float(follower["entry_distance"]))
		result["waiting"] = movement.length_squared() <= EPSILON * EPSILON
		result["joining"] = false
	return _save(slot, result)


func _hold(slot: int) -> Dictionary:
	var result: Dictionary = _followers[slot]["output"].duplicate()
	result["velocity"] = Vector2.ZERO
	result["waiting"] = true
	result["joining"] = false
	return _save(slot, result)


func _save(slot: int, result: Dictionary) -> Dictionary:
	result.erase("distance")
	_followers[slot]["last_tick"] = _tick
	_followers[slot]["output"] = result
	return result.duplicate()


func _point_at(distance: float) -> Dictionary:
	var left_index: int = _points.size() - 1
	while left_index > 0 and float(_points[left_index]["distance"]) > distance:
		left_index -= 1
	var left: Dictionary = _points[left_index]
	if left_index == _points.size() - 1 or distance <= float(left["distance"]) + EPSILON:
		return left.duplicate()
	var right: Dictionary = _points[left_index + 1]
	var span: float = float(right["distance"]) - float(left["distance"])
	var weight: float = clampf((distance - float(left["distance"])) / maxf(span, EPSILON), 0.0, 1.0)
	var result: Dictionary = left.duplicate() if weight < 0.5 else right.duplicate()
	var left_position: Vector2 = left["position"]
	var right_position: Vector2 = right["position"]
	var left_velocity: Vector2 = left["velocity"]
	var right_velocity: Vector2 = right["velocity"]
	result["position"] = left_position.lerp(right_position, weight)
	result["velocity"] = left_velocity.lerp(right_velocity, weight)
	# Entre um ponto no ar e um ponto de pouso, ainda estamos no ar.
	result["grounded"] = bool(left["grounded"]) and bool(right["grounded"]) if weight < 1.0 - EPSILON else bool(right["grounded"])
	return result


func _trim_history() -> void:
	if _followers.is_empty():
		while _points.size() > 2:
			_points.pop_front()
		return
	var oldest_needed: float = _distance
	for follower in _followers:
		oldest_needed = minf(oldest_needed, float(follower["cursor"]))
	var keep_from: float = oldest_needed - maxf(spacing, 1.0)
	# Guardar tambem o ponto anterior permite interpolar o primeiro segmento.
	while _points.size() > 2 and float(_points[1]["distance"]) < keep_from:
		_points.pop_front()
	while _points.size() > MAX_SAMPLES:
		_points.pop_front()
