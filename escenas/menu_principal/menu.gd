extends CanvasLayer


func _ready():
	# Conectar señales de los botones
	$CenterContainer/VBoxContainer/Play.pressed.connect(_on_play_pressed)
	$CenterContainer/VBoxContainer/Exit.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	get_tree().change_scene_to_file("res://escenas/selector_levels/selector_levels.tscn")

func _on_quit_pressed():
	get_tree().quit()
