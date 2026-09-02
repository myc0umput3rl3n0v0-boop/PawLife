# scripts/Kitten.gd
extends CharacterBody2D

signal hunger_changed(percent)
signal energy_changed(percent)
signal state_changed(state_name)

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
@export var hunger_decrease_per_second: float = 2.0 # units per second

# Internal
var move_input: Vector2 = Vector2.ZERO
var is_sprinting: bool = false
var jump_pressed_local: bool = false

func _ready():
    energy = max_energy
    hunger = max_hunger
    emit_signals()

func _physics_process(delta: float) -> void:
    # Gravity
    if not is_on_floor():
        velocity.y += gravity * delta
    else:
        if velocity.y > 0:
            velocity.y = 0.0

    # Determine target speed
    var target_speed = walk_speed
    if is_sprinting and energy > 5.0 and abs(move_input.x) > 0.1:
        target_speed = run_speed

    # Hunger and energy penalties
    var hunger_factor := 1.0
    if hunger <= 20.0:
        hunger_factor = 0.8
    var energy_factor := 1.0
    if energy <= 10.0:
        energy_factor = min(energy_factor, 0.7)
    var final_speed := target_speed * hunger_factor * energy_factor

    # Smooth horizontal movement
    var desired_vx = move_input.x * final_speed
    if abs(desired_vx - velocity.x) < 1.0:
        velocity.x = desired_vx
    elif desired_vx > velocity.x:
        velocity.x = min(velocity.x + acceleration * delta, desired_vx)
    else:
        velocity.x = max(velocity.x - deceleration * delta, desired_vx)

    # Jump
    if jump_pressed_local:
        if is_on_floor() and energy >= energy_drain_jump * 0.5:
            velocity.y = -jump_velocity
            energy -= energy_drain_jump
        jump_pressed_local = false

    # Sprint energy drain or recovery
    if is_sprinting and abs(move_input.x) > 0.1:
        energy -= energy_drain_sprint * delta
    else:
        energy += energy_recover_rate * delta * (1.0 if is_on_floor() else 0.6)

    # Hunger drains over time
    hunger -= hunger_decrease_per_second * delta
    clamp_state()

    # Apply movement
    velocity = move_and_slide()

    emit_signals()

func clamp_state():
    energy = clamp(energy, 0.0, max_energy)
    hunger = clamp(hunger, 0.0, max_hunger)

func emit_signals():
    emit_signal("energy_changed", energy / max_energy)
    emit_signal("hunger_changed", hunger / max_hunger)

# External control methods (called from TouchControls or Main)
func set_move_input(v: Vector2) -> void:
    move_input = v

func set_sprint(on: bool) -> void:
    is_sprinting = on

func press_jump() -> void:
    jump_pressed_local = true

# Interaction
func eat(amount: float) -> void:
    hunger = clamp(hunger + amount, 0.0, max_hunger)
    emit_signals()

# Save/load helpers
func get_save_state() -> Dictionary:
    return {
        "position": global_position,
        "energy": energy,
        "hunger": hunger
    }

func load_save_state(state: Dictionary) -> void:
    if state.has("position"):
        global_position = state["position"]
    if state.has("energy"):
        energy = float(state["energy"])
    if state.has("hunger"):
        hunger = float(state["hunger"])
    emit_signals()
