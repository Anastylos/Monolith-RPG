extends CharacterBody3D
class_name EnemyBase

signal died(enemy: EnemyBase)
signal health_changed(current: float, maximum: float)

@export var stats: EnemyStats
@export var damage_mesh_path: NodePath

var health: float
var damage_mesh: MeshInstance3D

var _sustained_effects: Array[Dictionary] = []
var _lingering_effects: Array[Dictionary] = []

func _ready() -> void:
	_setup_stats()
	_find_damage_mesh()
	_on_enemy_ready()


func _physics_process(delta: float) -> void:
	_process_sustained_effects(delta)
	_process_lingering_effects(delta)
	_update_enemy(delta)


func _setup_stats() -> void:
	if stats == null:
		stats = EnemyStats.new()
	health = stats.max_health


func _find_damage_mesh() -> void:
	if damage_mesh_path != NodePath():
		damage_mesh = get_node_or_null(damage_mesh_path) as MeshInstance3D

	if damage_mesh == null:
		damage_mesh = find_child("*", true, false) as MeshInstance3D


func _on_enemy_ready() -> void:
	pass


func _update_enemy(_delta: float) -> void:
	pass


func take_damage(amount: float) -> void:
	_apply_final_damage(amount)
	_flash_damage()


func take_damage_type(damage_type: DamageTypes.Type) -> void:
	match damage_type:
		DamageTypes.Type.FIRE:
			print("enemy attacked with fire")
		DamageTypes.Type.ICE:
			print("enemy attacked with ice")
		DamageTypes.Type.LIGHTNING:
			print("enemy attacked with lightning")
		DamageTypes.Type.SOUL:
			print("enemy attacked with soul")


func take_typed_damage(amount: float, damage_type: DamageTypes.Type) -> void:
	var final_amount := amount * _get_damage_multiplier(damage_type)
	_apply_final_damage(final_amount)
	take_damage_type(damage_type)
	_flash_damage()


func apply_sustained_damage(dps: float, tick_rate: float, damage_type: DamageTypes.Type) -> void:
	_sustained_effects.append({
		"dps": dps,
		"tick_rate": tick_rate,
		"time_until_tick": tick_rate,
		"damage_type": damage_type
	})


func apply_lingering_damage(
	dps: float,
	duration: float,
	falloff: float,
	tick_rate: float,
	damage_type: DamageTypes.Type
) -> void:
	_lingering_effects.append({
		"base_dps": dps,
		"remaining": duration,
		"duration": duration,
		"falloff": falloff,
		"tick_rate": tick_rate,
		"time_until_tick": tick_rate,
		"damage_type": damage_type
	})


func clear_sustained_damage_of_type(damage_type: DamageTypes.Type) -> void:
	_sustained_effects = _sustained_effects.filter(
		func(effect: Dictionary) -> bool:
			return effect["damage_type"] != damage_type
	)


func _process_sustained_effects(delta: float) -> void:
	for effect in _sustained_effects:
		effect["time_until_tick"] -= delta

		if effect["time_until_tick"] <= 0.0:
			var damage_type: DamageTypes.Type = effect["damage_type"]
			var tick_damage: float = effect["dps"] * effect["tick_rate"]
			take_typed_damage(tick_damage, damage_type)
			effect["time_until_tick"] = effect["tick_rate"]


func _process_lingering_effects(delta: float) -> void:
	var expired: Array[Dictionary] = []

	for effect in _lingering_effects:
		effect["remaining"] -= delta
		effect["time_until_tick"] -= delta

		if effect["time_until_tick"] <= 0.0:
			var progress: float = 1.0 - (effect["remaining"] / effect["duration"])
			var fade_multiplier: float = pow(max(1.0 - progress, 0.0), effect["falloff"])
			var current_dps: float = effect["base_dps"] * fade_multiplier
			var damage_type: DamageTypes.Type = effect["damage_type"]
			var tick_damage: float = current_dps * effect["tick_rate"]

			if tick_damage > 0.0:
				take_typed_damage(tick_damage, damage_type)

			effect["time_until_tick"] = effect["tick_rate"]

		if effect["remaining"] <= 0.0:
			expired.append(effect)

	for effect in expired:
		_lingering_effects.erase(effect)


func _get_damage_multiplier(damage_type: DamageTypes.Type) -> float:
	match damage_type:
		DamageTypes.Type.FIRE:
			return stats.fire_multiplier
		DamageTypes.Type.ICE:
			return stats.ice_multiplier
		DamageTypes.Type.LIGHTNING:
			return stats.lightning_multiplier
		DamageTypes.Type.SOUL:
			return stats.soul_multiplier
		_:
			return 1.0


func _apply_final_damage(amount: float) -> void:
	health -= amount
	health_changed.emit(health, stats.max_health)
	print("Enemy took damage. Health: ", health)

	if health <= 0.0:
		die()


func _flash_damage() -> void:
	if damage_mesh == null:
		return

	if damage_mesh.material_override == null:
		damage_mesh.material_override = StandardMaterial3D.new()

	var mat := damage_mesh.material_override as StandardMaterial3D
	if mat != null:
		mat.albedo_color = Color(1.0, 0.4, 0.4)


func die() -> void:
	print("Enemy died")
	died.emit(self)
	queue_free()
