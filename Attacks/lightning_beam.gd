extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var _life: float = 0.08

func setup_beam(from: Vector3, to: Vector3, duration: float) -> void:
	_life = duration

	global_position = from
	look_at(to, Vector3.UP)

	var distance := from.distance_to(to)
	mesh_instance.position = Vector3(0, 0, -distance * 0.5)
	mesh_instance.scale = Vector3(0.06, 0.06, distance)

func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
