class_name Player
extends CharacterBody2D

@export var animation: AnimationPlayer

# Movement
const WALK_SPEED = 400.0
const DASH_SPEED = 4
const JUMP_VELOCITY = -575.0
var walk_speed := WALK_SPEED
var is_backward_walk := false
var direction := 0.0:
	set(value):
		var old_value = direction
		dash_direction = value
		direction = value
		is_backward_walk = not (direction == look_direction)
		
		if is_punch and punch_series == 3:
			walk_speed = 0.0
		elif is_punch and punch_series < 3:
			walk_speed = WALK_SPEED * 0.4
		elif is_backward_walk or is_shield:
			walk_speed = WALK_SPEED * 0.85
		else:
			walk_speed = WALK_SPEED
		
		if is_dash or is_punch or is_jump:
			return
		
		if old_value == value:
			if value == 0:
				if is_shield:
					$AnimatedSprite2D.play("shield_idle")
				else:
					$AnimatedSprite2D.play("idle")
					play_animation("anim_idle")
			else:
				if is_shield:
					if not is_backward_walk:
						$AnimatedSprite2D.play("shield_walk")
					else:
						$AnimatedSprite2D.play_backwards("shield_walk")
				else:
					if not is_backward_walk:
						$AnimatedSprite2D.play("run")
						#play_animation("anim_run")
					else:
						$AnimatedSprite2D.play("backward_walk")
		else:
			if old_value == 0:
				play_animation("anim_run_start")
			elif value == 0:
				play_animation("anim_run_end")
var look_direction := 1.0:
	set(value):
		look_direction = value
		if not value == 0:
			$AnimatedSprite2D.scale.x = value * 0.8
			$AnimatedSprite2D.scale.y = abs(value * 0.8)
var dash_direction := 1.0:
	set(value):
		if not value == 0:
			dash_direction = value

# Dash
var dash_count := 3
var is_dash := false:
	set(value):
		if value:
			is_dash = value
			if direction == look_direction or direction == 0:
				$AnimatedSprite2D.play("dash")
			else:
				$AnimatedSprite2D.play("backdash")
			play_animation("anim_dash_start")
		else:
			play_animation("anim_dash_end")
			await animation.animation_finished
			is_dash = value
var dash_speed := 0.0

# Punch
var punch_series = 0.0:
	set(value):
		punch_series = value
		while true:
			if punch_series == 4:
				punch_series = 1
			#if not is_punch and punch_series == 3:
			#	play_animation("anim_punch_2_3")
			is_punch = true
			if punch_series == 3:
				$AnimatedSprite2D.play("punch3_down")
				await $AnimatedSprite2D.frame_changed
				punch_area.send_punch(punch_series)
				await $AnimatedSprite2D.animation_finished
			else:
				$AnimatedSprite2D.play("punch" + str(punch_series))
				await $AnimatedSprite2D.frame_changed
				punch_area.send_punch(punch_series)
				await $AnimatedSprite2D.animation_finished
			#await play_animation("anim_punch_" + str(punch_series))
			#await animation.animation_finished
			if Input.is_action_pressed("punch"):
				punch_series += 1
			else:
				#if punch_series == 2:
				#	play_animation("anim_punch_2_3")
				is_punch = false
				break
var punch_freeze_speed := 1.0
var is_punch := false:
	set(value):
		is_punch = value
		if value:
			punch_freeze_speed = 0.5
			if punch_series == 4:
				punch_freeze_speed = 0.0
		else:
			punch_freeze_speed = 1.0

# Jump
var is_jump := false:
	set(value):
		print("1")
		var old_value = is_jump
		if not old_value == value:
			if value and not is_punch:
				print("2")
				$AnimatedSprite2D.play("jump" + str(randi_range(1, 2)))
				play_animation("anim_jump")
		is_jump = value
var is_fall := false:
	set(value):
		var old_value = is_fall
		if not old_value == value:
			if value and not is_punch:
				$AnimatedSprite2D.play("fall")
				play_animation("anim_fall")
		is_fall = value

# Shield
var is_shield := false

@export var punch_area: Area2D


func _ready() -> void:
	$AnimatedSprite2D.play("idle")
	play_animation("anim_idle")
	#is_attack_freeze = true
	#await get_tree().create_timer(4).timeout
	#play_animation("anim_choppy_ready")
	#await animation.animation_finished
	#await get_tree().create_timer(1).timeout
	##play_animation("anim_choppy_ready")
	##await animation.animation_finished
	##play_animation("anim_choppy_idle")
	##is_attack_freeze = false

func _physics_process(delta: float) -> void:
	# Jump
	is_fall = velocity.y > 0
	
	if is_on_floor():
		is_jump = false
	else:
		velocity += get_gravity() * delta * 1.25
	
	if Input.is_action_pressed("jump") and is_on_floor() and not is_punch:
		is_jump = true
		velocity.y = JUMP_VELOCITY * 1.25
	
	# Movement
	if Input.is_action_pressed("left"):
		direction = -1
	elif Input.is_action_pressed("right"):
		direction = 1
	else:
		direction = 0.0
		
	
	#if is_attack_freeze:
	#	direction = 0.0
	
	# Look direction
	#print(get_local_mouse_position().normalized().x)
	look_direction = Vector2(get_local_mouse_position().x, 0).normalized().x
	is_shield = Input.is_action_pressed("shield")
	# Dash
	if Input.is_action_just_pressed("dash") and dash_count > 0 and not is_punch:
		if not is_dash:
			is_dash = true
			start_dash(delta)
	
	# Velocity
	if direction:
		velocity.x = direction * walk_speed
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
	
	# Dash velocity
	if is_dash:
		print(look_direction)
		velocity.x = dash_direction * dash_speed
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
	if Input.is_action_pressed("punch") and not is_punch:
		punch_series += 1

var current_animation: String

func play_animation(name: String):
	var animation_transitions = [
			"anim_run_start",
			"anim_run_end",
			"anim_dash_start",
			"anim_dash_end",
			"anim_punch_2_3"
	]
	var animation_name = name
	var animation_speed := 1.0
	match name:
		#"anim_choppy_run_start" when animation.current_animation == "anim_choppy_idle":
		#	animation.play(name)
		"anim_run" when animation_transitions.has(current_animation):
			return
		"anim_idle" when animation_transitions.has(current_animation):
			return
		#"anim_choppy_jump" when is_punch:
		#	return
		"anim_punch_1", "anim_punch_2", "anim_punch_4", "anim_punch_3":
			if current_animation == "anim_punch_2_3":
				await animation.animation_finished
			animation_speed = 0.9
		
			#animation_name = "anim_choppy_punch_2"
			#animation_speed = -1.1
		"anim_dash_end" when current_animation == "anim_jump" or current_animation == "anim_fall":
			return
		"anim_dash_end":
			animation_name = "anim_dash_start"
			animation_speed = -0.5
	animation.play(animation_name, -1, animation_speed, (animation_speed < 0))
	current_animation = name

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	current_animation = ""
