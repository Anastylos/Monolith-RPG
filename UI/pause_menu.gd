extends CanvasLayer
class_name PauseMenu

@onready var continue_button: Button = $Panel/VBoxContainer/ContinueButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton

func _ready() -> void:
	visible = false
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func open() -> void:
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func close() -> void:
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func _on_continue_pressed() -> void:
	close()


func _on_quit_pressed() -> void:
	get_tree().quit()
