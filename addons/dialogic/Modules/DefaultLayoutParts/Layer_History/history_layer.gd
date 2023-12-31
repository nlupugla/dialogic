@tool
extends DialogicLayoutLayer

## Example scene for viewing the History
## Implements most of the visual options from 1.x History mode

@export_group('Look')
@export_subgroup('Font')
@export var font_use_global_size : bool = true
@export var font_custom_size : int = 15
@export var font_use_global_fonts : bool = true
@export_file('*.ttf') var font_custom_normal : String = ""
@export_file('*.ttf') var font_custom_bold : String = ""
@export_file('*.ttf') var font_custom_italics : String = ""

@export_subgroup('Buttons')
@export var show_open_button: bool = true
@export var show_close_button: bool = true

@export_group('Settings')
@export_subgroup('Events')
@export var show_all_choices: bool = true
@export var show_join_and_leave: bool = true

@export_subgroup('Behaviour')
@export var scroll_to_bottom: bool = true
@export var show_name_colors: bool = true
@export var name_delimeter: String = ": "

var scroll_to_bottom_flag: bool = false

@export_group('Private')
@export var HistoryItem: PackedScene = null

var history_item_theme : Theme = null

@onready var show_history_button : Button = $ShowHistory
@onready var hide_history_button : Button = $HideHistory
@onready var history_box : ScrollContainer = %HistoryBox
@onready var history_log : VBoxContainer = %HistoryLog


func _ready() -> void:
	if Engine.is_editor_hint():
		return


func _apply_export_overrides() -> void:
	if DialogicUtil.autoload().has_subsystem('History'):
		show_history_button.visible = show_open_button and (DialogicUtil.autoload().get(&'History') as DialogicSubsystemHistory).simple_history_enabled
	else:
		self.visible = false

	history_item_theme = Theme.new()

	if font_use_global_size:
		history_item_theme.default_font_size = get_global_setting(&'font_size', font_custom_size)
	else:
		history_item_theme.default_font_size = font_custom_size

	if font_use_global_fonts and ResourceLoader.exists(get_global_setting(&'font', '') as String):
		history_item_theme.default_font = load(get_global_setting(&'font', '') as String) as Font
	elif ResourceLoader.exists(font_custom_normal):
		history_item_theme.default_font = load(font_custom_normal)

	if ResourceLoader.exists(font_custom_bold):
		history_item_theme.set_font(&'RichtTextLabel', &'bold_font', load(font_custom_bold) as Font)
	if ResourceLoader.exists(font_custom_italics):
		history_item_theme.set_font(&'RichtTextLabel', &'italics_font', load(font_custom_italics) as Font)



func _process(_delta : float) -> void:
	if Engine.is_editor_hint():
		return
	if scroll_to_bottom_flag and history_box.visible and history_log.get_child_count():
		await get_tree().process_frame
		history_box.ensure_control_visible(history_log.get_children()[-1] as Control)
		scroll_to_bottom_flag = false


func _on_show_history_pressed() -> void:
	DialogicUtil.autoload().paused = true
	show_history()


func show_history() -> void:
	for child : Node in history_log.get_children():
		child.queue_free()

	for info : Dictionary in (DialogicUtil.autoload().get(&'History') as DialogicSubsystemHistory).get_simple_history():
		var history_item : Node = HistoryItem.instantiate()
		history_item.set(&'theme', history_item_theme)
		match info.event_type:
			"Text":
				if info.has('character') and info['character']:
					if show_name_colors:
						history_item.call(&'load_info', info['text'], info['character']+name_delimeter, info['character_color'])
					else:
						history_item.call(&'load_info', info['text'], info['character']+name_delimeter)
				else:
					history_item.call(&'load_info', info['text'])
			"Character":
				if !show_join_and_leave:
					history_item.queue_free()
					continue
				history_item.call(&'load_info', '[i]'+info['text'])
			"Choice":
				var choices_text : String = ""
				if show_all_choices:
					for i : String in info['all_choices']:
						if i.ends_with('#disabled'):
							choices_text += "-  [i]("+i.trim_suffix('#disabled')+")[/i]\n"
						elif i == info['text']:
							choices_text += "-> [b]"+i+"[/b]\n"
						else:
							choices_text += "-> "+i+"\n"
				else:
					choices_text += "- [b]"+info['text']+"[/b]\n"
				history_item.call(&'load_info', choices_text)

		history_log.add_child(history_item)

	if scroll_to_bottom:
		scroll_to_bottom_flag = true

	show_history_button.hide()
	hide_history_button.visible = show_close_button
	history_box.show()


func _on_hide_history_pressed() -> void:
	DialogicUtil.autoload().paused = false
	history_box.hide()
	hide_history_button.hide()
	show_history_button.visible = show_open_button and (DialogicUtil.autoload().get(&'History') as DialogicSubsystemHistory).simple_history_enabled
