extends Gun
class_name BurstGun

# True if the gun has received command to fire
var firing: bool = false

# Fire a burst over a short period of time.
@onready var burst_timer: Timer = $BurstTimer

# How many consecutive shots are fired when trigger is pulled
@export var burst_total: int = 1

# Shots in a burst per second:
@export var burst_rate: float = 1.0

# For tracking how many shots in the burst have been fired
var burst_count: int = 0

func _physics_process(_delta):
	if firing and burst_timer.is_stopped():
		shoot_actual()


# Override parent class
func ready_to_fire() -> bool:
	return super.ready_to_fire() and burst_timer.is_stopped()


func shoot_actual() -> void:
	super.shoot_actual()

	firing = true
	burst_timer.start(1.0 / burst_rate)
	burst_count += 1

	# Play firing sound via AudioManager
	if audio_manager:
		audio_manager.play_weapon_fire(global_position)

	# Check if we're done firing this burst
	if burst_total <= burst_count:
		# Play reload sound via AudioManager
		if audio_manager:
			audio_manager.play_weapon_reload(global_position)

		firing = false
		burst_count = 0
		burst_timer.stop()


# Override parent class's function
func deactivate() -> void:
	super.deactivate()
	burst_count = 0
	burst_timer.stop()
	firing = false
