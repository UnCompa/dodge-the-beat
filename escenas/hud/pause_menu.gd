extends Control

# Referencias a los contenedores (para intercambiarlos)
@onready var main_vbox: VBoxContainer = $CenterContainer/VBox
@onready var option_menu: Control = $OptionMenu # Asegúrate de que este sea el nombre del nodo hijo

# Botones Principales
@onready var resume_button: Button = $CenterContainer/VBox/ResumeButton
@onready var retry_button: Button = $CenterContainer/VBox/RetryButton
@onready var option_button: Button = $CenterContainer/VBox/OptionButton
@onready var quit_button: Button = $CenterContainer/VBox/QuitButton

# Botones de Opciones
@onready var music_slider: HSlider = $OptionMenu/CenterContainer/OptionPanel/HBoxContainer/MusicSlider
@onready var fullscreen_toggle: CheckButton = $OptionMenu/CenterContainer/OptionPanel/HBoxContainer2/FullscreenToggle
@onready var back_button: Button = $OptionMenu/CenterContainer/OptionPanel/Exit

func _ready() -> void:
	hide()
	option_menu.hide() # Empezar con opciones ocultas
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	# --- CONECTAR BOTONES PRINCIPALES ---
	resume_button.pressed.connect(_on_resume_button_pressed)
	retry_button.pressed.connect(_on_retry_button_pressed)
	option_button.pressed.connect(_on_options_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	# --- CONECTAR OPCIONES ---
	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	
	var bus_idx = AudioServer.get_bus_index("Musica")
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	
	music_slider.value_changed.connect(_on_music_slider_changed)

	back_button.pressed.connect(_on_back_button_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): 
		toggle_pause()
		
func _process(_delta: float) -> void:
	if get_tree().paused and visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func toggle_pause() -> void:
	var new_pause_state = !get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state
	
	if new_pause_state:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		# Al abrir la pausa, siempre mostramos el menú principal, no el de opciones
		main_vbox.show()
		option_menu.hide()
		resume_button.grab_focus()
		_set_low_pass_filter(true)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		_set_low_pass_filter(false)

# --- FUNCIONES DE NAVEGACIÓN ---

func _on_options_button_pressed() -> void:
	main_vbox.hide()   # Ocultamos botones principales
	option_menu.show() # Mostramos panel de opciones
	back_button.grab_focus() # Foco al botón de volver

func _on_back_button_pressed() -> void:
	option_menu.hide() # Ocultamos opciones
	main_vbox.show()   # Mostramos botones principales
	option_button.grab_focus() # Foco vuelve al botón que nos trajo aquí

# --- LÓGICA DE JUEGO ---

func _on_resume_button_pressed() -> void:
	toggle_pause()

func _on_retry_button_pressed() -> void:
	get_tree().paused = false
	_set_low_pass_filter(false)
	GameManager.reset_game()
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	_set_low_pass_filter(false)
	LevelManager.go_to_level_select() # Descomenta si tienes esta función
	

# --- LÓGICA DE CONFIGURACIÓN ---

func _on_music_slider_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Musica")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _on_fullscreen_toggled(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _set_low_pass_filter(active: bool) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	for i in AudioServer.get_bus_effect_count(bus_idx):
		if AudioServer.get_bus_effect(bus_idx, i) is AudioEffectLowPassFilter:
			AudioServer.set_bus_effect_enabled(bus_idx, i, active)
