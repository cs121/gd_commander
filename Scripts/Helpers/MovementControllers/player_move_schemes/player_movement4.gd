class_name PlayerMovement4 extends CharacterBodyControlParent

# Differences between this and Version 3
#     Tighter pitch radius: pitch_std from 1 -> 1.8
#     Reduced pitch, roll, yaw while accelerating: 0.9 -> 0.3
#     Reduced pitch, roll, yaw while drifting: 1.3 -> 0.7
#     More roll on right stick: 1.2 -> 2
#     Mild "fine-grained" pitch on right stick: 0.4
#     Stronger impulse acceleration: 100 -> 6500
#     This stronger accel is offset by use of impulse_lerp
# such that the impulse isn't instantaneous, but has to be
# lerped up to and back down from, meanwhile, turn rate is
# reduced.
#     Slower impulse lerp: 0.2 -> 1.0
#     Pitch, roll, yaw maxes out at default speed and
# scales based on difference between current speed and
# default speed. See everything related to
# "turn_reduction" below.
#     Temporary acceleration (You can't just keep holding the button)
# Implemented with all the variables below starting with
# accel_max_duration. <----- Except I didn't like it so I 
# kept the code, but set the values such that accel shouldn't
# ever really run out.
#     I lowered friction from 0.99 (which was misleading because
# it's also getting multiplied by delta which is typically 1/60)
# to 0.8 to get a "driftier" feel. Zero is full ballistic
# "asteroids" controls.
#     No brakes (EXCEPT WE KEPT THEM IN FOR TESTING PURPOSES)

@onready var camera_controller = get_node("%CameraGroup")
@onready var first_person_camera = camera_controller.get_node("Body/Head/FirstPersonCamera")


#Strength of movements under standard motion
var pitch_std: float = 1.8
var roll_std_left_stick: float = 1.2  # Doppelt so schnell Rollen bei Links/Rechts
var roll_std_right_stick: float = 2.0
var pitch_std_right_stick: float = 0.4
var yaw_std: float = 1.2               # Doppelt so schnelle Yaw-Bewegung

# Steuerung
var friction_std: float = 0.8

#forward motion
var impulse_std: float
var current_impulse: float = 0.0

# Nachbrenner
var afterburner_speed: float = 280.0
var afterburner_duration: float = 3.0  # Sekunden
var afterburner_cooldown: float = 5.0  # Sekunden
var afterburner_active: bool = false
var afterburner_timer: float = 0.0
var afterburner_cooldown_timer: float = 15.0

# Can't accelerate forever. These variables control how
# long ship can accelerate and how long it takes for the
# acceleration bar to refill.

# will be added to accel_available
var accel_regen_rate:float = 1.0 #Used to be 1.0, but I didn't like the "feature"
var accel_min:float = 1.5 # Can't accelerate if accel_available is less than accel_min
var is_accelerating:bool
var acceleration_rate: float = 5.0  # Wie schnell die Geschwindigkeit steigt (units/s²)
var deceleration_rate: float = 10.0  # Wie schnell die Geschwindigkeit sinkt wenn kein Schub


var is_dead := false

var im : InputManager


func _ready() -> void:
	
	var ship = get_parent()
	if ship and ship is Ship:
		impulse_std = ship.max_speed
	
	im = Global.input_man
	# Tell the global script who the player is.
	# Since this is a player controller, it SHOULD
	# be an immediate child of the player.
	Global.player = get_parent()


# Override parent class function
func move_and_turn(mover, delta: float) -> void:
	if is_dead:
		return

	im.update()

	# === Steuerungsmodifikatoren (werden durch Zustand beeinflusst) ===
	var pitch_modifier := 1.0
	var roll_modifier := 1.0
	var yaw_modifier := 1.0
	friction = friction_std
	var is_moving := false  # True, wenn Schub aktiv ist

	# === Nachbrenneraktivierung (nur wenn Afterburner-Taste gedrückt und kein Cooldown) ===
	_handle_afterburner(delta)

	# === Steuerung abhängig von Benutzereingabe ===
	if im.accelerate:
		# Normales Beschleunigen
		is_moving = true
		current_impulse = min(current_impulse + acceleration_rate * delta, impulse_std)
		pitch_modifier = 0.9
		roll_modifier = 0.9
		yaw_modifier = 0.9
	else:
		current_impulse = max(current_impulse - deceleration_rate * delta, 0.0)
		mover.velocity = mover.velocity.lerp(Vector3.ZERO, 1.0 * delta)

	# === Bewegungsphysik ===
	if is_moving:
		var direction = -mover.global_transform.basis.z.normalized()
		mover.velocity = mover.velocity.lerp(direction * current_impulse, friction * delta)
	else:
		mover.velocity = mover.velocity.lerp(Vector3.ZERO, friction * delta)

	# === Geschwindigkeitslimitierung ===
	var speed_limit = afterburner_speed if afterburner_active else impulse_std
	if mover.velocity.length() > speed_limit:
		mover.velocity = mover.velocity.normalized() * speed_limit

	# Optional: Bewegung komplett stoppen, wenn sehr langsam
	if mover.velocity.length() < 0.5:
		mover.velocity = Vector3.ZERO

	# === Rotation (Steuereingaben mit Verzögerung) ===
	pitch_input = lerp(pitch_input,
		(im.up_down1 * pitch_std + im.up_down2 * pitch_std_right_stick) * pitch_modifier,
		lerp_strength * delta)
	roll_input = lerp(roll_input,
		(im.left_right1 * roll_std_left_stick + im.left_right2 * roll_std_right_stick) * roll_modifier,
		lerp_strength * delta)
	yaw_input = lerp(yaw_input,
		im.left_right1 * yaw_std * yaw_modifier,
		lerp_strength * delta)

	# === Triebwerksgeräusche verwalten ===
	handle_engine_audio(mover)

	# === Cockpit-Screenshake bei hoher Geschwindigkeit ===
	var speed_ratio = mover.velocity.length() / impulse_std
	if speed_ratio > 0.4:
		_apply_cockpit_shake()
	else:
		first_person_camera.position = Vector3.ZERO

	# === Bewegung und Rotation anwenden ===
	super.move_and_turn(mover, delta)

