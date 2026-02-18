extends CharacterBody2D

@export_group("Movimiento Normal")
@export var speed := 320.0
@export var acceleration := 1800.0
@export var deceleration := 1400.0

@export_group("Dash Settings")
@export var dash_speed := 600.0 # Un poco más rápido para compensar el frenado
@export var dash_duration := 0.2
@export var dash_cooldown := 0.6
@export var dash_brake_force := 5000.0 # Fuerza para frenar si presionas atrás

var dash_timer: float = 0.0
var cooldown_timer: float = 0.0
var is_dashing: bool = false
var dash_direction := Vector2.ZERO

@onready var trail_particles: GPUParticles2D

func _ready() -> void:
	create_and_setup_trail()

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Gestionar timers
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	# LÓGICA DE DASH
	if Input.is_action_just_pressed("ui_accept") and cooldown_timer <= 0:
		start_dash(input_dir)
	
	if is_dashing:
		process_dash(input_dir, delta)
	else:
		process_normal_movement(input_dir, delta)
	
	move_and_slide()
	update_trail()

func start_dash(input_dir: Vector2) -> void:
	is_dashing = true
	dash_timer = dash_duration
	cooldown_timer = dash_cooldown
	
	# Si no hay input, dashea hacia donde ya se movía o hacia adelante
	if input_dir == Vector2.ZERO:
		dash_direction = velocity.normalized() if velocity.length() > 10 else Vector2.RIGHT
	else:
		dash_direction = input_dir.normalized()
	
	velocity = dash_direction * dash_speed

func process_dash(input_dir: Vector2, delta: float) -> void:
	dash_timer -= delta
	
	# --- MEJORA DE CONTROL: FRENADO CONTRARIO ---
	# Si el jugador presiona una dirección opuesta al dash, desaceleramos fuerte
	if input_dir != Vector2.ZERO:
		var dot_product = input_dir.dot(dash_direction)
		if dot_product < -0.1: # Está presionando hacia atrás o diagonal atrás
			velocity = velocity.move_toward(Vector2.ZERO, dash_brake_force * delta)
	
	# Salir del dash si se acaba el tiempo o si frenamos casi por completo
	if dash_timer <= 0 or velocity.length() < speed:
		is_dashing = false

func process_normal_movement(input_dir: Vector2, delta: float) -> void:
	if input_dir != Vector2.ZERO:
		# Aceleración normal
		velocity = velocity.move_toward(input_dir * speed, acceleration * delta)
	else:
		# Fricción cuando no hay input
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)

func create_and_setup_trail() -> void:
	trail_particles = GPUParticles2D.new()
	trail_particles.name = "TrailParticles"
	trail_particles.show_behind_parent = true
	trail_particles.local_coords = false 
	
	# Asegúrate de que la posición sea el centro (0,0) relativo al CharacterBody2D
	trail_particles.position = Vector2.ZERO 
	add_child(trail_particles)
	
	var material := ParticleProcessMaterial.new()
	
	# --- LA CLAVE PARA EL CENTRO ---
	# Esto hace que las partículas nazcan en un área circular en lugar de un punto
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 15.0 # Ajusta este radio según el tamaño de tu Sprite
	# -------------------------------

	material.gravity = Vector3.ZERO
	material.spread = 0.0
	material.initial_velocity_min = 0.0
	material.initial_velocity_max = 0.0
	
	# Curva de escala (más bonito: empieza mediano, crece un poco y desaparece)
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.5))
	scale_curve.add_point(Vector2(0.2, 1.0))
	scale_curve.add_point(Vector2(1.0, 0.0))
	var scale_texture := CurveTexture.new()
	scale_texture.curve = scale_curve
	material.scale_curve = scale_texture
	
	# Gradiente
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(0.15, 0.55, 1.0, 0.8)) # Un poco de transparencia inicial
	gradient.add_point(1.0, Color(0.15, 0.55, 1.0, 0.0)) 
	var color_ramp := GradientTexture1D.new()
	color_ramp.gradient = gradient
	material.color_ramp = color_ramp

	trail_particles.process_material = material
	
	trail_particles.amount = 100
	trail_particles.lifetime = 0.4
	trail_particles.emitting = true

func update_trail() -> void:
	var speed_percent = velocity.length() / dash_speed
	
	if velocity.length() > 50.0:
		# En lugar de apagar/prender, ajustamos la cantidad de partículas
		trail_particles.amount_ratio = clamp(speed_percent, 0.2, 1.0)
	else:
		trail_particles.amount_ratio = 0.0
	
	if is_dashing:
		trail_particles.lifetime = 0.8
		# Glow usando modulación (requiere que el CanvasItem tenga un material con Bloom)
		trail_particles.self_modulate = Color(2.5, 2.5, 5.0, 1.0) 
	else:
		trail_particles.lifetime = 0.4
		trail_particles.self_modulate = Color.WHITE
