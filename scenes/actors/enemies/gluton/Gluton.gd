# Aqui van las caracteristicas del enemigo Gluton

extends "res://scenes/actors/enemies/GEnemy.gd"

const MAX_SPEED = 25
const MAX_FORCE = 0.02
const RANDOM_RUN_DISTANCE = 200

var velocity = Vector2()

export (int, "SEEK", "FLEE") var mode = 0

var speed : int = 3
var attack : int = 2

var view_distance : float = 10
var attack_distance : float = 1

# Objetivo random cuando no esta haciendo nada
var random_objective : Vector2 = Vector2()
# Ultima posicion del objetivo
var last_objective_position : Vector2

onready var objective = null

# Se usa para atacar solo una vez
var ot_attack = true

func _ready():
	state = State.RANDOM_WALK
	
	$Body.playing = true
	$DamageDelay.set_wait_time(0.2)
	
	.spawn()
	
	randomize()
	random_objective = get_random_objective()
	
	data.hp = 8
	data.xp_drop = 5 # temp
	
	data.connect("dead", self, "_on_dead")
	data.connect("drop_xp", self, "_on_drop_xp")
	
func _physics_process(delta):
	match state:
		State.SEEKER:
			if objective and not objective.is_mark_to_dead and data.hp > 3:
				sekeer(objective.global_position)
				
				if data.hp < 3:
					change_state(State.RUN)
			else:
				change_state(State.RANDOM_WALK)
		State.RUN:
			if objective and not objective.is_mark_to_dead:
				run(objective.global_position)
			else:
				change_state(State.RANDOM_WALK)
		State.ATTACK:
			if objective.is_mark_to_dead : 
				change_state(State.RANDOM_WALK)
				return
			$Body.look_at(objective.position)
			$Body.flip_h = false
			
			if $Body.frame == 10 and ot_attack:
				ot_attack = false
				objective.data.damage(1) # TEMP
			elif $Body.frame == 11:
				ot_attack = true
		State.DIE:
			if not is_mark_to_dead:
				is_mark_to_dead = true
				SoundManager.play(SoundManager.Sound.MONSTER_DEAD_1)
				.dead()
		State.RANDOM_WALK:
			if not objective or objective.is_mark_to_dead:
				sekeer(random_objective)
			elif data.hp < 3 and objective and not objective.is_mark_to_dead:
				change_state(State.RUN)
			elif data.hp > 3 and objective and not objective.is_mark_to_dead:
				change_state(State.SEEKER)

# Devuelve la direccion en grados
func get_direction_to_see(objective):
	var rounded_angle = round(transform.origin.angle_to_point(objective))
	
	if rounded_angle == 2:
		return 0
	elif rounded_angle == -2:
		return 180
	elif rounded_angle == 0:
		return -90
	elif rounded_angle == 3:
		return 90
	else:
		return $Body.get_animation()
	
# Rutina en caso de que vea al objetivo
func sekeer(objective):
	match get_direction_to_see(objective):
		0:
			$Body.play("Run_Up")
		180:
			$Body.play("Run_Down")
		90:
			if $Body.flip_h:
				$Body.flip_h = false
			$Body.play("Run_Side")
		-90:
			if !$Body.flip_h:
				$Body.flip_h = true
			$Body.play("Run_Side")
			
	velocity = steer(objective)
	move_and_slide(velocity)
	
# Rutina en caso de tener que huir del objetivo
func run(objective):
	match get_direction_to_see(objective):
		0:
			$Body.play("Run_Down")
		180:
			$Body.play("Run_Up")
		90:
			if !$Body.flip_h:
				$Body.flip_h = true
			$Body.play("Run_Side")
		-90:
			if $Body.flip_h:
				$Body.flip_h = false
			$Body.play("Run_Side")
	
	velocity = steer(objective)
	move_and_slide(velocity * 3)
	
func steer(target : Vector2):
	var desired_velocity = (target - position).normalized() * MAX_SPEED
	
	if state == State.RUN:
		desired_velocity = -desired_velocity
	
	var steer = desired_velocity - velocity
	var target_velocity = velocity + (steer * MAX_FORCE)
	
	return(target_velocity)

func get_random_objective():
	if objective:
		last_objective_position = objective.global_position
	
	# Caso en el cual a visto al jugador alguna ves
	if last_objective_position and random_objective.distance_to(last_objective_position) <= RANDOM_RUN_DISTANCE:
		random_objective = Vector2(
			rand_range(global_position.x + RANDOM_RUN_DISTANCE, global_position.y + RANDOM_RUN_DISTANCE),
			rand_range(global_position.x + -RANDOM_RUN_DISTANCE, global_position.y + -RANDOM_RUN_DISTANCE) 
		)
		
		while random_objective.distance_to(last_objective_position) <= RANDOM_RUN_DISTANCE:
			random_objective = Vector2(
				rand_range(global_position.x + RANDOM_RUN_DISTANCE, global_position.y + RANDOM_RUN_DISTANCE),
				rand_range(global_position.x + -RANDOM_RUN_DISTANCE, global_position.y + -RANDOM_RUN_DISTANCE) 
			)
	elif last_objective_position and random_objective and random_objective.distance_to(last_objective_position) > RANDOM_RUN_DISTANCE:
		return random_objective
	else:
		random_objective = Vector2(
			rand_range(global_position.x + RANDOM_RUN_DISTANCE, global_position.y + RANDOM_RUN_DISTANCE),
			rand_range(global_position.x + -RANDOM_RUN_DISTANCE, global_position.y + -RANDOM_RUN_DISTANCE) 
		)

	return random_objective

func _on_DetectArea_body_entered(body):
	if body as GPlayer:
		objective = body
		
func _on_drop_xp(amount):
	# TEMP
	DataManager.get_current_player_instance().add_xp(amount)
	
func _on_DetectArea_body_exited(body):
	if body as GPlayer:
		objective = null
	
func _on_DamageDelay_timeout():
	can_damage = true

func _on_dead():
	change_state(State.DIE)
	
func _on_DamageArea_body_entered(body):
	if body is GBullet and not is_mark_to_dead:
		body.dead()
		.damage(1) # temp
		if data.hp != 0: SoundManager.play(SoundManager.Sound.MONSTER_DAMAGE_2)
	
func _on_ChangeRandomObjective_timeout():
	random_objective = get_random_objective()
	
func _on_AttackArea_body_entered(body):
	if body is GPlayer:
		change_state(State.ATTACK)
		$Body.play("Attack")

func _on_AttackArea_body_exited(body):
	if body is GPlayer:
		$Body.rotation_degrees = 0
		change_state(State.SEEKER)
