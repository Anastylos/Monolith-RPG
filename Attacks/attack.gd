extends Node3D
class_name Attack

@export_group("Attack Settings")
@export var attack_range: float = 3.0
@export var cooldown: float = 0.3

@export_group("Damage")
@export var initial_damage: float = 3.0
@export var sustained_damage_per_second: float = 0.0
@export var lingering_damage_per_second: float = 0.0
@export var lingering_duration: float = 0.0
@export var lingering_falloff: float = 1.0
@export var damage_tick_rate: float = 0.2

@export_group("Raycast Sources")
@export var origin_node: Node3D
@export var direction_node: Node3D

@export_group("Collision")
@export var collide_with_areas: bool = true
@export var collide_with_bodies: bool = true

@export var damage_groups: Array[String] = []

var _cooldown_left: float = 0.0

func _physics_process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left -= delta


func can_attack() -> bool:
	return _cooldown_left <= 0.0


func execute(owner: Node3D) -> bool:
	if not can_attack():
		return false

	if origin_node == null or direction_node == null:
		push_warning("Attack is missing origin_node or direction_node.")
		return false

	var hit := _raycast(owner)
	if hit.is_empty():
		_cooldown_left = cooldown
		return false

	_apply_hit(hit)
	_cooldown_left = cooldown
	return true


func _raycast(owner: Node3D) -> Dictionary:
	var space_state := get_world_3d().direct_space_state
	var from := origin_node.global_position
	var to := from + (-direction_node.global_transform.basis.z) * attack_range

	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.collide_with_areas = collide_with_areas
	params.collide_with_bodies = collide_with_bodies
	params.exclude = [owner]

	return space_state.intersect_ray(params)


func _apply_hit(hit: Dictionary) -> void:
	var collider = hit.get("collider")
	if collider == null:
		return

	var damage_type := get_damage_type()

	if collider.has_method("take_typed_damage"):
		collider.take_typed_damage(initial_damage, damage_type)
	elif collider.has_method("take_damage"):
		collider.take_damage(initial_damage)

	if sustained_damage_per_second > 0.0 and collider.has_method("apply_sustained_damage"):
		collider.apply_sustained_damage(
			sustained_damage_per_second,
			damage_tick_rate,
			damage_type
		)

	if lingering_damage_per_second > 0.0 and lingering_duration > 0.0 and collider.has_method("apply_lingering_damage"):
		collider.apply_lingering_damage(
			lingering_damage_per_second,
			lingering_duration,
			lingering_falloff,
			damage_tick_rate,
			damage_type
		)


func get_damage_type() -> DamageTypes.Type:
	if "fire" in damage_groups:
		return DamageTypes.Type.FIRE
	elif "ice" in damage_groups:
		return DamageTypes.Type.ICE
	elif "lightning" in damage_groups:
		return DamageTypes.Type.LIGHTNING
	else:
		return DamageTypes.Type.SOUL
