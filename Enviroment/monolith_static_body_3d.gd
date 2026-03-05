extends StaticBody3D

@export var enemy_scene: PackedScene
@export var spawn_count: int = 3
@export var spawn_radius: float = 6.0


func interact(_player: Node = null) -> void:
	if enemy_scene == null:
		push_error("Enemy scene not assigned")
		return

	for i in range(spawn_count):
		var enemy = enemy_scene.instantiate()

		get_tree().current_scene.add_child(enemy)

		var offset = Vector3(
			randf_range(-1.0, 1.0),
			0.0,
			randf_range(-1.0, 1.0)
		).normalized() * randf_range(2.0, spawn_radius)

		enemy.global_position = global_position + offset

		if enemy.has_method("set_start_position"):
			enemy.set_start_position(global_position)

		print("Spawned enemy")
