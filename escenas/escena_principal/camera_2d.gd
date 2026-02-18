extends Camera2D

# Variable para guardar las paredes
var static_body: StaticBody2D

func _ready() -> void:
	setup_camera_walls()

func setup_camera_walls() -> void:
	# 1. Creamos el cuerpo estático
	static_body = StaticBody2D.new()
	static_body.name = "CameraWalls"
	add_child(static_body)
	
	# 2. Creamos las 4 formas de colisión
	for i in range(4):
		var collision_shape := CollisionShape2D.new()
		var segment := WorldBoundaryShape2D.new() # Usamos límites infinitos
		collision_shape.shape = segment
		static_body.add_child(collision_shape)

func _process(_delta: float) -> void:
	update_wall_positions()

func update_wall_positions() -> void:
	# Obtenemos el tamaño del viewport (la pantalla actual)
	var view_size = get_viewport_rect().size
	# Calculamos el centro y los bordes considerando el zoom de la cámara
	var half_size = (view_size * (1.0 / zoom.x)) / 2.0
	
	# Referencias a los hijos (las 4 colisiones)
	var left_wall = static_body.get_child(0)
	var right_wall = static_body.get_child(1)
	var top_wall = static_body.get_child(2)
	var bottom_wall = static_body.get_child(3)
	
	# Posicionamos las paredes relativas a la cámara
	# WorldBoundaryShape2D usa un vector 'normal' para saber hacia dónde empujar
	
	# Pared Izquierda (Empuja hacia la derecha)
	left_wall.position = Vector2(-half_size.x, 0)
	left_wall.shape.normal = Vector2.RIGHT
	
	# Pared Derecha (Empuja hacia la izquierda)
	right_wall.position = Vector2(half_size.x, 0)
	right_wall.shape.normal = Vector2.LEFT
	
	# Pared Superior (Empuja hacia abajo)
	top_wall.position = Vector2(0, -half_size.y)
	top_wall.shape.normal = Vector2.DOWN
	
	# Pared Inferior (Empuja hacia arriba)
	bottom_wall.position = Vector2(0, half_size.y)
	bottom_wall.shape.normal = Vector2.UP
