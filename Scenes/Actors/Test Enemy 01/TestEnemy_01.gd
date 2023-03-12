extends Actor
"""
	Purpose: Lays out the behavoir for this enemy type.
	
	Handles: Path finding, attacking behavoir.
"""
var target = null
const TURN_SPEED = 200
enum {IDLE, ATTACK, CHASE_ATTACK, RUN}
var current_state:int = IDLE
@onready var rotation_helper:Node3D = $RotationHelper
@onready var nav_agent:NavigationAgent3D = $NavigationAgent3D

func _ready():
	# Initialize weapon information
	weapon_list = weapon_holder.get_children()
	weapon = weapon_list[current_weapon_index]

func attack():
	if time_to_next_fire < Time.get_ticks_msec():
		# Tell weapon to fire and calculate the next fire time
		weapon.fire_weapon(target.global_transform.origin)
		calculate_next_fire()

func look_at_target(delta:float):
	# Change the rotation helper variable and weapon_holder to face the target
	rotation_helper.look_at(target.global_transform.origin, Vector3.UP)
	weapon_holder.look_at(target.global_transform.origin, Vector3.UP)
	# Rotate along the y axis by TURN_SPEED
	rotate_y(deg_to_rad(rotation_helper.rotation.y * TURN_SPEED * delta)) # Delta is used to negate frame rate differences

func _physics_process(delta):
	match current_state:
		IDLE:
			# Not implemented yet
			pass
		ATTACK:
			look_at_target(delta)
			attack()
		CHASE_ATTACK:
			# Look at the target and attack
			look_at_target(delta)
			attack()
			# Calculate move position in relation to the target
			nav_agent.target_position = target.global_transform.origin
			var next_location = nav_agent.get_next_path_position()
			var position_change = (target.global_transform.origin - next_location)
			var new_velocity = Vector3(position_change.x, 0, position_change.z).normalized() * ground_accel
			velocity = new_velocity
		RUN:
			# Not implemented yet
			pass
	# Apply gravity and move enemey
	apply_gravity(delta)
	move_and_slide()

# Detection area is a sphere arround the enemy
func _on_detection_area_body_entered(body):
	if body.is_in_group("Player"):
		current_state = CHASE_ATTACK
		target = body

func _on_detection_area_body_exited(body):
	if body.is_in_group("Player"):
		current_state = IDLE
		velocity = Vector3.ZERO
		target = null

# Stopper area is a sphere arround the enemy
func _on_stopper_area_body_entered(body):
	if body.is_in_group("Player"):
		velocity = Vector3.ZERO
		current_state = ATTACK


func _on_stopper_area_body_exited(body):
	if body.is_in_group("Player"):
		current_state = CHASE_ATTACK

func die():
	queue_free()
