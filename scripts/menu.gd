extends Control

## Controlador del Menú Principal con diseño enriquecido

@onready var main_vbox: VBoxContainer = %MainVBox
@onready var play_button: Button = %PlayButton
@onready var rules_button: Button = %RulesButton
@onready var exit_button: Button = %ExitButton

# Panel de Nombres
@onready var names_popup: PanelContainer = %NamesPopup
@onready var p1_name_input: LineEdit = %P1NameInput
@onready var p2_name_input: LineEdit = %P2NameInput
@onready var start_game_button: Button = %StartGameButton
@onready var cancel_names_button: Button = %CancelNamesButton

# Panel de Reglas
@onready var rules_popup: PanelContainer = %RulesPopup
@onready var close_rules_button: Button = %CloseRulesButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	rules_button.pressed.connect(_on_rules_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	start_game_button.pressed.connect(_on_start_game_pressed)
	cancel_names_button.pressed.connect(_hide_all_popups)
	close_rules_button.pressed.connect(_hide_all_popups)
	
	_hide_all_popups()

func _on_play_pressed() -> void:
	p1_name_input.text = GameManager.player_1_name
	p2_name_input.text = GameManager.player_2_name
	main_vbox.visible = false
	names_popup.visible = true
	p1_name_input.grab_focus()

func _on_rules_pressed() -> void:
	main_vbox.visible = false
	rules_popup.visible = true

func _on_exit_pressed() -> void:
	get_tree().quit()

func _hide_all_popups() -> void:
	names_popup.visible = false
	rules_popup.visible = false
	main_vbox.visible = true

func _on_start_game_pressed() -> void:
	GameManager.set_player_names(p1_name_input.text, p2_name_input.text)
	get_tree().change_scene_to_file("res://scenes/main.tscn")
