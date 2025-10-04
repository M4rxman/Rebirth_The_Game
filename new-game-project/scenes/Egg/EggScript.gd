extends Node3D

@export var hatch_time: float = 5.0  # seconds before hatching

func _ready():
	pass

func hatch():
	print("hatching")
	# Start hatching process
	self.show()
	var timer = get_tree().create_timer(hatch_time)
	await timer.timeout
	get_parent().switch_to_character()
