extends Node2D

func _ready():
	var player = PlayerManager.init_player(0)
	player.global_position = Vector2(10, 10)
	add_child(player)
	player.enable_player()
	
	$Camera.following = player
	
	var player2 = PlayerManager.init_player(1)
	player2.global_position = Vector2(100, 100)
	add_child(player2)