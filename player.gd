extends CharacterBody2D

@export var animation: AnimationPlayer

const WALK_SPEED = 400.0
const DASH_SPEED = 4
const JUMP_VELOCITY = -500.0
var direction := 0.0:
	set(value):
		var old_value = direction
		direction = value
		if not value == 0:
			$Skeleton2D.scale.x = value
		
		if is_dash_freeze or is_attack_freeze:
			return
		
		if old_value == value:
			if not value == 0:
				animation.play("anim_choppy_run_ninja")
			else:
				animation.play("anim_choppy_idle")
		else:
			if old_value == 0 and not value == 0:
				if not animation.current_animation == "anim_choppy_idle":
					animation.queue("anim_choppy_run_start")
				else:
					print("START")
					animation.play("anim_choppy_run_start")
				animation.queue("anim_choppy_run_ninja")
			elif value == 0:
				if not animation.current_animation == "anim_choppy_run_ninja":
					animation.queue("anim_choppy_run_end")
				else:
					animation.play("anim_choppy_run_end")
				animation.queue("anim_choppy_idle")
var look_direction := 1.0

var dash_count := 3
var is_dash := false:
	set(value):
		is_dash = value
		if value:
			is_dash_freeze = true
			animation.play("anim_choppy_dash_start")
		else:
			animation.play("anim_choppy_dash_start", -1, -0.25, true)
			await animation.animation_finished
			is_dash_freeze = false
var dash_speed := 0.0

var punch_series = 0.0:
	set(value):
		punch_series = value
		if punch_series == 5:
			punch_series = 1
		
		is_attack_freeze = true
		if punch_series == 3:
			animation.play("anim_choppy_test_punch_2", -1, -0.9, true)
		else:
			animation.play("anim_choppy_test_punch_" + str(punch_series), -1, 0.9)
		await animation.animation_finished
		animation.play("anim_choppy_idle")
		is_attack_freeze = false
		
var punch_freeze_speed := 1.0

var is_dash_freeze := false
var is_attack_freeze := false:
	set(value):
		is_attack_freeze = value
		
		
		if value:
			punch_freeze_speed = 0.5
			if punch_series == 4:
				punch_freeze_speed = 0.0
		else:
			punch_freeze_speed = 1.0
		


func _ready() -> void:
	animation.play("anim_choppy_idle")
	is_attack_freeze = true
	await get_tree().create_timer(4).timeout
	animation.play("anim_choppy_ready")
	await animation.animation_finished
	await get_tree().create_timer(1).timeout
	animation.play_backwards("anim_choppy_ready")
	await animation.animation_finished
	animation.play("anim_choppy_idle")
	is_attack_freeze = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta * 1.25
	
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY * 1.25
	
	# Movement
	if Input.is_action_pressed("left"):
		look_direction = -1
		direction = -1
	elif Input.is_action_pressed("right"):
		look_direction = 1
		direction = 1
	else:
		direction = 0.0
	
	#if is_attack_freeze:
	#	direction = 0.0
	
	# Look direction
	#if Input.is_action_pressed("up"):
	#	look_direction.y = -1
	#else:
	#	look_direction.y = 0
	
	# Dash
	if Input.is_action_just_pressed("dash") and dash_count > 0 and not is_attack_freeze:
		if not is_dash:
			is_dash = true
			start_dash(delta)
	
	# Velocity
	if direction:
		velocity.x = direction * WALK_SPEED * punch_freeze_speed
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
	
	if is_dash:
		velocity.x = look_direction * dash_speed
		#if not fixed_look_direction.y == 0.0:
		#	velocity.y = fixed_look_direction.y * dash_speed * 0.5
	elif is_dash and not direction:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
	
	move_and_slide()

func start_dash(delta: float):
	dash_speed = WALK_SPEED * DASH_SPEED
	while dash_speed > WALK_SPEED:
		dash_speed -= 2400.0 * delta
		await get_tree().create_timer(delta).timeout
	dash_speed = WALK_SPEED
	is_dash = false

func _input(event: InputEvent) -> void:
	# Punch
	if Input.is_action_just_pressed("punch"):
		punch_series += 1

func play_animation(name: String):
	match animation.current_animation:
		"anim_choppy_idle", name == "anim_choppy_run_start":
			pass
	animation.play(name)
