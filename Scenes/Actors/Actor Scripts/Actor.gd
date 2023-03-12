extends CharacterBody3D
class_name Actor

"""
PURPOSE: Base class for all actors (players/enemies) in the game.
		 Holds important information and functions for every actor in the game.
"""
@onready var head = $Head
@onready var body_collider:CollisionShape3D = $BodyCollision
@onready var physics_bumper:ShapeCast3D = $PhysicsBumper
@onready var aim_cast:RayCast3D = $Head/AimRayCast
@onready var weapon_holder:Node3D = $Head/WeaponHolder
@export_category("Actor Physics and Movement")
@export var push_force:float = 0.5
@export var ground_accel:float = 2.5
@export var ground_decel:float = 5.0
@export var max_speed:float = 7
@export_category("Stats")
@export var health:int = 200
var weapon_list:Array = []
var current_weapon:int = 0
var weapon:Area3D = null
var time_to_next_fire:float = Time.get_ticks_msec()

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func calculate_next_fire():
	time_to_next_fire =  Time.get_ticks_msec() + weapon.get_fire_rate()

func switch_weapon():
	weapon.visible = false # Disable visbility for current weapon
	weapon.process_mode = Node.PROCESS_MODE_DISABLED # Disable current weapon
	current_weapon += 1 # Increment weapon index
	if current_weapon >= len(weapon_list):
		current_weapon = 0 # If weapon index is out of range set it back to 0
	weapon = weapon_list[current_weapon] # Get the new weapon at the new weapon index
	weapon.process_mode = Node.PROCESS_MODE_INHERIT # Enable the new weapon
	weapon.visible = true # Make it visible

func apply_gravity(delta:float):
	if not is_on_floor():
		velocity.y -= gravity * delta

func push_rigidbody():
	for i in physics_bumper.get_collision_count():
		var collider = physics_bumper.get_collider(i)
		if collider is RigidBody3D:
			collider.apply_central_impulse(-physics_bumper.get_collision_normal(i) * push_force)

func take_damage(damage:int):
	health -= damage
	if health <= 0:
		die()

func die():
	print("Died")
