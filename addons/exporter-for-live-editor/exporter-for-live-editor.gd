tool
extends EditorPlugin

const LiveEditorExporterUtilsPath = "res://addons/exporter-for-live-editor/utils/LiveEditorExporterUtils.gd"
const LiveEditorExporterUtils := preload(LiveEditorExporterUtilsPath)
var live_editor_exporter_utils = LiveEditorExporterUtils.new()
var file_dialog := preload("./ui/file_dialog.gd").new()
var container := preload("./ui/container.gd").new()
var config := preload("./utils/config.gd").new(self)

const SceneScriptsRepository := preload("./collection/SceneScriptsRepository.gd")
const SceneScript := SceneScriptsRepository.SceneScript


func _enter_tree() -> void:
	add_autoload_singleton("LiveEditorExporterUtils", LiveEditorExporterUtilsPath)

	connect("scene_changed", self, "_on_scene_changed")
	connect("main_screen_changed", self, "_on_screen_changed")
	config.load_settings()

	container.scene_path = config.scene_path
	container.file_browser_button.icon = config.get_icon("File")
	container.run_button.icon = config.get_icon("Play")
	container.remove_button.icon = config.get_icon("Close")
	container.pin_button.icon = config.get_icon("Pin")
	container.pin_button.pressed = config.was_manually_set

	container.connect("scene_path_changed", self, "_on_scene_path_changed")
	container.connect("file_browser_requested", file_dialog, "popup_centered_ratio")
	container.connect("run_button_pressed", self, "_on_run_button_pressed")
	container.connect("pin_button_toggled", config, "set_was_manually_set")

	add_control_to_container(CONTAINER_TOOLBAR, container)

	file_dialog.connect("file_selected", self, "_on_file_dialog_file_selected")
	get_editor_interface().get_base_control().add_child(file_dialog)


func _exit_tree() -> void:
	remove_control_from_container(CONTAINER_TOOLBAR, container)
	container.queue_free()
	file_dialog.queue_free()
	remove_autoload_singleton("LiveEditorExporterUtils")


func _on_file_dialog_file_selected(path: String) -> void:
	if path:
		container.scene_path = path
		config.scene_path = path
		config.was_manually_set = true
		container.pin_button.pressed = true
	else:
		container.scene_path = get_current_scene_path()
		config.was_manually_set = false
		container.pin_button.pressed = false


func get_current_scene_path() -> String:
	var current_scene: Node = get_editor_interface().get_edited_scene_root()
	if current_scene:
		return current_scene.filename
	return ""


func _on_scene_path_changed(new_text: String) -> void:
	if new_text == "":
		config.was_manually_set = false
		container.pin_button.pressed = false
		config.scene_path = ""


func _on_scene_changed(new_scene: Node):
	if config.was_manually_set:
		return
	container.scene_path = new_scene.filename
	config.scene_path = new_scene.filename


func _on_screen_changed(new_screen: String) -> void:
	if new_screen == "2D" or new_screen == "3D":
		container.show()
	else:
		pass
		#container.hide()


func _on_run_button_pressed() -> void:
	if not config.scene_path:
		return
	var packed_scene: PackedScene = load(config.scene_path)
	var scene = packed_scene.instance()
	scene.hide()
	add_child(scene)
	var collector: SceneScriptsRepository = live_editor_exporter_utils.collect_script(scene)
	for _repo in collector:
		var repo: SceneScript = collector.current()
		print(repo)
		for _nodePath in repo:
			var nodePath: NodePath = repo.current()
			print(nodePath)
	var file_name = config.scene_path.get_basename() + ".live-editor.tres"
	ResourceSaver.save(file_name, collector)
	remove_child(scene)
	scene.queue_free()
	#get_editor_interface().play_main_scene()