func _apply_cockpit_shake() -> void:
	if first_person_camera and Global.player:
		var velocity = Global.player.velocity.length()
		var speed_ratio = clamp(velocity / impulse_std, 0.0, 1.0)
		var strength = (speed_ratio - 0.4)  # Werte feinjustieren
		var shake_offset = Vector3(randf_range(-.5, .5),randf_range(-.5, .5),0) * strength
		first_person_camera.position = shake_offset
		




func _reset_cockpit_shake() -> void:
	if first_person_camera:
		first_person_camera.position = Vector3.ZERO


func _handle_afterburner(delta: float) -> void:
	if im.afterburner and !afterburner_active and afterburner_cooldown_timer <= 0.0:
		afterburner_active = true
		afterburner_timer = afterburner_duration
		print("Afterburner aktiviert!")
	elif afterburner_active and (!im.afterburner or afterburner_timer <= 0.0):
		afterburner_active = false
		afterburner_cooldown_timer = afterburner_cooldown
		print("Afterburner deaktiviert!")

	if afterburner_active:
		afterburner_timer -= delta

	# Cooldown immer runterzählen, egal ob aktiv oder nicht
	if afterburner_cooldown_timer > 0.0 and not afterburner_active:
		afterburner_cooldown_timer = max(0.0, afterburner_cooldown_timer - delta)

func handle_engine_audio(mover) -> void:
	if !mover.engineAV:
		return
	# NOTE! These transition time numbers
	# are based on nothing in particular!
	if im.brake:
		mover.engineAV.shift2brake(0.0)
	elif im.accelerate:
		mover.engineAV.shift2afterburners(2.0)
	elif afterburner_active:
		mover.engineAV.shift2afterburners(4.0)
	else:
		mover.engineAV.shift2default(1.0)


# Override parent class function
func shoot(shooter, delta:float) -> void:
	if is_dead:
		return
	
	# Aim assist audio cue
	if shooter.aim_assist and target and is_instance_valid(target):
		shooter.aim_assist.use_aim_assist(
			shooter, target,
			shooter.weapon_handler.get_bullet_speed())
	
	# Trigger pulled. Try to shoot.
	if shooter.weapon_handler.is_automatic():
		if im.shoot_pressed:
			shooter.weapon_handler.shoot(shooter, target)
	else: # Semiautomatic
		if im.shoot_just_pressed:
			shooter.weapon_handler.shoot(shooter, target)
	
	# Missile lock
	if shooter.missile_lock:
		if im.retarget_just_pressed:
			shooter.missile_lock.attempt_to_start_seeking(shooter)
		if im.retarget_just_released:
			shooter.missile_lock.attempt_to_fire_missile(shooter)
		shooter.missile_lock.update(shooter, delta)
		if is_instance_valid(shooter.missile_lock.target):
			target = shooter.missile_lock.target


# Override parent class function
func select_target(targeter:Node3D) -> void:
	if is_dead:
		return
	
	if im.retarget_just_pressed:
		target = Global.get_center_most_from_group(enemy_team,targeter)
		if is_instance_valid(target):
			target.set_targeted(targeter, true)


func misc_actions(actor) -> void:
	if im.switch_weapons:
		actor.weapon_handler.change_weapon()


# Override parent class function
func enter_death_animation() -> void:
	is_dead = true


# Override parent class function
func died(who_died) -> void:
	Global.main_scene.to_main_menu()
	Callable(who_died.queue_free).call_deferred()
