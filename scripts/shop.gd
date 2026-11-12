extends Control

signal shop_closed

@onready var coin_label: Label = $Panel/VBoxContainer/Header/CoinsContainer/CoinLabel
@onready var scroll_container: ScrollContainer = $Panel/VBoxContainer/ScrollContainer
@onready var items_container: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/ItemsContainer
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton
@onready var panel: Panel = $Panel

var game_node: Node = null

const SKINS := [
	{"id": "default", "name": "Classic Yellow", "price": 0, "texture": "res://assets/textures/bird.png"},
	{"id": "blue", "name": "Blue Jay", "price": 20, "texture": "res://assets/textures/skins/bluebird-midflap.png"},
	{"id": "red", "name": "Red Robin", "price": 50, "texture": "res://assets/textures/skins/redbird-midflap.png"},
]

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	_apply_retro_button_style(close_button, 18)
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	# Style Shop Panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.96, 0.88, 0.68)
	panel_style.border_color = Color(0.3, 0.18, 0.08)
	panel_style.set_border_width_all(4)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", panel_style)

func _apply_retro_button_style(btn: Button, font_size: int = 18) -> void:
	var font = load("res://assets/fonts/flappyfont.TTF")
	if font:
		btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", font_size)

	var normal_box = StyleBoxFlat.new()
	normal_box.bg_color = Color(0.95, 0.62, 0.1)
	normal_box.border_color = Color(0.2, 0.1, 0.0)
	normal_box.set_border_width_all(3)
	normal_box.corner_radius_top_left = 4
	normal_box.corner_radius_top_right = 4
	normal_box.corner_radius_bottom_left = 4
	normal_box.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", normal_box)

	var hover_box = normal_box.duplicate()
	hover_box.bg_color = Color(1.0, 0.72, 0.2)
	btn.add_theme_stylebox_override("hover", hover_box)

	var pressed_box = normal_box.duplicate()
	pressed_box.bg_color = Color(0.8, 0.5, 0.05)
	btn.add_theme_stylebox_override("pressed", pressed_box)

	var disabled_box = normal_box.duplicate()
	disabled_box.bg_color = Color(0.5, 0.5, 0.5)
	disabled_box.border_color = Color(0.3, 0.3, 0.3)
	btn.add_theme_stylebox_override("disabled", disabled_box)

	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 0.8))
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))
	btn.add_theme_color_override("font_disabled_color", Color(0.7, 0.7, 0.7))

func init_shop(game: Node) -> void:
	game_node = game
	refresh_display()

func refresh_display() -> void:
	if game_node:
		coin_label.text = str(game_node.bank_coins)

	for child in items_container.get_children():
		child.queue_free()

	for skin in SKINS:
		var skin_id = skin["id"]
		var is_unlocked = skin_node_unlocked(skin_id)
		var is_equipped = (game_node and game_node.equipped_skin == skin_id)

		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 64)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 15)

		# Icon preview
		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(48, 48)
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		if skin_id == "default":
			var atlas = AtlasTexture.new()
			atlas.atlas = load(skin["texture"])
			atlas.region = Rect2(34, 0, 34, 24)
			tex_rect.texture = atlas
		else:
			tex_rect.texture = load(skin["texture"])

		row.add_child(tex_rect)

		# Name & Price
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var name_lbl = Label.new()
		name_lbl.text = skin["name"]
		var font = load("res://assets/fonts/flappyfont.TTF")
		if font:
			name_lbl.add_theme_font_override("font", font)
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", Color(0.15, 0.1, 0.05))
		info_vbox.add_child(name_lbl)

		var price_lbl = Label.new()
		if skin["price"] == 0:
			price_lbl.text = "Unlocked"
		else:
			price_lbl.text = "%d Coins" % skin["price"]
		if font:
			price_lbl.add_theme_font_override("font", font)
		price_lbl.add_theme_font_size_override("font_size", 14)
		price_lbl.add_theme_color_override("font_color", Color(0.8, 0.5, 0.1))
		info_vbox.add_child(price_lbl)

		row.add_child(info_vbox)

		# Action Button
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(110, 40)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_apply_retro_button_style(btn, 16)

		if is_equipped:
			btn.text = "EQUIPPED"
			btn.disabled = true
		elif is_unlocked:
			btn.text = "EQUIP"
			btn.pressed.connect(func():
				if game_node:
					game_node.equip_skin(skin_id)
				refresh_display()
			)
		else:
			btn.text = "BUY (%d)" % skin["price"]
			if game_node and game_node.bank_coins < skin["price"]:
				btn.disabled = true
			else:
				btn.pressed.connect(func():
					if game_node and game_node.buy_skin(skin_id, skin["price"]):
						refresh_display()
				)
		row.add_child(btn)

		items_container.add_child(row)

func skin_node_unlocked(skin_id: String) -> bool:
	if not game_node:
		return skin_id == "default"
	return skin_id in game_node.unlocked_skins

func _on_close_pressed() -> void:
	shop_closed.emit()
	queue_free()
