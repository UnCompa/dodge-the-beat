extends Node2D

signal beat_hit(magnitude)

enum SpawnSide { TOP, BOTTOM, LEFT, RIGHT }

const DIFFICULTY_PATTERNS: Array = [
	# Dificultad 1 — Un solo lado (los 4 posibles)
	[
		[SpawnSide.TOP],
		[SpawnSide.BOTTOM],
		[SpawnSide.LEFT],
		[SpawnSide.RIGHT],
	],
	# Dificultad 2 — Dos lados (todas las combinaciones posibles: 6 pares)
	[
		[SpawnSide.TOP,    SpawnSide.BOTTOM],
		[SpawnSide.LEFT,   SpawnSide.RIGHT],
		[SpawnSide.TOP,    SpawnSide.LEFT],
		[SpawnSide.TOP,    SpawnSide.RIGHT],
		[SpawnSide.BOTTOM, SpawnSide.LEFT],
		[SpawnSide.BOTTOM, SpawnSide.RIGHT],
	],
	# Dificultad 3 — Tres lados (todas las combinaciones posibles: 4 tríos)
	[
		[SpawnSide.TOP,    SpawnSide.BOTTOM, SpawnSide.LEFT],
		[SpawnSide.TOP,    SpawnSide.BOTTOM, SpawnSide.RIGHT],
		[SpawnSide.TOP,    SpawnSide.LEFT,   SpawnSide.RIGHT],
		[SpawnSide.BOTTOM, SpawnSide.LEFT,   SpawnSide.RIGHT],
	],
	# Dificultad 4 — Los cuatro lados a la vez
	[
		[SpawnSide.TOP, SpawnSide.BOTTOM, SpawnSide.LEFT, SpawnSide.RIGHT],
	],
]

@export_group("Spawner Settings")
## La escena del proyectil/obstáculo que se instanciará en cada beat.
## Debe tener un script con los métodos init() y _on_beat_detected() en su nodo raíz.
@export var obstacle_scene: PackedScene

## Referencia a la cámara del nivel. Se usa para calcular los límites del mundo
## y saber desde dónde spawnear los obstáculos correctamente.
## Si se deja vacío, se usa el tamaño del viewport como fallback.
@export var camera: Camera2D

## Si está ACTIVADO: los obstáculos aparecen desde múltiples lados según la dificultad,
## empezando desde side_override en dificultad 0 y abriendo más lados progresivamente.
## Si está DESACTIVADO: los obstáculos SIEMPRE spawnean solo desde el lado definido en side_override.
@export var random_sides: bool = true

## El lado desde el que spawnean los obstáculos cuando random_sides está desactivado.
## También define el lado inicial cuando random_sides está activado (dificultad 0).
## TOP = arriba, BOTTOM = abajo, LEFT = izquierda, RIGHT = derecha.
@export var side_override: SpawnSide = SpawnSide.TOP

## Distancia en píxeles fuera del borde de la pantalla donde aparecen los obstáculos.
## Un valor mayor da más "tiempo de reacción" al jugador antes de que el proyectil entre en pantalla.
## Recomendado: entre 50 y 150 px según el tamaño y velocidad de tus obstáculos.
@export var margin: float = 80.0


@export_group("Dificultad")

## Velocidad base en píxeles/segundo de los obstáculos al inicio de la canción.
## Esta es la velocidad mínima de referencia; se multiplica por speed_mult a lo largo de la canción.
## Ajusta según el tamaño de tu nivel: niveles más grandes necesitan valores más altos.
@export var base_speed: float = 200.0

## Variación aleatoria de velocidad aplicada a cada obstáculo individualmente (± este valor).
## Hace que los proyectiles no lleguen todos al mismo tiempo, añadiendo impredecibilidad.
## Un valor de 0 hace que todos vayan exactamente a la misma velocidad.
@export var speed_variation: float = 50.0

## Multiplicador máximo de velocidad que se alcanzará al final de la canción.
## La velocidad crece linealmente desde 1.0x al inicio hasta este valor al final.
## Ejemplo: 2.5 significa que al final los obstáculos van al 250% de base_speed.
@export var max_speed_multiplier: float = 2.5

## Nivel de dificultad máximo que puede alcanzar el juego.
## Debe coincidir con el número de entradas en DIFFICULTY_PATTERNS (actualmente 5).
## Subir este valor sin agregar patrones equivalentes puede causar errores de índice.
@export var difficulty_cap: int = 4

## Cada cuántos segundos de canción sube un nivel de dificultad.
## Ejemplo: 60.0 significa que la dificultad sube cada minuto.
## Para canciones cortas (~1 min) usa valores de 20-30. Para canciones largas (~3 min) usa 60-90.
@export var difficulty_interval: float = 60.0

## Cantidad máxima de obstáculos que pueden spawnear por lado en un solo beat.
## Actúa como techo duro: aunque la magnitud o dificultad sean muy altas, nunca se superará este número.
## Recomendado: entre 4 y 8 según qué tan caótico quieres que sea el juego en su pico.
@export var max_obstacles_per_beat: int = 6

