extends CharacterBody3D
class_name Actor

"""
PURPOSE: Base class for all actors (players/enemies) in the game.
		 Holds important information and functions for every actor in the game.
		
		Every actor in the game is kinematic, can hold weapons, and is impacted
		by gravity.
		
		Every actor also requires a certain Node structure each actor must have:
			RootNode/Head:Node3D
			RootNode/BodyCollision:CollisionShape3D
			RootNode/PhysicsBumber:ShapeCast3D
			RootNode/Head:Node3D/Node3D:Raycst3D
"""
@onready var head:Node3D = $Head # Spatial container for other objects in Actor
@onready var body_collider:CollisionShape3D = $BodyCollision # Collider
@onready var physics_bumper:ShapeCast3D = $PhysicsBumper # Definition of physics area
@onready var weapon_holder:Node3D = $Head/WeaponHolder # Spatial container for weapon nodes
@export_category("Actor Physics and Movement")
@export var push_force:float = 0.5 # How much rigidbodies are impacted by physics_bumber
@export var ground_accel:float = 2.5 # How fast the actor accelerates on the ground
@export var ground_decel:float = 5.0 # How fast 
@export var max_speed:float = 7
@export_category("Stats")
@export var health:int = 200
var weapon_list:Array = []
var current_weapon_index:int = 0
var weapon:Area3D = null
var time_to_next_fire:float = Time.get_ticks_msec()

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func calculate_next_fire():
	time_to_next_fire =  Time.get_ticks_msec() + weapon.get_fire_rate()

func switch_weapon():
	weapon.visible = false # Disable visbility for current weapon
	weapon.process_mode = Node.PROCESS_MODE_DISABLED # Disable current weapon
	current_weapon_index += 1 # Increment weapon index
	if current_weapon_index >= len(weapon_list):
		current_weapon_index = 0 # If weapon index is out of range set it back to 0
	weapon = weapon_list[current_weapon_index] # Get the new weapon at the new weapon index
	weapon.process_mode = Node.PROCESS_MODE_INHERIT # Enable the new weapon
	weapon.visible = true # Make it visible

func apply_gravity(delta:float):
	if not is_on_floor():
		velocity.y -= gravity * delta

func push_rigidbody():
	# Iterate through the collisions in physics_bumber and push everything away
	for i in physics_bumper.get_collision_count():
		var collider = physics_bumper.get_collider(i)
		if collider is RigidBody3D:
			collider.apply_central_impulse(-physics_bumper.get_collision_normal(i) * push_force)

func take_damage(damage:int):
	health -= damage
	if health <= 0:
		die()

func die():
	# Default behavoir of die function which can be overwritten in subclasses
	print("Died")
