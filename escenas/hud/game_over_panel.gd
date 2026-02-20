extends Control

@onready var score_label = $CenterContainer/VBox/ScoreLabel
@onready var retry_button = $CenterContainer/VBox/RetryButton

func _ready() -> void:
	# Nos aseguramos de que el panel procese aunque el juego esté en "pausa"
	process_mode = PROCESS_MODE_ALWAYS
	hide() # Empezamos ocultos
	
	# Conectamos botones
	retry_button.pressed.connect(_on_retry_pressed)
	$CenterContainer/VBox/MenuButton.pressed.connect(_on_menu_pressed)

func show_screen():
	score_label.text = "Puntaje final: " + str(GameManager.score).pad_zeros(6)
	show()
	# Animación de entrada suave
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	modulate.a = 0
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	# Hacer que el ratón aparezca
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_retry_pressed():
	# ¡IMPORTANTE! Resetear el tiempo antes de recargar
	Engine.time_scale = 1.0 
	GameManager.reset_game()
	get_tree().reload_current_scene()

func _on_menu_pressed():
	Engine.time_scale = 1.0
	GameManager.back_game()
	get_tree().change_scene_to_file("res://escenas/selector_levels/selector_levels.tscn")
