extends Node2D

signal beat_hit(magnitude)

enum SpawnSide { TOP, BOTTOM, LEFT, RIGHT }

const DIFFICULTY_PATTERNS: Array = [
	[[SpawnSide.TOP]],
	[[SpawnSide.TOP], [SpawnSide.BOTTOM]],
	[[SpawnSide.TOP], [SpawnSide.BOTTOM], [SpawnSide.LEFT], [SpawnSide.RIGHT]],
	[[SpawnSide.TOP, SpawnSide.BOTTOM], [SpawnSide.LEFT, SpawnSide.RIGHT]],
	[[SpawnSide.TOP, SpawnSide.LEFT], [SpawnSide.BOTTOM, SpawnSide.RIGHT]],
	[[SpawnSide.TOP, SpawnSide.BOTTOM, SpawnSide.LEFT, SpawnSide.RIGHT]],
]

@export_group("Spawner Settings")
@export var obstacle_scene: PackedScene
@export var camera: Camera2D
@export var random_sides: bool = true
@export var side_override: SpawnSide = SpawnSide.TOP
@export var margin: float = 80.0

@export_group("Dificultad")
@export var base_speed: float = 200.0
@export var speed_variation: float = 50.0
@export var max_speed_multiplier: float = 2.5
@export var difficulty_cap: int = 5
@export var difficulty_interval: float = 60.0
@export var max_obstacles_per_beat: int = 6
@export var acceleration_difficulty_threshold: int = 3

@export_group("Análisis de Ritmo")
@export var music: AudioStreamPlayer2D
@export var energy_threshold: float = 0.5
@export var min_time_between_beats: float = 0.2
@export var freq_range_low: float = 20.0
@export var freq_range_high: float = 150.0

var spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance
var last_beat_time: float = 0.0
var difficulty_level: int = 0
var song_time: float = 0.0

# ─────────────────────────────────────────

func _ready() -> void:
	if music == null:
		push_error("¡Asigna un AudioStreamPlayer2D!")
		return
	if camera == null:
		push_warning("No hay cámara asignada, usando viewport como fallback.")

	spectrum_analyzer = AudioServer.get_bus_effect_instance(
		AudioServer.get_bus_index("Master"), 0
	)
	music.play()

func _process(_delta: float) -> void:
	if not music.playing: return

	song_time = music.get_playback_position() + AudioServer.get_time_since_last_mix()
	song_time -= AudioServer.get_output_latency()

	var current_interval = floor(song_time / difficulty_interval)
	if current_interval > difficulty_level and difficulty_level < difficulty_cap:
		difficulty_level = int(current_interval)

	if spectrum_analyzer == null: return

	var magnitude = spectrum_analyzer.get_magnitude_for_frequency_range(
		freq_range_low, freq_range_high
	).length() * 100

	var current_time = Time.get_ticks_msec() / 1000.0
	if magnitude > energy_threshold and (current_time - last_beat_time) > min_time_between_beats:
		beat_hit.emit(magnitude)
		_spawn_wave(magnitude)
		last_beat_time = current_time

# ─────────────────────────────────────────
#  BOUNDS — coordenadas GLOBALES del mundo
# ─────────────────────────────────────────

func _get_bounds() -> Rect2:
	var view_size: Vector2
	var center: Vector2

	if camera != null:
		view_size = get_viewport_rect().size / camera.zoom
		center = camera.global_position
	else:
		view_size = get_viewport_rect().size
		center = view_size / 2.0

	var half := view_size / 2.0
	return Rect2(center - half, view_size)

# ─────────────────────────────────────────
#  SPAWN
# ─────────────────────────────────────────

func _spawn_wave(magnitude: float) -> void:
	if obstacle_scene == null: return

	var bounds: Rect2 = _get_bounds()
	var pattern_pool: Array = DIFFICULTY_PATTERNS[clamp(difficulty_level, 0, DIFFICULTY_PATTERNS.size() - 1)]
	var chosen_pattern: Array = pattern_pool[randi() % pattern_pool.size()]

	if not random_sides:
		chosen_pattern = [side_override]

	var song_length: float = music.stream.get_length() if music.stream else 180.0
	var song_progress: float = clamp(song_time / song_length, 0.0, 1.0)
	var speed_mult: float = lerp(1.0, max_speed_multiplier, song_progress) * pow(1.2, float(difficulty_level))

	var per_side: int = int(clamp(
		float(difficulty_level + 1) + floor(magnitude * 0.04),
		1.0, float(max_obstacles_per_beat)
	))

	var should_accelerate: bool = difficulty_level >= acceleration_difficulty_threshold

	for side in chosen_pattern:
		for i in range(per_side):
			_spawn_single(side, bounds, speed_mult, should_accelerate, magnitude)

func _spawn_single(side: SpawnSide, bounds: Rect2, speed_mult: float, should_accelerate: bool, magnitude: float) -> void:
	var obstacle = obstacle_scene.instantiate()

	var spawn_pos: Vector2
	var obstacle_direction: int  # índice del enum Direction del obstáculo

	match side:
		SpawnSide.TOP:
			spawn_pos = Vector2(randf_range(bounds.position.x, bounds.end.x), bounds.position.y - margin)
			obstacle_direction = 0  # DOWN
		SpawnSide.BOTTOM:
			spawn_pos = Vector2(randf_range(bounds.position.x, bounds.end.x), bounds.end.y + margin)
			obstacle_direction = 1  # UP
		SpawnSide.LEFT:
			spawn_pos = Vector2(bounds.position.x - margin, randf_range(bounds.position.y, bounds.end.y))
			obstacle_direction = 3  # RIGHT
		SpawnSide.RIGHT:
			spawn_pos = Vector2(bounds.end.x + margin, randf_range(bounds.position.y, bounds.end.y))
			obstacle_direction = 2  # LEFT

	# Verificación de seguridad CRÍTICA
	if obstacle.has_method("init"):
		# 1. Asignamos propiedades ANTES de iniciarlo
		obstacle.set("direction", obstacle_direction)
		
		var final_speed := (base_speed * speed_mult) + randf_range(-speed_variation, speed_variation)
		obstacle.set("speed", clamp(final_speed, base_speed * 0.5, base_speed * max_speed_multiplier * 2.0))
		obstacle.set("accelerate", should_accelerate)
		
		# 2. Asignamos posición global
		obstacle.global_position = spawn_pos
		
		# 3. CAMBIO CLAVE: Lo añadimos a la escena raíz, NO al spawner
		get_tree().current_scene.add_child(obstacle)
		
		# 4. Conectamos señales y activamos
		beat_hit.connect(obstacle._on_beat_detected)
		obstacle.init()
		obstacle._on_beat_detected(magnitude)
	else:
		push_error("ERROR: El proyectil no tiene el script en su nodo raíz. ¡Revisa tu escena 'obstacle_scene'!")
		obstacle.queue_free()
