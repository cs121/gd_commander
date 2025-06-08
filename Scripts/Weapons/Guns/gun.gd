extends Node3D
class_name Gun

@export var bullet: PackedScene
@export var damage: float = 1.0
@export var bullet_speed: float = 1000.0
@export var bullet_timeout: float = 2.0 # Sekunden
@export var fire_rate: float = 1.0 # Schüsse pro Sekunde
@export var automatic: bool = true
@export var spread_deg: float = 0.0 # Winkel in Grad
@export var simultaneous_shots: int = 1

@export var gun_animation: AnimationPlayer
@export var muzzle_flash: VisualEffectSetting.VISUAL_EFFECT_TYPE
@onready var audio_manager = get_node_or_null("/root/AudioManager")

var firing_rate_timer: Timer
var ray: RayCast3D
var reticle: TextureRect
var ally_team: String
var data: ShootData
var range_sqd: float


func _ready():
	if has_node("FiringRateTimer"):
		firing_rate_timer = $FiringRateTimer

	for child in get_children():
		if child is RayCast3D:
			ray = child
		elif child is TextureRect:
			reticle = child

	range_sqd = bullet_speed * bullet_timeout
	range_sqd *= range_sqd


func _process(_delta: float) -> void:
	if reticle:
		var position_ahead: Vector3 = global_position - global_transform.basis.z * 500.0
		Global.set_reticle(null, reticle, position_ahead)


func ready_to_fire() -> bool:
	return !firing_rate_timer or firing_rate_timer.is_stopped()


func shoot(shooter: Node3D, target: Node3D = null, powered_up: bool = false) -> void:
	if ready_to_fire():
		if gun_animation:
			gun_animation.play("gun_animation")
		VfxManager.play_remote_transform(muzzle_flash, self)

		# Sound abspielen über AudioManager
		if audio_manager:
			audio_manager.play_3d("weapon_fire_1", global_position)

		restart_timer()
		setup_shoot_data(shooter, target, powered_up)
		shoot_actual()


func restart_timer() -> void:
	if firing_rate_timer:
		firing_rate_timer.start(1.0 / fire_rate)


func setup_shoot_data(shooter: Node3D, target: Node3D, powered_up: bool):
	data = ShootData.new()
	data.shooter = shooter
	data.gun = self
	data.damage = damage
	data.bullet_speed = bullet_speed
	data.bullet_timeout = bullet_timeout
	data.spread_deg = spread_deg
	data.ray = ray
	data.target = target
	data.super_powered = powered_up

	if "aim_assist" in shooter and shooter.aim_assist and simultaneous_shots == 1 and target and is_instance_valid(target):
		data.aim_assist = shooter.aim_assist.use_aim_assist(shooter, target, bullet_speed)


func shoot_actual() -> void:
	for i in range(simultaneous_shots):
		var b = bullet.instantiate()
		Global.add_to_team_group(b, ally_team)
		b.set_data(data)


func deactivate() -> void:
	set_process(false)
	set_physics_process(false)
	if reticle:
		reticle.hide()
	if gun_animation:
		gun_animation.stop()
	if ray:
		ray.enabled = false


func activate() -> void:
	visible = true
	set_process(true)
	set_physics_process(true)
	if reticle:
		reticle.show()
	if ray:
		ray.enabled = true
