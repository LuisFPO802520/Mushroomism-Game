extends Area2D

@export var next_level = ""
## Marque para novas áreas de água/lava. As áreas antigas chamadas Fall já
## são reconhecidas, mantendo o mapa e suas colisões como você os montou.
@export var is_hazard: bool = false

var _changing_scene: bool = false


func _ready() -> void:
	if is_hazard or name == &"Fall":
		collision_mask |= 16

# Called when the node enters the scene tree for the first time.
func _on_body_entered(body: Node2D) -> void:
	if _changing_scene:
		return
	if body.has_method("is_dead") and body.call("is_dead"):
		return
	if is_hazard or name == &"Fall":
		if (body.is_in_group("player") or body.is_in_group("rescued_allies")) and body.has_method("fall_into_hazard"):
			body.call_deferred("fall_into_hazard")
		return
	if not body.is_in_group("player"):
		return
	_changing_scene = true
	call_deferred("load_next_scene")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func load_next_scene():
	var path: String = "res://scene/" + next_level + ".tscn"
	var session: Node = get_node_or_null("/root/GameSession")
	if session != null:
		session.call("change_level", path)
	else:
		get_tree().change_scene_to_file(path)
