extends Control
# En tu script de opciones o pausa
@onready var music_slider: HSlider = $CenterContainer/OptionPanel/HBoxContainer/MusicSlider
@onready var display_option: OptionButton = $CenterContainer/OptionPanel/HBoxContainer2/DisplayOption
@onready var exit: Button = $CenterContainer/OptionPanel/Exit

func _ready() -> void:
	hide()
	# Configurar el OptionButton
	display_option.add_item("Ventana")
	display_option.add_item("Pantalla Completa")
	
	# Conectar señales
	music_slider.value_changed.connect(_on_music_slider_changed)
	display_option.item_selected.connect(_on_display_item_selected)

# --- LÓGICA DE AUDIO ---
func _on_music_slider_changed(value: float) -> void:
	# El bus "Musica" debe ser el que creamos antes
	var bus_idx = AudioServer.get_bus_index("Musica")
	
	# Convertimos el valor lineal (0 a 1) a Decibelios (escala logarítmica)
	# db_to_linear(0) es silencio total (-80db aprox)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

# --- LÓGICA DE PANTALLA ---
func _on_display_item_selected(index: int) -> void:
	match index:
		0: # Ventana
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1: # Pantalla Completa
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
