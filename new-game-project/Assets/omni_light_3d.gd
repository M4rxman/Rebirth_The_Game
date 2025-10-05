extends OmniLight3D

var time := 0.0

func _process(delta):
	time += delta
	light_energy = 2.0 + sin(time * 3.0) * 0.8  # base 2, pulse amplitude 1
