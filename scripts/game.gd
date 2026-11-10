extends Node2D
@onready var obstacle_spawner: Node2D = $ObstacleSpawner
@onready var ground: StaticBody2D = $Ground
@onready var hud: CanvasLayer = $HUD

var score := 0
var high_score := 0
var coins_this_run := 0
var bank_coins := 0

var save_file_path := "user://save_game.dat"

func _ready() -> void:
	add_to_group("game")
	load_save()
	hud.set_score(score)
	hud.set_bank_coins(bank_coins)

func _on_player_game_started() -> void:
	obstacle_spawner.start()
	hud.hide_start_message()

func _on_player_died() -> void:
	obstacle_spawner.stop()
	ground.animation_player.pause()
	get_tree().call_group("obstacles", "stop")

	bank_coins += coins_this_run

	if high_score < score:
		high_score = score

	save_save()

	await get_tree().create_timer(0.3).timeout
	hud.show_game_over_screen(score, high_score, coins_this_run, bank_coins)

func _on_player_scored() -> void:
	score += 1
	hud.set_score(score)

func add_coin() -> void:
	coins_this_run += 1
	hud.set_bank_coins(bank_coins + coins_this_run)

func save_save() -> void:
	var f = FileAccess.open(save_file_path, FileAccess.WRITE)
	f.store_var(high_score)
	f.store_var(bank_coins)
	f.close()

func load_save() -> void:
	if FileAccess.file_exists(save_file_path):
		var f = FileAccess.open(save_file_path, FileAccess.READ)
		var v1 = f.get_var()
		if v1 != null:
			high_score = v1
		var v2 = f.get_var()
		if v2 != null:
			bank_coins = v2
		f.close()
