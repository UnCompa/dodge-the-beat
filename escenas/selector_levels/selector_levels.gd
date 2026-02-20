extends Control

# Array de niveles: cada uno con título y path de la escena
var levels = [
	{"title": "Nivel 1 - Tutorial", "scene": "res://escenas/levels/level01/level01.tscn"},
	{"title": "Nivel 2 - El Bosque", "scene": "res://scenes/levels/level_02.tscn"},
	{"title": "Nivel 3 - La Cueva", "scene": "res://scenes/levels/level_03.tscn"},
	{"title": "Nivel 4 - Castillo", "scene": "res://scenes/levels/level_04.tscn"},
	{"title": "Nivel 5 - Final", "scene": "res://scenes/levels/level_05.tscn"},
]

@onready var vbox: VBoxContainer

func _ready():
	_create_ui()
	_create_background_particles()

func _create_ui():
	# Obtener o crear el VBoxContainer
	var center = $CanvasLayer/CenterContainer
	if not center:
		center = CenterContainer.new()
		center.name = "CenterContainer"
		center.layout_mode = 1
		center.anchors_preset = Control.PRESET_FULL_RECT
		add_child(center)
	
	vbox = center.get_node_or_null("VBoxContainer")
	if not vbox:
		vbox = VBoxContainer.new()
		vbox.name = "VBoxContainer"
		vbox.add_theme_constant_override("separation", 15)
		center.add_child(vbox)
	
	# Limpiar botones existentes (por si recargas)
	for child in vbox.get_children():
		child.queue_free()
	
	# Crear título
	var title = Label.new()
	title.text = "SELECCIONAR NIVEL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title)
	
	# Espaciador
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	# Crear botón para cada nivel
	for i in range(levels.size()):
		var level = levels[i]
		var button = Button.new()
		button.text = level.title
		button.custom_minimum_size = Vector2(250, 50)
		
		# Conectar señal con el índice del nivel
		button.pressed.connect(_on_level_selected.bind(i))
		
		vbox.add_child(button)
	
	# Botón volver al final
	var back_spacer = Control.new()
	back_spacer.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(back_spacer)
	
	var back_button = Button.new()
	back_button.text = "← Volver al Menú"
	back_button.custom_minimum_size = Vector2(250, 50)
	back_button.pressed.connect(_on_back_pressed)
	vbox.add_child(back_button)

func _on_level_selected(level_index: int):
	var level = levels[level_index]
	print("Cargando: " + level.title)
	get_tree().change_scene_to_file(level.scene)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://escenas/menu_principal/menu_principal.tscn")

# ========== PARTÍCULAS DE FONDO (mismo código de antes) ==========

func _create_background_particles():
	var particles = GPUParticles2D.new()
	particles.name = "BackgroundParticles"
	add_child(particles)
	move_child(particles, 0)
	
	# Cubrimos toda la pantalla
	particles.position = get_viewport().get_visible_rect().size / 2
	particles.amount = 80 # Un poco más para que se vea lleno
	particles.lifetime = 4.0
	# IMPORTANTE: Esto hace que las partículas ya estén ahí al iniciar
	particles.preprocess = 4.0 
	
	var particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	# Ajusta esto al tamaño de tu resolución (ej: 1920/2, 1080/2)
	particle_material.emission_box_extents = Vector3(960, 540, 0)
	
	# Movimiento muy lento y errático
	particle_material.gravity = Vector3.ZERO
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.spread = 180.0 # Hacia todas partes
	particle_material.initial_velocity_min = 5.0
	particle_material.initial_velocity_max = 15.0
	
	# Escala: bolitas pequeñas
	particle_material.scale_min = 1.0
	particle_material.scale_max = 3.0
	# Agregamos la curva de escala para el efecto de "aparecer/desaparecer"
	particle_material.scale_curve = _create_scale_curve()
	
	# Color y Transparencia
	particle_material.color = Color(1, 1, 1, 0.4)
	particle_material.color_ramp = _create_fade_gradient()
	
	particles.process_material = particle_material
	particles.texture = _create_circle_texture()
	particles.emitting = true

# Nueva función para que las bolitas crezcan y encojan
func _create_scale_curve() -> CurveTexture:
	var curve = Curve.new()
	curve.add_point(Vector2(0, 0))     # Empieza invisible (tamaño 0)
	curve.add_point(Vector2(0.5, 1))   # Punto máximo a mitad de vida
	curve.add_point(Vector2(1, 0))     # Desaparece al final
	
	var texture = CurveTexture.new()
	texture.curve = curve
	return texture

func _create_fade_gradient() -> GradientTexture1D:
	var gradient = Gradient.new()
	# Interpolación suave de transparencia
	gradient.set_color(0, Color(1, 1, 1, 0))
	gradient.add_point(0.5, Color(1, 1, 1, 0.4))
	gradient.set_color(1, Color(1, 1, 1, 0))
	
	var texture = GradientTexture1D.new()
	texture.gradient = gradient
	return texture

func _create_circle_texture() -> ImageTexture:
	# Hacemos la textura un poco más pequeña y suave
	var size = 16
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size/2, size/2)
	
	for x in range(size):
		for y in range(size):
			var dist = center.distance_to(Vector2(x, y))
			# Dibujamos un círculo con borde suave (anti-aliasing manual)
			var alpha = clamp(1.0 - (dist / (size/2.0)), 0.0, 1.0)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
			
	return ImageTexture.create_from_image(image)
