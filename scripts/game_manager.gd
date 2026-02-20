# game_manager.gd
extends Node

signal lives_changed(new_lives)
signal score_changed(new_score)
signal game_over
signal game_started
signal level_completed

@export var max_lives: int = 1
var current_lives: int = 1:
	set(value):
		current_lives = clamp(value, 0, max_lives)
		lives_changed.emit(current_lives)
		if current_lives <= 0:
			print("MANAGER: ¡Vida en 0! Disparando secuencia de muerte...")
			_trigger_death_sequence()
var score: int = 0

# Referencia al bus Master
@onready var master_bus_idx = AudioServer.get_bus_index("Master")

func _ready() -> void:
	# Asegurarnos de que al arrancar el motor esté a velocidad normal
	Engine.time_scale = 1.0
	reset_game()

func reset_game() -> void:
	# 1. Limpiar efectos de audio (Desactivar el filtro de la muerte)
	# Usamos un bucle para apagar cualquier efecto de filtro que hayamos activado
	for i in AudioServer.get_bus_effect_count(master_bus_idx):
		if AudioServer.get_bus_effect(master_bus_idx, i) is AudioEffectLowPassFilter:
			AudioServer.set_bus_effect_enabled(master_bus_idx, i, false)
	
	# 2. Resetear el tiempo del motor
	Engine.time_scale = 1.0
	
	# 3. Resetear valores
	current_lives = max_lives
	score = 0
	lives_changed.emit(current_lives)
	score_changed.emit(score)
	game_started.emit()
	
func back_game() -> void:
	# 1. Limpiar efectos de audio (Desactivar el filtro de la muerte)
	# Usamos un bucle para apagar cualquier efecto de filtro que hayamos activado
	for i in AudioServer.get_bus_effect_count(master_bus_idx):
		if AudioServer.get_bus_effect(master_bus_idx, i) is AudioEffectLowPassFilter:
			AudioServer.set_bus_effect_enabled(master_bus_idx, i, false)
	
	# 2. Resetear el tiempo del motor
	Engine.time_scale = 1.0
	
	# 3. Resetear valores
	current_lives = max_lives
	score = 0
	lives_changed.emit(current_lives)
	score_changed.emit(score)

func decrease_lives():
	if current_lives <= 0: return
	
	current_lives -= 1
	lives_changed.emit(current_lives)
	
	if current_lives <= 0:
		_trigger_death_sequence()

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

func _trigger_death_sequence() -> void:
	game_over.emit()
	
	# Reducimos la duración total para que sea más frenético
	var duration := 0.01
	
	for i in AudioServer.get_bus_effect_count(master_bus_idx):
		var effect = AudioServer.get_bus_effect(master_bus_idx, i)
		if effect is AudioEffectLowPassFilter:
			AudioServer.set_bus_effect_enabled(master_bus_idx, i, true)
			
			var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			
			# Usamos TRANS_EXPO para que el cambio sea muy rápido al inicio y suave al final
			# El filtro baja a 400Hz casi instantáneamente
			tween.tween_property(effect, "cutoff_hz", 400.0, duration)\
				.from(20000.0)\
				.set_trans(Tween.TRANS_EXPO)\
				.set_ease(Tween.EASE_IN_OUT)
			
			# El tiempo se ralentiza en sincronía
			tween.parallel().tween_property(Engine, "time_scale", 0.1, duration)\
				.set_trans(Tween.TRANS_EXPO)\
				.set_ease(Tween.EASE_OUT)
			
			await tween.finished
			_show_game_over_ui()
			break # Salimos del bucle una vez encontrado y aplicado
			
func _show_game_over_ui():
	var go_ui = get_tree().current_scene.find_child("GameOverPanel", true, false)
	if go_ui:
		go_ui.show_screen()
		
func complete_level() -> void:
	print("¡NIVEL COMPLETADO!")
	level_completed.emit()
	LevelManager.complete_level(LevelManager.current_level_index)
	
	# 1. Detener el tiempo ligeramente para el efecto visual (opcional)
	# Engine.time_scale = 0.5 
	
	# 2. Hacer al jugador invulnerable para que nada lo mate en la pantalla de victoria
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.is_invulnerable = true 
	
	# 3. Mostrar el panel de victoria
	_show_win_ui()

func _show_win_ui():
	var win_ui = get_tree().current_scene.find_child("CompleteLevelPanel", true, false)
	if win_ui:
		# Si tu panel tiene una función para mostrarse:
		win_ui.show_win_screen() 
	else:
		push_warning("No se encontró el panel de Nivel Completado")
