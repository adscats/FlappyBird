extends Node2D
@onready var obstacle_spawner: Node2D = $ObstacleSpawner
@onready var ground: StaticBody2D = $Ground
@onready var hud: CanvasLayer = $HUD
@onready var player: RigidBody2D = $Player

var score := 0
var high_score := 0
var coins_this_run := 0
var bank_coins := 0

var unlocked_skins: Array = ["default"]
var equipped_skin: String = "default"

var save_file_path := "user://save_game.dat"

# Slow power-up state
var _slow_active := false
var _slow_timer: SceneTreeTimer = null
const SLOW_DURATION := 5.0
const SLOW_SCALE := 0.5

func _ready() -> void:
	add_to_group("game")
	load_save()
	hud.set_score(score)
	hud.set_bank_coins(bank_coins)
	player.apply_skin(equipped_skin)
	hud.shop_pressed.connect(open_shop)

func _on_player_game_started() -> void:
	obstacle_spawner.start()
	hud.hide_start_message()

func _on_player_died() -> void:
	obstacle_spawner.stop()
	ground.animation_player.pause()
	get_tree().call_group("obstacles", "stop")

	# Cancel slow power-up if active so we don't restore it after game over
	_slow_active = false

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

# ── Chest reward handlers ────────────────────────────────────────────────────

func add_chest_coins(amount: int) -> void:
	coins_this_run += amount
	hud.set_bank_coins(bank_coins + coins_this_run)
	hud.show_powerup_message("+%d COINS!" % amount, Color(1.0, 0.85, 0.1))

func add_bonus_score(amount: int) -> void:
	score += amount
	hud.set_score(score)
	hud.show_powerup_message("+%d SCORE!" % amount, Color(0.5, 1.0, 0.4))

func apply_slow_powerup() -> void:
	if _slow_active:
		# Refresh timer without double-applying speed change
		if _slow_timer:
			_slow_timer = get_tree().create_timer(SLOW_DURATION)
			_slow_timer.timeout.connect(_end_slow, CONNECT_ONE_SHOT)
		hud.show_powerup_message("0.5× SPEED! (refreshed)", Color(0.4, 0.9, 1.0))
		return

	_slow_active = true
	_set_game_speed(SLOW_SCALE)
	hud.show_powerup_message("0.5× SPEED!", Color(0.4, 0.9, 1.0))
	hud.show_slow_indicator(true)

	_slow_timer = get_tree().create_timer(SLOW_DURATION)
	_slow_timer.timeout.connect(_end_slow, CONNECT_ONE_SHOT)

func _end_slow() -> void:
	if not _slow_active:
		return
	_slow_active = false
	_set_game_speed(1.0)
	hud.show_slow_indicator(false)
	hud.show_powerup_message("SPEED RESTORED", Color(1.0, 0.6, 0.3))

func _set_game_speed(speed_scale: float) -> void:
	# Scale every obstacle (pipes + coins + chests) in the obstacles group
	for obj in get_tree().get_nodes_in_group("obstacles"):
		if obj.has_method("set_speed_scale"):
			obj.set_speed_scale(speed_scale)
	# Scale the spawner timer so pipe spacing stays consistent
	obstacle_spawner.set_speed_scale(speed_scale)
	# Scale the ground scroll speed
	if ground.has_method("set_speed_scale"):
		ground.set_speed_scale(speed_scale)

# ── Shop Methods ─────────────────────────────────────────────────────────────

func buy_skin(skin_id: String, price: int) -> bool:
	if bank_coins >= price and not (skin_id in unlocked_skins):
		bank_coins -= price
		unlocked_skins.append(skin_id)
		equipped_skin = skin_id
		save_save()
		hud.set_bank_coins(bank_coins)
		player.apply_skin(equipped_skin)
		return true
	return false

func equip_skin(skin_id: String) -> void:
	if skin_id in unlocked_skins:
		equipped_skin = skin_id
		save_save()
		player.apply_skin(equipped_skin)

func open_shop() -> void:
	var shop_scene = preload("res://scenes/shop.tscn")
	var shop = shop_scene.instantiate()
	hud.add_child(shop)
	shop.init_shop(self)

# ── Save / Load ──────────────────────────────────────────────────────────────

func save_save() -> void:
	var f = FileAccess.open(save_file_path, FileAccess.WRITE)
	f.store_var(high_score)
	f.store_var(bank_coins)
	f.store_var(unlocked_skins)
	f.store_var(equipped_skin)
	f.close()

func load_save() -> void:
	if FileAccess.file_exists(save_file_path):
		var f = FileAccess.open(save_file_path, FileAccess.READ)
		if f:
			var v1 = f.get_var()
			if v1 != null:
				high_score = v1
			if f.get_position() < f.get_length():
				var v2 = f.get_var()
				if v2 != null:
					bank_coins = v2
			if f.get_position() < f.get_length():
				var v3 = f.get_var()
				if v3 != null and v3 is Array:
					unlocked_skins = v3
			if f.get_position() < f.get_length():
				var v4 = f.get_var()
				if v4 != null and v4 is String:
					equipped_skin = v4
			f.close()
