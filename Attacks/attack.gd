extends Node3D
class_name Attack

@export_group("Attack Settings")
@export var attack_range: float = 3.0
@export var attack_damage: int = 3
@export var cooldown: float = 0.3

@export_group("Raycast Sources")
@export var origin_node: Node3D
@export var direction_node: Node3D

@export_group("Collision")
@export var collide_with_areas: bool = true
@export var collide_with_bodies: bool = true

var _cooldown_left: float = 0.0

enum DamageType { FIRE, ICE, LIGHTNING, STANDARD }


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

	var space_state := get_world_3d().direct_space_state

	var from := origin_node.global_position
	var to := from + (-direction_node.global_transform.basis.z) * attack_range

	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.collide_with_areas = collide_with_areas
	params.collide_with_bodies = collide_with_bodies
	params.exclude = [owner]

	var hit := space_state.intersect_ray(params)
	if hit.is_empty():
		_cooldown_left = cooldown
		return false

	_apply_hit(hit)

	_cooldown_left = cooldown
	return true


func _apply_hit(hit: Dictionary) -> void:
	var collider = hit.get("collider")
	if collider != null:
		if collider.has_method("take_damage"):
			collider.take_damage(attack_damage)
		if collider != null and collider.has_method("take_damage_type"):
			collider.take_damage_type(get_damage_type())
			
func get_damage_type() -> DamageType:
	print("Groups this attack is in:", get_groups())
	if is_in_group("fire"):
		print("attacking with fire")
		return DamageType.FIRE
	elif is_in_group("ice"):
		print("attacking with ice")
		return DamageType.ICE
	elif is_in_group("lightning"):
		print("attacking with lightning")
		return DamageType.LIGHTNING
	else:
		print("attacking with normal attack")
		return DamageType.STANDARD
