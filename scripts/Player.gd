extends CharacterBody3D

#player nodes
@export var head : Node
@onready var neck : Node = $Neck
@onready var standing_collision : CollisionShape3D = $standing_collision
@onready var crouching_collision : CollisionShape3D = $crouching_collision
@onready var ray_cast_3d : RayCast3D = $RayCast3D
@onready var camera_3d : Camera3D = $Neck/Head/Camera3D

#speed variables
@export var current_speed : float = 5.0
@export var walking_speed : float = 5.0
@export var sprinting_speed : float = 8.0
@export var crouching_speed : float = 3.0

#states
var walking = false
var sprinting = false
var crouching = false
var free_looking = false
var sliding = false

#movement vars
@export var jump_velocity : float = 4.5
var def_head_pos_y : float
var crouching_depth : float = -0.5
var lerp_speed : float = 10.0
var free_look_tilt_amount : float = 8

#input variables
var direction : Vector3
@export var mouse_sens : float = 0.25

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	def_head_pos_y = head.position.y
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	#mouse looking
	if event is InputEventMouseMotion:
		if free_looking:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			neck.rotation.y = clamp(neck.rotation.y,deg_to_rad(-120), deg_to_rad(120) )
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x,deg_to_rad(-89), deg_to_rad(89) )

func _physics_process(delta):
	#handle movement state
	
	#crouching
	if Input.is_action_pressed("crouch"):
		current_speed = crouching_speed
		head.position.y = lerp(head.position.y, def_head_pos_y + crouching_depth, delta *lerp_speed)
		standing_collision.disabled = true
		crouching_collision.disabled = false
		walking = false
		sprinting = false
		crouching = true
		
	#standing
	elif !ray_cast_3d.is_colliding():
		standing_collision.disabled = false
		crouching_collision.disabled = true
		head.position.y = lerp(head.position.y, def_head_pos_y , delta * lerp_speed)
		if Input.is_action_pressed("sprint"):
			#sprinting
			current_speed = sprinting_speed
			walking = false
			sprinting = true
			crouching = false
		else:
			#walking
			current_speed = walking_speed
			walking = true
			sprinting = false
			crouching = false
	
	#handle free looking
	if Input.is_action_pressed("free_look"):
		free_looking = true
		camera_3d.rotation.z = -deg_to_rad(neck.rotation.y * free_look_tilt_amount)
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * lerp_speed)
		camera_3d.rotation.z = lerp(camera_3d.rotation.z, 0.0, delta * lerp_speed)
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
