extends Node3D

@export var service: String
@export var identifier: String

@onready var dialog_player: DialogPlayer = $DialogPlayer
@onready var timestamp:= str(Time.get_ticks_msec()) #string needed for talo
@onready var random_ID:=str(RandomNumberGenerator)

func _ready() -> void:
	var random_ID:=str(RandomNumberGenerator)
	Talo.players.identify("demo0.9.5",random_ID)
	first_dialog()
	
func first_dialog() -> void:
	# Signale verbinden
	dialog_player.dialog_started.connect(_on_dialog_started)
	dialog_player.dialog_ended.connect(_on_dialog_ended)
	# Starte den Dialog
	dialog_player.start()

func _on_dialog_started() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Talo.events.track("dialog_start", {"time": timestamp})
	Talo.events.flush()

func _on_dialog_ended() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Talo.events.track("dialog_end", {"time": timestamp})
	Talo.events.flush()
