extends Node2D

@onready var spawn_timer: Timer = $SpawnTimer

var obstacle_scene: PackedScene = preload("res://scenes/obstacle.tscn")
var coin_scene: PackedScene = preload("res://scenes/coin.tscn")
var chest_scene: PackedScene = preload("res://scenes/chest.tscn")

var max_y_pos := -210.0
var min_y_pos := 120.0

var collectible_spawn_chance := 0.30
var chest_ratio := 0.40

const BASE_WAIT_TIME := 1.5
var current_speed_scale := 1.0

func _on_spawn_timer_timeout() -> void:
	var obstacle = obstacle_scene.instantiate()
	add_child(obstacle)
	var obstacle_y = randf_range(max_y_pos, min_y_pos)
	obstacle.position.y = obstacle_y
	# Apply current speed scale to freshly spawned obstacle
	if current_speed_scale != 1.0:
		obstacle.set_speed_scale(current_speed_scale)

	if randf() < collectible_spawn_chance:
		var spawn_y = global_position.y + obstacle_y
		if randf() < chest_ratio:
			var chest = chest_scene.instantiate()
			get_parent().add_child(chest)
			chest.global_position = Vector2(global_position.x, spawn_y)
			if current_speed_scale != 1.0:
				chest.set_speed_scale(current_speed_scale)
		else:
			var coin = coin_scene.instantiate()
			get_parent().add_child(coin)
			coin.global_position = Vector2(global_position.x, spawn_y)
			if current_speed_scale != 1.0:
				coin.set_speed_scale(current_speed_scale)

func set_speed_scale(speed_scale: float) -> void:
	current_speed_scale = speed_scale
	spawn_timer.wait_time = BASE_WAIT_TIME / speed_scale

func start() -> void:
	spawn_timer.start()

func stop() -> void:
	spawn_timer.stop()
