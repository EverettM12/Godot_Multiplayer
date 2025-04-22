extends ColorRect

@onready var text: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/FPS
@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var play_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Resume
@onready var quit_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Quit

	
func unpause():
	animator.play("Unpause")
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func pause():
	animator.play("Pause")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	


func _ready() -> void:
	play_button.pressed.connect(unpause)
	quit_button.pressed.connect(pause)


func _process(_delta):
	text.text = "FPS: %d" % Engine.get_frames_per_second()


func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
