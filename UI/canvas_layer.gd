extends CanvasLayer

@onready var fire_icon: TextureRect = $HBoxContainer/FireIcon
@onready var ice_icon: TextureRect = $HBoxContainer/IceIcon
@onready var lightning_icon: TextureRect = $HBoxContainer/LightningIcon
@onready var soul_icon: TextureRect = $HBoxContainer/SoulIcon

var icons: Array = []  # Array zur einfachen Verwaltung der Icons

func _ready() -> void:
	icons = [fire_icon, ice_icon, lightning_icon, soul_icon]
	set_icon_transparency(0.5)  # Setze alle Icons auf halbtransparent
	highlight_selected_attack(0)  # Hervorhebe den ersten Angriff

func set_icon_transparency(alpha: float) -> void:
	for icon in icons:
		icon.modulate.a = alpha

func highlight_selected_attack(index: int) -> void:
	set_icon_transparency(0.5)  # Setze alle Icons auf halbtransparent
	if index >= 0 and index < icons.size():
		icons[index].modulate.a = 1.0  # Hervorhebe das ausgewählte Icon
