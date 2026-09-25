extends Control

## Modo Debug / Desarrollador: Permite marcar cualquier casilla directamente con un clic

@onready var board_manager: BoardManager = $BoardManager
@onready var turn_label: Label = %TurnLabel
@onready var grid_container: GridContainer = %GridContainer
@onready var status_label: Label = %StatusLabel
@onready var restart_button: Button = %RestartButton
@onready var back_to_main_button: Button = %BackToMainButton
@onready var game_over_panel: PanelContainer = %GameOverPanel
@onready var winner_label: Label = %WinnerLabel
@onready var toggle_player_button: Button = %TogglePlayerButton

var current_player: int = 1 # 1 = X, 2 = O
var game_is_over: bool = false

const COLOR_P1 = Color("#00e5ff")
const COLOR_P2 = Color("#ff9100")
const COLOR_NEUTRAL = Color("#ffffff")

func _ready() -> void:
	board_manager.board_updated.connect(_on_board_updated)
	board_manager.win_detected.connect(_on_win_detected)
	
	restart_button.pressed.connect(start_new_game)
	back_to_main_button.pressed.connect(_on_back_to_main_pressed)
	toggle_player_button.pressed.connect(_on_toggle_player_pressed)
	$CanvasLayer/GameOverPanel/VBoxContainer/PlayAgainButton.pressed.connect(start_new_game)
	
	start_new_game()

func start_new_game() -> void:
	game_is_over = false
	game_over_panel.visible = false
	current_player = 1
	board_manager.generate_board()
	_update_turn_ui()
	status_label.text = "🛠️ MODO DEBUG: Haz clic en CUALQUIER casilla del tablero para marcarla inmediatamente."

func _update_turn_ui() -> void:
	if current_player == 1:
		turn_label.text = "DEBUG: COLOCANDO (%s - X)" % GameManager.player_1_name.to_upper()
		turn_label.add_theme_color_override("font_color", COLOR_P1)
	else:
		turn_label.text = "DEBUG: COLOCANDO (%s - O)" % GameManager.player_2_name.to_upper()
		turn_label.add_theme_color_override("font_color", COLOR_P2)

func _on_toggle_player_pressed() -> void:
	current_player = 1 if current_player == 2 else 2
	_update_turn_ui()

func _on_cell_clicked(col: int, row: int) -> void:
	if game_is_over: return
	
	var cell_data = board_manager.grid[row][col]
	if cell_data["owner"] == 0:
		board_manager.claim_cell(col, row, current_player)
		if not game_is_over:
			current_player = 1 if current_player == 2 else 2
			_update_turn_ui()

func _on_board_updated() -> void:
	for child in grid_container.get_children():
		child.queue_free()
		
	for r in range(BoardManager.GRID_ROWS):
		for c in range(BoardManager.GRID_COLS):
			var cell_data = board_manager.grid[r][c]
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(55, 42)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
			
			var val: int = cell_data["value"]
			var owner_id: int = cell_data["owner"]
			
			var style = StyleBoxFlat.new()
			style.set_corner_radius_all(4)

			if owner_id == 1:
				btn.text = "%d  X" % val
				btn.add_theme_color_override("font_color", COLOR_P1)
				btn.add_theme_font_size_override("font_size", 16)
				style.bg_color = Color("#003344")
				style.set_border_width_all(2)
				style.border_color = COLOR_P1
			elif owner_id == 2:
				btn.text = "%d  O" % val
				btn.add_theme_color_override("font_color", COLOR_P2)
				btn.add_theme_font_size_override("font_size", 16)
				style.bg_color = Color("#442200")
				style.set_border_width_all(2)
				style.border_color = COLOR_P2
			else:
				btn.text = str(val)
				btn.add_theme_color_override("font_color", COLOR_NEUTRAL)
				btn.add_theme_font_size_override("font_size", 14)
				style.bg_color = Color("#1e222d")
				style.set_border_width_all(1)
				style.border_color = Color("#343a4a")
				
				var click_c = c
				var click_r = r
				btn.pressed.connect(func(): _on_cell_clicked(click_c, click_r))
				
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			grid_container.add_child(btn)

func _on_win_detected(player_id: int, winning_cells: Array) -> void:
	game_is_over = true
	GameManager.set_winner(player_id)
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func _on_back_to_main_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
