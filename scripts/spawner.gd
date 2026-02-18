extends Node2D

@export_group("Spawner Settings")
@export var obstacle_scene: PackedScene  # <-- Arrastra tu escena de obstáculo aquí
@export var spawn_interval: float = 1.5    # Segundos entre spawns
@export var spawn_width: float = 800.0     # Ancho de la zona de spawn (X)
@export var spawn_height_offset: float = -100.0  # Altura donde spawnean (arriba de pantalla)

@export_group("Variación")
@export var random_interval: bool = true
@export var min_interval: float = 0.8
@export var max_interval: float = 2.5
@export var speed_variation: float = 50.0   # +/- velocidad de obstáculos

var spawn_timer: float = 0.0
var next_spawn_time: float = 0.0
var screen_bottom: float = 0.0

func _ready():
	# Calcular límites de pantalla
	var viewport = get_viewport_rect()
	screen_bottom = viewport.size.y + 100.0
	
	# Primer spawn inmediato o con delay
	set_next_spawn_time()
	spawn_timer = next_spawn_time * 0.5  # Primer spawn más rápido

func _process(delta: float) -> void:
	spawn_timer += delta
	
	if spawn_timer >= next_spawn_time:
		spawn_obstacle()
		spawn_timer = 0.0
		set_next_spawn_time()
	
	# Limpiar obstáculos que salieron de pantalla (opcional)
	cleanup_obstacles()

func set_next_spawn_time() -> void:
	if random_interval:
		next_spawn_time = randf_range(min_interval, max_interval)
	else:
		next_spawn_time = spawn_interval

func spawn_obstacle() -> void:
	if obstacle_scene == null:
		push_error("No hay escena de obstáculo asignada!")
		return
	
	# Instanciar obstáculo
	var obstacle = obstacle_scene.instantiate()
	
	# Posición aleatoria en X, arriba de la pantalla
	var random_x = randf_range(-spawn_width / 2, spawn_width / 2)
	obstacle.position = Vector2(random_x, spawn_height_offset)
	
	# Variación de velocidad (opcional)
	if obstacle.has_method("set_speed") or "speed" in obstacle:
		var base_speed = obstacle.get("speed") if "speed" in obstacle else 200.0
		var new_speed = base_speed + randf_range(-speed_variation, speed_variation)
		obstacle.set("speed", new_speed)
	
	add_child(obstacle)

func cleanup_obstacles() -> void:
	# Eliminar obstáculos que pasaron la pantalla
	for child in get_children():
		if child is Area2D and child.position.y > screen_bottom:
			child.queue_free()
			
