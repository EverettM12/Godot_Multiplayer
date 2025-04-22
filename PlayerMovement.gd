extends CharacterBody3D

# ===== MULTIPLAY =====
@onready var mpp: MPPlayer = get_parent()

# ===== NODES =====
@onready var head: Node3D = $Head
@onready var Camera: Camera3D = $Head/Camera3D
@onready var animation: AnimationPlayer = $AuxScene/AnimationPlayer
@onready var timer: Timer = $Timer

# ===== MOVEMENT SETTINGS =====
@export var WALK_SPEED = 3.0
@export var CROUCH_SPEED = 1.5
@export var SPRINT_SPEED = 4.5 
@export var JUMP_VELOCITY = 4.8
@export var acceleration := 7.0
@export var air_acceleration := 3.0
var speed = WALK_SPEED

# ===== CAMERA SETTINGS =====
@export var sensitivity: float = 0.07
@export var invert_y: bool = false
var rotation_x: float = 0.0

# ===== CAMERA BOB & SHAKE =====
@export var BOB_FREQ = 2.4
@export var BOB_AMP = 0.08
@export var SHAKE_INTENSITY_WALK = 0.0005
@export var SHAKE_INTENSITY_SPRINT = 0.01
@export var shake_amount = 0.0
@export var shake_target = Vector3.ZERO
@export var shake_offset = Vector3.ZERO
var rng = RandomNumberGenerator.new()
var t_bob = 0.0

# ===== FOV =====
@export var normal_fov: float = 70.0
@export var sprint_fov: float = 85.0

# ===== GRAVITY =====
var gravity = 9.8

# ===== READY =====
func _ready():
	mpp.player_ready.connect(_on_player_ready)
	mpp.handshake_ready.connect(_on_handshake_ready)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_player_ready():
	print("Player's now ready!")
	if mpp.mpc.mode != mpp.mpc.PlayMode.Swap:
		Camera.current = true
	global_position = Vector3(mpp.player_index * 4, 1, 0)

func _on_handshake_ready(_hs):
	print(mpp.player_index)


# ===== INPUT =====
func _input(event):
	if event is InputEventMouseMotion:
		var mouse_x = -event.relative.x * sensitivity
		var mouse_y = event.relative.y * sensitivity * (1 if invert_y else -1)
		rotate_y(deg_to_rad(mouse_x))
		rotation_x = clamp(rotation_x + mouse_y, -90, 90)
		Camera.rotation_degrees.x = rotation_x

# ===== PHYSICS =====
func _physics_process(delta):
	if !mpp.is_ready:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir = Vector3.ZERO
	if Input.is_action_pressed(mpp.ma("left")):
		input_dir.x -= 1
	if Input.is_action_pressed(mpp.ma("right")):
		input_dir.x += 1
	if Input.is_action_pressed(mpp.ma("forward")):
		input_dir.z -= 1
	if Input.is_action_pressed(mpp.ma("back")):
		input_dir.z += 1
	input_dir = input_dir.normalized()

	var jump = Input.is_action_just_pressed(mpp.ma("jump")) and is_on_floor()
	var is_sprinting = Input.is_action_pressed(mpp.ma("Sprint")) and Input.is_action_pressed(mpp.ma("forward"))
	var target_speed = SPRINT_SPEED if is_sprinting else WALK_SPEED
	shake_amount = SHAKE_INTENSITY_SPRINT if is_sprinting else SHAKE_INTENSITY_WALK

	var cam_basis = head.global_transform.basis
	var move_dir = (cam_basis.x * input_dir.x + cam_basis.z * input_dir.z).normalized()
	move_dir.y = 0

	if is_on_floor():
		speed = lerp(speed, target_speed, delta * acceleration)
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
	else:
		velocity.x = lerp(velocity.x, move_dir.x * speed, delta * air_acceleration)
		velocity.z = lerp(velocity.z, move_dir.z * speed, delta * air_acceleration)

	if jump:
		velocity.y = JUMP_VELOCITY
		move_and_slide()
		return

	if is_sprinting:
		play_animation_once("Running(2)")
		move_and_slide()
		return

	if input_dir.length() > 0:
		play_animation_once("DrunkWalk(1)")
		move_and_slide()
		return

	play_animation_once("OldManIdle(1)")
	move_and_slide()




	adjust_fov(delta)
	handle_camera_effects(delta)

func play_animation_once(name: String):
	if animation.current_animation != name:
		animation.play(name)


# ===== FOV EFFECT =====
func adjust_fov(delta):
	var target_fov = sprint_fov if Input.is_action_pressed(mpp.ma("Sprint")) else normal_fov
	Camera.fov = lerp(Camera.fov, target_fov, delta * 8.0)

# ===== CAMERA SHAKE & BOB =====
func handle_camera_effects(delta):
	t_bob += delta * velocity.length() * float(is_on_floor())
	Camera.transform.origin = _headbob(t_bob) + _bodycam_shake(delta)

func _headbob(time) -> Vector3:
	return Vector3(
		cos(time * BOB_FREQ / 2) * BOB_AMP,
		sin(time * BOB_FREQ) * BOB_AMP,
		0
	)

func _bodycam_shake(delta: float) -> Vector3:
	if velocity.length() > 0 and is_on_floor():
		shake_target.x = rng.randf_range(-shake_amount, shake_amount)
		shake_target.y = rng.randf_range(-shake_amount, shake_amount)
		shake_offset = lerp(shake_offset, shake_target, delta * 5.0)
	else:
		shake_offset = lerp(shake_offset, Vector3.ZERO, delta * 5.0)
	return shake_offset

var is_chat_open: bool = false

# ===== PROCESS & PAUSE =====
func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("Pause"):
		$PauseMenu.pause()
		
	if Input.is_action_just_pressed("Chat"):
		if is_chat_open:
			$ChatOverlay.chatclosed()
			is_chat_open = false
		else:
			$ChatOverlay.chatopened()
			is_chat_open = true
		

func _on_Timer_timeout():
	animation.play("TwistDance(1)")
