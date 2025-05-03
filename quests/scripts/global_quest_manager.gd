## QUEST MANAGER - GLOBAL SCRIPT
extends Node

signal quest_updated(q)

const QUEST_DATA_LOCATION : String = "res://quests/"

var quests : Array[Quest]
var current_quests : Array = []

func _ready() -> void:
	gather_quest_data()
	pass

func gather_quest_data() -> void:
	var quest_files : PackedStringArray = DirAccess.get_files_at(QUEST_DATA_LOCATION)
	quests.clear()
	for q in quest_files:
		var file_name = q.trim_suffix(".remap")  # إزالة .remap إن وُجد
		var quest = load(QUEST_DATA_LOCATION + "/" + file_name) as Quest
		quests.append(quest)

func update_quest(_title: String, _completed_step: String = "", _is_complete: bool = false) -> void:
	var quest_index : int = get_quest_index_by_title(_title)
	if quest_index == -1:
		var new_quest : Dictionary = {
			"title": _title,
			"is_complete": _is_complete,
			"completed_steps": []
		}
		current_quests.append(new_quest)
		quest_updated.emit(new_quest)
		PlayerHud.queue_notification("بدأت المهمة", _title)
	else:
		var q = current_quests[quest_index]
		if _completed_step != "" and q.completed_steps.has(_completed_step) == false:
			q.completed_steps.append(_completed_step.to_lower())
		q.is_complete = _is_complete
		quest_updated.emit(q)
		if q.is_complete:
			PlayerHud.queue_notification("اكتملت المهمة!", _title)
			disperse_quest_rewards(find_quest_by_title(_title))
		else:
			PlayerHud.queue_notification("تحديث المهمة", _title + ": " + _completed_step)
	pass

func disperse_quest_rewards(_q: Quest) -> void:
	var _message : String = str(_q.reward_xp) + "نقاط المستوى"
	PlayerManager.reward_xp(_q.reward_xp)
	for i in _q.reward_items:
		PlayerManager.INVENTORY_DATA.add_item(i.item, i.quantity)
		_message += ", " + i.item.name + " x" + str(i.quantity)
	PlayerHud.queue_notification("المكافآت التي قد تم استلامها!", _message)
	pass

func find_quest(_quest: Quest) -> Dictionary:
	for q in current_quests:
		if q.title.to_lower() == _quest.title.to_lower():
			return q
	return {"title": "not found", "is_complete": false, "completed_steps": ['']}

func find_quest_by_title(_title: String) -> Quest:
	for q in quests:
		if q.title.to_lower() == _title.to_lower():
			return q
	return null

func get_quest_index_by_title(_title: String) -> int:
	for i in current_quests.size():
		if current_quests[i].title.to_lower() == _title.to_lower():
			return i
	return -1

func sort_quests() -> void:
	var active_quests : Array = []
	var completed_quests : Array = []
	for q in current_quests:
		if q.is_complete:
			completed_quests.append(q)
		else:
			active_quests.append(q)
	active_quests.sort_custom(sort_quests_ascending)
	completed_quests.sort_custom(sort_quests_ascending)
	current_quests = active_quests
	current_quests.append_array(completed_quests)
	pass

func sort_quests_ascending(a, b):
	if a.title < b.title:
		return true
	return false
