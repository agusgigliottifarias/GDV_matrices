class_name DiceManager
extends Node

## Controlador de lanzamiento de dados de 8 caras (D8)

signal dice_rolled(values: Array)
signal dice_selection_changed(selected_indices: Array)

var dice_values: Array[int] = [0, 0, 0]
var used_dice_indices: Array[int] = []

func roll_dice() -> Array[int]:
	randomize()
	dice_values.clear()
	for i in range(3):
		dice_values.append(randi_range(1, 8))
	used_dice_indices.clear()
	dice_rolled.emit(dice_values)
	return dice_values

func use_die(index: int) -> bool:
	if index >= 0 and index < dice_values.size() and not (index in used_dice_indices):
		used_dice_indices.append(index)
		dice_selection_changed.emit(used_dice_indices)
		return true
	return false

func unuse_die(index: int) -> bool:
	if index in used_dice_indices:
		used_dice_indices.erase(index)
		dice_selection_changed.emit(used_dice_indices)
		return true
	return false

func reset_selection() -> void:
	used_dice_indices.clear()
	dice_selection_changed.emit(used_dice_indices)

func is_all_dice_used() -> bool:
	return used_dice_indices.size() == dice_values.size()
