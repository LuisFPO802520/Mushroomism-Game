# Origem: elaborado com ajuda de IA (OpenAI/Codex).
extends Node
## Autoload: guarda vida e aliados enquanto os mapas são trocados.

const FIRST_LEVEL: String = "res://scene/map1.tscn"
const GAME_OVER_SCENE: String = "res://ui/game_over.tscn"

var health: int = 5
var max_health: int = 5
var total_falls: int = 0
var party_scenes: Array[String] = []
var party_health: Dictionary = {}
var _party_max_health: Dictionary = {}
var current_level: String = ""
var transitioning: bool = false
var game_over: Control

var _entry_party: Array[String] = []
var _player: Node2D
var _started: bool = false
var _menu_layer: CanvasLayer
var _hud_layer: CanvasLayer
var _hud: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func attach_player(player: Node2D) -> void:
	# Cenas de teste e prefabs isolados continuam funcionando sem uma partida.
	if not is_instance_valid(player) or player.is_queued_for_deletion():
		return
	var level: Node = get_tree().current_scene
	if level == null or not level.scene_file_path.begins_with("res://scene/"):
		return
	if not level.is_ancestor_of(player):
		return
	_player = player
	current_level = level.scene_file_path
	max_health = int(player.get("max_health"))
	if not _started:
		health = max_health
		_started = true
	_entry_party = party_scenes.duplicate()
	transitioning = false
	player.connect("health_changed", _on_health_changed)
	player.connect("ally_rescued", _on_ally_rescued)
	player.connect("fell_into_hazard", _on_fell_into_hazard)
	player.call("restore_session", self, health)
	_restore_party(player, level)
	_create_hud()
	_update_hud()


func _restore_party(player: Node2D, level: Node) -> void:
	# Não deixar outra cópia de Moss esperando ao voltar ao mapa onde ele estava.
	for ally: Node in get_tree().get_nodes_in_group("allies"):
		if level.is_ancestor_of(ally) and ally.has_method("get_party_scene_path"):
			var path: String = ally.call("get_party_scene_path")
			if path in party_scenes:
				ally.call("discard_as_duplicate")
	for path: String in party_scenes.duplicate():
		var packed := load(path) as PackedScene
		if packed == null:
			continue
		var ally := packed.instantiate() as Node2D
		level.add_child(ally)
		ally.global_position = player.global_position
		var saved_health: int = int(party_health.get(path, ally.get("max_health")))
		ally.call("restore_health", saved_health)
		if saved_health <= 0:
			show_game_over.call_deferred(player, "%s perdeu todas as vidas." % path.get_file().get_basename().capitalize())
			continue
		ally.call("follow_player", player)


func _on_health_changed(current: int, maximum: int) -> void:
	health = current
	max_health = maximum
	_update_hud()


func _on_ally_rescued(ally: Node2D, _total: int) -> void:
	if ally.has_method("get_party_scene_path"):
		var path: String = ally.call("get_party_scene_path")
		if not path.is_empty() and path not in party_scenes:
			party_scenes.append(path)
		if not path.is_empty() and ally.has_signal("health_changed"):
			party_health[path] = int(ally.get("health"))
			_party_max_health[path] = int(ally.get("max_health"))
			var receiver: Callable = _on_ally_health_changed.bind(ally)
			if not ally.is_connected("health_changed", receiver):
				ally.connect("health_changed", receiver)
	_update_hud()


func _on_ally_health_changed(current: int, maximum: int, ally: Node2D) -> void:
	if not is_instance_valid(ally):
		return
	var path: String = ally.call("get_party_scene_path")
	if path in party_scenes:
		party_health[path] = current
		_party_max_health[path] = maximum
		if current <= 0:
			# O respawn de Mush pode limpar a fila antes do aviso adiado do aliado.
			var ally_name: String = path.get_file().get_basename().capitalize()
			show_game_over.call_deferred(_player, "%s perdeu todas as vidas. Tente resgatar a equipe novamente." % ally_name)


func _on_fell_into_hazard() -> void:
	total_falls += 1


func change_level(path: String) -> void:
	if transitioning or is_instance_valid(game_over):
		return
	for ally_health: int in party_health.values():
		if ally_health <= 0:
			return
	if not ResourceLoader.exists(path):
		push_error("Mapa não encontrado: " + path)
		return
	transitioning = true
	_change_scene.call_deferred(path)


func _change_scene(path: String) -> void:
	var error: Error = get_tree().change_scene_to_file(path)
	if error != OK:
		transitioning = false
		push_error("Não foi possível abrir o mapa: " + path)


func show_game_over(player: Node2D, reason: String = "") -> void:
	if player != _player or transitioning or is_instance_valid(game_over):
		return
	var packed := load(GAME_OVER_SCENE) as PackedScene
	if packed == null:
		return
	_menu_layer = CanvasLayer.new()
	_menu_layer.name = "GameOverLayer"
	_menu_layer.layer = 100
	_menu_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_menu_layer)
	game_over = packed.instantiate() as Control
	game_over.connect("retry_requested", retry_level)
	game_over.connect("restart_requested", restart_journey)
	_menu_layer.add_child(game_over)
	game_over.call("setup", total_falls, party_scenes.size(), reason)
	get_tree().paused = true


func retry_level() -> void:
	if transitioning:
		return
	# Um retry recupera a equipe que entrou nesta fase. Os novos resgates
	# feitos nela voltam aos seus locais para a tentativa seguinte.
	party_scenes = _entry_party.duplicate()
	party_health.clear()
	for path: String in party_scenes:
		party_health[path] = int(_party_max_health.get(path, 5))
	health = max_health
	total_falls = 0
	_close_game_over()
	change_level(current_level if not current_level.is_empty() else FIRST_LEVEL)


func restart_journey() -> void:
	if transitioning:
		return
	party_scenes.clear()
	party_health.clear()
	_party_max_health.clear()
	_entry_party.clear()
	health = max_health
	total_falls = 0
	_started = false
	_close_game_over()
	change_level(FIRST_LEVEL)


func _close_game_over() -> void:
	get_tree().paused = false
	if is_instance_valid(_menu_layer):
		_menu_layer.queue_free()
	game_over = null
	_menu_layer = null


func _create_hud() -> void:
	if is_instance_valid(_hud_layer):
		return
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "VidaEAliados"
	_hud_layer.layer = 30
	add_child(_hud_layer)
	var packed := load("res://ui/hud.tscn") as PackedScene
	_hud = packed.instantiate() as Control
	_hud_layer.add_child(_hud)


func _update_hud() -> void:
	if is_instance_valid(_hud):
		_hud.call("update_values", health, party_scenes.size())
