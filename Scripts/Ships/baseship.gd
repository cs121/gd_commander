class_name Ship extends CharacterBody3D

signal destroyed

# Komponenten-Referenzen
var aim_assist:AimAssist
var burning_trail:BurningTrail # Visueller Effekt für Schäden
var controller:CharacterBodyControlParent
var engineAV:EngineAV
var health_component:HealthComponent
var missile_lock:MissileLockGroup
var weapon_handler:WeaponHandler

# Timer für Todesszene
var death_animation_timer:Timer

# Explosionen bei Zerstörung
@export var deathExplosion:VisualEffectSetting.VISUAL_EFFECT_TYPE
@export var finalExplosion:VisualEffectSetting.VISUAL_EFFECT_TYPE

# Dauer der Todesszene (visuell)
@export var death_animation_duration_min:float = 1.5
@export var death_animation_duration_max:float = 4.5
@export var max_speed = 99
@onready var audio_manager = get_node_or_null("/root/AudioManager")

# Kollisionsbezogene Eigenschaften
var hit_feedback:HitFeedback
var damage_exception:Ship  # Verhindert Friendly Fire
var reticle:TargetReticles
var shield: Shield

# Sucht beim Start nach Komponenten im Node-Baum und verbindet Signale
func _ready() -> void:
	for child in get_children():
		if child is AimAssist:
			aim_assist = child
		elif child is BurningTrail:
			burning_trail = child
		elif child is CharacterBodyControlParent:
			controller = child
		elif child is EngineAV:
			engineAV = child
		elif child is HealthComponent:
			health_component = child
			# Verbinde Schadens- und Todessignale
			health_component.health_lost.connect(_on_health_component_health_lost)
			health_component.died.connect(_on_health_component_died)
		elif child is Shield:
			shield = child
		elif child is MissileLockGroup:
			missile_lock = child
		elif child is WeaponHandler:
			weapon_handler = child
		elif child is HitFeedback:
			hit_feedback = child
		elif child is TargetReticles:
			reticle = child

	# Zusätzliche Soundinitialisierung (z.B. Motorlauf)
	if audio_manager and engineAV:
		# Starte Motorgeräusch als 3D-Loop am Schiff
		audio_manager.play_3d_loop("engine_idle", global_position)

# Physikverarbeitung – steuert Bewegung, Zielwahl, Schießen usw.
func _physics_process(delta):
	if controller:
		controller.move_and_turn(self, delta)     # Bewegen & Rotieren
		controller.select_target(self)            # Ziel auswählen
		controller.shoot(self, delta)             # Waffe abfeuern
		controller.misc_actions(self)             # Sonstige Aktionen (z. B. Waffenwechsel)

	# Optional: Engine-Sound-Update bei Bewegung (z.B. Schub)
	if audio_manager and engineAV:
		var speed_factor = velocity.length() / engineAV.max_speed
		audio_manager.set_3d_param("engine_idle", "speed", speed_factor)

# Gibt derzeit aktive Waffe zurück (Gun oder MissileLauncher)
func get_current_gun() -> Gun:
	if weapon_handler:
		return weapon_handler.current_weapon
	elif missile_lock:
		return missile_lock.missile_launcher
	else:
		return null

func _setup_weapons():
	if not weapon_handler:
		return

	for weapon in weapon_handler.get_children():
		# Optional: auch verschachtelte Strukturen prüfen
		_setup_weapon_recursive(weapon)


func _setup_weapon_recursive(node: Node):
	if node is Gun or node.get_class() == "MissileLauncher":
		if aim_assist:
			node.aim_assist = aim_assist
		if Global.has("player_team"):  # Beispiel für Team-Logik
			node.ally_team = Global.player_team
	elif node.get_child_count() > 0:
		for child in node.get_children():
			_setup_weapon_recursive(child)


# Wird ausgelöst, wenn das Schiff Schaden erleidet
func _on_health_component_health_lost() -> void:
	if controller:
		controller.took_damage()
	if health_component and burning_trail:
		burning_trail.display_damage(health_component.get_percent_health())
	
	# Spielt 3D-Hit-Sound (Treffer-Sound)
	if audio_manager:
		audio_manager.play_3d("hit_1", global_position)

