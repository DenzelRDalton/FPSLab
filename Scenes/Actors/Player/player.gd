extends Actor

"""
	Purpose: This script controls the player actor and houses information relevant to player 
	specific actions. 
	
	This script handles moving, jumping, crouching.
	It also polls for user input for: moving, jumping, crouching, weapon switching, 
	and weapon firing.
	
	Inherits from Actor.
"""
@export_category("Player Physics and Movement")
@export var air_accel:float = 0.08
@export var jump_velocity:float = 4.5
@export var air_decel:float = 0.25
@export var mouse_sensitivity:float = 0.03
@export var crouch_movement_speed:float = 3.5
@export var crouch_position_change_speed:float = 15 # How fast the player moves into crouching position
# References to child nodes
@onready var crouch_head_pos:Node3D  = $CrouchCameraPos 
@onready var head_ray_cast:RayCast3D = $Head/HeadRayCast
@onready var aim_cast:RayCast3D = $Head/AimRayCast # Aim in the middle of the camera
var crouch_height:float = 1
var normal_height:float = 0
var crouch_head_change:float = 1
var head_base_position = 0

func die():
	# If die is called restart the scene
	get_tree().reload_current_scene() 

func _ready():
	# Lock mouse cursor to the game
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 
	# Set the normal height for the player
	normal_height = body_collider.shape.height 
	# Set the head position for the player
	head_base_position = head.position 
	# Initialize weapon list by getting child nodes of weapon holder,
	# then set weapon to current_weapon_index
	weapon_list = weapon_holder.get_children() 
	weapon = weapon_list[current_weapon_index]
	

func _input(event):
	if event is InputEventMouseMotion:
		# Rotate player based on mouse x
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity)) 
		# Rotate player head based on mouse y
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity)) 
		# Clamp head rotation on x axis
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89)) 

func _physics_process(delta):
	# Poll for weapon switching
	if Input.is_action_just_pressed("switch_weapon"):
		switch_weapon()
	
	
	# Poll for weapon firing
	# Check to make sure the aim_cast is colliding with an object, and that we are allowed to fire
	if Input.is_action_pressed("fire") and aim_cast.is_colliding() and time_to_next_fire < Time.get_ticks_msec():
		# Tell the weapon to fire, pass the collision point as input
		weapon.fire_weapon(aim_cast.get_collision_point())
		# Calculate when we are allowed to fire again
		calculate_next_fire()
		
	# Bool to track if we are hitting our head on something
	var head_bonked:bool = false 
	
	# Apply the gravity
	apply_gravity(delta)
	
	# Handle Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	
	# Check for hitting our head
	if head_ray_cast.is_colliding():
		head_bonked = true
		# Push down the player a bit to keep from getting stuck on ceiling 
		velocity.y = -2 
	
	# Get the input direction and handle the movement/deceleration
	# Input.get_vector returns a vector 2 of our direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# transform.basis is the matrix that defines the players directions in 3d space
	# Normalize the direction value to so we don't move faster on the diagonal
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if is_on_floor():
			# velocity.length() gives use the magnitued of that vector,
			# check that magnitued to make sure we are not going faster than
			# max speed
			if velocity.length() >= max_speed: 
				# If we are
				# Move in our direction at the max speed
				velocity.x = direction.x * max_speed
				velocity.z = direction.z * max_speed
			else:
				# Move in our direction increment by ground_accel
				velocity.x += direction.x * ground_accel
				velocity.z += direction.z * ground_accel
		else:
			# If we are in the air, our direction will be influenced by air_accel
			velocity.x += direction.x * air_accel
			velocity.z += direction.z * air_accel
	elif is_on_floor():
		# Decelerate by ground_decel
		velocity.x = move_toward(velocity.x, 0, ground_decel)
		velocity.z = move_toward(velocity.z, 0, ground_decel)
	else:
		# Decelerate by air_decel
		velocity.x = move_toward(velocity.x, 0, air_decel)
		velocity.z = move_toward(velocity.z, 0, air_decel)
	
	if Input.is_action_pressed("crouch"):
		if is_on_floor():
			# Change movement speed if we are grounded to crouch speed
			velocity.x = direction.x * crouch_movement_speed
			velocity.z = direction.z * crouch_movement_speed
		# Change body_collider and head to crouch shape and position respectively
		body_collider.shape.height -= crouch_position_change_speed * delta # * delta for frame rate independance
		head.position.y -= crouch_position_change_speed * delta # * delta for frame rate independance
	elif not head_bonked:
		# Change body_collider and head back to normal unless we are hitting our head
		body_collider.shape.height += crouch_position_change_speed * delta
		head.position.y += crouch_position_change_speed * delta
	# Clamp body shape and head position based on max and min values
	body_collider.shape.height = clamp(body_collider.shape.height, crouch_height, normal_height)
	head.position.y = clamp(head.position.y, crouch_head_pos.position.y, head_base_position.y)
	
	# Make our kinematic character interact with physics objects 
	push_rigidbody()
	# Move and slide uses the velocity vector we calculated, also it accounts for frame rate by default
	move_and_slide()
