extends CharacterBody3D

#player nodes
@export var head : Node
@onready var neck : Node = $Neck
@onready var eyes : Node= $Neck/Head/Eyes

@onready var standing_collision : CollisionShape3D = $standing_collision
@onready var crouching_collision : CollisionShape3D = $crouching_collision
@onready var ray_cast_3d : RayCast3D = $RayCast3D
@onready var camera_3d : Camera3D = $Neck/Head/Eyes/Camera3D
@onready var animation_player : AnimationPlayer = $Neck/Head/Eyes/AnimationPlayer

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

#slide vars
var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 10.0

#head bobbings vars
const head_bobbing_sprinting_speed : float = 22.0
const head_bobbing_walking_speed : float = 14.0
const head_bobbing_crouching_speed : float = 10.0

const head_bobbing_sprinting_intensity : float = 0.09
const head_bobbing_walking_intensity : float = 0.06
const head_bobbing_crouching_intensity : float = 0.07

var head_bobbing_current_intencity = 0.0
var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0

#movement vars
@export var jump_velocity : float = 4.5
var def_head_pos_y : float
var crouching_depth : float = -0.5
var lerp_speed : float = 10.0
var air_lerp_speed : float = 3.0
var free_look_tilt_amount : float = 8

var last_velocity = Vector2.ZERO
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
	#getting movement input
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	#handle movement state
	
	#crouching
	if Input.is_action_pressed("crouch") or sliding:
		current_speed = lerp(current_speed, crouching_speed, delta * lerp_speed)
		head.position.y = lerp(head.position.y, def_head_pos_y + crouching_depth, delta *lerp_speed)
		standing_collision.disabled = true
		crouching_collision.disabled = false
		
		#slide begin logic
		if sprinting and input_dir != Vector2.ZERO:
			sliding = true
			free_looking = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
			print("sliding")
			
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
			current_speed = lerp(current_speed, sprinting_speed, delta * lerp_speed)
			walking = false
			sprinting = true
			crouching = false
		else:
			#walking
			current_speed = lerp(current_speed, walking_speed, delta * lerp_speed)
			walking = true
			sprinting = false
			crouching = false
	
	#handle free looking
	if Input.is_action_pressed("free_look") or sliding:
		free_looking = true
		if sliding:
			eyes.rotation.z = lerp(eyes.rotation.z, -deg_to_rad(7.0), delta * lerp_speed)
		else:
			eyes.rotation.z = -deg_to_rad(neck.rotation.y * free_look_tilt_amount)
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * lerp_speed)
		eyes.rotation.z = lerp(eyes.rotation.z, 0.0, delta * lerp_speed)
	
	#handle sliding
	
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
			free_looking = false
			print("slide end")
	
	#handle headbob
	if sprinting:
		head_bobbing_current_intencity = head_bobbing_sprinting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed * delta
	elif walking:
		head_bobbing_current_intencity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed * delta
	elif crouching:
		head_bobbing_current_intencity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed * delta
	
	if is_on_floor() and !sliding and input_dir != Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index/2) + 0.5
		
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y * (head_bobbing_current_intencity/2.0), delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x * head_bobbing_current_intencity, delta * lerp_speed)
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, delta * lerp_speed)		
		eyes.position.x = lerp(eyes.position.x, 0.0, delta * lerp_speed)
		
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		sliding = false
		animation_player.play("Jump")
		
	#handle landing
	if is_on_floor():
		if last_velocity.y < -10.0:
			animation_player.play("roll")
			print(last_velocity.y)
		elif last_velocity.y < -4.0:
			animation_player.play("landing")
			print(last_velocity.y)
			
			

	if is_on_floor():
		direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
	else:
		if input_dir != Vector2.ZERO:
			direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * air_lerp_speed)
		
	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
		current_speed =  (slide_timer + 0.1) * slide_speed

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	last_velocity = velocity
	move_and_slide()
