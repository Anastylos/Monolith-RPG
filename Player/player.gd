extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003
const PITCH_MIN = -1.4
const PITCH_MAX = 1.4
const INTERACT_RANGE = 3.0

@onready var look_pivot: Node3D = $LookPivot
@onready var camera_pivot: Node3D = $LookPivot/CameraPivot
@onready var camera: Camera3D = $LookPivot/CameraPivot/Camera3D
@onready var attack: Attack = $Attack
@onready var pause_menu: PauseMenu = $"../PauseMenu"

var pitch := 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.make_current()
	_configure_attack()


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
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("interact"):
		_try_interact()

	if Input.is_action_just_pressed("attack") and attack != null:
		attack.execute(self)

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


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


func _configure_attack() -> void:
	if attack == null:
		push_warning("Player is missing Attack node.")
		return

	# Default basic attack to camera-driven raycast if not set in scene.
	if attack.origin_node == null:
		attack.origin_node = camera
	if attack.direction_node == null:
		attack.direction_node = camera
