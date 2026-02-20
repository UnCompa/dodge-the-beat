extends Control

@onready var retry_button: Button = $CenterContainer/VBox/RetryButton
@onready var quit_button: Button = $CenterContainer/VBox/QuitButton
@onready var resume_button: Button = $CenterContainer/VBox/ResumeButton

func _ready() -> void:
	hide() 
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	# --- CONECTANDO LAS SEÑALES ---
	# Esto le dice a Godot: "Cuando presionen este botón, ejecuta esta función"
	resume_button.pressed.connect(_on_resume_button_pressed)
	retry_button.pressed.connect(_on_retry_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): 
		toggle_pause()

func toggle_pause() -> void:
	var new_pause_state = !get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state
	
	if new_pause_state:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		resume_button.grab_focus() # Usamos la referencia @onready
		
		# Opcional: Filtro sordo al pausar (JSAB Style)
		_set_low_pass_filter(true)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		_set_low_pass_filter(false)

# --- FUNCIONES DE LOS BOTONES ---

func _on_resume_button_pressed() -> void:
	toggle_pause()

func _on_retry_button_pressed() -> void:
	get_tree().paused = false
	_set_low_pass_filter(false) # Limpiar audio antes de reiniciar
	GameManager.reset_game()
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	_set_low_pass_filter(false)
	LevelManager.go_to_level_select()

# Función auxiliar para el efecto de sonido JSAB
func _set_low_pass_filter(active: bool) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	for i in AudioServer.get_bus_effect_count(bus_idx):
		if AudioServer.get_bus_effect(bus_idx, i) is AudioEffectLowPassFilter:
			AudioServer.set_bus_effect_enabled(bus_idx, i, active)
