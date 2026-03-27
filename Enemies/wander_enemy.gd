extends EnemyBase
class_name WanderEnemy

@export var start_position: Vector3 = Vector3.ZERO
@export var model_path: NodePath
@export var attack_origin_path: NodePath
@export var lightning_attack_path: NodePath
@export var lightning_interval_min: float = 3.0
@export var lightning_interval_max: float = 5.0
@export var player_face_radius: float = 8.0

var target_position: Vector3
var time_until_next_wander: float = 0.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var time_until_next_lightning: float = 0.0
var player_target: Node3D
var is_alerted_to_player: bool = false

@onready var model: Node3D = get_node_or_null(model_path) as Node3D
@onready var attack_origin: Node3D = get_node_or_null(attack_origin_path) as Node3D
@onready var lightning_attack: Attack = get_node_or_null(lightning_attack_path) as Attack


func _on_enemy_ready() -> void:
	if start_position == Vector3.ZERO:
		start_position = global_position
	player_target = get_tree().current_scene.get_node_or_null("Player") as Node3D
	_configure_lightning_attack()
	_reset_lightning_timer()
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

		_update_model_facing(direction, delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		_update_model_facing(Vector3.ZERO, delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	_update_attack_targeting()
	_process_lightning_attack(delta)
	move_and_slide()


func pick_new_target() -> void:
	var random_offset := Vector3(
		randf_range(-1.0, 1.0) * stats.wander_radius,
		0.0,
		randf_range(-1.0, 1.0) * stats.wander_radius
	)

	target_position = start_position + random_offset
	time_until_next_wander = stats.wander_timer


func _configure_lightning_attack() -> void:
	if lightning_attack == null or attack_origin == null:
		return

	lightning_attack.origin_node = attack_origin
	lightning_attack.direction_node = attack_origin


func _process_lightning_attack(delta: float) -> void:
	if lightning_attack == null or attack_origin == null:
		return

	time_until_next_lightning -= delta
	if time_until_next_lightning > 0.0:
		return

	if player_target == null:
		player_target = get_tree().current_scene.get_node_or_null("Player") as Node3D

	if player_target != null:
		lightning_attack.execute(self)

	_reset_lightning_timer()


func _update_attack_targeting() -> void:
	if attack_origin == null:
		return

	if player_target == null:
		player_target = get_tree().current_scene.get_node_or_null("Player") as Node3D

	if player_target == null:
		return

	var target_position_3d := player_target.global_position + Vector3.UP * 1.0
	attack_origin.look_at(target_position_3d, Vector3.UP, true)


func _reset_lightning_timer() -> void:
	time_until_next_lightning = randf_range(
		min(lightning_interval_min, lightning_interval_max),
		max(lightning_interval_min, lightning_interval_max)
	)


func _update_model_facing(wander_direction: Vector3, delta: float) -> void:
	if model == null:
		return

	var facing_direction := wander_direction
	if _should_face_player():
		var to_player := player_target.global_position - global_position
		to_player.y = 0.0
		if to_player.length() > 0.001:
			facing_direction = to_player.normalized()

	if facing_direction.length() <= 0.001:
		return

	var target_angle := atan2(facing_direction.x, facing_direction.z)
	model.rotation.y = lerp_angle(model.rotation.y, target_angle, 5.0 * delta)


func _should_face_player() -> bool:
	if player_target == null:
		player_target = get_tree().current_scene.get_node_or_null("Player") as Node3D

	if player_target == null:
		return false

	if is_alerted_to_player:
		return true

	return global_position.distance_to(player_target.global_position) <= player_face_radius


func _on_enemy_damaged(_amount: float, _damage_type: Attack.DamageType) -> void:
	is_alerted_to_player = true
