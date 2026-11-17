extends Area2D

@export var next_level = ""

# Called when the node enters the scene tree for the first time.
func _on_body_entered(body: Node2D) -> void:
	 # print ("passou").
	call_deferred("load_next_scene")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func load_next_scene():
	print ("passou")
	get_tree().change_scene_to_file("res://scene/" + next_level + ".tscn")
