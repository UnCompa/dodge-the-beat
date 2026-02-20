extends Control

@export_group("Referencias UI")
@onready var lives_label = $CanvasLayer/MarginContainer/HBox/LeftVBox/LivesHB/LivesLabel
@onready var score_label = $CanvasLayer/MarginContainer/HBox/LeftVBox/ScoreHB/ScoreLabel
@onready var progress_bar = $CanvasLayer/MarginContainer/HBox/RightHB/ProgressBar
@onready var song_icon = $CanvasLayer/MarginContainer/HBox/RightHB/SongIcon
@onready var time_label = $CanvasLayer/MarginContainer/HBox/RightHB/TimeLabel

@export_group("Configuración Música")
@export var music_player: AudioStreamPlayer2D

func _ready() -> void:
	# Conexiones del GameManager
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.game_over.connect(_on_game_over)
	
	# Inicializar valores
	_on_lives_changed(GameManager.current_lives)
	_on_score_changed(GameManager.score)
	
	# Configurar la barra de progreso
	if music_player and music_player.stream:
		progress_bar.max_value = music_player.stream.get_length()
		# Mostrar duración total desde el inicio
		var total := music_player.stream.get_length()
		time_label.text = "0:00 / " + _format_time(total)

func _process(_delta: float) -> void:
	if music_player and music_player.playing:
		var current := music_player.get_playback_position()
		var total := music_player.stream.get_length()
		progress_bar.value = current
		time_label.text = _format_time(current) + " / " + _format_time(total)

func _format_time(seconds: float) -> String:
	var m := int(seconds) / 60
	var s := int(seconds) % 60
	return "%d:%02d" % [m, s]
	
# --- SEÑALES ---

func _on_lives_changed(lives: int) -> void:
	if lives_label:
		lives_label.text = str(lives)
		# Feedback visual: Un pequeño "shake" o parpadeo cuando pierdes vida
		var tween = create_tween()
		tween.tween_property(lives_label, "scale", Vector2(1.5, 1.5), 0.1)
		tween.tween_property(lives_label, "scale", Vector2.ONE, 0.1)

func _on_score_changed(score: int) -> void:
	score_label.text = str(score).pad_zeros(6) # Estilo arcade: 000123

func _on_game_over() -> void:
	# Aquí podrías oscurecer el HUD o animar la salida
	modulate = Color.RED
	set_process(false)
