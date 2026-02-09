extends CharacterBody2D

@onready var camera := get_parent().get_node("Camera2D")

@onready var inventory: Node2D = $Inventory

###################################
# SIDE TO SIDE MOVEMENT VARIABLES #
###################################
const SPEED = 350.0 # Base horizontal movement speed
const ACCELERATION = 1200.0 # Base acceleration
const FRICTION = 1400.0 # Base friction

#################################
# GRAVITY AND FALLING VARIABLES #
#################################
const GRAVITY = 2000.0 # Gravity when moving upwards
const FALL_GRAVITY = 2500.0 # Gravity when falling downwards
const WALL_GRAVITY = 25.0 # Gravity while sliding on a wall
const MAX_FALL_VELOCITY = 4000.0

#####################
# JUMPING VARIABLES #
#####################
const JUMP_VELOCITY = -700.0 # Maximum jump strength
const WALL_JUMP_VELOCITY = -700.0 # Maximum wall jump strength
const WALL_JUMP_PUSHBACK = 400.0 # Horizontal push strength off walls

##############################
# INPUT ASSISTANCE VARIABLES #
##############################
const INPUT_BUFFER_PATIENCE = 0.1 # Input queue patience time
const COYOTE_TIME = 0.08 # Coyote patience time
var input_buffer : Timer # Reference to the input queue timer
var coyote_timer : Timer # Reference to the coyote timer
var coyote_jump_available := true

##################
# LEAP VARIABLES #
##################
const LEAP_X_VELOCITY = 600.0
const LEAP_Y_VELOCITY = -400.0
var has_leap := true
var is_leaping := false
var did_wall_jump := false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

#########################
# INTERACTION VARIABLES #
#########################
@onready var interact_area: Area2D = $Area2D
var interact_offset_x := 24.0
var nearby_interactables: Array = []
var nearby_npcs: Array = []
var is_interacting_with = null

var current_target: Node = null

@export var target_recalc_distance := 15.0  

var last_target_check_pos: Vector2
var target_dirty := true

#######################
# ANIMATION VARIABLES #
#######################
var anim_lock := false
var locked_anim := ""
var was_on_floor := false


func _ready() -> void:
	# Set up input buffer timer
	input_buffer = Timer.new()
	input_buffer.wait_time = INPUT_BUFFER_PATIENCE
	input_buffer.one_shot = true
	add_child(input_buffer)

	# Set up coyote timer
	coyote_timer = Timer.new()
	coyote_timer.wait_time = COYOTE_TIME
	coyote_timer.one_shot = true
	add_child(coyote_timer)
	coyote_timer.timeout.connect(coyote_timeout)
	
	# Set up interaction area
	interact_area.area_entered.connect(_on_interact_area_entered)
	interact_area.area_exited.connect(_on_interact_area_exited)
	
	last_target_check_pos = global_position
	
	# Set up animation system
	animated_sprite.animation_finished.connect(on_anim_finished)
	
	
func mark_targeting_dirty() -> void:
	target_dirty = true

func _on_world_event(event_name: String, data: Dictionary) -> void:
	print("WORLD EVENT:", event_name, data)
	
func _physics_process(delta) -> void:
	
	was_on_floor = is_on_floor()
	
	# Get inputs
	var horizontal_input := Input.get_axis("move_left", "move_right")
	var jump_attempted := Input.is_action_just_pressed("jump")

	# Add the gravity and handle jumping
	if jump_attempted or input_buffer.time_left > 0:
		if coyote_jump_available: # If jumping on the ground
			velocity.y = JUMP_VELOCITY
			coyote_jump_available = false
		elif is_on_wall() and horizontal_input != 0: # If jumping off a wall
			velocity.y = WALL_JUMP_VELOCITY
			velocity.x = WALL_JUMP_PUSHBACK * -sign(horizontal_input)
			did_wall_jump = true
		elif jump_attempted and has_leap and not is_on_floor():
			velocity.y = LEAP_Y_VELOCITY
			var dir = sign(horizontal_input)
			if dir == 0:
				dir = sign(velocity.x)
			if dir == 0:
				dir = 1

			velocity.x = dir * LEAP_X_VELOCITY
			
			has_leap = false
			is_leaping = true
			
		elif jump_attempted: # Queue input buffer if jump was attempted
			input_buffer.start()

	# Apply gravity and reset coyote jump
	if is_on_floor():
		coyote_jump_available = true
		coyote_timer.stop()
		has_leap = true
		is_leaping = false
		
	else:
		if coyote_jump_available:
			if coyote_timer.is_stopped():
				coyote_timer.start()
		if velocity.y < MAX_FALL_VELOCITY:
			velocity.y += custom_get_gravity(horizontal_input) * delta
		else:
			velocity.y = MAX_FALL_VELOCITY

	# Handle horizontal motion and friction
	var floor_damping := 1.0 if is_on_floor() else 0.2 # Set floor damping, friction is less when in air
	if horizontal_input:
		velocity.x = move_toward(velocity.x, horizontal_input * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, (FRICTION * delta) * floor_damping)

	# Apply velocity
	move_and_slide()
	
	update_animation(horizontal_input)
	
	set_interact_area_facing(horizontal_input)
	
	maybe_update_target()
	
	if Input.is_action_just_pressed("interact"):
		if is_interacting_with and is_interacting_with.is_typing:
			is_interacting_with.skip_typing()
		else:
			handle_interact()


