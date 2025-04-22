extends Area3D

@export var scene_to_load: String = ""



func _on_body_entered(body: Node):
	# Ignore if not server, only server should call load_scene
	if !MPIO.mpc.is_server:
		return
	
	# Check if the body is a player
	if body.is_in_group("player"):
		MPIO.mpc.load_scene(scene_to_load, true)