## A partir de qué nivel de dificultad los obstáculos empiezan a acelerar con cada beat detectado.
## Si el obstáculo tiene un efecto de aceleración en su script, se activará desde este nivel.
## Ejemplo: 3 significa que en dificultad 0, 1 y 2 los obstáculos van a velocidad constante.
@export var acceleration_difficulty_threshold: int = 3


@export_group("Análisis de Ritmo")

## El AudioStreamPlayer2D que reproduce la música del nivel.
## Es OBLIGATORIO: el spawner analiza el espectro de frecuencias de este player para detectar beats.
## Asegúrate de que su bus de audio tenga un efecto AudioEffectSpectrumAnalyzer asignado.
@export var music: AudioStreamPlayer2D

## Magnitud mínima que debe alcanzar el espectro de frecuencias para considerarse un beat válido.
## Valores más altos = solo los golpes fuertes generan obstáculos (más selectivo).
## Valores más bajos = casi cualquier sonido genera obstáculos (más caótico).
## Ajusta junto con sensitivity: si ves demasiados spawns, sube este valor.
@export var energy_threshold: float = 0.5

## Tiempo mínimo en segundos entre dos beats consecutivos.
## Evita que un beat muy largo genere una avalancha de obstáculos.
## Para canciones rápidas (140+ BPM) baja a ~0.15. Para canciones lentas sube a ~0.35.
@export var min_time_between_beats: float = 0.2

## Frecuencia mínima del rango que se analiza para detectar beats (en Hz).
## El rango 20-150 Hz captura graves y bombos (kick drum), ideal para música electrónica.
## Para música más melódica o aguda, prueba rangos como 200-800 Hz.
@export var freq_range_low: float = 20.0

## Frecuencia máxima del rango que se analiza para detectar beats (en Hz).
## Junto con freq_range_low define qué parte del espectro "escucha" el spawner.
## Subir este valor captura más medios/agudos además de los graves.
@export var freq_range_high: float = 150.0

## Amplificador de la magnitud cruda del espectro antes de compararla con energy_threshold.
## Es el control más importante para calibrar el spawner a cada canción.
## Si la canción no genera casi obstáculos: sube sensitivity. Si genera demasiados: bájala.
## Rango típico: entre 20 y 100 dependiendo del volumen y compresión de la pista.
@export var sensitivity: float = 50.0

@export_group("Color de Obstáculos")
@export var color_mode: int = 0
## 0 = cada obstáculo elige color aleatorio
## 1 = todos usan el mismo color fijo (spawner_color)
## 2 = todos usan el mismo color pero se renueva al cambiar de dificultad
@export var spawner_color: Color = Color(0.244, 0.61, 0.757, 1.0)

var active_color: Color = Color.TRANSPARENT

var spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance
var last_beat_time: float = 0.0
var difficulty_level: int = 0
var song_time: float = 0.0
var current_pattern: Array = []

# ─────────────────────────────────────────

func _ready() -> void:
	if music == null:
		push_error("¡Asigna un AudioStreamPlayer2D!")
		return
	if camera == null:
		push_warning("No hay cámara asignada, usando viewport como fallback.")

	spectrum_analyzer = AudioServer.get_bus_effect_instance(
		AudioServer.get_bus_index("Musica"), 0
	)
	await get_tree().process_frame 
	
	music.play()
	print("Iniciando canción: ", music.stream.resource_path)
	
	music.finished.connect(_on_music_finished)
	_refresh_color()
	
	
func _on_music_finished():
	# SEGURIDAD: Solo completar si el tiempo de la canción es mayor a 0
	# y si realmente ha pasado un tiempo mínimo desde que empezó el nivel.	
	if music.stream:
		if GameManager.current_lives > 0:
			GameManager.complete_level()
	else:
		# Si se dispara al segundo 0, es un error de carga o stream vacío
		print("Música finalizada prematuramente. ¿El archivo de audio es válido?")

