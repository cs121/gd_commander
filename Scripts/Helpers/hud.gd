extends CanvasLayer

@onready var speed_label = $Speed
@onready var afterburner_indicator = $Afterburner
@onready var shield_bar = $Shield
@onready var health_bar = $Health
@onready var target_name_label = $TargetBox/TargetName
@onready var target_distance_label = $TargetBox/TargetDistance

var ship: Ship

func set_ship(s: Ship) -> void:
	ship = s

func _ready() -> void:
	# Alternativ per Setter – falls nicht extern gesetzt wird
	if ship == null:
		ship = Global.player
	if ship == null:
		push_warning("HUD konnte kein Spieler-Schiff finden!")

func _process(delta: float) -> void:
	if ship == null or !is_instance_valid(ship):
		return
	
	update_speed_display()
	update_afterburner_display()
	update_shield_health_display()
	update_target_display()

func update_speed_display():
	var speed = ship.velocity.length()
	speed_label.text = "Speed: %d u/s" % int(speed)

func update_afterburner_display():
	# Verwende direkte Property, falls vorhanden
	var active = false
	if ship.controller and ship.controller.has_method("is_afterburner_active"):
		active = ship.controller.is_afterburner_active()
	elif ship.controller and "afterburner_active" in ship.controller:
		active = ship.controller.afterburner_active

	# DIM_GRAY ist kein vordefinierter Farbname in Godot → Ersatzfarbe
	afterburner_indicator.color = Color.RED if active else Color(0.3, 0.3, 0.3)

func update_shield_health_display():
	# Schild anzeigen, falls vorhanden
	if ship.shield and ship.shield.has_node("HealthComponent"):
		var shield_component = ship.shield.get_node("HealthComponent")
		shield_bar.max_value = shield_component.health_max if shield_component.has_method("health_max") else 100
		shield_bar.value = shield_component.health
	else:
		shield_bar.max_value = 100
		shield_bar.value = 0

	# Health anzeigen, falls vorhanden
	if "health_component" in ship and ship.health_component:
		var hp = ship.health_component
		health_bar.max_value = hp.health_max if hp.has_method("health_max") else 100
		health_bar.value = hp.health
	else:
		health_bar.max_value = 100
		health_bar.value = 0

func update_target_display():
	var tgt = null
	
	# Versuche get_target aufzurufen
	if ship.controller and ship.controller.has_method("get_target"):
		tgt = ship.controller.get_target()
	elif ship.controller and "current_target" in ship.controller:
		tgt = ship.controller.current_target

	# Gültiges Ziel?
	if is_instance_valid(tgt):
		target_name_label.text = "Target: %s" % tgt.name
		var distance = ship.global_position.distance_to(tgt.global_position)
		target_distance_label.text = "Distance: %d m" % int(distance)
	else:
		target_name_label.text = "No Target"
		target_distance_label.text = ""
