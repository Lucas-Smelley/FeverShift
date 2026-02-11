extends Control

class_name ChoiceMenu

var choices: Array[String] = []
var labels: Array[Label] = []

var selected := 0
var is_open := false

@onready var v_box_container: VBoxContainer = $Panel/VBoxContainer


func open_menu(new_choices: Array[String]) -> void:
	choices = new_choices.duplicate()
	selected = 0

	clear_labels()
	create_labels()

	is_open = true
	visible = true
	update_highlight()


func close_menu() -> void:
	is_open = false
	visible = false
	clear_labels()


func change_selected(dir: int) -> void:
	if not is_open or choices.is_empty():
		return

	selected += dir

	# Wrap navigation
	if selected < 0:
		selected = choices.size() - 1
	elif selected >= choices.size():
		selected = 0

	update_highlight()


func create_labels() -> void:
	for i in choices.size():
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 8)
		v_box_container.add_child(label)
		labels.append(label)


func update_highlight() -> void:
	for i in labels.size():
		labels[i].text = ("> " if i == selected else "  ") + choices[i]


func clear_labels() -> void:
	for label in labels:
		if is_instance_valid(label):
			label.queue_free()
	labels.clear()
	
	
func is_active() -> bool:
	return is_open

func nav_up() -> void:
	change_selected(-1)

func nav_down() -> void:
	change_selected(1)

func accept() -> void:
	emit_signal("choice_selected", selected, choices[selected])
	close_menu()
