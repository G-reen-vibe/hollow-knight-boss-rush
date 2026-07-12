extends CanvasLayer
## HUD: player masks (top-left), soul meter, boss health bar (top-center),
## boss name + index, controls help (bottom-left), and victory / continue prompts.

@onready var masks_row: HBoxContainer = %MasksRow
@onready var soul_bar: ProgressBar = %SoulBar
@onready var boss_bar: ProgressBar = %BossBar
@onready var boss_name_label: Label = %BossName
@onready var boss_index_label: Label = %BossIndex
@onready var message_label: Label = %Message
@onready var controls_label: Label = %ControlsLabel

var mask_icons: Array[TextureRect] = []
var _controls_visible: bool = true


func _ready() -> void:
        Globals.player_health_changed.connect(_on_player_hp)
        Globals.player_soul_changed.connect(_on_player_soul)
        Globals.boss_health_changed.connect(_on_boss_hp)
        Globals.boss_index_changed.connect(_on_boss_index)
        Globals.boss_rush_completed.connect(_on_rush_won)
        # Hide boss bar until a boss spawns.
        boss_bar.visible = false
        boss_name_label.visible = false
        boss_index_label.visible = false
        message_label.visible = false
        # Set controls text.
        controls_label.text = "A/D or ←/→  Move    SPACE  Jump (×2)\nX  Attack (hold ↑/↓ for up/down)\nZ  Dash    C  Spell (costs Soul)\nF  Focus/Heal (costs Soul)\nH  Toggle this help    R  Restart    ESC  Quit"
        # Auto-hide controls after 8 seconds.
        get_tree().create_timer(8.0).timeout.connect(func():
                if _controls_visible:
                        _fade_controls_out()
        )
        # Build mask icons (5 masks).
        var mask_size: int = 32
        for i in Globals.PLAYER_MAX_HEALTH:
                var icon := _make_mask_icon(true, mask_size)
                masks_row.add_child(icon)
                mask_icons.append(icon)


func _unhandled_input(event: InputEvent) -> void:
        if event.is_action_pressed("toggle_help") or (event is InputEventKey and event.keycode == KEY_H and event.pressed):
                _controls_visible = not _controls_visible
                if _controls_visible:
                        controls_label.modulate.a = 1.0
                else:
                        controls_label.modulate.a = 0.0


func _fade_controls_out() -> void:
        _controls_visible = false
        var tw := create_tween()
        tw.tween_property(controls_label, "modulate:a", 0.0, 1.5)


func _make_mask_icon(filled: bool, size: int = 32) -> TextureRect:
        var rect := TextureRect.new()
        rect.custom_minimum_size = Vector2(size, size)
        rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        # Draw a circle mask via a custom drawn control.
        var drawer := _MaskIcon.new()
        drawer.filled = filled
        drawer.size_px = size
        rect.add_child(drawer)
        drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
        return rect


func _on_player_hp(current: int, maximum: int) -> void:
        for i in mask_icons.size():
                var drawer := mask_icons[i].get_child(0) as _MaskIcon
                drawer.filled = i < current
                drawer.queue_redraw()


func _on_player_soul(current: float, maximum: float) -> void:
        soul_bar.max_value = maximum
        soul_bar.value = current


func _on_boss_hp(current: int, maximum: int) -> void:
        boss_bar.visible = true
        boss_name_label.visible = true
        boss_index_label.visible = true
        boss_bar.max_value = maximum
        boss_bar.value = current


func _on_boss_index(index: int, total: int, boss_name: String) -> void:
        boss_name_label.text = boss_name
        boss_index_label.text = "Boss %d of %d" % [index + 1, total]


func _on_rush_won() -> void:
        message_label.text = "VICTORY!\nAll bosses defeated."
        message_label.add_theme_color_override(&"font_color", Color(1, 0.85, 0.4))
        message_label.visible = true
        boss_bar.visible = false
        boss_name_label.visible = false
        boss_index_label.visible = false


class _MaskIcon extends Control:
        var filled: bool = true
        var size_px: int = 32
        func _init() -> void:
                mouse_filter = Control.MOUSE_FILTER_IGNORE
        func _draw() -> void:
                var r := float(size_px) * 0.35
                var center := Vector2(float(size_px) * 0.5, float(size_px) * 0.5)
                if filled:
                        draw_circle(center, r + 1, Color(0, 0, 0, 0.4))
                        draw_circle(center, r, Color(0.95, 0.95, 0.95))
                        draw_arc(center, r, 0, TAU, 32, Color(0.2, 0.2, 0.25), 2.0)
                else:
                        draw_circle(center, r, Color(0.2, 0.2, 0.25, 0.7))
                        draw_arc(center, r, 0, TAU, 32, Color(0.4, 0.4, 0.45), 1.5)
