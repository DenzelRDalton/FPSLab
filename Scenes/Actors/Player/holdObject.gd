extends Node3D
"""
	TODO:
"""
@onready var object_detector:RayCast3D = $"../InteractibleDetector"
const HOLDING_FORCE:int = 4500
var held_object = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if Input.is_action_just_pressed("interact"):
		if held_object:
			held_object.gravity_scale = 1
			held_object.lock_rotation = false
			held_object.linear_damp = 0
			held_object = null
		elif object_detector.get_collider():
			held_object = object_detector.get_collider()
			held_object.gravity_scale = 0
			held_object.lock_rotation = true
			held_object.linear_damp = 10
	if held_object and global_transform.origin.distance_to(held_object.global_transform.origin) > 0.1:
		var moveDir = Vector3(global_transform.origin - held_object.global_transform.origin)
		held_object.apply_central_force(moveDir * HOLDING_FORCE * delta)
