extends Area2D

enum Direction { DOWN, UP, LEFT, RIGHT }

@export var speed: float = 200.0
@export var accelerate: bool = false         # true = aumenta velocidad gradualmente
@export var acceleration_rate: float = 30.0   # unidades/segundo que gana de velocidad
@export var max_speed: float = 800.0          # techo de velocidad
@export var direction: Direction = Direction.DOWN

@export var scale_variation: float = 0.25
@export var rotation_variation: float = 15.0
@export var sprite_texture: Texture2D
@export var use_random_color: bool = true
@export var trail_color_base: Color = Color(0.244, 0.61, 0.757, 1.0)

var sprite: Sprite2D
var collision_shape: CollisionShape2D
var trail_particles: GPUParticles2D
var visible_notifier: VisibleOnScreenNotifier2D

var velocity: Vector2 = Vector2.ZERO
var current_speed: float = 0.0        # velocidad real actual (para la aceleración)
var move_dir: Vector2 = Vector2.ZERO  # dirección unitaria normalizada
var base_scale: Vector2 = Vector2(0.2, 0.2)
var pulse_energy: float = 1.0

# ─────────────────────────────────────────
#  CICLO DE VIDA
# ─────────────────────────────────────────

func _ready() -> void:
	set_physics_process(false)
	
	create_sprite_obstacle()
	apply_variations()
	create_trail_particles()
	setup_notifier()

# El spawner llama init() DESPUÉS de asignar direction, speed, etc.
func init() -> void:
	current_speed = speed
	move_dir      = _direction_to_vector(direction)
	velocity      = move_dir * current_speed
	_update_trail_direction()
	
	set_physics_process(true)

# ─────────────────────────────────────────
#  FÍSICA
# ─────────────────────────────────────────

func _physics_process(delta: float) -> void:
	# Aceleración gradual opcional
	if accelerate:
		current_speed = min(current_speed + acceleration_rate * delta, max_speed)

	velocity = move_dir * current_speed
	
	# CAMBIO CLAVE: Usamos global_position para ignorar cualquier jerarquía
	global_position += velocity * delta

	# Brillo de pulso
	#if pulse_energy > 1.0:
	#	pulse_energy = lerp(pulse_energy, 1.0, 0.10)
	#	sprite.self_modulate = Color(pulse_energy, pulse_energy, pulse_energy, 1.0)

	_update_trail_intensity()

# ─────────────────────────────────────────
#  REACCIÓN AL RITMO
# ─────────────────────────────────────────

