extends Node
class_name AimAssist

@export var angle_assist_limit: float = 3.0 # degrees
var angle_assist_limit_radians: float

var audio_key := "aim_assist_lock"  # Name in der audio.ini
var audio_manager: Node = null

var _last_state: bool = false  # Merkt sich ob Aim Assist aktiv war

func _ready() -> void:
	angle_assist_limit_radians = deg_to_rad(angle_assist_limit)
	audio_manager = get_node_or_null("/root/AudioManager")  # Globale Instanz, ggf. anpassen

func use_aim_assist(shooter: Node3D, target: Node3D,
					bullet_speed: float) -> bool:
	var intercept: Vector3 = Global.get_intercept(
		shooter.global_position, bullet_speed, target)
	var angle_to = Global.get_angle_to_target(
		shooter.global_position, intercept,
		-shooter.global_basis.z)
	var do_use_aim_assist: bool = angle_to < angle_assist_limit_radians
	play_audio(do_use_aim_assist, shooter.global_position)
	_last_state = do_use_aim_assist
	return do_use_aim_assist

func play_audio(do_use_aim_assist: bool, position: Vector3) -> void:
	if not audio_manager:
		return
	if do_use_aim_assist and !_last_state:
		audio_manager.play_3d(audio_key, position)
