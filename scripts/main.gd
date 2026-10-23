extends Control

## Controlador principal de la interfaz y flujo de juego (1v1 Local)

@onready var board_manager: BoardManager = $BoardManager
@onready var dice_manager: DiceManager = $DiceManager

# Nodos de Interfaz (UI)
@onready var turn_label: Label = %TurnLabel
@onready var grid_container: GridContainer = %GridContainer
@onready var roll_button: Button = %RollButton
@onready var dice_container: HBoxContainer = %DiceContainer
@onready var formula_label: Label = %FormulaLabel
@onready var result_label: Label = %ResultLabel
@onready var status_label: Label = %StatusLabel
@onready var confirm_button: Button = %ConfirmButton
@onready var clear_one_button: Button = %ClearOneButton
@onready var clear_all_button: Button = %ClearAllButton
@onready var restart_button: Button = %RestartButton
@onready var operators_container: HBoxContainer = %OperatorsContainer
@onready var game_over_panel: PanelContainer = %GameOverPanel
@onready var winner_label: Label = %WinnerLabel

# Estado del juego
var current_player: int = 1 # 1 = Cruz (X), 2 = Círculo (O)
var formula_tokens: Array = [] # Array de diccionarios: {"type": "die"|"op", "text": String, "die_index": int}
var dice_buttons: Array[Button] = []
var evaluated_target_value: int = -1
var game_is_over: bool = false

# Buffer para el código secreto ("siempre hay gdv")
var secret_buffer: String = ""
const SECRET_CODE: String = "siempre hay gdv"

# Colores característicos de alto contraste
const COLOR_P1 = Color("#00e5ff") # Cyan Neón / Azul
const COLOR_P2 = Color("#ff9100") # Naranja Neón
const COLOR_NEUTRAL = Color("#ffffff") # Blanco puro
const COLOR_VALID = Color("#00ff66") # Verde neón brillante
const COLOR_WARN = Color("#ffcc00") # Amarillo neón
const COLOR_ERROR = Color("#ff3366") # Rojo neón

