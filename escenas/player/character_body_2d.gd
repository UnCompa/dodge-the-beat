extends CharacterBody2D

@export_group("Movimiento Normal")
@export var speed := 320.0
@export var acceleration := 1800.0
@export var deceleration := 1400.0

@export_group("Dash Settings")
@export var dash_speed := 600.0
@export var dash_duration := 0.2
@export var dash_cooldown := 0.6
@export var dash_brake_force := 5000.0

@export_group("JSAB Visuals")
@export var stretch_factor := 0.6
@export var squash_factor := 0.3
@export var rotation_speed := 20.0
@export var return_speed := 10.0
@export var min_stretch_vel := 20.0
@export var player_color := Color(0.2, 0.8, 1.0, 1.0)  # Celeste JSAB

### NUEVO: Sistema de Vidas ###
@export_group("Vidas")
@export var invulnerability_time: float = 1.5    # Segundos de invulnerabilidad
@export var blink_speed: float = 10.0            # Velocidad de parpadeo

#var current_lives: int
var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0
var blink_timer: float = 0.0
var is_visible_override: bool = true

var dash_timer: float = 0.0
var cooldown_timer: float = 0.0
var is_dashing: bool = false
var dash_direction := Vector2.ZERO

# Referencias a nodos creados dinámicamente
var collision_poly: CollisionPolygon2D
var visual_poly: Polygon2D
var trail_particles: GPUParticles2D

# Estado de deformación
var current_rotation: float = 0.0
var current_stretch: float = 0.0
var facing_direction: Vector2 = Vector2.RIGHT
var base_polygon: PackedVector2Array  # Forma base del polígono

func _ready() -> void:
	create_player_shape()
	create_trail_particles()
	add_to_group('player')
	
	GameManager.game_over.connect(_on_game_over_global)

func create_player_shape() -> void:
	var size := 10.0
	var half := size / 2.0
	
	base_polygon = PackedVector2Array([
		Vector2(-half, -half),
		Vector2(half, -half),
		Vector2(half, half),
		Vector2(-half, half),
	])
	
	collision_poly = CollisionPolygon2D.new()
	collision_poly.name = "CollisionPolygon2D"
	collision_poly.polygon = base_polygon.duplicate()
	add_child(collision_poly)
	
	visual_poly = Polygon2D.new()
	visual_poly.name = "VisualPolygon"
	visual_poly.polygon = base_polygon.duplicate()
	visual_poly.color = player_color
	visual_poly.polygons = [PackedInt32Array(range(base_polygon.size()))]
	visual_poly.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	
	collision_poly.add_child(visual_poly)
	
	collision_poly.position = Vector2.ZERO
	visual_poly.position = Vector2.ZERO

func create_trail_particles() -> void:
	trail_particles = GPUParticles2D.new()
	trail_particles.name = "TrailParticles"
	trail_particles.show_behind_parent = true
	trail_particles.local_coords = false
	trail_particles.position = Vector2.ZERO
	add_child(trail_particles)
	
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 20.0
	material.gravity = Vector3.ZERO
	material.spread = 0.0
	material.initial_velocity_min = 0.0
	material.initial_velocity_max = 0.0
	
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.6))
	scale_curve.add_point(Vector2(0.3, 1.0))
	scale_curve.add_point(Vector2(1.0, 0.0))
	var scale_texture := CurveTexture.new()
	scale_texture.curve = scale_curve
	material.scale_curve = scale_texture
	
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(player_color.r, player_color.g, player_color.b, 0.6))
	gradient.add_point(1.0, Color(player_color.r, player_color.g, player_color.b, 0.0))
	var color_ramp := GradientTexture1D.new()
	color_ramp.gradient = gradient
	material.color_ramp = color_ramp
	
	trail_particles.process_material = material
	trail_particles.amount = 150
	trail_particles.lifetime = 0.5
	trail_particles.emitting = true

func _physics_process(delta: float) -> void:
	### NUEVO: Manejar invulnerabilidad ###
	if is_invulnerable:
		update_invulnerability(delta)
	
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	if Input.is_action_just_pressed("ui_accept") and cooldown_timer <= 0:
		start_dash(input_dir)
	
	if is_dashing:
		process_dash(input_dir, delta)
	else:
		process_normal_movement(input_dir, delta)
	
	move_and_slide()
	update_jsab_shape(delta)
	update_trail()

### NUEVO: Función de invulnerabilidad ###
func update_invulnerability(delta: float) -> void:
	invulnerability_timer -= delta
	blink_timer += delta * blink_speed
	
	# Parpadeo: alternar visibilidad
	if blink_timer >= 1.0:
		blink_timer = 0.0
		is_visible_override = !is_visible_override
		visual_poly.visible = is_visible_override
	
	# Terminar invulnerabilidad
	if invulnerability_timer <= 0:
		is_invulnerable = false
		visual_poly.visible = true  # Asegurar que sea visible al terminar
		collision_poly.disabled = false  # Reactivar colisión

