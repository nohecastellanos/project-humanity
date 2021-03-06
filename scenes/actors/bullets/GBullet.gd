extends KinematicBody2D

class_name GBullet

enum Trajectory {
	LINEAL,
	SEEKER
}
var trajectory = Trajectory.LINEAL
#var origin : Vector2
var direction : Vector2

# El que dispara las balas le dice a la bala cuanto daño
# hace, por ejemplo. Una torreta dispara y le asigna
# 2 de daño a la bala y la bala cuando choca con el
# player le hace 2 de daño.
var damage = 1

# Previene que se haga la animacion de dead mas
# de una vez.
var is_mark_to_dead = false

func _ready():
	$Sprite.playing = true

func _physics_process(delta):
	if trajectory == Trajectory.LINEAL:
		move_and_slide(direction * 250)

func dead():
	if not is_mark_to_dead:
		is_mark_to_dead = true
		$Anim.play("dead")

func _on_TimeToDead_timeout():
	if not is_mark_to_dead:
		dead()

func _on_Anim_animation_finished(anim_name):
	if anim_name == "dead":
		queue_free()
