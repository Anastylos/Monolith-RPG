extends Resource
class_name EnemyStats

@export var max_health: float = 10.0
@export var speed: float = 3.0
@export var wander_radius: float = 5.0
@export var wander_timer: float = 2.0

@export_group("Resistances")
@export var fire_multiplier: float = 1.0
@export var ice_multiplier: float = 1.0
@export var lightning_multiplier: float = 1.0
@export var soul_multiplier: float = 1.0
