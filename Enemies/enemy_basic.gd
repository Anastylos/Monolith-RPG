extends Node2D

@export var speed: float = 2.0
@export var monolith_position: Vector3 = Vector3.ZERO
@export var wander_radius: float = 5.0
@export var wander_timer: float = 2.0

var target_position: Vector3
var time_until_next_wander: float = 0.0

func _ready():
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
	# Generate a random point within wander_radius of the monolith
	var random_offset = Vector3(
		randf_range(-1, 1) * wander_radius,
		0,
		randf_range(-1, 1) * wander_radius
	)
	target_position = monolith_position + random_offset
	time_until_next_wander = wander_timer
