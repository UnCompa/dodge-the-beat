class_name LevelData
extends Resource

enum LevelState { LOCKED, AVAILABLE, COMPLETED }

@export var title: String = ""
@export var subtitle: String = ""
@export var scene_path: String = ""
@export var state: LevelState = LevelState.LOCKED
@export var best_time: float = 0.0
@export var thumbnail_color: Color = Color(0.2, 0.8, 1.0)

func is_unlocked() -> bool:
	return state != LevelState.LOCKED

func is_completed() -> bool:
	return state == LevelState.COMPLETED

func get_state_label() -> String:
	match state:
		LevelState.LOCKED: return "BLOQUEADO"
		LevelState.AVAILABLE: return "DISPONIBLE"
		LevelState.COMPLETED: return "COMPLETADO"
	return ""
