extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003
const PITCH_MIN = -1.4
const PITCH_MAX = 1.4
const INTERACT_RANGE = 3.0

signal health_changed(current: float, maximum: float)
signal died()

@export_group("Health")
@export var max_health: float = 20.0
@export var fire_multiplier: float = 1.0
@export var ice_multiplier: float = 1.0
@export var lightning_multiplier: float = 1.0
@export var soul_multiplier: float = 1.0

@onready var look_pivot: Node3D = $LookPivot
@onready var camera_pivot: Node3D = $LookPivot/CameraPivot
@onready var camera: Camera3D = $LookPivot/CameraPivot/Camera3D
@onready var attack_controller: AttackController = $AttackController
@onready var pause_menu: PauseMenu = $"../PauseMenu"

var pitch := 0.0
var health: float = 0.0
var _sustained_effects: Array[Dictionary] = []
var _lingering_effects: Array[Dictionary] = []
var _is_dead: bool = false


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.make_current()
	health = max_health
	health_changed.emit(health, max_health)
	_configure_attacks()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		pause_menu.toggle()
		return

	if get_tree().paused:
		return

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)

		pitch -= event.relative.y * MOUSE_SENSITIVITY
		pitch = clamp(pitch, PITCH_MIN, PITCH_MAX)
		camera_pivot.rotation.x = pitch


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_process_sustained_effects(delta)
	_process_lingering_effects(delta)

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("interact"):
		_try_interact()

	if Input.is_action_just_pressed("attack") and attack_controller != null:
		attack_controller.execute_current_attack(self)

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func take_damage(amount: float) -> void:
	_apply_final_damage(amount)


func take_typed_damage(amount: float, damage_type: Attack.DamageType) -> void:
	var final_amount := amount * _get_damage_multiplier(damage_type)
	_apply_final_damage(final_amount)


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


func _try_interact() -> void:
	var space_state = get_world_3d().direct_space_state

	var from = camera.global_position
	var to = from + (-camera.global_transform.basis.z) * INTERACT_RANGE

	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.exclude = [self]

	var hit := space_state.intersect_ray(params)
	if hit.is_empty():
		print("No hit")
		return

	var collider = hit["collider"]
	print("Hit:", collider)

	if collider != null and collider.has_method("interact"):
		collider.interact(self)
	else:
		print("Hit has no interact()")


func _configure_attacks() -> void:
	if attack_controller == null:
		push_warning("Player is missing AttackController node.")
		return

	for attack in attack_controller.attack_slots:
		if attack == null:
			continue

		if attack.origin_node == null:
			attack.origin_node = camera

		if attack.direction_node == null:
			attack.direction_node = camera


func _get_damage_multiplier(damage_type: Attack.DamageType) -> float:
	match damage_type:
		Attack.DamageType.FIRE:
			return fire_multiplier
		Attack.DamageType.ICE:
			return ice_multiplier
		Attack.DamageType.LIGHTNING:
			return lightning_multiplier
		Attack.DamageType.SOUL:
			return soul_multiplier
		Attack.DamageType.NONE:
			return 1.0
		_:
			return 1.0


func _apply_final_damage(amount: float) -> void:
	if _is_dead:
		return

	health -= amount
	health_changed.emit(health, max_health)
	print("Player took damage. Health: ", health)

	if health <= 0.0:
		die()


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


func die() -> void:
	if _is_dead:
		return

	_is_dead = true
	health = 0.0
	health_changed.emit(health, max_health)
	died.emit()
	print("Player died")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().reload_current_scene()
