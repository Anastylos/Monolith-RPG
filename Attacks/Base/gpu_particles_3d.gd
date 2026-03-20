extends GPUParticles3D

@onready var character: Node3D = get_parent()  # Angenommen, der Partikeleffekt ist ein Kind deines Charakters

func _process(delta: float) -> void:
	if character != null:
		# Berechne die Blickrichtung des Charakters (z. B. in Richtung der Maus oder eines Ziels)
		var target_position: Vector3
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			# Falls die Maus eingefangen ist, verwende die Blickrichtung des Charakters
			target_position = character.global_transform.origin + character.global_transform.basis.z * -1
		else:
			# Falls die Maus sichtbar ist, verwende die Mausposition
			var camera = get_viewport().get_camera_3d()
			var mouse_pos = get_viewport().get_mouse_position()
			var from = camera.project_ray_origin(mouse_pos)
			var to = from + camera.project_ray_normal(mouse_pos) * 1000
			var space_state = get_world_3d().direct_space_state
			var ray_query = PhysicsRayQueryParameters3D.create(from, to)
			var ray_result = space_state.intersect_ray(ray_query)
			if not ray_result.is_empty():
				target_position = ray_result.position
			else:
				target_position = to

		# Berechne die Richtung von deinem Charakter zum Ziel
		var direction = (target_position - global_position).normalized()

		# Setze die Emissionsrichtung der Partikel
		emission_shape = GPUParticles3D.EMISSION_SHAPE_DIRECTION_POINT
		direction_vector = direction
