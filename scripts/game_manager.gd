extends Node

## Singleton global para almacenar nombres de jugadores, estado del ganador y reproducción persistente de música

var player_1_name: String = "Jugador 1"
var player_2_name: String = "Jugador 2"

var winner_name: String = ""
var winner_player_id: int = 1 # 1 = X, 2 = O

# Reproductor de música persistente
var music_player: AudioStreamPlayer

func _ready() -> void:
	_setup_music_player()
	call_deferred("_auto_load_bgm")

func set_player_names(p1: String, p2: String) -> void:
	player_1_name = p1.strip_edges() if not p1.strip_edges().is_empty() else "Jugador 1"
	player_2_name = p2.strip_edges() if not p2.strip_edges().is_empty() else "Jugador 2"

func set_winner(player_id: int) -> void:
	winner_player_id = player_id
	if player_id == 1:
		winner_name = player_1_name
	else:
		winner_name = player_2_name

# --- LÓGICA DE MÚSICA PERSISTENTE ---

func _setup_music_player() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "BGMPlayer"
	music_player.bus = "Master"
	add_child(music_player)

func _auto_load_bgm() -> void:
	# Buscar en res://musica/
	var search_paths = ["res://musica/", "res://assets/musica/"]
	
	for path in search_paths:
		var dir = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir():
					var clean_name = file_name
					if clean_name.ends_with(".import"):
						clean_name = clean_name.trim_suffix(".import")
					
					var ext = clean_name.get_extension().to_lower()
					if ext in ["mp3", "ogg", "wav"]:
						var full_file_path = path + clean_name
						play_bgm(full_file_path)
						dir.list_dir_end()
						return
				file_name = dir.get_next()
			dir.list_dir_end()
			
	print("[GameManager] No se encontró ningún archivo de audio .mp3, .ogg o .wav")

func play_bgm(stream_path: String) -> void:
	if ResourceLoader.exists(stream_path):
		var stream = load(stream_path)
		if stream is AudioStream:
			# Activar bucle (loop)
			if "loop" in stream:
				stream.loop = true
			elif stream is AudioStreamMP3:
				stream.loop = true
			elif stream is AudioStreamOggVorbis:
				stream.loop = true
				
			music_player.stream = stream
			music_player.play()
			print("[GameManager] ¡Música de fondo cargada e iniciando reproducción!: ", stream_path)

func stop_bgm() -> void:
	if music_player and music_player.playing:
		music_player.stop()

func set_bgm_volume(volume_db: float) -> void:
	if music_player:
		music_player.volume_db = volume_db