# Wird ausgelöst, wenn das Schiff stirbt
func _on_health_component_died() -> void:
	# Visueller Todeseffekt
	VfxManager.play_with_transform(deathExplosion, global_position, transform)

	if controller:
		controller.enter_death_animation()

	# Erstelle und starte Timer für finale Explosion
	if !death_animation_timer:
		death_animation_timer = Timer.new()
		add_child(death_animation_timer)
		death_animation_timer.timeout.connect(_on_death_timer_timeout)
		death_animation_timer.start(randf_range(
			death_animation_duration_min,
			death_animation_duration_max))

	# Spielt 3D-Explosion-Sound beim Tod
	if audio_manager:
		audio_manager.play_3d("death_explosion_1", global_position)

# Wird ausgeführt, wenn die Todesanimation abgeschlossen ist
func _on_death_timer_timeout() -> void:
	destroyed.emit()  # Signal, dass Schiff vollständig zerstört wurde
	VfxManager.play_with_transform(finalExplosion, global_position, transform)

	# Spielt finale 3D-Explosion beim Todesschluss
	if audio_manager:
		audio_manager.play_3d("final_explosion_1", global_position)

	if controller:
		controller.died(self)
	else:
		Callable(queue_free).call_deferred()  # Fallback: Schiff löschen

# Verarbeitet direkten Schaden (entweder auf Schild oder Hülle)
func damage(amount: float, damager = null):
	if damager and is_instance_valid(damage_exception) and damager == damage_exception:
		return  # Verhindere Friendly Fire

	if shield and shield.has_node("HealthComponent"):
		shield.get_node("HealthComponent").health -= amount
		# Spielt 3D-Schildtreffer-Sound
		if audio_manager:
			audio_manager.play_3d("shield_hit_1", global_position)
	elif health_component:
		health_component.health -= amount
		# Spielt 3D-Hit-Sound (wenn Schild nicht da oder leer)
		if audio_manager:
			audio_manager.play_3d("hit_1", global_position)

	if hit_feedback:
		hit_feedback.hit()

# Setzt ein Schiff als Damage-Exception (z. B. für eigene Raketen)
func add_damage_exception(s:Ship) -> void:
	damage_exception = s

# Wird aufgerufen, wenn Zielvisier dieses Schiff anvisiert
func set_targeted(targeter:Node3D, value:bool) -> void:
	if Global.player == targeter and reticle:
		reticle.is_targeted = value
		# Optional: Sound bei Anvisieren (wenn gewünscht)
		if audio_manager and value:
			audio_manager.play_3d("target_lock_on", global_position)

# Wird aufgerufen, wenn Zielerfassung beginnt
func seeking_lock(_targeter:Node3D) -> void:
	if audio_manager:
		# Spielt 3D-Sound für Beginn Zielerfassung
		audio_manager.play_3d("lock_seeking", global_position)

# Wird aufgerufen, wenn Zielerfassung verloren geht
func lost_lock(_targeter:Node3D) -> void:
	if audio_manager:
		# Spielt 3D-Sound für verlorene Zielerfassung
		audio_manager.play_3d("lock_lost_1", global_position)

# Wird aufgerufen, wenn Zielerfassung erfolgreich ist
func lock_acquired(_targeter:Node3D) -> void:
	if audio_manager:
		# Spielt 3D-Sound für erfolgreiche Zielerfassung
		audio_manager.play_3d("lock_acquire_1", global_position)

# Wird aufgerufen, wenn Rakete im Anflug ist
func missile_inbound(_targeter:Node3D) -> void:
	if audio_manager:
		# Spielt 3D-Warnsound für Raketenanflug
		audio_manager.play_3d("missile_inbound", global_position)

# Trigger durch physikalischen Kontakt mit Area3D (z. B. Explosionen)
func _on_area_entered(_area: Area3D) -> void:
	if audio_manager:
		# Spielt 3D-Treffer-Sound bei Kollisions-Area
		audio_manager.play_3d("hit_1", global_position)

# Trigger durch physikalischen Kontakt mit Körpern (z. B. Kollision mit Schiffen)
func _on_body_entered(_body: Node3D) -> void:
	if audio_manager:
		# Spielt finale Explosion bei Kollision mit anderem Körper
		audio_manager.play_3d("final_explosion_1", global_position)

# Optional: Sound für Waffenwechsel, wenn controller.misc_actions das steuert
func _on_weapon_changed():
	if audio_manager:
		audio_manager.play_3d("weapon_switch_1", global_position)

# Optional: Sound bei Aktivierung des Schildes (falls relevant)
func activate_shield():
	if shield and audio_manager:
		audio_manager.play_3d("shield_activate", global_position)

# Optional: Sound bei Deaktivierung des Schildes (falls relevant)
func deactivate_shield():
	if shield and audio_manager:
		audio_manager.play_3d("shield_deactivate", global_position)
