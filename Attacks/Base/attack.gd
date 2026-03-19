extends Node3D
class_name Attack

enum DamageType {
	NONE,
	FIRE,
	ICE,
	LIGHTNING,
	SOUL
}

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
@export var damage_type: DamageType = DamageType.NONE

@export_group("Raycast Sources")
@export var origin_node: Node3D
@export var direction_node: Node3D

@export_group("Collision")
@export var collide_with_areas: bool = true
@export var collide_with_bodies: bool = true

var _cooldown_left: float = 0.0


func _ready() -> void:
	damage_type = _get_default_damage_type()


func _get_default_damage_type() -> DamageType:
	return DamageType.NONE

func _physics_process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left -= delta


func can_attack() -> bool:
	return _cooldown_left <= 0.0


func execute(caster: Node3D) -> bool:
	if not can_attack():
		return false

	if not _validate_nodes():
		return false

	var hits := _get_hits(caster)
	if hits.is_empty():
		_cooldown_left = cooldown
		return false

	_process_hits(hits)
	_cooldown_left = cooldown
	return true


func _validate_nodes() -> bool:
	if origin_node == null or direction_node == null:
		push_warning("%s is missing origin_node or direction_node." % name)
		return false
	return true


func _get_hits(caster: Node3D) -> Array:
	var hit := _raycast(caster)
	if hit.is_empty():
		return []
	return [hit]


func _process_hits(hits: Array) -> void:
	for hit in hits:
		_apply_hit(hit)


func _raycast(caster: Node3D) -> Dictionary:
	var space_state := get_world_3d().direct_space_state
	var from := origin_node.global_position
	var to := from + (-direction_node.global_transform.basis.z) * attack_range

	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.collide_with_areas = collide_with_areas
	params.collide_with_bodies = collide_with_bodies
	params.exclude = [caster]

	return space_state.intersect_ray(params)


func _apply_hit(hit: Dictionary) -> void:
	var collider = hit.get("collider")
	if collider == null:
		return

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
	print("Applying damage type: ", damage_type, " from ", name)
