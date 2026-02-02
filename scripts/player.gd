extends CharacterBody2D

@onready var camera := get_parent().get_node("Camera2D")


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
var current_interactable: Node = null
var is_interacting_with = null
var nearby_npcs: Array[Node] = []



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
	interact_area.body_entered.connect(_on_interact_body_entered)
	interact_area.body_exited.connect(_on_interact_body_exited)
	
	# Set up animation system
	animated_sprite.animation_finished.connect(on_anim_finished)
	

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
	
	if Input.is_action_just_pressed("interact"):
		try_talk()

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




func set_interact_area_facing(dir: int) -> void:
	if dir == 0:
		return
	var facing = 1 if dir > 0 else -1
	interact_area.position.x = abs(interact_area.position.x) * facing
	
func _on_interact_body_entered(body: Node) -> void:
	if body.is_in_group("interactable") and body.has_method("interact"):
		nearby_interactables.append(body)
	
func _on_interact_body_exited(body: Node) -> void:
	nearby_interactables.erase(body)
	
func get_best_interactable() -> Node:
	var best: Node = null
	var best_dist := INF
		
	for obj in nearby_interactables:
		if not is_instance_valid(obj):
			continue
		if obj.has_method("can_interact") and not obj.can_interact(self):
			continue
		
		var d := global_position.distance_to(obj.global_position)
		if d < best_dist:
			best_dist = d
			best = obj
	
	return best




func register_npc(npc: Node) -> void:
	if not nearby_npcs.has(npc):
		nearby_npcs.append(npc)

func unregister_npc(npc: Node) -> void:
	if npc == is_interacting_with:
		end_npc_interaction()
	nearby_npcs.erase(npc)

func get_best_npc() -> Node:
	var best: Node = null
	var best_dist := INF

	for npc in nearby_npcs:
		if not is_instance_valid(npc):
			continue
		if npc.has_method("can_interact") and not npc.can_interact(self):
			continue

		var d := global_position.distance_to(npc.global_position)
		if d < best_dist:
			best_dist = d
			best = npc
	return best

func start_npc_focus(npc: Node2D) -> void:
	is_interacting_with = npc
	camera.focus_on(npc)

func end_npc_interaction() -> void:
	is_interacting_with = null
	camera.clear_focus()

func try_talk() -> void:
	var npc := get_best_npc()
	if npc:
		start_npc_focus(npc)
		npc.set_icon_visible(false)
		npc.interact(self)
