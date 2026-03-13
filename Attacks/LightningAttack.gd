extends Attack
class_name LightningAttack

@export_group("Lightning")
@export var beam_count: int = 4
@export var beam_spread: float = 0.12
@export var beam_duration: float = 0.08
@export var beam_scene: PackedScene

func _ready() -> void:
	attack_range = 10.0
	cooldown = 0.05
	initial_damage = 2.0
	sustained_damage_per_second = 12.0
	lingering_damage_per_second = 4.0
	lingering_duration = 1.0
	lingering_falloff = 1.8
	damage_tick_rate = 0.2
	damage_groups = ["lightning"]


func execute(caster: Node3D) -> bool:
	if not can_attack():
		return false

	if origin_node == null or direction_node == null:
		push_warning("LightningAttack is missing origin_node or direction_node.")
		return false

	var hits := _multi_beam_raycast(caster)
	if hits.is_empty():
		_cooldown_left = cooldown
		return false

	var already_hit := {}

	for hit in hits:
		var collider = hit.get("collider")
		if collider == null:
			continue

		_spawn_beam_visual(hit)

		if not already_hit.has(collider):
			_apply_hit(hit)
			already_hit[collider] = true

	_cooldown_left = cooldown
	return true


func _multi_beam_raycast(caster: Node3D) -> Array:
	var results: Array = []
	var space_state := get_world_3d().direct_space_state
	var from := origin_node.global_position

	var forward := -direction_node.global_transform.basis.z
	var right := direction_node.global_transform.basis.x
	var up := direction_node.global_transform.basis.y

	for i in range(beam_count):
		var t := 0.0
		if beam_count > 1:
			t = float(i) / float(beam_count - 1)

		var horizontal_offset := (t - 0.5) * 2.0 * beam_spread
		var vertical_offset := randf_range(-beam_spread * 0.35, beam_spread * 0.35)

		var dir := (forward + right * horizontal_offset + up * vertical_offset).normalized()
		var to := from + dir * attack_range

		var params := PhysicsRayQueryParameters3D.create(from, to)
		params.collide_with_areas = collide_with_areas
		params.collide_with_bodies = collide_with_bodies
		params.exclude = [caster]

		var hit := space_state.intersect_ray(params)

		if hit.is_empty():
			results.append({
				"from": from,
				"to": to,
				"collider": null
			})
		else:
			hit["from"] = from
			hit["to"] = hit["position"]
			results.append(hit)

	return results


func _spawn_beam_visual(hit: Dictionary) -> void:
	if beam_scene == null:
		return

	var beam = beam_scene.instantiate()
	get_tree().current_scene.add_child(beam)

	if beam.has_method("setup_beam"):
		beam.setup_beam(hit["from"], hit["to"], beam_duration)
