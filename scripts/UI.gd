extends CanvasLayer
onready var hunger_bar := $HUD/HungerBar
onready var energy_bar := $HUD/EnergyBar
var player := null

func _ready():
    # If scene already has a kitten node, try to auto-find it
    if player == null and get_tree().get_root().has_node("Main/KittenInstance"):
        var inst = get_tree().get_root().get_node("Main/KittenInstance")
        # The instance is a PackedScene instance; find the CharacterBody2D child
        if inst.has_node("Kitten"):
            player = inst.get_node("Kitten")
    # Player can be set later via Main.gd if needed

func set_player(p):
    player = p
    if player:
        if not player.is_connected("hunger_changed", Callable(self, "_on_hunger_changed")):
            player.connect("hunger_changed", Callable(self, "_on_hunger_changed"))
        if not player.is_connected("energy_changed", Callable(self, "_on_energy_changed")):
            player.connect("energy_changed", Callable(self, "_on_energy_changed"))
        _on_hunger_changed(player.hunger / player.max_hunger)
        _on_energy_changed(player.energy / player.max_energy)

func _on_hunger_changed(pct: float) -> void:
    if hunger_bar:
        hunger_bar.value = pct * 100.0

func _on_energy_changed(pct: float) -> void:
    if energy_bar:
        energy_bar.value = pct * 100.0
