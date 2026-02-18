extends CharacterBody2D

@export var speed := 320.0
@export var acceleration := 1800.0
@export var deceleration := 1400.0

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Si hay input → aceleramos
	if input_dir:
		velocity = velocity.move_toward(input_dir * speed, acceleration * delta)
	# Si no hay input → frenamos
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	
	move_and_slide()
