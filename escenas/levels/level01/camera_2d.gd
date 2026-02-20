extends Camera2D

signal camera_bounds_changed(top_left: Vector2, bottom_right: Vector2)

var static_body: StaticBody2D

func _ready() -> void:
	setup_camera_walls()

func setup_camera_walls() -> void:
	static_body = StaticBody2D.new()
	static_body.name = "CameraWalls"
	add_child(static_body)

	for i in range(4):
		var collision_shape := CollisionShape2D.new()
		var segment := WorldBoundaryShape2D.new()
		collision_shape.shape = segment
		static_body.add_child(collision_shape)

func _process(_delta: float) -> void:
	update_wall_positions()

func update_wall_positions() -> void:
	var view_size = get_viewport_rect().size
	var half_size = (view_size * (1.0 / zoom.x)) / 2.0

	var left_wall  = static_body.get_child(0)
	var right_wall = static_body.get_child(1)
	var top_wall   = static_body.get_child(2)
	var bottom_wall = static_body.get_child(3)

	left_wall.position   = Vector2(-half_size.x, 0)
	left_wall.shape.normal = Vector2.RIGHT

	right_wall.position  = Vector2(half_size.x, 0)
	right_wall.shape.normal = Vector2.LEFT

	top_wall.position    = Vector2(0, -half_size.y)
	top_wall.shape.normal = Vector2.DOWN

	bottom_wall.position = Vector2(0, half_size.y)
	bottom_wall.shape.normal = Vector2.UP

# Llamar esto desde el spawner para obtener los bordes en coordenadas globales
func get_world_bounds() -> Rect2:
	var view_size = get_viewport_rect().size
	var half_size = (view_size * (1.0 / zoom.x)) / 2.0
	var center = global_position
	return Rect2(center - half_size, half_size * 2.0)
