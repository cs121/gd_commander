extends Node
class_name HitFeedback
@onready var audio_manager = get_node_or_null("/root/AudioManager")

func hit() -> void:
	if audio_manager:
		audio_manager.play_3d("hit_1", 1)
	$AnimationPlayer.play('TakeDamage')
