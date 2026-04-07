extends CanvasLayer

@onready var fire_icon: TextureRect = $HBoxContainer/fire_TextureRect
@onready var ice_icon: TextureRect = $HBoxContainer/ice_TextureRect2
@onready var lightning_icon: TextureRect = $HBoxContainer/lightning_TextureRect4
@onready var soul_icon: TextureRect = $HBoxContainer/soul_TextureRect3

var icons: Array = []

func _ready() -> void:
	icons = [fire_icon, ice_icon, lightning_icon, soul_icon]
	set_icon_transparency(0.5)
	GlobalSignals.connect("global_attack_selected", _on_global_attack_selected)

func set_icon_transparency(alpha: float) -> void:
	for icon in icons:
		icon.modulate.a = alpha

func _on_global_attack_selected(index: int) -> void:
	set_icon_transparency(0.5)
	if index >= 0 and index < icons.size():
		icons[index].modulate.a = 1.0
