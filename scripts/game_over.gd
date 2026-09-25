extends Control

## Controlador de la Escena de Victoria / Fin de Juego

@onready var winner_label: Label = %WinnerLabel
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton

const COLOR_P1 = Color("#00e5ff")
const COLOR_P2 = Color("#ff9100")

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	_display_winner()

func _display_winner() -> void:
	var w_name = GameManager.winner_name
	var p_id = GameManager.winner_player_id
	
	if p_id == 1:
		winner_label.text = "¡%s GANÓ!" % w_name.to_upper()
		winner_label.add_theme_color_override("font_color", COLOR_P1)
	else:
		winner_label.text = "¡%s GANÓ!" % w_name.to_upper()
		winner_label.add_theme_color_override("font_color", COLOR_P2)

func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
