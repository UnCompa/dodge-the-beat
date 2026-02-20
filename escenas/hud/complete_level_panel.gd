extends Control

@onready var score_label = $CenterContainer/VBox/ScoreLabel
@onready var continue_button = $CenterContainer/VBox/ContinueButton

func _ready() -> void:
	# Nos aseguramos de que el panel procese aunque el juego esté en "pausa"
	process_mode = PROCESS_MODE_ALWAYS
	hide() # Empezamos ocultos
	
	# Conectamos botones
	continue_button.pressed.connect(_on_continue_level)
	$CenterContainer/VBox/MenuButton.pressed.connect(_on_menu_pressed)

func show_win_screen():
	score_label.text = "Puntaje final: " + str(GameManager.score).pad_zeros(6)
	show()
	# Animación de entrada suave
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	modulate.a = 0
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	# Hacer que el ratón aparezca
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_continue_level():
	# ¡IMPORTANTE! Resetear el tiempo antes de recargar
	Engine.time_scale = 1.0 
	LevelManager.load_next_level()
	get_tree().reload_current_scene()

func _on_menu_pressed():
	Engine.time_scale = 1.0
	GameManager.back_game()
	get_tree().change_scene_to_file("res://escenas/selector_levels/selector_levels.tscn")
