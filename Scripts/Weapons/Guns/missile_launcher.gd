extends Node3D
class_name MissileLauncher

@export var missile_scene: PackedScene
@export var missile_speed: float = 500.0
@export var fire_rate: float = 0.25
@export var max_range: float = 3000.0
@export var muzzle_flash: VisualEffectSetting.VISUAL_EFFECT_TYPE
@export var animation: AnimationPlayer

@onready var audio_manager = get_node_or_null("/root/AudioManager")
@onready var firing_rate_timer: Timer = Timer.new()

var ally_team: String
var current_target: Node3D
var owner_ship: Node3D

func _ready():
	firing_rate_timer = Timer.new()
	firing_rate_timer.one_shot = true
	add_child(firing_rate_timer)

func set_ship_owner(ship: Node3D):
	owner_ship = ship

func set_target(target: Node3D):
	current_target = target

func can_fire() -> bool:
	return firing_rate_timer.is_stopped()

func fire_missile():
	if !can_fire() or !owner_ship or !missile_scene:
		return

	var missile = missile_scene.instantiate()
	missile.global_transform = global_transform
	missile.set_target(current_target)
	missile.set_owner(owner_ship)
	Global.add_to_team_group(missile, ally_team)

	get_tree().current_scene.add_child(missile)

	if muzzle_flash:
		VfxManager.play_remote_transform(muzzle_flash, self)
	if animation:
		animation.play("launch")
	if audio_manager:
		audio_manager.play_3d("missile_fire", global_position)

	firing_rate_timer.start(fire_rate)

func deactivate():
	set_process(false)
	set_physics_process(false)

func activate():
	set_process(true)
	set_physics_process(true)