func _on_beat_detected(magnitude: float) -> void:
	# --- SISTEMA DE PROBABILIDAD ---
	# Ajusta este valor: 0.5 = 50% de probabilidad, 0.3 = 30%, etc.
	var chance_to_pulse: float = 0.4 
	
	if randf() > chance_to_pulse:
		return # Si no pasa la probabilidad, ignoramos el beat y no hacemos nada
	# -------------------------------

	# Mapeamos la magnitud para que sea visible (de 0.1-1.2 a 1.0-5.0)
	var glow_intensity = remap(magnitude, 0.1, 1.2, 1.0, 5.0)
	glow_intensity = clamp(glow_intensity, 1.0, 6.0)
	
	var tween = create_tween()
	
	# Flash de iluminación HDR (Color Blanco puro por encima de 1.0 para que brille)
	tween.tween_property(sprite, "self_modulate", Color(glow_intensity, glow_intensity, glow_intensity, 1.0), 0.05) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		
	# Regreso suave al estado normal
	tween.tween_property(sprite, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Rebote de escala sutil mapeado
	var bounce_factor = remap(magnitude, 0.1, 1.2, 1.0, 1.25)
	var scale_tween = create_tween()
	scale_tween.tween_property(sprite, "scale", base_scale * bounce_factor, 0.05)
	scale_tween.tween_property(sprite, "scale", base_scale, 0.15)

# ─────────────────────────────────────────
#  CONSTRUCCIÓN DEL NODO
# ─────────────────────────────────────────

func apply_variations() -> void:
	var scale_rand = 1.0 + randf_range(-scale_variation, scale_variation)
	base_scale = base_scale * scale_rand
	sprite.scale = base_scale
	collision_shape.scale = sprite.scale / Vector2(0.2, 0.2)
	sprite.rotation_degrees = randf_range(-rotation_variation, rotation_variation)
	collision_shape.rotation_degrees = sprite.rotation_degrees
	if use_random_color:
		sprite.modulate = Color.from_hsv(randf(), 0.8, 1.0, 1.0)
		trail_color_base = sprite.modulate
	else:
		sprite.modulate = trail_color_base

func create_sprite_obstacle() -> void:
	sprite = Sprite2D.new()
	sprite.texture = sprite_texture
	sprite.scale = base_scale
	add_child(sprite)

	collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	var tex_size = sprite_texture.get_size() if sprite_texture else Vector2(64, 64)
	rect_shape.size = tex_size * base_scale
	collision_shape.shape = rect_shape
	add_child(collision_shape)

func create_trail_particles() -> void:
	trail_particles = GPUParticles2D.new()
	trail_particles.show_behind_parent = true
	trail_particles.local_coords = false
	add_child(trail_particles)

	var material := ParticleProcessMaterial.new()
	
	# Emisión: Caja mucho más pequeña para concentrar la "luz"
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(2, 2, 0)
	material.gravity = Vector3.ZERO
	
	# Las partículas salen muy lento respecto al proyectil, esto hace
	# que "dibujen" la línea exacta por donde pasó, como un trazo de luz
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 10.0
	
	# Dispersión casi nula para que no se esparza a los lados
	material.spread = 2.0
	material.direction = Vector3(0, -1, 0)

	var trail_color := trail_color_base
	if use_random_color and sprite:
		trail_color = sprite.modulate
		
	# Gradiente de color ajustado para parecer luz: 
	# Empieza con 60% de opacidad y se desvanece más rápido
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(trail_color.r, trail_color.g, trail_color.b, 0.6))
	gradient.add_point(0.8, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
	var color_ramp := GradientTexture1D.new()
	color_ramp.gradient = gradient
	material.color_ramp = color_ramp

	# La escala empieza media, se encoge rápido a 0 (estela afilada)
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))
	scale_curve.add_point(Vector2(0.3, 0.5))
	scale_curve.add_point(Vector2(1.0, 0.0))
	var scale_tex := CurveTexture.new()
	scale_tex.curve = scale_curve
	material.scale_curve = scale_tex
	
	# Tamaños más pequeños para que sea un rastro fino
	material.scale_min = 2.0
	material.scale_max = 6.0

	trail_particles.process_material = material
	
	# Menos partículas necesarias al ser más corto, y tiempo de vida reducido a la mitad
	trail_particles.amount = 40
	trail_particles.lifetime = 0.25 # <-- ESTO LA HACE MUCHO MÁS CORTA
	trail_particles.emitting = true

func setup_notifier() -> void:
	visible_notifier = VisibleOnScreenNotifier2D.new()
	add_child(visible_notifier)
	var tex_size = sprite_texture.get_size() if sprite_texture else Vector2(64, 64)
	var half = (tex_size * base_scale) / 2.0 + Vector2(30, 30)
	visible_notifier.rect = Rect2(-half, half * 2.0)
	visible_notifier.screen_exited.connect(_on_screen_exited)

# ─────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────

func _direction_to_vector(dir: Direction) -> Vector2:
	match dir:
		Direction.DOWN:  return Vector2(0,  1)
		Direction.UP:    return Vector2(0, -1)
		Direction.LEFT:  return Vector2(-1, 0)
		Direction.RIGHT: return Vector2( 1, 0)
	return Vector2(0, 1)

func _update_trail_direction() -> void:
	var material = trail_particles.process_material as ParticleProcessMaterial
	if material == null: return
	var trail_dir = -move_dir
	material.direction = Vector3(trail_dir.x, trail_dir.y, 0)

func _update_trail_intensity() -> void:
	var speed_ratio = clamp(current_speed / max_speed, 0.1, 1.0)
	trail_particles.amount_ratio = lerp(0.2, 1.0, speed_ratio)
	trail_particles.speed_scale  = lerp(0.5, 2.0, speed_ratio)

# ─────────────────────────────────────────
#  COLISIONES Y LIMPIEZA
# ─────────────────────────────────────────

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Verificamos si el jugador tiene la variable 'is_dashing' en true
		if "is_dashing" in body and body.is_dashing:
			# Si está dasheando, no hacemos nada y salimos de la función
			return 
		
		# Si NO está dasheando, aplicamos el impacto y destruimos el proyectil
		body.register_collision_impact(-velocity.normalized(), velocity.length())
		queue_free()

func _on_screen_exited() -> void:
	queue_free()
