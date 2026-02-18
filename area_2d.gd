extends Area2D

@export var speed: float = 200.0
@export var stretch_speed: float = 5.0
@export var max_stretch: float = 0.5
@export var sprite_texture: Texture2D  # <-- Asigna tu imagen aquí
@export var destroy_offset: float = 100.0  # Margen fuera de pantalla

@onready var visible_notifier: VisibleOnScreenNotifier2D

# Referencias
var sprite: Sprite2D
var collision_shape: CollisionShape2D  # RectangleShape2D para el sprite
var trail_particles: GPUParticles2D

# Estado
var current_stretch: float = 0.0
var base_scale: Vector2 = Vector2.ONE

func _ready():
	visible_notifier = VisibleOnScreenNotifier2D.new()
	visible_notifier.screen_exited.connect(_on_screen_exited)
	add_child(visible_notifier)
	
	# Opcional: ajustar el rectángulo de detección al tamaño del sprite
	if has_node("Sprite2D"):
		var sprite = $Sprite2D
		var size = sprite.texture.get_size() * sprite.scale if sprite.texture else Vector2(40, 40)
		visible_notifier.rect = Rect2(-size/2, size)

	create_sprite_obstacle()
	create_trail_particles()

func create_sprite_obstacle() -> void:
	# 1. Crear Sprite2D
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = sprite_texture
	sprite.scale = Vector2(0.2, 0.2)  # <-- TAMAÑO DEL SPRITE (ajusta aquí)
	base_scale = sprite.scale
	add_child(sprite)
	
	# 2. Crear colisión basada en el tamaño del sprite
	collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	
	var rect_shape = RectangleShape2D.new()
	# Tamaño de colisión = tamaño de la textura * escala del sprite
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
	material.emission_box_extents = Vector3(20, 5, 0)
	
	# Partículas hacia abajo
	material.gravity = Vector3(0, 980, 0)
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 100.0
	material.spread = 30.0
	material.direction = Vector3(0, 1, 0)
	
	# Color desde el sprite (o default rojo)
	var trail_color = Color(0.244, 0.61, 0.757, 1.0)
	
	var gradient := Gradient.new()
	gradient.add_point(0.0, trail_color)
	gradient.add_point(1.0, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
	var color_ramp := GradientTexture1D.new()
	color_ramp.gradient = gradient
	material.color_ramp = color_ramp
	
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))
	scale_curve.add_point(Vector2(1.0, 0.0))
	var scale_texture := CurveTexture.new()
	scale_texture.curve = scale_curve
	material.scale_curve = scale_texture
	
	trail_particles.process_material = material
	trail_particles.amount = 50
	trail_particles.lifetime = 0.6
	trail_particles.emitting = true

func _physics_process(delta: float) -> void:
	position.y += speed * delta
	update_stretch(delta)
	update_trail()

func update_stretch(delta: float) -> void:
	var target_stretch = clamp(speed / 400.0, 0.0, max_stretch)
	current_stretch = lerp(current_stretch, target_stretch, stretch_speed * delta)
	
	# Estirar en Y (caída), comprimir en X
	var stretch_mult = 1.0 + current_stretch
	var squash_mult = 1.0 - (current_stretch * 0.5)
	
	var deform_scale = Vector2(squash_mult, stretch_mult)
	
	# Aplicar al sprite y a la colisión
	sprite.scale = base_scale * deform_scale
	collision_shape.scale = deform_scale

func update_trail() -> void:
	var speed_percent = clamp(speed / 400.0, 0.2, 1.0)
	trail_particles.amount_ratio = speed_percent

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):  # O verifica con has_method
		print('Player touch')
		body.register_collision_impact(Vector2.UP, speed)
		
func _on_screen_exited() -> void:
	print('saliendo')
	queue_free()
