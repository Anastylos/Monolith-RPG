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


func _on_damage_type_received(damage_type: Attack.DamageType) -> void:
	match damage_type:
		Attack.DamageType.FIRE:
			print("enemy attacked with fire")
		Attack.DamageType.ICE:
			print("enemy attacked with ice")
		Attack.DamageType.LIGHTNING:
			print("enemy attacked with lightning")
		Attack.DamageType.SOUL:
			print("enemy attacked with soul")
		Attack.DamageType.NONE:
			print("enemy attacked with untyped damage")


func take_typed_damage(amount: float, damage_type: Attack.DamageType) -> void:
	var final_amount := amount * _get_damage_multiplier(damage_type)
	_apply_final_damage(final_amount)
	_on_damage_type_received(damage_type)
	_flash_damage()


func apply_sustained_damage(dps: float, tick_rate: float, damage_type: Attack.DamageType) -> void:
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
	damage_type: Attack.DamageType
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


func clear_sustained_damage_of_type(damage_type: Attack.DamageType) -> void:
	_sustained_effects = _sustained_effects.filter(
		func(effect: Dictionary) -> bool:
			return effect["damage_type"] != damage_type
	)


func _process_sustained_effects(delta: float) -> void:
	for effect in _sustained_effects:
		effect["time_until_tick"] -= delta

		if effect["time_until_tick"] <= 0.0:
			var damage_type: Attack.DamageType = effect["damage_type"]
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
			var damage_type: Attack.DamageType = effect["damage_type"]
			var tick_damage: float = current_dps * effect["tick_rate"]

			if tick_damage > 0.0:
				take_typed_damage(tick_damage, damage_type)

			effect["time_until_tick"] = effect["tick_rate"]

		if effect["remaining"] <= 0.0:
			expired.append(effect)

	for effect in expired:
		_lingering_effects.erase(effect)


func _get_damage_multiplier(damage_type: Attack.DamageType) -> float:
	match damage_type:
		Attack.DamageType.FIRE:
			return stats.fire_multiplier
		Attack.DamageType.ICE:
			return stats.ice_multiplier
		Attack.DamageType.LIGHTNING:
			return stats.lightning_multiplier
		Attack.DamageType.SOUL:
			return stats.soul_multiplier
		Attack.DamageType.NONE:
			return 1.0
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
	var timestamp:= str(Time.get_ticks_msec()) #string needed for talo
	Talo.events.track("kill", {"time": timestamp})
	Talo.events.flush()
	died.emit(self)
	queue_free()
