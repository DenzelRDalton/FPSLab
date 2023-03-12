extends Actor

"""
	Todo:
"""
@export_category("Player Physics and Movement")
@export var air_accel:float = 0.08
@export var air_max_speed:float = 1
@export var jump_velocity:float = 4.5
@export var air_decel:float = 0.25
@export var mouse_sensitivity:float = 0.03
@export var crouch_movement_speed:float = 3.5
@export var crouch_position_change_speed:float = 15
@onready var crouch_head_pos:Node3D  = $CrouchCameraPos
@onready var head_ray_cast:RayCast3D = $Head/HeadRayCast
var crouch_height:float = 1
var normal_height:float = 0
var crouch_head_change:float = 1
var head_base_position = 0

func die():
	get_tree().reload_current_scene()

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	normal_height = body_collider.shape.height
	head_base_position = head.position
	weapon_list = weapon_holder.get_children()
	weapon = weapon_list[current_weapon]
	

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity)) # Rotate player based on mouse x
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity)) # Rotate player head based on mouse y
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89)) # Clamp head rotation on x axis

func _physics_process(delta):
	if Input.is_action_just_pressed("switch_weapon"):
		switch_weapon()
	
	
	# fire with current weapon
	if Input.is_action_pressed("fire") and aim_cast.is_colliding() and time_to_next_fire < Time.get_ticks_msec():
		weapon.fire_weapon(aim_cast.get_collision_point())
		calculate_next_fire()
		
	
	var head_bonked:bool = false # Bool to track if we are hitting our head on something
	
	# Add the gravity
	apply_gravity(delta)
	
	# Handle Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	
	# Check for hitting our head
	if head_ray_cast.is_colliding():
		head_bonked = true 
		velocity.y = -2 # Push down the player a bit to keep from getting stuck on ceiling
	
	# Get the input direction and handle the movement/deceleration
	# Input.get_vector returns a vector 2 of our direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	# transform.basis is an identity matrix 
	# Normalize the direction value to so we don't move faster on the diagonal
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if is_on_floor():
			if velocity.length() > max_speed: # velocity.length() gives use the magnitued of that vector
				# Move in our direction at the max speed
				velocity.x = direction.x * max_speed
				velocity.z = direction.z * max_speed
			else:
				# Move in our direction increment by ground_accel
				velocity.x += direction.x * ground_accel
				velocity.z += direction.z * ground_accel
		else:
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
	# Move and slide uses the velocity vector we calculated, also it accounts for frame rate by default
	push_rigidbody()
	move_and_slide()
