class_name BoardManager
extends Node

## Manager para la matriz de 10 filas x 5 columnas (números 1 al 50 en orden) y verificación de 3 en raya

signal board_updated()
signal win_detected(player_id: int, winning_cells: Array)

const GRID_ROWS: int = 10
const GRID_COLS: int = 5
const WIN_COUNT: int = 3 # Alineación requerida para ganar (3 en raya)

# Estructura del tablero: Array de 10x5 diccionarios {"value": int, "owner": int (0=nadie, 1=J1, 2=J2)}
var grid: Array = []

func _ready() -> void:
	generate_board()

func generate_board() -> void:
	grid.clear()
	
	var current_num = 1
	for r in range(GRID_ROWS):
		var row_array: Array = []
		for c in range(GRID_COLS):
			row_array.append({
				"value": current_num,
				"owner": 0
			})
			current_num += 1
		grid.append(row_array)
	
	board_updated.emit()

func find_available_cell_pos(value: int) -> Vector2i:
	if value < 1 or value > 50:
		return Vector2i(-1, -1)
		
	var idx = value - 1
	var r = idx / GRID_COLS
	var c = idx % GRID_COLS
	
	if r >= 0 and r < GRID_ROWS and c >= 0 and c < GRID_COLS:
		if grid[r][c]["owner"] == 0:
			return Vector2i(c, r) # (x=col, y=row)
			
	return Vector2i(-1, -1)

func claim_cell(col: int, row: int, player_id: int) -> bool:
	if row >= 0 and row < GRID_ROWS and col >= 0 and col < GRID_COLS:
		if grid[row][col]["owner"] == 0:
			grid[row][col]["owner"] = player_id
			board_updated.emit()
			
			var win_cells = check_win_for_player(player_id)
			if win_cells.size() > 0:
				win_detected.emit(player_id, win_cells)
			return true
	return false

func check_win_for_player(player_id: int) -> Array:
	var directions = [
		Vector2i(1, 0),   # Horizontal
		Vector2i(0, 1),   # Vertical
		Vector2i(1, 1),   # Diagonal ↘
		Vector2i(1, -1)   # Diagonal ↗
	]
	
	for r in range(GRID_ROWS):
		for c in range(GRID_COLS):
			if grid[r][c]["owner"] != player_id:
				continue
				
			for d in directions:
				var line_cells: Array[Vector2i] = [Vector2i(c, r)]
				for step in range(1, WIN_COUNT):
					var nc = c + d.x * step
					var nr = r + d.y * step
					if nc >= 0 and nc < GRID_COLS and nr >= 0 and nr < GRID_ROWS:
						if grid[nr][nc]["owner"] == player_id:
							line_cells.append(Vector2i(nc, nr))
						else:
							break
					else:
						break
				
				if line_cells.size() >= WIN_COUNT:
					return line_cells
					
	return []
