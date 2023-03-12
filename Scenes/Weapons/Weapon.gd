extends Area3D
class_name Weapon
"""
	TODO:
		Incorperate fire rates for weapons
		Write comments you idoit
"""
@export_category("Weapon stats")
@export var damage:float = 10
@export var type:Globals.weapon_types
@export var fire_rate:float = 0.5
@export_category("Projectile information")
@export var projectile:Resource = null
@export var projectile_speed:float = 10
@onready var muzzle:Node3D = $Muzzle


func fire_weapon(collision_point:Vector3):
	if type == Globals.weapon_types.hitscan:
		hitscan_fire(collision_point)
	elif type == Globals.weapon_types.projectile:
		projectile_fire(collision_point)

func projectile_fire(collision_point:Vector3):
	if projectile:
		var bullet = projectile.instantiate()
		bullet.set_damage(damage)
		bullet.set_speed(projectile_speed)
		muzzle.add_child(bullet)
		bullet.look_at(collision_point, Vector3.UP)
		bullet.shoot = true

func hitscan_fire(collision_point:Vector3):
	var bullet = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.from = muzzle.global_transform.origin
	params.to = collision_point
	params.exclude = []
	params.collision_mask = 1
	var collision = bullet.intersect_ray(params)
	if collision:
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
