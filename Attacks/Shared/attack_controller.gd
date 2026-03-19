extends Node
class_name AttackController

@export var attack_slots: Array[Attack] = []

var current_attack_index: int = -1
var current_attack: Attack = null


func _ready() -> void:
	if attack_slots.is_empty():
		push_warning("AttackController has no attacks assigned.")
		return

	select_attack(0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack_slot_1"):
		select_attack(0)
	elif event.is_action_pressed("attack_slot_2"):
		select_attack(1)
	elif event.is_action_pressed("attack_slot_3"):
		select_attack(2)
	elif event.is_action_pressed("attack_slot_4"):
		select_attack(3)


func select_attack(index: int) -> void:
	if index < 0 or index >= attack_slots.size():
		return

	if attack_slots[index] == null:
		push_warning("Attack slot %d is empty." % (index + 1))
		return

	if current_attack_index == index:
		return

	current_attack_index = index
	current_attack = attack_slots[index]

	print("Selected attack: ", current_attack.name, " | slot ", index + 1)


func execute_current_attack(caster: Node3D) -> bool:
	if current_attack == null:
		push_warning("No current attack selected.")
		return false

	return current_attack.execute(caster)
