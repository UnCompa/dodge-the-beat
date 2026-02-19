extends Area2D

@export var speed: float = 200.0  
@export var gravity_object: float = 600.0  
@export var drift_variation: float = 40.0  
@export var scale_variation: float = 0.25  
@export var rotation_variation: float = 15.0  
@export var sprite_texture: Texture2D  
@export var use_random_color: bool = true
@export var trail_color_base: Color = Color(0.244, 0.61, 0.757, 1.0)

@onready var visible_notifier: VisibleOnScreenNotifier2D

# Referencias
var sprite: Sprite2D
var collision_shape: CollisionShape2D
var trail_particles: GPUParticles2D
var velocity: Vector2 = Vector2.ZERO
var base_scale: Vector2 = Vector2(0.2, 0.2)
var original_modulate: Color

func _ready():
	visible_notifier = VisibleOnScreenNotifier2D.new()
	visible_notifier.screen_exited.connect(_on_screen_exited)
	add_child(visible_notifier)

	create_sprite_obstacle()
	create_trail_particles()
	
	# VARIACIONES al aparecer (después de que spawner setee 'speed')
	apply_variations()
	
	# Configurar visible notifier después de escalas
	var size = sprite.texture.get_size() * sprite.scale if sprite.texture else Vector2(64, 64)
	visible_notifier.rect = Rect2(Vector2(-size.x / 2, -size.y / 2), size)

func apply_variations() -> void:
	# Variación de escala
	var scale_rand = 1.0 + randf_range(-scale_variation, scale_variation)
	sprite.scale = base_scale * scale_rand
	
	# Ajustar colisión al nuevo scale (sin deformación)
	collision_shape.scale = sprite.scale / base_scale
	
	# Variación de rotación
	sprite.rotation_degrees = randf_range(-rotation_variation, rotation_variation)
	collision_shape.rotation_degrees = sprite.rotation_degrees  # Rotación compartida
	
	# Variación local de velocidad (extra al spawner)
	
	# TODO: Fixed this logic, and add pulse beat with spawner logic
	#velocity.y = speed + randf_range(-speed_local_variation, speed_local_variation)
	
	# Drift horizontal para movimiento natural
	velocity.x = randf_range(-drift_variation, drift_variation)
	
	# Color aleatorio opcional (tint sprite y trail)
	if use_random_color:
		var random_hue = Color.from_hsv(randf(), 0.7 + randf() * 0.3, 0.8 + randf() * 0.2, 1.0)
		sprite.modulate = random_hue
		# Trail color se maneja en create_trail_particles, pero puedes recrear material si quieres dinámico

func create_sprite_obstacle() -> void:
	# Sprite
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = sprite_texture
	sprite.scale = base_scale
	add_child(sprite)
	
	# Colisión (tamaño base, se ajusta en variations)
	collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var rect_shape = RectangleShape2D.new()
	var texture_size = sprite_texture.get_size() if sprite_texture else Vector2(64, 64)
	rect_shape.size = texture_size * base_scale
	collision_shape.shape = rect_shape
	add_child(collision_shape)

func create_trail_particles() -> void:
	trail_particles = GPUParticles2D.new()
	trail_particles.name = "TrailParticles"
	trail_particles.show_behind_parent = true
	trail_particles.local_coords = false
	trail_particles.position = Vector2.ZERO
	add_child(trail_particles)
	
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(25, 8, 0)  # Un poco más ancho para drift
	
	# ¡Fix aquí! Usamos 'gravity_object' (Vector3), no 'gravity_object_object'
	material.gravity = Vector3(0, 980, 0)  # Gravedad extra en partículas (ajusta si quieres más/menos)
	
	material.initial_velocity_min = 80.0
	material.initial_velocity_max = 150.0
	material.spread = 45.0  # Más spread para variedad
	material.direction = Vector3(0, 1, 0)
	
	# Color (base o random)
	var trail_color: Color = trail_color_base
	if use_random_color:
		trail_color = Color.from_hsv(randf(), 0.8, 0.9, 1.0)
	var gradient := Gradient.new()
	gradient.add_point(0.0, trail_color)
	gradient.add_point(1.0, Color(trail_color.r * 0.5, trail_color.g * 0.5, trail_color.b * 0.5, 0.0))
	var color_ramp := GradientTexture1D.new()
	color_ramp.gradient = gradient
	material.color_ramp = color_ramp
	
	# Escala que se achica
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))
	scale_curve.add_point(Vector2(1.0, 0.0))
	var scale_texture := CurveTexture.new()
	scale_texture.curve = scale_curve
	material.scale_curve = scale_texture
	
	trail_particles.process_material = material
	trail_particles.amount = 64  # Más partículas para mejor efecto
	trail_particles.lifetime = 0.8
	trail_particles.emitting = true

func _physics_process(delta: float) -> void:
	# Aceleración por gravedad + movimiento
	velocity.y += gravity_object * delta
	position += velocity * delta
	
	# Actualizar trail basado en velocidad actual
	update_trail()

func update_trail() -> void:
	var speed_percent = clamp(velocity.length() / 500.0, 0.15, 1.0)
	trail_particles.amount_ratio = speed_percent
	trail_particles.speed_scale = 1.0 + (velocity.length() / 400.0) * 0.5  # Más rápido = trail más intenso

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print('Player hit!')
		# Impacto mejorado: dirección opuesta a velocity, fuerza por velocidad
		var impact_dir = -velocity.normalized()
		var impact_force = velocity.length()
		body.register_collision_impact(impact_dir, impact_force)

func _on_screen_exited() -> void:
	queue_free()