### NUEVO: Función para recibir daño ###
func take_damage() -> void:
	# Ahora preguntamos directamente al GameManager
	if is_invulnerable or is_dashing or GameManager.current_lives <= 0:
		return
	
	GameManager.current_lives -= 1
	
	# Ahora el print mostrará la vida REAL del Manager
	print("Vidas restantes (Manager): ", GameManager.current_lives)
	
	start_invulnerability()

### NUEVO: Iniciar invulnerabilidad ###
func start_invulnerability() -> void:
	is_invulnerable = true
	invulnerability_timer = invulnerability_time
	blink_timer = 0.0
	is_visible_override = true

func _on_game_over_global() -> void:
	print("Jugador: Deteniendo procesos por Game Over")
	set_physics_process(false)
	visual_poly.visible = false
	trail_particles.emitting = false

func update_jsab_shape(delta: float) -> void:
	var vel = velocity.length()
	
	if vel > min_stretch_vel:
		var move_dir = velocity.normalized()
		facing_direction = move_dir
		
		var vel_percent = clamp(vel / dash_speed, 0.0, 1.0)
		var target_stretch = lerp(0.0, stretch_factor, vel_percent)
		
		if is_dashing:
			target_stretch *= 1.3
		
		var target_rotation = move_dir.angle()
		current_rotation = lerp_angle(current_rotation, target_rotation, rotation_speed * delta)
		current_stretch = lerp(current_stretch, target_stretch, rotation_speed * delta)
	else:
		current_stretch = lerp(current_stretch, 0.0, return_speed * delta)
		if current_stretch < 0.05:
			current_rotation = lerp_angle(current_rotation, 0.0, return_speed * delta)
	
	apply_deformation()

func apply_deformation() -> void:
	if current_stretch < 0.01:
		visual_poly.rotation = current_rotation
		collision_poly.rotation = current_rotation
		visual_poly.scale = Vector2.ONE
		collision_poly.scale = Vector2.ONE
		return
	
	var stretch_mult = 1.0 + current_stretch
	var squash_mult = 1.0 - (current_stretch * squash_factor)
	
	visual_poly.rotation = current_rotation
	collision_poly.rotation = current_rotation
	
	var deform_scale = Vector2(stretch_mult, squash_mult)
	visual_poly.scale = deform_scale
	collision_poly.scale = deform_scale

func update_trail() -> void:
	var vel = velocity.length()
	var speed_percent = vel / dash_speed
	
	if vel > 50.0:
		trail_particles.amount_ratio = clamp(speed_percent, 0.2, 1.0)
	else:
		trail_particles.amount_ratio = 0.0
	
	if is_dashing:
		trail_particles.lifetime = 0.8
		trail_particles.self_modulate = Color(3.0, 3.0, 5.0, 1.0) # Brillo HDR
		visual_poly.self_modulate = Color(2.0, 2.0, 2.0, 1.0)    # Personaje brilla en blanco
	else:
		trail_particles.lifetime = 0.4
		trail_particles.self_modulate = Color.WHITE
		# Solo volvemos al color normal si no estamos parpadeando por daño
		if not is_invulnerable:
			visual_poly.self_modulate = Color.WHITE # O player_color si prefieres

func start_dash(input_dir: Vector2) -> void:
	is_dashing = true
	dash_timer = dash_duration
	cooldown_timer = dash_cooldown
	
	if input_dir == Vector2.ZERO:
		dash_direction = velocity.normalized() if velocity.length() > 10 else Vector2.RIGHT
	else:
		dash_direction = input_dir.normalized()
	
	velocity = dash_direction * dash_speed
	current_stretch = -0.15

func process_dash(input_dir: Vector2, delta: float) -> void:
	dash_timer -= delta
	
	if input_dir != Vector2.ZERO:
		var dot = input_dir.dot(dash_direction)
		if dot < -0.1:
			velocity = velocity.move_toward(Vector2.ZERO, dash_brake_force * delta)
	
	if dash_timer <= 0 or velocity.length() < speed:
		is_dashing = false
		current_stretch *= 0.3

func process_normal_movement(input_dir: Vector2, delta: float) -> void:
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)

### NUEVO: Función de colisión modificada ###
func register_collision_impact(collision_normal: Vector2, impact_force: float) -> void:
	# Solo aplicar efecto visual si no estamos invulnerables
	if not is_invulnerable:
		current_rotation = (-collision_normal).angle()
		current_stretch = clamp(impact_force / 800.0, 0.0, 0.4)
		
		visual_poly.self_modulate = Color.WHITE
		await get_tree().create_timer(0.05).timeout
		# Solo volver al color normal si no estamos en parpadeo
		if not is_invulnerable:
			visual_poly.self_modulate = player_color
	
	# Llamar daño
	take_damage()
