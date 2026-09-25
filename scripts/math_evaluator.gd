class_name MathEvaluator
extends RefCounted

## Evaluador y validador de expresiones matemáticas para el juego GDV Matrices.
## Reglas:
## 1. La expresión debe usar exactamente los 3 dados proporcionados.
## 2. Los operadores permitidos son: +, -, *, /, (, ).
## 3. Solo se permiten operaciones que den como resultado números enteros exactos (sin decimales ni ceros negativos).
## 4. El resultado final debe ser un entero positivo.

static func evaluate_expression(expr_text: String, dice_values: Array) -> Dictionary:
	var clean_expr = expr_text.strip_edges()
	if clean_expr.is_empty():
		return {"valid": false, "result": 0, "error": "La expresión está vacía."}
	
	# 1. Verificar caracteres válidos
	var allowed_regex = RegEx.create_from_string("^[0-9+\\-*/()\\s]+$")
	if not allowed_regex.search(clean_expr):
		return {"valid": false, "result": 0, "error": "Contiene caracteres no válidos."}

	# 2. Extraer los números utilizados en la expresión
	var number_regex = RegEx.create_from_string("\\d+")
	var matches = number_regex.search_all(clean_expr)
	var used_numbers: Array = []
	for m in matches:
		used_numbers.append(int(m.get_string()))
	
	# Verificar que la cantidad de números sea exactamente igual a la cantidad de dados (3)
	if used_numbers.size() != dice_values.size():
		return {
			"valid": false, 
			"result": 0, 
			"error": "Debes usar exactamente los 3 dados (%d usados)." % used_numbers.size()
		}

	# Verificar que el multiset de números coincida exactamente con los dados
	var temp_dice = dice_values.duplicate()
	for num in used_numbers:
		if num in temp_dice:
			temp_dice.erase(num)
		else:
			return {
				"valid": false, 
				"result": 0, 
				"error": "El número %d no corresponde a ninguno de tus dados disponibles." % num
			}

	# 3. Evaluar la expresión usando Godot Expression
	var expression = Expression.new()
	var parse_err = expression.parse(clean_expr)
	if parse_err != OK:
		return {"valid": false, "result": 0, "error": "Sintaxis de expresión inválida (revisa paréntesis u operadores)."}
	
	var result = expression.execute([], null, false)
	if expression.has_execute_failed():
		return {"valid": false, "result": 0, "error": "Error al calcular la expresión (posible división por cero)."}
	
	# 4. Validar que el resultado sea un número entero
	if typeof(result) == TYPE_FLOAT:
		var float_val: float = result
		if is_equal_approx(float_val, round(float_val)):
			result = int(round(float_val))
		else:
			return {
				"valid": false, 
				"result": 0, 
				"error": "El resultado (%.2f) no es un entero exacto." % float_val
			}
	elif typeof(result) != TYPE_INT:
		return {"valid": false, "result": 0, "error": "Resultado no numérico."}
	
	var final_int: int = result
	if final_int <= 0:
		return {"valid": false, "result": 0, "error": "El resultado debe ser un número entero positivo (> 0)."}

	return {"valid": true, "result": final_int, "error": ""}