func _process(_delta: float) -> void:
	if not music.playing: return

	song_time = music.get_playback_position() + AudioServer.get_time_since_last_mix()
	song_time -= AudioServer.get_output_latency()

	var current_interval = floor(song_time / difficulty_interval)
	if current_interval > difficulty_level and difficulty_level < difficulty_cap:
				difficulty_level = int(current_interval)
				
				# ── LOG DE CAMBIO DE DIFICULTAD ──
				var sides_desc: String
				match difficulty_level:
					0: sides_desc = "1 lado fijo (side_override)"
					1: sides_desc = "1 lado aleatorio"
					2: sides_desc = "2 lados aleatorios"
					3: sides_desc = "3 lados aleatorios"
					4: sides_desc = "4 lados (todos)"
					_: sides_desc = "desconocido"
				
				var time_str = "%d:%02d" % [int(song_time) / 60, int(song_time) % 60]
				print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
				print("🎯 DIFICULTAD %d  |  ⏱ %s" % [difficulty_level, time_str])
				print("   Patrón: %s" % sides_desc)
				print("   Velocidad base actual: x%.2f" % (pow(1.15, float(difficulty_level))))
				print("   Aceleración activa: %s" % ("SÍ" if difficulty_level >= acceleration_difficulty_threshold else "NO"))
				print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
				_select_new_pattern()

	if spectrum_analyzer == null: return

	var magnitude = spectrum_analyzer.get_magnitude_for_frequency_range(
		freq_range_low, freq_range_high
	).length() * sensitivity

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
	
	var label = _get_intensity_label(magnitude)
	print("Ritmo detectado: ", label, " | Magnitud: ", str(magnitude).pad_decimals(3))

	var bounds: Rect2 = _get_bounds()
	
	var intensity_ratio = remap(magnitude, energy_threshold, 5.0, 0.0, 1.0)
	intensity_ratio = clamp(intensity_ratio, 0.0, 1.0)

	# ── NUEVO: Selección de patrón respetando random_sides y side_override ──
	var chosen_pattern: Array = []

	if not random_sides:
		# Modo fijo: siempre usa side_override, sin importar la dificultad
		chosen_pattern = [side_override]
	else:
		# Modo aleatorio: en dificultad 0, empieza desde side_override si está definido
		if difficulty_level == 0:
			chosen_pattern = [side_override]
		else:
			# A partir de dificultad 1, usa los patrones progresivos normalmente
			chosen_pattern = current_pattern

	# ── NUEVO: Cantidad de obstáculos según intensidad real de la magnitud ──
	# En lugar de usar difficulty_level para base_count, la magnitud manda
	var base_count: int
	if magnitude > 5.0:   base_count = 5      # EXTREMO
	elif magnitude > 3.5: base_count = 4      # ALTO
	elif magnitude > 2.5: base_count = 3      # MEDIO-ALTO
	elif magnitude > 1.5: base_count = 2      # MEDIO
	elif magnitude > 0.8: base_count = 1      # BAJO-MEDIO
	else:                 base_count = 1      # BAJO — mínimo 1

	# Bono adicional por dificultad (progresivo pero que no aplaste la intensidad)
	var difficulty_bonus = int(difficulty_level * 0.5)
	var total_per_side = clamp(base_count + difficulty_bonus, 1, max_obstacles_per_beat)

	# Velocidad (sin cambios)
	var song_length: float = music.stream.get_length() if music.stream else 180.0
	var song_progress: float = clamp(song_time / song_length, 0.0, 1.0)
	var speed_mult: float = lerp(1.0, max_speed_multiplier, song_progress) * pow(1.15, float(difficulty_level))

	var should_accelerate: bool = difficulty_level >= acceleration_difficulty_threshold

	for side in chosen_pattern:
		for i in range(total_per_side):
			_spawn_single(side, bounds, speed_mult, should_accelerate, magnitude)
			
	# DEBUG — borrarlo una vez confirmado
	print("   chosen_pattern: ", chosen_pattern, " | dif: ", difficulty_level, " | random_sides: ", random_sides)
	if GameManager.current_lives != 0:
		GameManager.add_score(1)
	
func _get_intensity_label(mag: float) -> String:
	if mag > 5.0:   return "🔥 [EXTREMO]"      # Picos máximos
	if mag > 3.5:   return "⚡ [ALTO]"         # Beats muy marcados
	if mag > 2.5:   return "✨ [MEDIO-ALTO]"   # Ritmo constante
	if mag > 1.5:   return "💎 [MEDIO]"        # El cuerpo de la canción
	if mag > 0.8:   return "🍃 [BAJO-MEDIO]"   # Sonidos de fondo
	return "❄️ [BAJO]"                         # Silencios o sutiles

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
		
		if active_color != Color.TRANSPARENT:
			obstacle.set("use_random_color", false)
			obstacle.set("trail_color_base", active_color)
		
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


func _on_audio_stream_player_2d_finished() -> void:
	pass # Replace with function body.
	
func _select_new_pattern() -> void:
	if not random_sides:
		current_pattern = [side_override]
		return
	
	if difficulty_level == 0:
		current_pattern = [side_override]
	else:
		var pattern_pool: Array = DIFFICULTY_PATTERNS[clamp(difficulty_level - 1, 0, DIFFICULTY_PATTERNS.size() - 1)]
		current_pattern = pattern_pool[randi() % pattern_pool.size()]
	
	print("🎲 Nuevo patrón seleccionado: ", current_pattern)
	_refresh_color()
	
func _refresh_color() -> void:
	match color_mode:
		0: active_color = Color.TRANSPARENT  # aleatorio por obstáculo
		1: active_color = spawner_color       # fijo siempre
		2: active_color = Color.from_hsv(randf(), 0.8, 1.0, 1.0)  # aleatorio por dificultad
