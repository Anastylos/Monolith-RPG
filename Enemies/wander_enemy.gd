extends EnemyBase
class_name WanderEnemy

@export var start_position: Vector3 = Vector3.ZERO

var target_position: Vector3
var time_until_next_wander: float = 0.0

func _on_enemy_ready() -> void:
	if start_position == Vector3.ZERO:
		start_position = global_position
	pick_new_target()


func _update_enemy(delta: float) -> void:
	if time_until_next_wander <= 0.0:
		pick_new_target()
	else:
		time_until_next_wander -= delta

	var to_target := target_position - global_position

	if to_target.length() > 0.1:
		var direction := to_target.normalized()
		velocity.x = direction.x * stats.speed
		velocity.z = direction.z * stats.speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()


func pick_new_target() -> void:
	var random_offset := Vector3(
		randf_range(-1.0, 1.0) * stats.wander_radius,
		0.0,
		randf_range(-1.0, 1.0) * stats.wander_radius
	)

	target_position = start_position + random_offset
	time_until_next_wander = stats.wander_timer
