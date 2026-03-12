extends CharacterBody3D

@export var speed: float = 3.0
@export var start_position: Vector3 = Vector3.ZERO
@export var wander_radius: float = 5.0
@export var wander_timer: float = 2.0
@export var max_health: int = 10
@export var damage_mesh_path: NodePath

var health: int
var target_position: Vector3
var time_until_next_wander: float = 1.0
var damage_mesh: MeshInstance3D

enum DamageType { FIRE, ICE, LIGHTNING, STANDARD }

func _ready():
	health = max_health
	
	if damage_mesh_path != NodePath():
		damage_mesh = get_node_or_null(damage_mesh_path) as MeshInstance3D
	if damage_mesh == null:
		damage_mesh = find_child("*", true, false) as MeshInstance3D
		
	pick_new_target()


func _physics_process(delta):
	if time_until_next_wander <= 0:
		pick_new_target()
	else:
		time_until_next_wander -= delta

	var direction = (target_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()


func pick_new_target():
	var random_offset = Vector3(
		randf_range(-1, 1) * wander_radius,
		0,
		randf_range(-1, 1) * wander_radius
	)
	target_position = start_position + random_offset
	time_until_next_wander = wander_timer


func take_damage(amount: int, damage_type : DamageType) -> void:
	health -= amount
	print("Enemy took damage. Health:", health)

	if damage_mesh != null:
		if damage_mesh.material_override == null:
			damage_mesh.material_override = StandardMaterial3D.new()
		damage_mesh.material_override.albedo_color = Color(1, 0.4, 0.4)

	if health <= 0:
		die()

	match damage_type:
		DamageType.FIRE:
			add_to_group("fire")
			print("enemy attacked with fire")
		DamageType.ICE:
			add_to_group("ice")
			print("enemy attacked with ice")
		DamageType.LIGHTNING:
			add_to_group("lightning")
			print("enemy attacked with lightning")


func die() -> void:
	print("Enemy died")
	queue_free()
