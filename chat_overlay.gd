extends Control

@onready var message: LineEdit = %Message
@onready var Send: Button = %Send
@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var name_field: LineEdit = $MarginContainer/HBoxContainer/Chat/VBoxContainer/NameField
@onready var ForbiddenWords = preload("res://scripts/ForbiddenWords.gd")
@onready var PlayersList: ItemList = %PlayersList

var fallback_names = [
	"Unknown Player",
	"Nameless Wanderer",
	"???",
	"Anonymous",
	"Stranger Danger",
	"User404",
	"Spectator",
	"Someone Mysterious",
	"Silent Typist",
	"MissingNo",
	"Encrypted Name",
	"The Void",
	"Some Idiot",
	"Cant Swear silly",
]

func _ready() -> void:
	randomize() # seed the RNG or it'll pick the same thing every time

func is_valid_name(name: String) -> bool:
	var lower_name = name.to_lower()
	for bad_word in ForbiddenWords.LIST:
		if lower_name.find(bad_word) != -1:
			return false
	return true

func get_random_fallback_name() -> String:
	return fallback_names[randi() % fallback_names.size()]

func _on_send_pressed() -> void:
	var msg := message.text.strip_edges()
	var name := name_field.text.strip_edges()

	if msg != "":
		if name == "":
			name = "Unknown Player"
		
		if is_valid_name(name):
			%ChatMessages.append_text(name + ": " + msg + "\n")
			add_name_to_players_list()
		else:
			%ChatMessages.append_text("[Blocked Name]" + ": " + msg + "\n")
		
		message.clear()

func _on_message_text_submitted(new_text: String) -> void:
	var msg := new_text.strip_edges()
	var name := name_field.text.strip_edges()

	if msg != "":
		if name == "" or !is_valid_name(name):
			name = get_random_fallback_name()
		%ChatMessages.append_text(name + ": " + msg + "\n")
		message.clear()

	if name_field.text.strip_edges() == "testing":
		%ChatMessages.append_text("Working" + ": " + msg + "\n")
		message.clear()

func chatopened():
	animator.play("chatopen")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func chatclosed():
	animator.play("chatclosed")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func add_name_to_players_list():
	var name := name_field.text.strip_edges()
	if name == "":
		name = "Unknown Player"

	if not is_valid_name(name):
		print("Blocked inappropriate name attempt: ", name)
		return
	
	if not PlayersList.get_item_count() == 0:
		for i in PlayersList.get_item_count():
			if PlayersList.get_item_text(i).to_lower() == name.to_lower():
				print("Name already in list")
				return
	
	PlayersList.add_item(name)
