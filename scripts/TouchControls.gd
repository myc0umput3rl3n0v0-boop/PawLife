# scripts/TouchControls.gd
extends Control
signal joystick_moved(vec)
signal jump_pressed()
signal sprint_pressed(is_down)

@export var joystick_radius: float = 60.0
onready var joystick_base := $JoystickBase
onready var joystick_knob := $JoystickKnob
onready var btn_jump := $BtnJump
onready var btn_sprint := $BtnSprint

var active_touch_index: int = -1

func _ready():
    joystick_knob.visible = false

func _on_JoystickBase_gui_input(event):
    if event is InputEventScreenTouch or event is InputEventScreenDrag:
        if event is InputEventScreenTouch and event.pressed:
            active_touch_index = event.index
            joystick_knob.visible = true
            _update_knob(event.position)
        elif event is InputEventScreenDrag and event.index == active_touch_index:
            _update_knob(event.position)
        elif event is InputEventScreenTouch and not event.pressed and event.index == active_touch_index:
            active_touch_index = -1
            joystick_knob.visible = false
            emit_signal("joystick_moved", Vector2.ZERO)

func _update_knob(global_pos: Vector2) -> void:
    var base_center = joystick_base.rect_global_position + joystick_base.rect_size * 0.5
    var dir = global_pos - base_center
    var len = dir.length()
    if len > joystick_radius:
        dir = dir.normalized() * joystick_radius
    joystick_knob.rect_global_position = base_center + dir - joystick_knob.rect_size * 0.5
    var norm = Vector2.ZERO
    if joystick_radius > 0:
        norm = dir / joystick_radius
    emit_signal("joystick_moved", norm)

func _on_BtnJump_pressed():
    emit_signal("jump_pressed")

func _on_BtnSprint_toggled(button_pressed: bool):
    emit_signal("sprint_pressed", button_pressed)
