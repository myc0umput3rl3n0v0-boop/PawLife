extends CharacterBody2D

signal hunger_changed(percent: float)
signal energy_changed(percent: float)

# Movement parameters
@export var walk_speed: float = 80.0
@export var run_speed: float = 140.0
@export var acceleration: float = 900.0
@export var deceleration: float = 900.0
@export var jump_velocity: float = 260.0
@export var gravity: float = 900.0

# Energy / Stamina
@export var max_energy: float = 100.0
var energy: float = max_energy
@export var energy_drain_sprint: float = 18.0
@export var energy_drain_jump: float = 12.0
@export var energy_recover_rate: float = 16.0

# Hunger
@export var max_hunger: float = 100.0
var hunger: float = max_hunger
@export var hunger_decrease_per_second: float = 2.0

# Internal
var move_input: Vector2 = Vector2.ZERO
var is_sprinting: bool = false
var jump_pressed_local: bool = false

# Sprite child (auto-find)
@onready var sprite_node: Sprite2D = $Sprite if has_node("Sprite") else null

func _ready() -> void:
	energy = max_energy
	hunger = max_hunger
	if sprite_node == null:
		push_warning("Sprite child not found on Kitten node; create a Sprite2D named 'Sprite' for visuals.")
	else:
		if sprite_node.texture == null:
			sprite_node.texture = make_placeholder_texture(Vector2i(64, 64), Color8(200,150,100), Color8(255,255,255))

	emit_signals()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		if velocity.y > 0.0:
			velocity.y = 0.0

	var target_speed: float = walk_speed
	if is_sprinting and energy > 5.0 and abs(move_input.x) > 0.1:
		target_speed = run_speed

	var hunger_factor: float = 1.0
	if hunger <= 20.0:
		hunger_factor = 0.8

	var energy_factor: float = 1.0
	if energy <= 10.0:
		energy_factor = min(energy_factor, 0.7)

	var final_speed: float = float(target_speed) * float(hunger_factor) * float(energy_factor)

	var desired_vx: float = move_input.x * final_speed
	if abs(desired_vx - velocity.x) < 1.0:
		velocity.x = desired_vx
	elif desired_vx > velocity.x:
		velocity.x = min(velocity.x + acceleration * delta, desired_vx)
	else:
		velocity.x = max(velocity.x - deceleration * delta, desired_vx)

	if jump_pressed_local:
		if is_on_floor() and energy >= energy_drain_jump * 0.5:
			velocity.y = -jump_velocity
			energy -= energy_drain_jump
		jump_pressed_local = false

	if is_sprinting and abs(move_input.x) > 0.1:
		energy -= energy_drain_sprint * delta
	else:
		energy += energy_recover_rate * delta * (1.0 if is_on_floor() else 0.6)

	hunger -= hunger_decrease_per_second * delta
	clamp_state()

	move_and_slide()
	emit_signals()

func clamp_state() -> void:
	energy = clamp(energy, 0.0, max_energy)
	hunger = clamp(hunger, 0.0, max_hunger)

func emit_signals() -> void:
	emit_signal("energy_changed", clamp(energy / max_energy, 0.0, 1.0))
	emit_signal("hunger_changed", clamp(hunger / max_hunger, 0.0, 1.0))

func set_move_input(v: Vector2) -> void:
	move_input = v

func set_sprint(on: bool) -> void:
	is_sprinting = on

func press_jump() -> void:
	jump_pressed_local = true

func eat(amount: float) -> void:
	hunger = clamp(hunger + amount, 0.0, max_hunger)
	emit_signals()

func get_save_state() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y],
		"energy": energy,
		"hunger": hunger
	}

func load_save_state(state: Dictionary) -> void:
	if state.has("position"):
		var pos = state["position"]
		if pos is Array and pos.size() >= 2:
			global_position = Vector2(float(pos[0]), float(pos[1]))
	if state.has("energy"):
		energy = float(state["energy"])
	if state.has("hunger"):
		hunger = float(state["hunger"])
	emit_signals()

func make_placeholder_texture(size: Vector2i, color: Color, accent: Color) -> ImageTexture:
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var cx = size.x / 2.0
	var cy = size.y / 2.0
	var radius = min(size.x, size.y) * 0.4
	for y in range(size.y):
		for x in range(size.x):
			var dx = x - cx
			var dy = y - cy
			var d = sqrt(dx*dx + dy*dy)
			if d <= radius:
				img.set_pixel(x, y, accent)
			else:
				img.set_pixel(x, y, Color(0,0,0,0))
	var tex := ImageTexture.create_from_image(img)
	return tex
