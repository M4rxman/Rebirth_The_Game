extends Node3D

var character_state : int 
var character_generation : int = 0

var _is_transforming: bool = false
var _egg_spawn_transform = null

@export var move_speed: float = 10.0
@export var turn_speed: float = 1.0
@export var ground_offset: float = 0.5
@export var ground_clearance: float = 0.6
@export var ground_raycast_depth: float = 8.0
@export var ground_collision_mask: int = 1
@export var egg_opened: PackedScene = preload("res://Scenes/Egg/brokenegg.tscn")
@export var egg_duration: float = 3.0

@onready var fl_leg = $FrontLeftIKTarget
@onready var fr_leg = $FrontRightIKTarget

@onready var bl_leg = $BackLeftIKTarget
@onready var br_leg = $BackRightIKTarget
@onready var tank_tower = $Plane
@onready var character_slot = $Armature/Skeleton3D
@onready var egg_slot = $Egg 


func _ready() -> void:
	tank_tower.visible = true
	character_slot.visible = true
	egg_slot.hide()

func _process(delta):
	var plane1 = Plane(bl_leg.global_position, fl_leg.global_position, fr_leg.global_position)
	var plane2 = Plane(fr_leg.global_position, br_leg.global_position, bl_leg.global_position)
	var avg_normal = ((plane1.normal + plane2.normal) / 2).normalized()
	
	var target_basis = _basis_from_normal(avg_normal)
	transform.basis = lerp(transform.basis, target_basis, move_speed * delta).orthonormalized()
	
	var avg = (fl_leg.position + fr_leg.position + bl_leg.position + br_leg.position) / 4
	var target_pos = avg + transform.basis.y * ground_offset
	var distance = transform.basis.y.dot(target_pos - position)
	position = lerp(position, position + transform.basis.y * distance, move_speed * delta)
	
	if Input.is_action_just_pressed("egg_action") and Globals.meal>Globals.character_generation*5:
		if not _is_transforming:
			start_egg_sequence()
	
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
	
	tank_tower.visible = true
	character_slot.visible = true
	egg_slot.visible = false
	
func drop_egg():
	# legacy single-arg drop; forward to new signature
	drop_egg_at(null)


func drop_egg_at(spawn_transform = null):
	# Accept either a PackedScene (exported) or a path; our exported is a PackedScene
	var packed: PackedScene = egg_opened
	if packed == null:
		push_error("egg_opened PackedScene is not assigned: %s" % [egg_opened])
		return

	var instance = packed.instantiate()
	if instance == null:
		push_error("Failed to instantiate egg scene")
		return

	if spawn_transform != null:
		instance.global_transform = spawn_transform
	elif tank_tower != null:
		instance.global_transform = tank_tower.global_transform
	else:
		instance.global_transform = global_transform

	var root = get_tree().get_current_scene()
	if root == null:
		push_error("No current scene to add the egg to")
		return
	root.add_child(instance)

func switch_to_egg():
	print("swithced to the egg")
	Globals.character_generation += 1
	Globals.meal = 0
	egg_slot.show()
	
	move_speed = 0
	turn_speed = 0
	character_slot.visible = false
	tank_tower.visible = false
	
	egg_slot.hatch()

	# record spawn transform so the egg will be left at this location
	_egg_spawn_transform = global_transform
	_is_transforming = true


func start_egg_sequence() -> void:
	# Switch visuals to egg and wait
	switch_to_egg()

	# use exported duration
	var duration := egg_duration
	var timer = get_tree().create_timer(duration)
	await timer.timeout

	# spawn the egg at the recorded transform
	drop_egg_at(_egg_spawn_transform)

	# restore player state so they can walk away
	switch_to_character()
	_is_transforming = false

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
