extends Node3D

var character_state : int 
var character_generation : int = 0

@export var move_speed: float = 5.0
@export var turn_speed: float = 1.0
@export var ground_offset: float = 0.5
@export var ground_clearance: float = 0.6
@export var ground_raycast_depth: float = 8.0
@export var ground_collision_mask: int = 1
@export var max_hp : float = 100.0
@export var hp_depletion_rate : float = 5.0
var current_hp: float = 100.0
var is_alive: bool = true

@onready var fl_leg = $FrontLeftIKTarget
@onready var fr_leg = $FrontRightIKTarget

@onready var bl_leg = $BackLeftIKTarget
@onready var br_leg = $BackRightIKTarget
@onready var tank_tower = $Plane
@onready var character_slot = $Armature/Skeleton3D
@onready var egg_slot = $Egg 

var hp_bar: ProgressBar

func _ready() -> void:
	tank_tower.visible = true
	character_slot.visible = true
	egg_slot.hide()
	
	current_hp = max_hp
	# Get HP bar reference from UI
	hp_bar = get_tree().get_first_node_in_group("hp_bar")
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp

func _process(delta):
	if is_alive:
		# Deplete HP over time
		current_hp -= hp_depletion_rate * delta
		current_hp = clamp(current_hp, 0, max_hp)
		
		# Update HP bar
		if hp_bar:
			hp_bar.value = current_hp
		
		# Check for death
		if current_hp <= 0:
			die()
			return
	
	if not is_alive:
		return
	
	var plane1 = Plane(bl_leg.global_position, fl_leg.global_position, fr_leg.global_position)
	var plane2 = Plane(fr_leg.global_position, br_leg.global_position, bl_leg.global_position)
	var avg_normal = ((plane1.normal + plane2.normal) / 2).normalized()
	
	var target_basis = _basis_from_normal(avg_normal)
	transform.basis = lerp(transform.basis, target_basis, move_speed * delta).orthonormalized()
	
	var avg = (fl_leg.position + fr_leg.position + bl_leg.position + br_leg.position) / 4
	var target_pos = avg + transform.basis.y * ground_offset
	var distance = transform.basis.y.dot(target_pos - position)
	position = lerp(position, position + transform.basis.y * distance, move_speed * delta)
	
	if Input.is_action_just_pressed("egg_action"):
		switch_to_egg()
	
	_handle_movement(delta)
	_handle_turret_rotation(delta)
	# ensure we don't sink into procedurally generated terrain
	_ensure_clearance(delta)
	
func _handle_turret_rotation(delta: float) -> void:
	var turret_input = Input.get_axis("rotate_right", "rotate_left") # or define custom "turret_left/right"
	if turret_input != 0.0:
		tank_tower.rotate_y(turret_input * turn_speed * delta)
	
func _handle_movement(delta):
	var dir = Input.get_axis('move_backwards', 'move_forwards')
	translate(Vector3(0, 0, -dir) * move_speed * delta)
	
	var a_dir = Input.get_axis('move_right', 'move_left')
	rotate_object_local(Vector3.UP, a_dir * turn_speed * delta)

func _basis_from_normal(normal: Vector3) -> Basis:
	var result = Basis()
	result.x = normal.cross(transform.basis.z)
	result.y = normal
	result.z = transform.basis.x.cross(normal)

	result = result.orthonormalized()
	result.x *= scale.x 
	result.y *= scale.y 
	result.z *= scale.z 
	
	return result
	
func switch_to_character():
	move_speed = 5.0
	turn_speed = 1.0
	
	hp_depletion_rate = 5.0
	current_hp = max_hp
	if hp_bar:
		hp_bar.value = current_hp
	
	tank_tower.visible = true
	character_slot.visible = true
	egg_slot.visible = false

func switch_to_egg():
	hp_depletion_rate = 0.0
	print("swithced to the egg")
	character_generation += 1
	egg_slot.show()
	
	current_hp = max_hp
	if hp_bar:
		hp_bar.value = current_hp
	
	move_speed = 0
	turn_speed = 0
	character_slot.visible = false
	tank_tower.visible = false
	
	egg_slot.hatch()

func _ensure_clearance(delta: float) -> void:
	# Raycast from above the spider downwards to find the terrain under the spider
	var up_dir = transform.basis.y
	var origin = global_position + up_dir * ground_raycast_depth
	var target = global_position - up_dir * ground_raycast_depth
	var exclude = [self]
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.from = origin
	params.to = target
	params.exclude = exclude
	params.collision_mask = ground_collision_mask
	var result = space.intersect_ray(params)
	if result:
		var hit_pos = result.get("position", null)
		if hit_pos != null:
			# desired position keeps a fixed clearance above the hit point (world up)
			var desired_global = Vector3(global_position.x, hit_pos.y + ground_clearance, global_position.z)
			# only raise if we're below desired clearance
			if global_position.y < desired_global.y - 0.001:
				var t = clamp(move_speed * delta * 2.0, 0.0, 1.0)
				global_position = global_position.lerp(desired_global, t)


func die():
	if not is_alive:
		return
	
	is_alive = false
	print("Player died!")
	
	# Create simple explosion effect
	create_explosion()
	
	# Hide the character
	character_slot.visible = false
	tank_tower.visible = false
	
	# Wait a moment then respawn or game over
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/World/menue.tscn")

func create_explosion():
	# Create multiple particle-like spheres that expand outward
	for i in range(12):
		var explosion_part = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.3
		sphere.height = 0.6
		explosion_part.mesh = sphere
		
		# Create material
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.5, 0.0, 1.0)  # Orange explosion
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.3, 0.0)
		mat.emission_energy_multiplier = 2.0
		explosion_part.material_override = mat
		
		get_parent().add_child(explosion_part)
		explosion_part.global_position = global_position
		
		# Random direction
		var random_dir = Vector3(
			randf_range(-1, 1),
			randf_range(0.5, 1),
			randf_range(-1, 1)
		).normalized()
		
		# Animate the explosion part
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(explosion_part, "global_position", 
			global_position + random_dir * randf_range(3, 6), 1.0)
		tween.tween_property(explosion_part, "scale", Vector3.ZERO, 1.0)
		
		# Delete after animation
		tween.finished.connect(func(): explosion_part.queue_free())

func respawn():
	# Reset position to spawn or current position
	current_hp = max_hp
	is_alive = true
	character_slot.visible = true
	tank_tower.visible = true
	
	if hp_bar:
		hp_bar.value = current_hp
	
	print("Player respawned!")
