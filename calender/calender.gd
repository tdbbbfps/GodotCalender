@tool
extends Control
class_name Calender

@export var month_label : Label
@export var year_button : Button
@export var days_grid : GridContainer
var months : Array[String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
var current_month : int = 0:
	set(value):
		if (value == 0): 
			current_year -= 1
			current_month = 12
		elif (value == 13): 
			current_year += 1
			current_month = 1
		else:
			current_month = value
		generate_calender()
		month_label.text = months[current_month - 1]
var current_year : int = 0:
	set(value):
		current_year = value
		year_button.text = str(current_year)
signal _on_date_selected(date : Dictionary)

func _ready() -> void:
	# Initialize current year and month
	current_year = get_date_param("year")
	current_month = get_date_param("month")
	generate_calender()
	generate_year_selector()

# year, month, day, weekday, hour, minute, second, and dst (Daylight Savings Time)
func get_date_param(param : String):
	return Time.get_datetime_dict_from_system()[param]

func generate_calender():
	var column_counts : int = 0
	# Clear calender
	for child in days_grid.get_children():
		child.queue_free()

	# Add previous month days to fill the blanks in front of the first day.
	for i in get_previous_month_days(get_first_weekday()):
		column_counts += 1
		var blank = Button.new()
		blank.text = str(i)
		blank.custom_minimum_size = Vector2(32, 32)
		blank.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		blank.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		blank.disabled = true
		days_grid.add_child(blank)
	
	# Add current month days
	for i in range(1, get_days_in_month() + 1, 1):
		column_counts += 1
		var day_button = Button.new()
		day_button.text = str(i)
		day_button.custom_minimum_size = Vector2(32, 32)
		day_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		day_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		day_button.pressed.connect(date_selected.bind(int(day_button.text)))
		# Set focus if the day is current system day
		if (i == get_date_param("day") and is_current_month()):
			day_button.call_deferred("grab_focus")
		days_grid.add_child(day_button)
		

	# Check if there's any unfill columns in final row.
	if (column_counts % 7 == 0): return
	# Generates the dates needed to fill the current calendar grid's final row
	# from next month's first week.	
	for i in range(1, (7 - column_counts % 7) + 1, 1):
		var blank = Button.new()
		blank.text = str(i)
		blank.custom_minimum_size = Vector2(32, 32)
		blank.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		blank.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		blank.disabled = true
		days_grid.add_child(blank)

func date_selected(day : int):
	var selected_date = {"year" : current_year, "month" : current_month, "day" : day}
	_on_date_selected.emit(selected_date)

# Turn to previous month
func _on_prev_month_btn_pressed() -> void:
	current_month -= 1

# Turn to next month
func _on_next_month_btn_pressed() -> void:
	current_month += 1

# Get first the day of the first week of a month.
func get_first_weekday() -> int:
	var date = "%04d-%02d-01" % [current_year, current_month]
	return Time.get_datetime_dict_from_datetime_string(date, true)["weekday"]
	
var month_days = [31,28,31,30,31,30,31,31,30,31,30,31]
# Return days by current_month
func get_days_in_month() -> int:
	# Return 29 if February and is leap year
	if (current_month == 2 && is_leap_year(current_year)):
		return 29
	return month_days[current_month - 1]

# Check if is leap year
func is_leap_year(year : int) -> bool:
	return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)

# Check if system time is current year and month.
func is_current_month() -> bool:
	var now = Time.get_date_dict_from_system()
	return current_year == now["year"] && current_month == now["month"]

# Generates the dates needed to fill the current calendar grid's first row
# from previous month's final week.
func get_previous_month_days(days : int):
	var previous_month = current_month - 1 if current_month - 1 > 0 else 12
	var previous_month_days : Array
	for i in days:
		previous_month_days.append(month_days[previous_month - 1] - i)
	previous_month_days.reverse()
	return previous_month_days

# Generate year selector
@export_category("Year Selector")
@export var year_selector : Node
@export var scroll_container : ScrollContainer
@export var year_container : VBoxContainer
@export var max_year_gap : int = 50 # Control max and min year that year selector can generate.
var year_btn_ids : Dictionary
func generate_year_selector():
	for i in range(get_date_param("year") - 50, get_date_param("year") + 51 + 1, 1):
		var year_button = Button.new()
		year_btn_ids[str(i)] = year_button
		year_button.custom_minimum_size = Vector2(64, 16)
		year_button.text = str(i)
		year_button.button_down.connect(_on_year_selected.bind(i))
		year_container.add_child(year_button)
		
# Switch to selected year
func _on_year_selected(year : int):
	if (current_year == year): return
	current_year = year
	year_selector.hide()
	generate_calender()

# Set year selector's visibility
func _on_year_button_button_down() -> void:
	if (not year_selector.visible):
		year_selector.show()
		year_btn_ids[str(current_year)].grab_focus()
	else:
		year_selector.hide()
		year_btn_ids[str(current_year)].release_focus()
