extends Level

const ORB_COUNT:int = 20
var dead_orb_count := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	# Seed global random number generator for replicable first level
	seed(123)
	# Instantiate orbs
# Lade die Szene einmal außerhalb der Schleife (Performance!)
	var dralthi_scene := preload("res://Scenes/Ships/Enemy/Dralthi.tscn")

	for x in range(ORB_COUNT):
		var dralthi = dralthi_scene.instantiate()
		$RedTeam.add_child(dralthi)
		$RedTeam.set_team_properties(dralthi)
		dralthi.position_randomly()
		#dralthi.destroyed.connect(orb_died)


func orb_died() -> void:
	dead_orb_count += 1
	#print("orb died: %s" % dead_orb_count)
	#Go back to main menu once all orbs are destroyed
	if dead_orb_count >= ORB_COUNT:
		Global.main_scene.to_main_menu()
