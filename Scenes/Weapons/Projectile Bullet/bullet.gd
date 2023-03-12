extends RigidBody3D
"""
	Prupose: Defines behavoir for weapon projectiles.
"""
var damage:float = 0
var speed:float = 0 
var shoot:bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	set_as_top_level(true)

func set_damage(damage:float):
	self.damage = damage

func set_speed(speed:float):
	self.speed = speed
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if shoot:
		apply_impulse(-transform.basis.z, transform.basis.z * speed)

func _on_area_3d_body_entered(body):
	if body.is_in_group("Enemy") or body.is_in_group("Player"):
		body.take_damage(damage)
	queue_free()
