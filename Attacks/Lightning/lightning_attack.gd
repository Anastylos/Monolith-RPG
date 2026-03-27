extends Attack
class_name LightningAttack


@export_group("Lightning")
@export var beam_count: int = 4
@export var beam_spread: float = 0.12
@export var beam_duration: float = 0.08
@export var beam_scene: PackedScene
@export var target_node: Node3D
@export var target_offset: Vector3 = Vector3.ZERO

func _get_default_damage_type() -> DamageType:
	return DamageType.LIGHTNING

func _get_hits(caster: Node3D) -> Array:
	return _multi_beam_raycast(caster)


func _process_hits(hits: Array) -> void:
	var already_hit := {}

	for hit in hits:
		_spawn_beam_visual(hit)

		var collider = hit.get("collider")
		if collider == null:
			continue

		if already_hit.has(collider):
			continue

		_apply_hit(hit)
		already_hit[collider] = true


func _multi_beam_raycast(caster: Node3D) -> Array:
	var results: Array = []
	var space_state := get_world_3d().direct_space_state
	var from := origin_node.global_position

	var forward := -direction_node.global_transform.basis.z
	if target_node != null:
		var target_position := target_node.global_position + target_offset
		var to_target := target_position - from
		if to_target.length() > 0.001:
			forward = to_target.normalized()

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
