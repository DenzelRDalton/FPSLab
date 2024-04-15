extends Actor
"""
	Purpose: Lays out the behavoir for this enemy type.
	
	Handles: Path finding, attacking behavoir.
	
	
	Behavoir description:
		If the player is in line of sight attack set alert status to true and attack.
		If the player is not in line of sight but alert status is true persue player, untile in line of sight.
		If the player is not in line of sight and alter status is false patrol.
		If health gets too low run from player.
"""
var target = null
var alert:bool = false
const TURN_SPEED = 200
enum {IDLE, ATTACK, CHASE, RUN}
var current_state:int = IDLE
@onready var rotation_helper:Node3D = $RotationHelper
@onready var nav_agent:NavigationAgent3D = $NavigationAgent3D
@onready var detection_cast = $Head/DetectionArea/DetectionRaycast
@export var path_waypoint_list:Array = []

func _ready() -> void:
	# Initialize weapon information
	weapon_list = weapon_holder.get_children()
	weapon = weapon_list[current_weapon_index]

func check_line_of_sight() -> bool:
	if target:
		detection_cast.look_at(target.global_transform.origin)
	else:
		return false
	
	if detection_cast.is_colliding() and detection_cast.get_collider() == target:
		return true
	
	return false

func attack() -> void:
	if not check_line_of_sight():
		current_state = CHASE
		return
	
	if time_to_next_fire < Time.get_ticks_msec():
		# Tell weapon to fire and calculate the next fire time
		weapon.fire_weapon(target.global_transform.origin)
		calculate_next_fire()

func look_at_target(delta:float) -> void:
	# Change the rotation helper variable and weapon_holder to face the target
	rotation_helper.look_at(target.global_transform.origin, Vector3.UP)
	weapon_holder.look_at(target.global_transform.origin, Vector3.UP)
	# Rotate along the y axis by TURN_SPEED
	rotate_y(deg_to_rad(rotation_helper.rotation.y * TURN_SPEED * delta)) # Delta is used to negate frame rate differences

func chase_target() -> void:
	
	if check_line_of_sight():
		current_state = ATTACK
		velocity = Vector3.ZERO
		return
	
	# Calculate move position in relation to the target
	nav_agent.target_position = target.global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	var position_change = global_position.direction_to(next_location)
	var new_velocity = Vector3(position_change.x, 0, position_change.z).normalized() * ground_accel
	velocity = new_velocity
	
func _physics_process(delta) -> void:
	match current_state:
		IDLE:
			# Not implemented yet
			pass
		ATTACK:
			look_at_target(delta)
			attack()
		CHASE:
			look_at_target(delta)
			chase_target()
		RUN:
			# Not implemented yet
			pass
	# Apply gravity and move enemey
	apply_gravity(delta)
	move_and_slide()

# Detection cone for the enemy
func _on_detection_area_body_entered(body) -> void:
	if body.is_in_group("Player"):
		current_state = ATTACK
		target = body
		alert = true

func die() -> void:
	queue_free()
