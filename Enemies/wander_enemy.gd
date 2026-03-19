extends EnemyBase
class_name WanderEnemy

@export var start_position: Vector3 = Vector3.ZERO
@export var model_path: NodePath

var target_position: Vector3
var time_until_next_wander: float = 0.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var model: Node3D = get_node_or_null(model_path) as Node3D


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
	to_target.y = 0.0

	if to_target.length() > 0.1:
		var direction := to_target.normalized()
		velocity.x = direction.x * stats.speed
		velocity.z = direction.z * stats.speed

		if model != null:
			var target_angle := atan2(direction.x, direction.z)
			model.rotation.y = lerp_angle(model.rotation.y, target_angle, 5.0 * delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()


func pick_new_target() -> void:
	var random_offset := Vector3(
		randf_range(-1.0, 1.0) * stats.wander_radius,
		0.0,
		randf_range(-1.0, 1.0) * stats.wander_radius
	)

	target_position = start_position + random_offset
	time_until_next_wander = stats.wander_timer