func _ready() -> void:
	board_manager.board_updated.connect(_on_board_updated)
	board_manager.win_detected.connect(_on_win_detected)
	dice_manager.dice_rolled.connect(_on_dice_rolled)
	
	roll_button.pressed.connect(_on_roll_button_pressed)
	clear_one_button.pressed.connect(_on_clear_one_pressed)
	clear_all_button.pressed.connect(_on_clear_all_pressed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	$CanvasLayer/GameOverPanel/VBoxContainer/PlayAgainButton.pressed.connect(_on_restart_button_pressed)

	_setup_operator_buttons()
	start_new_game()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var unicode = event.unicode
		if unicode > 0:
			var char_typed = String.chr(unicode).to_lower()
			secret_buffer += char_typed
			if secret_buffer.length() > 30:
				secret_buffer = secret_buffer.right(30)
			
			if secret_buffer.ends_with(SECRET_CODE):
				secret_buffer = ""
				print("[CheatCode] ¡Código secreto detectado! Abriendo Modo Debug...")
				get_tree().change_scene_to_file("res://scenes/debug_mode.tscn")

func start_new_game() -> void:
	game_is_over = false
	game_over_panel.visible = false
	current_player = 1
	board_manager.generate_board()
	_update_turn_ui()
	_reset_turn_state()
	
	dice_manager.roll_dice()
	roll_button.disabled = true
	var p1_name = GameManager.player_1_name
	status_label.text = "¡Partida iniciada! Turno de %s." % p1_name

func _setup_operator_buttons() -> void:
	var ops = ["+", "-", "*", "/", "(", ")"]
	for child in operators_container.get_children():
		child.queue_free()
		
	for op in ops:
		var btn = Button.new()
		btn.text = " " + op + " "
		btn.custom_minimum_size = Vector2(48, 48)
		btn.add_theme_font_size_override("font_size", 18)
		btn.add_theme_color_override("font_color", Color("#00e5ff"))
		
		var op_style = StyleBoxFlat.new()
		op_style.set_corner_radius_all(6)
		op_style.bg_color = Color("#141b2d")
		op_style.set_border_width_all(2)
		op_style.border_color = Color("#294268")
		btn.add_theme_stylebox_override("normal", op_style)
		
		var op_hover = op_style.duplicate()
		op_hover.bg_color = Color("#1e2c4a")
		op_hover.border_color = Color("#00e5ff")
		btn.add_theme_stylebox_override("hover", op_hover)
		
		var op_text = op
		btn.pressed.connect(func(): _append_operator(op_text))
		operators_container.add_child(btn)

func _update_turn_ui() -> void:
	if current_player == 1:
		turn_label.text = "TURNO: %s (X)" % GameManager.player_1_name.to_upper()
		turn_label.add_theme_color_override("font_color", COLOR_P1)
	else:
		turn_label.text = "TURNO: %s (O)" % GameManager.player_2_name.to_upper()
		turn_label.add_theme_color_override("font_color", COLOR_P2)

func _reset_turn_state() -> void:
	formula_tokens.clear()
	evaluated_target_value = -1
	formula_label.text = "Operación: _"
	result_label.text = "Resultado: -"
	result_label.add_theme_color_override("font_color", COLOR_NEUTRAL)
	confirm_button.disabled = true
	dice_manager.reset_selection()
	_update_dice_buttons_state()
	_highlight_target_board_cell(-1)

func _on_roll_button_pressed() -> void:
	if game_is_over: return
	dice_manager.roll_dice()
	roll_button.disabled = true
	status_label.text = "Combina los 3 dados y operadores para formar un número del tablero."

func _on_dice_rolled(values: Array) -> void:
	for child in dice_container.get_children():
		child.queue_free()
	dice_buttons.clear()
	
	for i in range(values.size()):
		var btn = Button.new()
		btn.text = str(values[i]) 
		btn.custom_minimum_size = Vector2(56, 46)
		btn.add_theme_font_size_override("font_size", 20)
		btn.add_theme_color_override("font_color", COLOR_NEUTRAL)
		
		var die_style = StyleBoxFlat.new()
		die_style.set_corner_radius_all(8)
		die_style.bg_color = Color("#1c2438")
		die_style.set_border_width_all(2)
		die_style.border_color = Color("#3d527a")
		btn.add_theme_stylebox_override("normal", die_style)
		
		var die_hover = die_style.duplicate()
		die_hover.bg_color = Color("#263452")
		die_hover.border_color = Color("#00e5ff")
		btn.add_theme_stylebox_override("hover", die_hover)
		
		var die_index = i
		var die_val = values[i]
		btn.pressed.connect(func(): _on_die_pressed(die_index, die_val))
		dice_container.add_child(btn)
		dice_buttons.append(btn)
		
	_reset_turn_state()

func _on_die_pressed(die_index: int, die_value: int) -> void:
	if dice_manager.use_die(die_index):
		formula_tokens.append({
			"type": "die",
			"text": str(die_value),
			"die_index": die_index
		})
		_update_dice_buttons_state()
		_rebuild_and_evaluate_formula()

func _append_operator(op_symbol: String) -> void:
	formula_tokens.append({
		"type": "op",
		"text": op_symbol,
		"die_index": -1
	})
	_rebuild_and_evaluate_formula()

func _on_clear_one_pressed() -> void:
	if formula_tokens.size() > 0:
		var last_token = formula_tokens.pop_back()
		if last_token["type"] == "die":
			dice_manager.unuse_die(last_token["die_index"])
			_update_dice_buttons_state()
		_rebuild_and_evaluate_formula()

func _on_clear_all_pressed() -> void:
	_reset_turn_state()

func _update_dice_buttons_state() -> void:
	for i in range(dice_buttons.size()):
		if i < dice_buttons.size():
			var is_used = (i in dice_manager.used_dice_indices)
			dice_buttons[i].disabled = is_used
			if is_used:
				var disabled_style = StyleBoxFlat.new()
				disabled_style.set_corner_radius_all(8)
				disabled_style.bg_color = Color("#0e131d")
				disabled_style.set_border_width_all(1)
				disabled_style.border_color = Color("#1e283a")
				dice_buttons[i].add_theme_stylebox_override("disabled", disabled_style)

func _rebuild_and_evaluate_formula() -> void:
	var expr_str = ""
	for t in formula_tokens:
		if t["type"] == "op":
			expr_str += " " + t["text"] + " "
		else:
			expr_str += t["text"]
			
	formula_label.text = "Operación: " + (expr_str if not expr_str.is_empty() else "_")
	
	if expr_str.strip_edges().is_empty():
		result_label.text = "Resultado: -"
		result_label.add_theme_color_override("font_color", COLOR_NEUTRAL)
		confirm_button.disabled = true
		_highlight_target_board_cell(-1)
		return

	var eval_res = MathEvaluator.evaluate_expression(expr_str, dice_manager.dice_values)
	
	if eval_res["valid"]:
		var val: int = eval_res["result"]
		evaluated_target_value = val
		
		if val > 50:
			result_label.text = "Resultado: %d ⚠️ (Mayor a 50)" % val
			result_label.add_theme_color_override("font_color", COLOR_WARN)
			confirm_button.disabled = true
			status_label.text = "💡 ¡Tremenda cuenta! (%d), pero el tablero llega hasta 50. Usá '⌫ Borrar 1' para probar otra opción." % val
			_highlight_target_board_cell(-1)
		else:
			var pos = board_manager.find_available_cell_pos(val)
			if pos != Vector2i(-1, -1):
				result_label.text = "Resultado: %d ✓" % val
				result_label.add_theme_color_override("font_color", COLOR_VALID)
				confirm_button.disabled = false
				status_label.text = "¡Resultado %d VÁLIDO y LIBRE! Presioná 'Confirmar'." % val
				_highlight_target_board_cell(val)
			else:
				result_label.text = "Resultado: %d ⚠️ (Ocupado)" % val
				result_label.add_theme_color_override("font_color", COLOR_WARN)
				confirm_button.disabled = true
				status_label.text = "El casillero %d ya fue ocupado. Usá '⌫ Borrar 1' para buscar otra opción libre." % val
				_highlight_target_board_cell(-1)
	else:
		evaluated_target_value = -1
		result_label.text = "Resultado: " + eval_res["error"]
		result_label.add_theme_color_override("font_color", COLOR_ERROR)
		confirm_button.disabled = true
		_highlight_target_board_cell(-1)

func _on_confirm_button_pressed() -> void:
	if evaluated_target_value <= 0 or evaluated_target_value > 50 or game_is_over: return
	
	var pos = board_manager.find_available_cell_pos(evaluated_target_value)
	if pos != Vector2i(-1, -1):
		board_manager.claim_cell(pos.x, pos.y, current_player)
		if not game_is_over:
			_switch_turn()

func _switch_turn() -> void:
	current_player = 1 if current_player == 2 else 2
	_update_turn_ui()
	_reset_turn_state()
	
	dice_manager.roll_dice()
	roll_button.disabled = true
	var curr_name = GameManager.player_1_name if current_player == 1 else GameManager.player_2_name
	status_label.text = "Turno de %s." % curr_name

func _on_board_updated() -> void:
	for child in grid_container.get_children():
		child.queue_free()
		
	for r in range(BoardManager.GRID_ROWS):
		for c in range(BoardManager.GRID_COLS):
			var cell_data = board_manager.grid[r][c]
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(58, 44)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
			
			var val: int = cell_data["value"]
			var owner_id: int = cell_data["owner"]
			
			var style = StyleBoxFlat.new()
			style.set_corner_radius_all(6)

			if owner_id == 1:
				btn.text = "%d  X" % val
				btn.add_theme_color_override("font_color", COLOR_P1)
				btn.add_theme_font_size_override("font_size", 17)
				style.bg_color = Color("#0b324d")
				style.set_border_width_all(2)
				style.border_color = COLOR_P1
			elif owner_id == 2:
				btn.text = "%d  O" % val
				btn.add_theme_color_override("font_color", COLOR_P2)
				btn.add_theme_font_size_override("font_size", 17)
				style.bg_color = Color("#4d240b")
				style.set_border_width_all(2)
				style.border_color = COLOR_P2
			else:
				btn.text = str(val)
				btn.add_theme_color_override("font_color", COLOR_NEUTRAL)
				btn.add_theme_font_size_override("font_size", 16)
				style.bg_color = Color("#182030")
				style.set_border_width_all(2)
				style.border_color = Color("#3e5278")
				
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("disabled", style)
			btn.disabled = true
			grid_container.add_child(btn)

func _highlight_target_board_cell(target_val: int) -> void:
	var children = grid_container.get_children()
	var index = 0
	for r in range(BoardManager.GRID_ROWS):
		for c in range(BoardManager.GRID_COLS):
			if index < children.size():
				var btn: Button = children[index]
				var cell_data = board_manager.grid[r][c]
				if target_val > 0 and cell_data["value"] == target_val and cell_data["owner"] == 0:
					btn.add_theme_color_override("font_color", COLOR_VALID)
					var highlight_style = StyleBoxFlat.new()
					highlight_style.set_corner_radius_all(6)
					highlight_style.bg_color = Color("#0a4a22")
					highlight_style.set_border_width_all(3)
					highlight_style.border_color = COLOR_VALID
					btn.add_theme_stylebox_override("disabled", highlight_style)
				else:
					var normal_style = StyleBoxFlat.new()
					normal_style.set_corner_radius_all(6)
					if cell_data["owner"] == 1:
						btn.add_theme_color_override("font_color", COLOR_P1)
						normal_style.bg_color = Color("#0b324d")
						normal_style.set_border_width_all(2)
						normal_style.border_color = COLOR_P1
					elif cell_data["owner"] == 2:
						btn.add_theme_color_override("font_color", COLOR_P2)
						normal_style.bg_color = Color("#44240b")
						normal_style.set_border_width_all(2)
						normal_style.border_color = COLOR_P2
					else:
						btn.add_theme_color_override("font_color", COLOR_NEUTRAL)
						normal_style.bg_color = Color("#182030")
						normal_style.set_border_width_all(2)
						normal_style.border_color = Color("#3e5278")
					btn.add_theme_stylebox_override("disabled", normal_style)
			index += 1

func _on_win_detected(player_id: int, winning_cells: Array) -> void:
	game_is_over = true
	GameManager.set_winner(player_id)
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func _on_restart_button_pressed() -> void:
	start_new_game()
