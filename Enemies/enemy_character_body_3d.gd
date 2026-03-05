extends CharacterBody3D

@export var speed: float = 3.0
@export var start_position: Vector3 = Vector3.ZERO
@export var wander_radius: float = 5.0
@export var wander_timer: float = 2.0
@export var max_health: int = 10

var health: int
var target_position: Vector3
var time_until_next_wander: float = 1.0


func _ready():
	health = max_health
	pick_new_target()


func _physics_process(delta):
	if time_until_next_wander <= 0:
		pick_new_target()
	else:
		time_until_next_wander -= delta

	var direction = (target_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()


func pick_new_target():
	var random_offset = Vector3(
		randf_range(-1, 1) * wander_radius,
		0,
		randf_range(-1, 1) * wander_radius
	)
	target_position = start_position + random_offset
	time_until_next_wander = wander_timer


func take_damage(amount: int) -> void:
	health -= amount
	print("Enemy took damage. Health:", health)

	var mesh = $MeshInstance3D
	if mesh and mesh.material_override:
		mesh.material_override.albedo_color = Color(1, 0.4, 0.4)

	if health <= 0:
		die()


func die() -> void:
	print("Enemy died")
	queue_free()
