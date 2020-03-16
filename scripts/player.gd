extends KinematicBody2D
signal attacked

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
var velocity = Vector2()
var gravity = -9.8
export var rot_angle = 5.0
export var damping = 0.1
export var min_speed = 5.0
export var speed = 50.0
export var attack_force = 10.0
export var health = 100.0
export var is_player = false
export var enemy_selection_ttl = 5.0
export var attack_distance = 40.0
export var safety_distance = 150.0
export var rapid_multiplier1 = 1.5
export var rapid_multiplier2 = 2.0
export var blocking_duration = 0.5
export var attack_cooldown_base = 2.0
export var attack_cooldown_var = 4.0
func _ready():
	add_to_group("characters")


# Called every frame. 'delta' is the elapsed time since the previous frame.
var ai_enemy = null
var ai_enemy_ttl = enemy_selection_ttl
func ai_select_enemy(delta):
	if ai_enemy:
		if ai_enemy.health > 0.0 && ai_enemy_ttl > 0.0:
			ai_enemy_ttl -= delta
			return
	var enemy = null
	var dv = INF
	for o in get_tree().get_nodes_in_group("characters"):
		if self == o:
			continue
		if o.is_dead():
			continue
		var d = position.distance_squared_to(o.position)
		if dv > d:
			dv = d
			enemy = o
	if enemy:
		ai_enemy = enemy
		ai_enemy_ttl = enemy_selection_ttl
func char_distance(c1, c2):
	return c1.position.distance_to(c2.position)
var attack_cooldown = 0.0
var blocking = 0.0
func attacked(attacker):
	if blocking <= 0.0:
		$body/attacked.show()
	attack_cooldown += 0.5
	if is_dead():
		velocity = Vector2()
	else:
		emit_signal("attacked")
		if blocking <= 0.0:
			yield(get_tree().create_timer(0.1 + randf() * 0.2), "timeout")
			$body/attacked.hide()
func attack1(c1, c2):
	attack_cooldown += attack_cooldown_base + randf() * attack_cooldown_var
	var base = int(attack_force / 3)
	var r = int(attack_force - base)
	var adata = base
	if r > 0:
		adata += randi() % r
	if c2.blocking <= 0.0:
		c2.health -= adata
		if c2.is_dead():
			ai_enemy = null
			ai_enemy_ttl = 0.0
	c2.call_deferred("attacked", c1)
func can_attack():
	return attack_cooldown < 0.0 && health > 0
func is_dead():
	return health <= 0
func _process(delta):
	if is_dead():
		return
	if is_player:
		if Input.is_action_pressed("turn_left"):
			rotate(deg2rad(-rot_angle * 60.0 * delta))
		if Input.is_action_pressed("turn_right"):
			rotate(deg2rad(rot_angle * 60.0 * delta))
		if Input.is_action_pressed("move_forward"):
			velocity += Vector2(cos(rotation) * speed, sin(rotation) * speed) * damping
		if Input.is_action_pressed("attack"):
			if can_attack():
				if $attack_ray.is_colliding():
					var o = $attack_ray.get_collider()
					if o.is_in_group("characters") && o != self:
						if char_distance(self, o) < attack_distance:
							attack1(self, o)
		if Input.is_action_pressed("retreat"):
			velocity -= Vector2(cos(rotation) * speed * rapid_multiplier2, sin(rotation) * speed * rapid_multiplier2) * damping
		if Input.is_action_pressed("block"):
			if can_attack():
				blocking += blocking_duration
				velocity -= Vector2(cos(rotation) * speed * rapid_multiplier2, sin(rotation) * speed * rapid_multiplier2) * damping
				attack_cooldown += blocking_duration * 2.0
	if velocity.length() < 5.0:
		velocity = Vector2()
	if !is_player:
		if can_attack():
			ai_select_enemy(delta)
			if ai_enemy:
				look_at(ai_enemy.position)
				var cd = char_distance(self, ai_enemy)
				if cd < 40.0:
					attack1(self, ai_enemy)
				else:
					velocity += Vector2(cos(rotation) * speed, sin(rotation) * speed) * damping
		elif !is_dead():
			ai_select_enemy(delta)
			if ai_enemy:
				var cd = char_distance(self, ai_enemy)
				if cd < safety_distance && cd > attack_distance:
					var ev = ai_enemy.position - position
					var look_pos = position - ev
					look_at(look_pos)
					velocity += Vector2(cos(rotation) * speed * rapid_multiplier1, sin(rotation) * speed * rapid_multiplier1) * damping
				elif cd <= attack_distance:
					velocity -= Vector2(cos(rotation) * speed * rapid_multiplier2, sin(rotation) * speed * rapid_multiplier2) * damping
	velocity = velocity * (1.0 - damping)
	if attack_cooldown >= 0:
		attack_cooldown -= delta
	if blocking >= 0:
		blocking -= delta
func _physics_process(delta):
	velocity += Vector2(0, gravity) * delta
	velocity = move_and_slide(velocity)