## Returns the gravity based on the state of the player
func custom_get_gravity(input_dir : float = 0) -> float:
	if is_on_wall_only() and velocity.y > 0 and input_dir != 0:
		return WALL_GRAVITY
	return GRAVITY if velocity.y < 0 else FALL_GRAVITY
	
## Reset coyote jump
func coyote_timeout() -> void:
	coyote_jump_available = false



func update_animation(horizontal_input: float) -> void:
	
	if horizontal_input > 0:
		animated_sprite.flip_h = false
	elif horizontal_input < 0:
		animated_sprite.flip_h = true
		
	if did_wall_jump:
		did_wall_jump = false
		play_one_shot("wall_jump")
		return
		
	if (not was_on_floor) and is_on_floor():
		play_one_shot("land")
		return
		
	if anim_lock:
		return

		
	if is_on_floor():
		if horizontal_input != 0:
			animated_sprite.play("run")
		else:
			animated_sprite.play("idle")
	elif is_on_wall_only() and velocity.y > 0 and horizontal_input != 0:
		animated_sprite.play("wall_slide")
	elif is_leaping:
		animated_sprite.play("leap")
	else:
		animated_sprite.play("jump")
		
func on_anim_finished() -> void:
	if anim_lock and animated_sprite.animation == locked_anim:
		anim_lock = false
		locked_anim = ""
		
func play_one_shot(anim_name: String) -> void:
	if anim_lock and locked_anim == anim_name:
		return
	anim_lock = true
	locked_anim = anim_name
	animated_sprite.play(anim_name)




func set_interact_area_facing(dir: float) -> void:
	if dir == 0:
		return
	var facing = 1 if dir > 0 else -1
	interact_area.position.x = abs(interact_area.position.x) * facing
	
func _on_interact_area_entered(area: Area2D) -> void:
	var interactable = area.interactable_base
	if interactable == null:
		return
	nearby_interactables.append(interactable)
	target_dirty = true
	
func _on_interact_area_exited(area: Area2D) -> void:
	var interactable = area.interactable_base
	if interactable == null:
		return
	nearby_interactables.erase(interactable)
	target_dirty = true




func register_npc(npc: Node) -> void:
	if not nearby_npcs.has(npc):
		nearby_npcs.append(npc)

func unregister_npc(npc: Node) -> void:
	nearby_npcs.erase(npc)

func start_npc_interaction(npc: Node2D) -> void:
	if is_interacting_with:
		end_npc_interaction(is_interacting_with)
	is_interacting_with = npc
	camera.focus_on(npc)

func end_npc_interaction(npc: Node2D) -> void:
	npc.hide_dialogue()
	camera.clear_focus()
	is_interacting_with = null

	
func maybe_update_target() -> void:
	var total := nearby_interactables.size() + nearby_npcs.size()

	# If nothing nearby, ensure we clear/hide once (no spam)
	if total == 0:
		if current_target and is_instance_valid(current_target):
			current_target.set_icon_visible(false)
		current_target = null
		target_dirty = false
		last_target_check_pos = global_position
		return

	# If only 1 thing nearby, we can choose it without distance thrashing.
	# Still only run if dirty (enter/exit) so we don't redo work.
	if total == 1:
		if target_dirty:
			update_target()
			target_dirty = false
			last_target_check_pos = global_position
		return

	# total >= 2: only re-evaluate if dirty OR moved far enough
	var moved_far_enough := global_position.distance_to(last_target_check_pos) >= target_recalc_distance
	if target_dirty or moved_far_enough:
		update_target()
		target_dirty = false
		last_target_check_pos = global_position


func handle_interact() -> void:
	if current_target and current_target != is_interacting_with:
		current_target.interact(self)


func get_closest_valid(list: Array) -> Node:
	var best_dist = INF
	var best: Node = null

	for n in list:

		if not n.has_method("interact") or is_interacting_with == n:
			continue

		var d := global_position.distance_to((n as Node2D).global_position)
		if d < best_dist:
			best_dist = d
			best = n

	return best

func update_target() -> void:

	var new_target: Node = null

	# Prefer interactables
	var best_interactable = get_closest_valid(nearby_interactables)
	if best_interactable:
		new_target = best_interactable
	else:
		# Fallback to NPCs
		var best_npc = get_closest_valid(nearby_npcs)
		if best_npc:
			new_target = best_npc

	# If target didn't change, do nothing
	if new_target == current_target:
		return

	# Hide old icon
	if current_target and is_instance_valid(current_target):
		current_target.set_icon_visible(false)

	# Set new target
	current_target = new_target

	# Show new icon
	if current_target and is_instance_valid(current_target):
		current_target.set_icon_visible(true)
