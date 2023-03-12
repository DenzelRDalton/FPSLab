extends Area3D
class_name Weapon
"""
	Purpose: Define behavoir for weapons in the game. Houses information for
	both projectile type weapons and hitscan weapons. Also contains stats for the
	weapon the script is attached to.
"""
@export_category("Weapon stats")
@export var damage:float = 10
@export var type:Globals.weapon_types
@export var fire_rate:float = 0.5
@export_category("Projectile information")
@export var projectile:Resource = null
@export var projectile_speed:float = 10
@onready var muzzle:Node3D = $Muzzle # Spatial node for where to fire the weapon from


func fire_weapon(collision_point:Vector3):
	# Check the weapon type and call the corrisponding function
	if type == Globals.weapon_types.hitscan:
		hitscan_fire(collision_point)
	elif type == Globals.weapon_types.projectile:
		projectile_fire(collision_point)

func projectile_fire(collision_point:Vector3):
	# Check to make sure there is a projectile
	if projectile:
		# create a projectile instance
		var bullet = projectile.instantiate()
		# set damage and speed of projectile
		bullet.set_damage(damage)
		bullet.set_speed(projectile_speed)
		# make bullet a child of muzzle for positioning
		muzzle.add_child(bullet)
		# rotate the bullet tward the collision point
		bullet.look_at(collision_point, Vector3.UP)
		# Allow the projectile to fire
		bullet.shoot = true

func hitscan_fire(collision_point:Vector3):
	# In this function we cast an interected ray from the muzzle to the collision point
	# This allows the bullet to collide with things in between the muzzel and the
	# collision point.
	var bullet = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.from = muzzle.global_transform.origin # Where the bullet comes from
	params.to = collision_point # The point of impact
	params.exclude = [] # Collisions to exclude
	params.collision_mask = 1 # Collisions to count
	var collision = bullet.intersect_ray(params) # Our intersected ray
	if collision: # If there was a collison
		var target = collision.collider
		if target.is_in_group("Enemy"):
			target.take_damage(damage)

func get_muzzle():
	return muzzle

func get_damage():
	return damage

func get_type():
	return type

func get_fire_rate():
	return fire_rate
