extends SceneTree
# =============================================================================
# Unity -> Godot scene converter
# =============================================================================
# Reads the Unity YAML of "SC Demo.unity" plus every prefab it instances and
# emits a native Godot 4 scene.
#
#   godot --headless --script tools/convert.gd -- --assets-only   (pass 1)
#   godot --headless --import                                   (in between)
#   godot --headless --script tools/convert.gd                   (pass 2)
#
# Pass 1 only copies textures and writes AtlasTexture resources, because the
# TileSet builder loads those textures and load() cannot open a raw .png until
# the editor has produced its imported .ctex.
#
# Coordinate convention
# ---------------------
# Unity's 2D world is Y-up, Godot's is Y-down, so world Y is negated on the way
# in (and rotations flip sign with it). Everything else - positions, collider
# offsets, sprite pivots - is a straight mirror, which keeps the converter's
# maths local and the resulting scene idiomatic: no flipped camera, no negative
# zoom, so text and asymmetric sprites render the right way up.
#
# TileMapLayer is the one place where the mirror is not a plain negation: its
# grid is Y-down, so Unity cell (x, y) becomes Godot cell (x, -y - 1).
#
# Sorting
# -------
# Unity sorts on (sortingLayer, sortingOrder); Godot has a single z_index. Every
# renderer is made absolute (z_as_relative = false) with
#   z_index = sortingLayer * SORT_STRIDE + sortingOrder
# which reproduces Unity's ordering exactly over the ranges this project uses.
# =============================================================================

const UNITY_PROJECT := "C:/Users/LUQMAN/Documents/tournamentgame/GAME_COMP_RPG-2026-10-09_22-39-09"
const UNITY_ASSETS := UNITY_PROJECT + "/Assets"
const SCENE_REL := "Cainos/Pixel Art Top Down - Basic/Scene/SC Demo.unity"
const OUT_SCENE := "res://scenes/main.tscn"
const SORT_STRIDE := 100
const SHADOW_SHADER_GUID := "6550f6ce69d62b841b4c4f6818d8e73c"
const SCRIPT_DIR := "res://scripts/"
const REFERENCE_SCREEN := Vector2(1280, 720)

## Unity collision layer index -> Godot physics bit.
const LAYER_TO_BIT := {0: 1, 5: 32, 6: 16, 20: 2, 21: 4, 22: 8}

const S_CAMERA_FOLLOW := "13d0e62721e731a47916713e45e4ef50"
const S_ALTAR := "7edd0f787bc46de479f0d96bba16e2a6"
const S_COLOR_ANIM := "09ca5a4575c17ac4897d1f972b5f6b51"
const S_STAIRS := "7c3513c9018a5a9489aa2ee86a9d20f0"
const S_CHEST := "b0ab32ea7a5f768409b031e3aed91d21"
const S_POINT_CLICK := "f8933db8ae9623f46b83aca51201ab40"
const S_POPUP := "a3637f1fd315a3b4d8a6c9a80d6b6282"
const S_LEGACY_MOVE := "abd146093740c5d43b5909c7913f3109"
const S_BUILTIN_UI := "0000000000000000e000000000000000"

const SCRIPT_MAP := {
	S_CAMERA_FOLLOW: "camera_follow.gd",
	S_ALTAR: "props_altar.gd",
	S_COLOR_ANIM: "sprite_color_animation.gd",
	S_STAIRS: "stairs_layer_trigger.gd",
	S_CHEST: "chest_interact.gd",
	S_POINT_CLICK: "point_and_click_controller.gd",
	S_POPUP: "welcome_popup.gd",
	S_LEGACY_MOVE: "",
}


# =============================================================================
# Output tree
# =============================================================================

class N:
	var name := "Node"
	var type := "Node2D"
	var props := {}                     # String -> String | Ref
	var children: Array = []
	var script_file := ""
	var npath := "."
	var parent_path := "."
	var parent: N = null
	var sort_layer := 0
	var sort_order := 0
	var has_sort := false


class Ref:
	var kind := "node"                   # node | ext | sub | tileset | nodelist
	var value: Variant = null


# =============================================================================
# State
# =============================================================================

var guid_paths := {}
var sprite_table := {}
var mat_tint := {}
var doc_cache := {}
var scene_docs := {}
var scene_nodes := {}                   # scene fileID -> N (for late wiring)
var stripped_map := {}                  # "prefabInstanceFileID:sourceFileID" -> N
var instance_src := {}                  # PrefabInstance fileID -> prefab guid
var ext_res := []
var sub_res := []
var name_counts := {}
var tileset_payloads := []
var pending_scripts := []               # [{doc, host, ctx}]
var variant_cache := {}
var report := []
var scene_root: N
var assets_only := false


func _init() -> void:
	assets_only = OS.get_cmdline_user_args().has("--assets-only")
	print("=== Unity -> Godot conversion%s ===" % (" (assets only)" if assets_only else ""))
	_scan_guids()
	_load_sprite_tables()
	_copy_textures()
	_write_atlas_textures()
	if assets_only:
		print("  assets staged; run --headless --import next")
		quit()
		return
	_load_material_tints()
	scene_docs = Uyaml.parse_file(UNITY_ASSETS + "/" + SCENE_REL)
	print("  scene objects: %d" % scene_docs.size())

	scene_root = N.new()
	scene_root.name = "Main"
	scene_root.type = "Node2D"
	scene_root.npath = "."
	var roots := 0
	for fid in _scene_roots():
		var d: Doc = scene_docs[fid]
		# A root may be a Transform, a RectTransform (a screen-space canvas) or a
		# PrefabInstance (SceneRoots lists those by their own file id).
		if d.class_id == 1001:
			_build_prefab(d, scene_root)
			roots += 1
		elif d.class_id == 4 or d.class_id == 224:
			_build_transform(int(fid), scene_docs, scene_root, {})
			roots += 1
	print("  scene roots: %d" % roots)
	_wire_up()
	_write_tilesets()
	_write_scene()
	_write_report()
	print("=== done: %d ext, %d sub, %d notes ===" % [ext_res.size(), sub_res.size(), report.size()])
	# Release the Unity document graph before exit; otherwise thousands of
	# RefCounted Doc objects are reported as leaks at shutdown.
	_release()
	quit()


## Unity records the true scene roots in a SceneRoots object; falling back to
## "parent is zero" would miss prefab instances placed at the root.
func _scene_roots() -> Array:
	var out := []
	for fid in scene_docs.keys():
		var d: Doc = scene_docs[fid]
		if d.class_id != 1660057539:
			continue
		for r in ((d.body as Dictionary).get("m_Roots", []) as Array):
			out.append(_fid(r))
		return out
	for fid in scene_docs.keys():
		var d2: Doc = scene_docs[fid]
		if d2.class_id != 4 and d2.class_id != 224:
			continue
		var f = (d2.body as Dictionary).get("m_Father")
		if f is Dictionary and int(f.get("fileID", -1)) == 0:
			out.append(int(fid))
	return out


# =============================================================================
# Unity YAML
# =============================================================================

class Doc:
	var class_id := 0
	var file_id := 0
	var stripped := false
	var src_guid := ""
	var src_fid := 0
	var prefab_instance := 0
	var body := {}


class Uyaml:
	## Unity writes a restricted YAML subset: block maps, block sequences whose
	## dashes sit at the key's own indent, and single-line flow maps. Small
	## enough to parse directly, with no external dependency.

	## Integers, decimals and exponent form (the exponent must be signed so that
	## a hex-ish GUID like 0000000000000000e000000000000000 is not read as 0e0).
	static var _num_re := RegEx.create_from_string(
		"^-?(\\d+(\\.\\d*)?|\\.\\d+)([eE][+-]\\d+)?$")

	static func parse_file(path: String) -> Dictionary:
		var out := {}
		if not FileAccess.file_exists(path):
			push_error("missing unity file: " + path)
			return out
		var raw := FileAccess.get_file_as_string(path).replace("\r\n", "\n").replace("\r", "\n").split("\n")
		var docs := []
		var cur: Doc = null
		var buf := PackedStringArray()
		var head := RegEx.create_from_string("^--- !u!(\\d+) &(-?\\d+)( stripped)?$")
		for line in raw:
			if head.search(line) != null:
				if cur != null:
					cur.body = _parse_body(buf)
					docs.append(cur)
				buf = PackedStringArray()
				var g := head.search(line)
				cur = Doc.new()
				cur.class_id = int(g.get_string(1))
				cur.file_id = int(g.get_string(2))
				cur.stripped = g.get_string(3) != ""
				continue
			if line.begins_with("%"):
				continue
			buf.append(line)
		if cur != null:
			cur.body = _parse_body(buf)
			docs.append(cur)
		if docs.is_empty():
			# A .meta file carries one implicit document with no "--- !u!nn"
			# header, so the whole file is a single object.
			var single := Doc.new()
			single.body = _parse_body(PackedStringArray(raw))
			docs.append(single)

		for d in docs:
			# Unity writes "<TypeName>:" on the line after the "--- !u!nn &id"
			# header and indents the real fields under it, so unwrap that layer.
			d.body = _unwrap(d.body)
			if d.stripped:
				var co: Dictionary = d.body.get("m_CorrespondingSourceObject", {})
				d.src_guid = str(co.get("guid", ""))
				d.src_fid = int(co.get("fileID", 0))
				d.prefab_instance = int((d.body.get("m_PrefabInstance", {}) as Dictionary).get("fileID", 0))
			out[d.file_id] = d
		return out

	static func _unwrap(body: Dictionary) -> Dictionary:
		if body.size() != 1:
			return body
		var key := str(body.keys()[0])
		var value = body[key]
		# The wrapper is the component type name ("GameObject", "MonoBehaviour",
		# "SpriteRenderer", ...): capitalised and never starting with "m_".
		# Serialised field names are lowercase or m_-prefixed, so a lone
		# capitalised key is the wrapper.
		if value is Dictionary and not key.is_empty() \
				and key[0] == key[0].to_upper() and not key.begins_with("m_"):
			return value
		return body

	static func _parse_body(buf: PackedStringArray) -> Dictionary:
		var lines := []
		for line in buf:
			var t := line.strip_edges()
			if t == "" or t == "..." or line.begins_with("#"):
				continue
			var indent := 0
			while indent < line.length() and line[indent] == " ":
				indent += 1
			lines.append({"i": indent, "t": line.substr(indent)})
		if lines.is_empty():
			return {}
		var res = _parse_block(lines, 0, lines[0]["i"])
		return res[0] if res[0] is Dictionary else {}

	static func _parse_block(lines: Array, i: int, indent: int) -> Array:
		if i >= lines.size():
			return [null, i]
		if lines[i]["t"].begins_with("- ") or lines[i]["t"] == "-":
			return _parse_seq(lines, i, indent)
		return _parse_map(lines, i, indent)

	static func _parse_seq(lines: Array, i: int, indent: int) -> Array:
		var arr := []
		while i < lines.size() and lines[i]["i"] == indent \
				and (lines[i]["t"].begins_with("- ") or lines[i]["t"] == "-"):
			var rest: String = lines[i]["t"].substr(1).strip_edges()
			if rest == "":
				i += 1
				if i < lines.size() and lines[i]["i"] > indent:
					var r = _parse_block(lines, i, lines[i]["i"])
					arr.append(r[0])
					i = r[1]
				else:
					arr.append(null)
			else:
				# A bare flow collection ("- {fileID: 1}") is a scalar, not a map.
				if rest.begins_with("{") or rest.begins_with("["):
					arr.append(_scalar(rest))
					i += 1
					continue
				# "- key: value" continues as a map indented two further in.
				lines[i] = {"i": indent + 2, "t": rest}
				var r = _parse_block(lines, i, indent + 2)
				arr.append(r[0])
				i = r[1]
		return [arr, i]

	static func _parse_map(lines: Array, i: int, indent: int) -> Array:
		var d := {}
		while i < lines.size() and lines[i]["i"] == indent and not lines[i]["t"].begins_with("- "):
			var line: String = lines[i]["t"]
			var ci := line.find(":")
			if ci < 0:
				i += 1
				continue
			var key := line.substr(0, ci).strip_edges()
			var val := line.substr(ci + 1).strip_edges()
			if val == "":
				i += 1
				# Unity writes block sequences at the key's own indent rather than
				# indenting them under the key, so a same-indent "- " item still
				# belongs to this key.
				var is_seq: bool = i < lines.size() and int(lines[i]["i"]) == indent \
					and (str(lines[i]["t"]).begins_with("- ") or str(lines[i]["t"]) == "-")
				if i < lines.size() and (int(lines[i]["i"]) > indent or is_seq):
					var r = _parse_block(lines, i, lines[i]["i"])
					d[key] = r[0]
					i = r[1]
				else:
					d[key] = null
			else:
				d[key] = _scalar(val)
				i += 1
		return [d, i]

	static func _scalar(s: String) -> Variant:
		s = s.strip_edges()
		if s == "":
			return null
		if s.begins_with("{"):
			var d := {}
			for part in _split_top(s.substr(1, s.length() - 2)):
				var ci := part.find(":")
				if ci >= 0:
					d[part.substr(0, ci).strip_edges()] = _scalar(part.substr(ci + 1))
			return d
		if s.begins_with("["):
			var a := []
			for p2 in _split_top(s.substr(1, s.length() - 2)):
				if p2.strip_edges() != "":
					a.append(_scalar(p2))
			return a
		if s.length() >= 2 and s.begins_with("\"") and s.ends_with("\""):
			return s.substr(1, s.length() - 2)
		if s == "Infinity":
			return INF
		if s == "-Infinity":
			return -INF
		# Unity's built-in resource GUID is "0000000000000000e000000000000000",
		# which float() happily reads as 0e0. Only treat a token as a number when
		# it really looks like one: an exponent must carry an explicit sign.
		# The leading-character guard keeps the regex off the common path, since
		# this runs once per scalar in a multi-megabyte scene file.
		if not _starts_numeric(s) or _num_re.search(s) == null:
			return s
		if s.contains(".") or s.contains("e") or s.contains("E"):
			return float(s)
		return int(s)


	static func _starts_numeric(s: String) -> bool:
		if s.is_empty():
			return false
		var c := s[0]
		return c == "-" or c == "." or (c >= "0" and c <= "9")

	static func _split_top(s: String) -> PackedStringArray:
		var out := PackedStringArray()
		var depth := 0
		var cur := ""
		for i in s.length():
			var c := s[i]
			if c == "{" or c == "[":
				depth += 1
			elif c == "}" or c == "]":
				depth -= 1
			if c == "," and depth == 0:
				out.append(cur)
				cur = ""
			else:
				cur += c
		if cur.strip_edges() != "":
			out.append(cur)
		return out


# =============================================================================
# Asset discovery
# =============================================================================

func _scan_guids() -> void:
	var metas := PackedStringArray()
	_walk(UNITY_ASSETS, metas)
	var re := RegEx.create_from_string("(?m)^guid: ([0-9a-f]+)$")
	var prefix := UNITY_PROJECT.replace("\\", "/") + "/"
	for m in metas:
		var g := re.search(FileAccess.get_file_as_string(m))
		if g == null:
			continue
		guid_paths[g.get_string(1)] = m.substr(0, m.length() - 5).replace("\\", "/").replace(prefix, "")
	print("  meta files: %d" % guid_paths.size())


func _walk(dir_path: String, out: PackedStringArray) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if n.begins_with("."):
			n = d.get_next()
			continue
		var full := dir_path + "/" + n
		if d.current_is_dir():
			_walk(full, out)
		elif n.ends_with(".meta"):
			out.append(full)
		n = d.get_next()
	d.list_dir_end()


func _load_objs(rel: String) -> Dictionary:
	var abs_path := UNITY_PROJECT + "/" + rel
	if doc_cache.has(abs_path):
		return doc_cache[abs_path]
	var o := Uyaml.parse_file(abs_path)
	doc_cache[abs_path] = o
	return o


static func png_size(path: String) -> Vector2i:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return Vector2i.ZERO
	var head := f.get_buffer(24)
	f.close()
	if head.size() < 24:
		return Vector2i.ZERO
	return Vector2i((head[16] << 24) | (head[17] << 16) | (head[18] << 8) | head[19],
			(head[20] << 24) | (head[21] << 16) | (head[22] << 8) | head[23])


static func sanitize(s: String) -> String:
	var out := ""
	for c in s:
		out += "_" if c in ['.', ':', '@', '/', '"', '%'] else c
	return out if out != "" else "Node"


## Ext/sub resource ids are parsed as identifiers in .tscn, so they cannot
## contain spaces (the textures are named "TX Props__TX Props Chest").
static func id_safe(s: String) -> String:
	var out := ""
	for c in s:
		out += "_" if c in [' ', '.', ':', '@', '/', '"', '%', '(', ')'] else c
	return out if out != "" else "res"


static func n(v: float) -> String:
	if absf(v - roundf(v)) < 0.0000005:
		return str(int(roundf(v)))
	return "%.6f" % v


## Godot's .text parser wants floats inside Vector2()/Color() constructors and
## rejects bare integers there, so whole numbers still get a decimal point.
static func nf(v: float) -> String:
	return "%.6f" % v


static func v2s(v: Vector2) -> String:
	return "Vector2(%s, %s)" % [nf(v.x), nf(v.y)]


static func cols(c: Color) -> String:
	return "Color(%s, %s, %s, %s)" % [nf(c.r), nf(c.g), nf(c.b), nf(c.a)]


static func _col(c: Variant) -> Color:
	if not (c is Dictionary):
		return Color(1, 1, 1, 1)
	return Color(float(c.get("r", 1)), float(c.get("g", 1)), float(c.get("b", 1)), float(c.get("a", 1)))


static func _v2(c: Variant) -> Vector2:
	if not (c is Dictionary):
		return Vector2.ZERO
	return Vector2(float(c.get("x", 0)), float(c.get("y", 0)))


static func _fid(c: Variant) -> int:
	return int((c as Dictionary).get("fileID", 0)) if c is Dictionary else 0


static func _truthy(v: Variant) -> bool:
	if v is bool:
		return v
	if v is int or v is float:
		return float(v) != 0.0
	return str(v) == "1" or str(v).to_lower() == "true"


static func _flip_y(v: Vector2) -> Vector2:
	return Vector2(v.x, -v.y)


static func _script_guid(md: Doc) -> String:
	var b: Dictionary = md.body
	return str(((b.get("m_Script", {}) as Dictionary)).get("guid", ""))


static func _builtin_ui_fid(md: Doc) -> int:
	return int(((md.body as Dictionary).get("m_Script", {}) as Dictionary).get("fileID", 0))


# =============================================================================
# Sprites
# =============================================================================

func _load_sprite_tables() -> void:
	for guid in guid_paths.keys():
		var rel: String = guid_paths[guid]
		if not rel.ends_with(".png"):
			continue
		var meta := UNITY_PROJECT + "/" + rel + ".meta"
		if not FileAccess.file_exists(meta):
			continue
		var objs := Uyaml.parse_file(meta)
		if objs.is_empty():
			continue
		var ti: Dictionary = (objs[objs.keys()[0]].body as Dictionary).get("TextureImporter", {})
		if ti.is_empty():
			continue
		var ppu := float(ti.get("spritePixelsToUnits", 100))
		var def_pivot: Dictionary = ti.get("spritePivot", {"x": 0.5, "y": 0.5})
		var tsize := png_size(UNITY_PROJECT + "/" + rel)
		var entries: Array = (ti.get("spriteSheet", {}) as Dictionary).get("sprites", [])
		if entries.is_empty():
			entries = [{
				"name": rel.get_file().get_basename(),
				"rect": {"x": 0, "y": 0, "width": tsize.x, "height": tsize.y},
				"pivot": def_pivot, "internalID": 21300000, "physicsShape": [],
			}]
		for e in entries:
			if not (e is Dictionary):
				continue
			var r: Dictionary = (e as Dictionary).get("rect", {})
			var w := float(r.get("width", 0))
			var h := float(r.get("height", 0))
			var pv: Dictionary = (e as Dictionary).get("pivot", def_pivot)
			sprite_table["%s:%s" % [guid, str((e as Dictionary).get("internalID", 21300000))]] = {
				"tex": rel,
				"tex_size": tsize,
				"name": str((e as Dictionary).get("name", "sprite")),
				# Unity's rect origin is bottom-left, PNG rows run top-down.
				"region": Rect2(float(r.get("x", 0)), tsize.y - float(r.get("y", 0)) - h, w, h),
				"pivot": Vector2(float(pv.get("x", 0.5)), float(pv.get("y", 0.5))),
				"world_size": Vector2(w / ppu, h / ppu),
				"px_size": Vector2i(int(w), int(h)),
				"ppu": ppu,
				"physics": (e as Dictionary).get("physicsShape", []),
			}
	print("  sprite slices: %d" % sprite_table.size())


func _copy_textures() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/textures"))
	var seen := {}
	for key in sprite_table.keys():
		var tex: String = sprite_table[key]["tex"]
		if seen.has(tex):
			continue
		seen[tex] = true
		var src := UNITY_PROJECT + "/" + tex
		var dst := ProjectSettings.globalize_path("res://assets/textures/" + tex.get_file())
		if FileAccess.file_exists(dst):
			continue
		# DirAccess.copy() opens its directory for writing, which on Windows then
		# makes the source unreadable; a byte copy is reliable.
		var bytes := FileAccess.get_file_as_bytes(src)
		if bytes.is_empty():
			report.append("could not read " + src)
			continue
		var out := FileAccess.open(dst, FileAccess.WRITE)
		out.store_buffer(bytes)
		out.close()
	print("  source textures: %d" % seen.size())


func _atlas_path(guid: String, file_id: String) -> String:
	var key := "%s:%s" % [guid, file_id]
	if not sprite_table.has(key):
		return ""
	var s: Dictionary = sprite_table[key]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/sprites"))
	var base := sanitize("%s__%s" % [(s["tex"] as String).get_file().get_basename(), s["name"]])
	var path := "res://assets/sprites/%s.tres" % base
	var k := 2
	while FileAccess.file_exists(path) and not _atlas_matches(path, s):
		path = "res://assets/sprites/%s_%d.tres" % [base, k]
		k += 1
	return path


static func _atlas_matches(path: String, s: Dictionary) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var txt: String = f.get_as_text()
	f.close()
	var r: Rect2 = s["region"]
	return txt.contains("region = Rect2(%s, %s, %s, %s)"
		% [n(r.position.x), n(r.position.y), n(r.size.x), n(r.size.y)])


func _write_atlas_textures() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/sprites"))
	var written := 0
	for key in sprite_table.keys():
		var parts: PackedStringArray = (key as String).split(":")
		var path := _atlas_path(parts[0], parts[1])
		if path == "" or FileAccess.file_exists(path):
			continue
		var s: Dictionary = sprite_table[key]
		var r: Rect2 = s["region"]
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(
			"[gd_resource type=\"AtlasTexture\" load_steps=2 format=3]\n\n"
			+ "[ext_resource type=\"Texture2D\" path=\"res://assets/textures/%s\" id=\"1_tex\"]\n\n"
			% (s["tex"] as String).get_file()
			+ "[resource]\natlas = ExtResource(\"1_tex\")\n"
			+ "region = Rect2(%s, %s, %s, %s)\n"
			% [n(r.position.x), n(r.position.y), n(r.size.x), n(r.size.y)]
			+ "margin = Rect2(0, 0, 0, 0)\nfilter_clip = false\n")
		f.close()
		written += 1
	print("  atlas resources written: %d" % written)


func _load_material_tints() -> void:
	for guid in guid_paths.keys():
		var rel: String = guid_paths[guid]
		if not rel.ends_with(".mat"):
			continue
		var objs := _load_objs(rel)
		if objs.is_empty():
			continue
		var b: Dictionary = objs[objs.keys()[0]].body
		if str(((b.get("m_Shader", {})) as Dictionary).get("guid", "")) != SHADOW_SHADER_GUID:
			continue
		# The shadow shader multiplies by _Color and then premultiplies. Under
		# premultiplied blending that arithmetic is identical to Godot's default
		# mix blending with the same colour in `modulate`, so no shader port is
		# needed - the tint travels on the node instead.
		var tint := Color(1, 1, 1, 1)
		for c in ((b.get("m_SavedProperties", {})) as Dictionary).get("m_Colors", []):
			if c is Dictionary and str((c as Dictionary).keys()[0]).ends_with("_Color"):
				tint = _col((c as Dictionary)[(c as Dictionary).keys()[0]])
		mat_tint[guid] = tint
	print("  shadow materials: %d" % mat_tint.size())


func _sprite_ref(c: Variant) -> Dictionary:
	if not (c is Dictionary):
		return {}
	var g := str(c.get("guid", ""))
	if g == "":
		return {}
	return sprite_table.get("%s:%s" % [g, str(c.get("fileID", 0))], {})


func _sprite_path(c: Variant) -> String:
	if not (c is Dictionary):
		return ""
	return _atlas_path(str(c.get("guid", "")), str(c.get("fileID", 0)))


# =============================================================================
# Scene graph construction
# =============================================================================

func _uniq(base: String, parent_path: String) -> String:
	var key := "%s|%s" % [parent_path, base]
	var c: int = name_counts.get(key, 0)
	name_counts[key] = c + 1
	return base if c == 0 else "%s_%d" % [base, c + 1]


func _attach(parent: N, child: N) -> N:
	child.parent = parent
	child.parent_path = parent.npath
	child.npath = parent.npath + "/" + child.name if parent != scene_root else child.name
	parent.children.append(child)
	return child


func _new(parent: N, name: String, type: String) -> N:
	var c := N.new()
	c.name = _uniq(sanitize(name), parent.npath)
	c.type = type
	return _attach(parent, c)


func _build_transform(tr_fid: int, objs: Dictionary, parent: N, ctx: Dictionary,
		forced_type := "") -> N:
	var tr: Doc = objs[tr_fid]
	var node := _build_go(_fid(tr.body.get("m_GameObject")), tr_fid, objs, parent, ctx, forced_type)
	if node == null:
		return null
	_apply_transform(node, tr.body)
	ctx[tr_fid] = node
	if objs == scene_docs:
		scene_nodes[tr_fid] = node
	for ch in ((tr.body as Dictionary).get("m_Children", [])):
		var cfid := _fid(ch)
		if not objs.has(cfid):
			continue
		var cd: Doc = objs[cfid]
		if cd.class_id == 1001:
			_build_prefab(cd, node)
		elif cd.class_id == 4 or cd.class_id == 224:
			# A stripped Transform in the scene is the root of a prefab
			# instance: the rest of its hierarchy lives in the prefab asset.
			if cd.stripped and cd.prefab_instance != 0 and objs.has(cd.prefab_instance):
				_build_prefab(objs[cd.prefab_instance], node)
			else:
				_build_transform(cfid, objs, node, ctx)
	return node


func _apply_transform(node: N, tr: Dictionary) -> void:
	# A screen-space canvas carries a degenerate transform (Unity parks the
	# overlay canvas at zero scale); a CanvasLayer has no such thing.
	if node.type == "CanvasLayer":
		return
	var p := _v2(tr.get("m_LocalPosition", {}))
	var s := _v2(tr.get("m_LocalScale", {}))
	# Unity is Y-up, Godot is Y-down.
	if p != Vector2.ZERO:
		node.props["position"] = _flip_y(p)
	if s != Vector2.ONE:
		node.props["scale"] = s
	var q = tr.get("m_LocalRotation")
	if q is Dictionary:
		_finalise_quat(node, q)


func _finalise_quat(node: N, q: Dictionary) -> void:
	var ang := 2.0 * atan2(float(q.get("z", 0)), float(q.get("w", 1)))
	if absf(ang) > 0.000001:
		# Mirroring Y reverses the sense of rotation.
		node.props["rotation"] = n(-ang)


func _build_go(go_id: int, tr_fid: int, objs: Dictionary, parent: N, ctx: Dictionary,
		forced_type := "") -> N:
	if go_id == 0 or not objs.has(go_id):
		return null
	var body: Dictionary = (objs[go_id] as Doc).body
	var comps: Array = body.get("m_Component", [])

	var by_class := {}
	var monos := []
	for c in comps:
		var cfid := _fid((c as Dictionary).get("component"))
		if not objs.has(cfid):
			continue
		var cd: Doc = objs[cfid]
		if cd.class_id == 114:
			monos.append(cd)
		else:
			by_class[cd.class_id] = cfid

	var is_canvas := by_class.has(223)
	var is_ui = is_canvas or by_class.has(224)

	var node := N.new()
	node.name = _uniq(sanitize(str(body.get("m_Name", "GameObject"))), parent.npath)
	if is_canvas:
		node.type = "CanvasLayer"
		node.props["layer"] = "100"
	elif is_ui:
		node.type = "Control"
	else:
		node.type = forced_type if forced_type != "" else _world_type(by_class, monos, objs)
		if by_class.has(212) and node.type == "Node2D":
			node.type = "Sprite2D"
	if not _truthy(body.get("m_IsActive", 1)):
		node.props["process_mode"] = "4"   # Node.ProcessMode.DISABLED
		if node.type in ["Sprite2D", "TileMapLayer"]:
			node.props["visible"] = "false"
	_attach(parent, node)

	ctx[go_id] = node
	if tr_fid != 0:
		ctx[tr_fid] = node
	if objs == scene_docs:
		scene_nodes[go_id] = node
	for c in comps:
		ctx[_fid((c as Dictionary).get("component"))] = node
		if objs == scene_docs:
			scene_nodes[_fid((c as Dictionary).get("component"))] = node

	if is_ui:
		if not is_canvas:
			_build_ui(node, body, by_class, objs, ctx)
	elif not is_canvas:
		_build_world(node, by_class, monos, objs, ctx)
	return node


func _world_type(by_class: Dictionary, monos: Array, objs: Dictionary) -> String:
	if _has_script(monos, S_CHEST) or _has_script(monos, S_STAIRS) or _has_script(monos, S_ALTAR):
		return "Area2D"
	if by_class.has(20):
		return "Camera2D"
	if by_class.has(50):
		if _has_script(monos, S_POINT_CLICK):
			return "CharacterBody2D"
		var bt := int(((objs[by_class[50]].body) as Dictionary).get("m_BodyType", 0))
		if bt == 2:
			return "StaticBody2D"
		if bt == 1:
			return "AnimatableBody2D"
		return "RigidBody2D"
	return "Node2D"


func _build_world(node: N, by_class: Dictionary, monos: Array, objs: Dictionary,
		ctx: Dictionary) -> void:
	# ---- rigidbody ---------------------------------------------------------
	if by_class.has(50) and node.type == "RigidBody2D":
		var rb: Dictionary = (objs[by_class[50]].body as Dictionary)
		node.props["mass"] = n(float(rb.get("m_Mass", 1)))
		node.props["gravity_scale"] = n(float(rb.get("m_GravityScale", 0)))
		# Unity gave these barrels and crates zero gravity and no forces, so they
		# never moved; freezing reproduces that without a body fighting itself.
		node.props["freeze"] = "true"
		node.props["freeze_mode"] = "1"

	# ---- colliders ---------------------------------------------------------
	# An Area2D cannot block movement, so a solid collider on one (the chest)
	# moves onto a StaticBody2D child while its trigger stays on the Area2D.
	for cid in by_class.keys():
		if not _is_collider(cid):
			continue
		var cd: Doc = objs[by_class[cid]]
		var is_trigger := _truthy(((cd.body) as Dictionary).get("m_IsTrigger", 0))
		var host := node
		if is_trigger and node.type != "Area2D":
			host = _sub(node, "Trigger", "Area2D")
		elif not is_trigger and node.type == "Area2D":
			host = _sub(node, "Solid", "StaticBody2D")
		var shape := _add_collider(host, cd)
		if shape:
			ctx[cd.file_id] = shape
			if objs == scene_docs:
				scene_nodes[cd.file_id] = shape

	# ---- renderer ----------------------------------------------------------
	if by_class.has(212):
		var target := node
		if node.type != "Sprite2D":
			target = _sub(node, "Sprite", "Sprite2D")
		_build_sprite_renderer(target, (objs[by_class[212]].body as Dictionary))
		ctx[by_class[212]] = target

	if by_class.has(20):
		_build_camera(node, (objs[by_class[20]].body as Dictionary))

	if by_class.has(1839735485):
		_build_tilemap(node, (objs[by_class[1839735485]].body as Dictionary),
				objs.get(by_class.get(483693784, 0)))

	for md in monos:
		if _script_guid(md) != S_BUILTIN_UI:
			pending_scripts.append({"doc": md, "host": node, "ctx": ctx, "scene": objs == scene_docs})


func _sub(parent: N, name: String, type: String) -> N:
	for c in parent.children:
		if c.type == type:
			return c
	return _new(parent, name, type)


static func _is_collider(class_id: int) -> bool:
	return class_id in [61, 58, 60, 68, 136, 19719996, 66]


static func _has_script(monos: Array, guid: String) -> bool:
	for md in monos:
		if _script_guid(md) == guid:
			return true
	return false


# -----------------------------------------------------------------------------
# SpriteRenderer
# -----------------------------------------------------------------------------

func _build_sprite_renderer(node: N, sr: Dictionary) -> void:
	node.type = "Sprite2D"
	node.props["centered"] = "true"
	node.sort_layer = int(sr.get("m_SortingLayer", 0))
	node.sort_order = int(sr.get("m_SortingOrder", 0))
	node.has_sort = true

	var tint := _col(sr.get("m_Color", {}))
	var mats: Array = sr.get("m_Materials", [])
	if mats.size() > 0:
		var mg := str(((mats[0] as Dictionary)).get("guid", ""))
		if mat_tint.has(mg):
			var mt: Color = mat_tint[mg]
			tint = Color(tint.r * mt.r, tint.g * mt.g, tint.b * mt.b, tint.a * mt.a)
	if tint != Color(1, 1, 1, 1):
		node.props["modulate"] = cols(tint)

	var sref: Variant = sr.get("m_Sprite")
	var spr := _sprite_ref(sref)
	if spr.is_empty():
		return
	_ref(node, "texture", "ext", _add_ext("Texture2D", _sprite_path(sref)))
	node.props["_sprite_key"] = "%s:%s" % [str((sref as Dictionary).get("guid", "")), str((sref as Dictionary).get("fileID", 0))]
	node.props["_native_px"] = spr["px_size"]

	# Godot has no pixels-per-unit: one texture pixel is one world unit unless
	# the node is scaled, so Unity's PPU becomes an inverse scale. `offset` is
	# applied before that scale, so it stays expressed in texture pixels.
	var target := Vector2.ZERO
	if int(sr.get("m_DrawMode", 0)) == 1:
		# Unity nine-slice. The only sliced sprite in the project is the player,
		# whose slice borders add up to more than the target height, so Unity
		# effectively scaled the whole sprite; a plain stretch reproduces that.
		target = _v2(sr.get("m_Size", {}))
		node.props["_sliced_size"] = target
	_sprite_metrics(node, spr, target)

	if _truthy(sr.get("m_FlipX", 0)):
		node.props["flip_h"] = "true"
	if _truthy(sr.get("m_FlipY", 0)):
		node.props["flip_v"] = "true"


## Sets `scale` (world units per texture pixel) and the pixel-space `offset`
## that places Unity's sprite pivot on the node origin.
func _sprite_metrics(node: N, spr: Dictionary, target_size := Vector2.ZERO) -> void:
	var px: Vector2i = spr["px_size"]
	var ppu: float = spr["ppu"]
	var pv: Vector2 = spr["pivot"]
	var s := Vector2(1.0 / ppu, 1.0 / ppu)
	if target_size != Vector2.ZERO:
		s = Vector2(target_size.x / float(maxi(px.x, 1)), target_size.y / float(maxi(px.y, 1)))
	node.props["offset"] = Vector2((0.5 - pv.x) * px.x, -(0.5 - pv.y) * px.y)
	node.props["scale"] = s


func _build_camera(node: N, cam: Dictionary) -> void:
	node.type = "Camera2D"
	var ortho := maxf(float(cam.get("orthographic size", 5)), 0.001)
	var z := REFERENCE_SCREEN.y / (2.0 * ortho)
	# Unity's orthographic size is the half-height; Godot's zoom is pixels per
	# world unit, and the vertical extent is viewport height / zoom.
	node.props["zoom"] = v2s(Vector2(z, z))


# -----------------------------------------------------------------------------
# Colliders
# -----------------------------------------------------------------------------

func _add_collider(parent: N, cd: Doc) -> N:
	var body: Dictionary = cd.body
	match cd.class_id:
		61:
			var cs := _new(parent, "Shape", "CollisionShape2D")
			cs.props["shape"] = _ref_of("sub", _add_sub("RectangleShape2D",
					["size = " + v2s(_v2(body.get("m_Size", {})))]))
			cs.props["position"] = v2s(_flip_y(_v2(body.get("m_Offset", {}))))
			return cs
		58:
			var cs2 := _new(parent, "Shape", "CollisionShape2D")
			cs2.props["shape"] = _ref_of("sub", _add_sub("CircleShape2D",
					["radius = " + n(float(body.get("m_Radius", 0.5)))]))
			cs2.props["position"] = v2s(_flip_y(_v2(body.get("m_Offset", {}))))
			return cs2
		68:
			var pts: Array = body.get("m_Points", [])
			if pts.size() < 2:
				return null
			var poly := _new(parent, "Shape", "CollisionPolygon2D")
			var flipped := []
			for i in range(pts.size() - 1, -1, -1):
				flipped.append(_flip_y(_v2(pts[i])))
			# Unity's EdgeCollider2D is a zero-width line, which Godot's Area2D
			# cannot overlap-test. Give a two-point edge a small thickness so it
			# behaves as the band the original relied on.
			if flipped.size() == 2:
				var a: Vector2 = flipped[0]
				var b: Vector2 = flipped[1]
				var dir := (b - a).normalized()
				var nrm := Vector2(-dir.y, dir.x) * 0.15
				flipped = [a + nrm, b + nrm, b - nrm, a - nrm]
			var arr := PackedStringArray()
			for p in flipped:
				arr.append_array([nf(p.x), nf(p.y)])
			# PackedVector2Array takes a flat component list, not Vector2()s.
			poly.props["polygon"] = "PackedVector2Array(%s)" % ", ".join(arr)
			return poly
	return null


# -----------------------------------------------------------------------------
# Screen-space UI
# -----------------------------------------------------------------------------

func _build_ui(node: N, body: Dictionary, by_class: Dictionary, objs: Dictionary,
		ctx: Dictionary) -> void:
	node.type = "Control"
	node.props.set("mouse_filter", "2")

	# The RectTransform of this GameObject carries the layout.
	for c in body.get("m_Component", []):
		var cfid := _fid((c as Dictionary).get("component"))
		var cd: Doc = objs.get(cfid)
		if cd == null:
			continue
		if cd.class_id == 224:
			_apply_rect(node, cd.body)
			ctx[cfid] = node

	for c in body.get("m_Component", []):
		var cd2: Doc = objs.get(_fid((c as Dictionary).get("component")))
		if cd2 == null:
			continue
		# uGUI components are identified by the fields they serialise rather
		# than by script guid: the project pulls UnityEngine.UI from the
		# package registry, so those guids differ from the built-in ones.
		if cd2.class_id == 28 or (cd2.class_id == 114 and (cd2.body as Dictionary).has("m_EffectColor")):
			_apply_outline(node, (cd2.body as Dictionary))
		elif cd2.class_id == 225:
			node.props["mouse_filter"] = "2"   # CanvasGroup: no raycast target
		elif cd2.class_id == 114:
			var ub: Dictionary = cd2.body
			if ub.has("m_FontData"):
				node.type = "Label"
				node.props["text"] = JSON.stringify(str(ub.get("m_Text", "")))
				node.props["horizontal_alignment"] = "1"
				node.props["vertical_alignment"] = "1"
				_apply_font(node, ub)
			elif ub.has("m_FillMethod"):
				node.type = "ColorRect"
				node.props["color"] = cols(_col(ub.get("m_Color", {})))
			elif SCRIPT_MAP.has(_script_guid(cd2)):
				pending_scripts.append({"doc": cd2, "host": node, "ctx": ctx,
					"scene": objs == scene_docs})


static func _apply_font(node: N, body: Dictionary) -> void:
	var fd: Dictionary = body.get("m_FontData", {})
	node.props["theme_override_font_sizes/font_size"] = str(int(fd.get("m_FontSize", 16)))
	node.props["theme_override_colors/font_color"] = cols(_col(body.get("m_Color", {})))


static func _apply_outline(node: N, body: Dictionary) -> void:
	if node.type != "Label":
		return
	# Unity's Outline is a symmetric 3px drop at (3, -3); 6px matches its weight.
	node.props["theme_override_constants/outline_size"] = "6"
	node.props["theme_override_colors/font_outline_color"] = cols(_col(body.get("m_EffectColor", {})))


## Unity RectTransform (Y-up, parent-relative) -> Godot Control anchors/offsets.
## The reference parent size is the 1280x720 the CanvasScaler was set to; a
## Control child of another Control reuses the size that parent resolved to.
static func _apply_rect(node: N, rt: Dictionary) -> void:
	var parent_size := REFERENCE_SCREEN
	if node.parent != null and node.parent.props.has("_rect_size"):
		parent_size = node.parent.props["_rect_size"]
	var a_min := _v2(rt.get("m_AnchorMin", {}))
	var a_max := _v2(rt.get("m_AnchorMax", {}))
	var size := parent_size * (a_max - a_min) + _v2(rt.get("m_SizeDelta", {}))
	var pivot_pos := (a_min + a_max) * 0.5 * parent_size + _v2(rt.get("m_AnchoredPosition", {}))
	var pivot := _v2(rt.get("m_Pivot", {"x": 0.5, "y": 0.5}))
	var rect_min := pivot_pos - pivot * size
	var rect_max := rect_min + size
	node.props["_rect_size"] = size

	# Godot measures anchors from the top-left; Unity's Y is up.
	var a_top := 1.0 - a_max.y
	var a_bottom := 1.0 - a_min.y

	node.props["anchor_left"] = n(a_min.x)
	node.props["anchor_right"] = n(a_max.x)
	node.props["anchor_top"] = n(a_top)
	node.props["anchor_bottom"] = n(a_bottom)
	node.props["offset_left"] = n(rect_min.x - a_min.x * parent_size.x)
	node.props["offset_right"] = n(rect_max.x - a_max.x * parent_size.x)
	node.props["offset_top"] = n((parent_size.y - rect_max.y) - a_top * parent_size.y)
	node.props["offset_bottom"] = n((parent_size.y - rect_min.y) - a_bottom * parent_size.y)
	node.props["grow_horizontal"] = "2"
	node.props["grow_vertical"] = "2"


# =============================================================================
# Script wiring (deferred: references can point at anything in the scene)
# =============================================================================

func _ref_of(kind: String, value: Variant) -> Ref:
	var r := Ref.new()
	r.kind = kind
	r.value = value
	return r


func _ref(host: N, prop: String, kind: String, value: Variant) -> void:
	if value == null:
		report.append("%s.%s left unresolved" % [host.name, prop])
		return
	host.props[prop] = _ref_of(kind, value)


func _wire_up() -> void:
	for entry in pending_scripts:
		_attach_script(entry["doc"], entry["host"], entry["ctx"], entry["scene"])
	_each(scene_root, "_post_wire")
	_wire_stairs_z()


func _post_wire(nd: N) -> void:
	if nd.script_file.ends_with("point_and_click_controller.gd"):
		_wire_player(nd)
	elif nd.script_file.ends_with("welcome_popup.gd"):
		nd.props["panel_path"] = _ref_of("node", nd)


func _attach_script(md: Doc, host: N, ctx: Dictionary, is_scene: bool) -> void:
	var body: Dictionary = md.body
	var guid := _script_guid(md)
	if not SCRIPT_MAP.has(guid):
		report.append("unhandled MonoBehaviour %s on '%s'" % [guid, host.name])
		return
	var fname: String = SCRIPT_MAP[guid]
	if fname == "":
		report.append("'%s': legacy movement script replaced by the port" % host.name)
		return
	host.script_file = SCRIPT_DIR + fname

	match guid:
		S_CAMERA_FOLLOW:
			_ref(host, "target_path", "node", _resolve(body.get("target", {}), ctx, is_scene))
			host.props["lerp_speed"] = n(float(body.get("lerpSpeed", 1.0)))
		S_ALTAR:
			_ref(host, "rune_paths", "nodelist", _resolve_list(body.get("runes", []), ctx, is_scene))
			host.props["lerp_speed"] = n(float(body.get("lerpSpeed", 1.0)))
		S_COLOR_ANIM:
			host.props["period"] = n(float(body.get("time", 1.0)))
			var g = body.get("gradient")
			if g is Dictionary and g.has("m_NumColorKeys"):
				_ref(host, "gradient", "sub", _gradient_id(g))
		S_STAIRS:
			host.props["direction"] = str(int(body.get("direction", 0)))
			host.props["_sort_upper"] = str(_sorting_index(body.get("sortingLayerUpper", "")))
			host.props["_sort_lower"] = str(_sorting_index(body.get("sortingLayerLower", "")))
		S_CHEST:
			for pair in [["closed_sprite", "closedSprite"], ["open_sprite", "openSprite"],
					["closed_shadow_sprite", "closedShadowSprite"], ["open_shadow_sprite", "openShadowSprite"]]:
				var p := _sprite_path(body.get(pair[1]))
				if p != "":
					_ref(host, pair[0], "ext", _add_ext("Texture2D", p))
			_ref(host, "sprite_path", "node", _resolve(body.get("spriteRenderer", {}), ctx, is_scene))
			_ref(host, "shadow_path", "node", _resolve(body.get("shadowRenderer", {}), ctx, is_scene))
			_ref(host, "popup_path", "node", _resolve(body.get("popup", {}), ctx, is_scene))
			# Key enums are written as plain ints in .tscn; Godot's Key values for
			# A-Z coincide with ASCII, which is what Unity's KeyCode uses too.
			host.props["interact_key"] = str(_keycode(int(body.get("interactKey", 101))))
			host.props["require_key_press"] = str(_truthy(body.get("requireKeyPress", 1))).to_lower()
			host.props["only_once"] = str(_truthy(body.get("onlyOnce", 1))).to_lower()
		S_POINT_CLICK:
			host.props["speed"] = n(float(body.get("speed", 3)))
			host.props["arrive_threshold"] = n(float(body.get("arriveThreshold", 0.15)))
			host.props["manual_input_cancels_click"] = str(_truthy(body.get("manualInputCancelsClick", 1))).to_lower()
			host.props["show_click_marker"] = str(_truthy(body.get("showClickMarker", 1))).to_lower()
			host.props["click_marker_color"] = cols(_col(body.get("clickMarkerColor", {})))
			host.props["marker_lifetime"] = n(float(body.get("markerLifetime", 0.6)))
			host.props["stuck_timeout"] = n(float(body.get("stuckTimeout", 1.1)))
		S_POPUP:
			host.props["message"] = JSON.stringify(str(body.get("message", "")))
			host.props["fade_in_duration"] = n(float(body.get("fadeInDuration", 0.3)))
			host.props["hold_duration"] = n(float(body.get("holdDuration", 2.5)))
			host.props["fade_out_duration"] = n(float(body.get("fadeOutDuration", 0.45)))
			host.props["pop_scale"] = str(_truthy(body.get("popScale", 1))).to_lower()
			host.props["scale_from"] = n(float(body.get("scaleFrom", 0.85)))


static func _keycode(unity_kc: int) -> int:
	return {101: 69, 97: 65, 100: 68, 87: 87, 83: 83, 32: 32}.get(unity_kc, 69)   # E


static func _layer_bit(layer_name: Variant) -> int:
	var parts := str(layer_name).split(" ")
	# Unity layers 20/21/22 are "Layer 1/2/3"; the map holds their Godot bits.
	return int(LAYER_TO_BIT.get(19 + int(parts[1]), 2)) if parts.size() > 1 else 2


static func _sorting_index(layer_name: Variant) -> int:
	var parts := str(layer_name).split(" ")
	return int(parts[1]) if parts.size() > 1 else 1


## Resolves a Unity object reference to the Godot node standing in for it.
func _resolve(c: Variant, ctx: Dictionary, is_scene := false) -> N:
	if not (c is Dictionary):
		return null
	var fid := int(c.get("fileID", 0))
	if fid == 0:
		return null
	if ctx.has(fid):
		return ctx[fid]
	var g := str(c.get("guid", ""))
	if g != "":
		# A reference into a prefab: find the instance built from that prefab.
		for inst in instance_src.keys():
			if instance_src[inst] == g and stripped_map.has("%d:%d" % [inst, fid]):
				return stripped_map["%d:%d" % [inst, fid]]
		return null
	# A stripped scene object points back at the instance it belongs to.
	if scene_docs.has(fid):
		var d: Doc = scene_docs[fid]
		var hit: N = stripped_map.get("%d:%d" % [d.prefab_instance, d.src_fid])
		return hit if hit else scene_nodes.get(fid)
	if scene_nodes.has(fid):
		return scene_nodes[fid]
	return null


func _resolve_list(items: Array, ctx: Dictionary, is_scene := false) -> Array:
	var out := []
	for it in items:
		var r := _resolve(it, ctx, is_scene)
		if r:
			out.append(r)
	return out


## Unity stores a Gradient as two independent ramps (colour and alpha) while
## Godot wants one combined ramp, so both are resampled onto the union of their
## key times. Godot also requires strictly increasing offsets.
func _gradient_id(g: Dictionary) -> String:
	var n_color := int(g.get("m_NumColorKeys", 0))
	var n_alpha := int(g.get("m_NumAlphaKeys", 0))
	var rgb_keys := []
	var a_keys := []
	for i in n_color:
		rgb_keys.append([float(g.get("ctime%d" % i, 0)) / 65535.0, _col(g.get("key%d" % i, {}))])
	for i in n_alpha:
		a_keys.append([float(g.get("atime%d" % i, 0)) / 65535.0,
			float(((g.get("key%d" % i, {}) as Dictionary)).get("a", 1.0))])
	if rgb_keys.is_empty():
		rgb_keys = [[0.0, Color(1, 1, 1, 1)], [1.0, Color(1, 1, 1, 1)]]
	if a_keys.is_empty():
		a_keys = [[0.0, 1.0], [1.0, 1.0]]

	var times := {}
	for k in rgb_keys:
		times[k[0]] = true
	for k in a_keys:
		times[k[0]] = true
	var offsets := PackedFloat32Array()
	for t in times.keys():
		offsets.append(t)
	offsets.sort()

	var colors := PackedColorArray()
	for t in offsets:
		var rgb := _sample_ramp(rgb_keys, t)
		var a := _sample_alpha(a_keys, t)
		colors.append(Color(rgb.r, rgb.g, rgb.b, a))
	return _add_sub("Gradient", [
		"offsets = PackedFloat32Array(%s)" % _join_floats(offsets),
		"colors = PackedColorArray(%s)" % _join_colors(colors)])


static func _sample_ramp(keys: Array, t: float) -> Color:
	if t <= float(keys[0][0]):
		return keys[0][1]
	for i in range(keys.size() - 1):
		var a = keys[i]
		var b = keys[i + 1]
		if t <= float(b[0]):
			var span := float(b[0]) - float(a[0])
			var k := 0.0 if span <= 0.0 else (t - float(a[0])) / span
			return (a[1] as Color).lerp(b[1], k)
	return keys[keys.size() - 1][1]


static func _sample_alpha(keys: Array, t: float) -> float:
	if t <= float(keys[0][0]):
		return float(keys[0][1])
	for i in range(keys.size() - 1):
		var a = keys[i]
		var b = keys[i + 1]
		if t <= float(b[0]):
			var span := float(b[0]) - float(a[0])
			var k := 0.0 if span <= 0.0 else (t - float(a[0])) / span
			return lerpf(float(a[1]), float(b[1]), k)
	return float(keys[keys.size() - 1][1])


static func _join_floats(a: PackedFloat32Array) -> String:
	var p := PackedStringArray()
	for v in a:
		p.append(nf(v))
	return ", ".join(p)


## Godot's .text format for PackedColorArray is a flat RGBA component list, not
## a list of Color() constructors.
static func _join_colors(a: PackedColorArray) -> String:
	var p := PackedStringArray()
	for v in a:
		p.append_array([nf(v.r), nf(v.g), nf(v.b), nf(v.a)])
	return ", ".join(p)


# -----------------------------------------------------------------------------
# Prefab instances
# -----------------------------------------------------------------------------

func _build_prefab(inst: Doc, parent: N) -> N:
	var src: Dictionary = (inst.body as Dictionary).get("m_SourcePrefab", {})
	var guid := str(src.get("guid", ""))
	var rel: String = guid_paths.get(guid, "")
	if rel == "":
		report.append("prefab missing: guid %s" % guid)
		return null
	var objs := _load_objs(rel)
	var root_tr := _find_root_transform(objs)
	if root_tr == 0:
		report.append("prefab %s has no root transform" % rel)
		return null

	var mod: Dictionary = (inst.body as Dictionary).get("m_Modification", {})
	# Components added by the scene (the chest's trigger and ChestInteract, the
	# player's PointAndClickController) decide the Godot node type, so they have
	# to be known before the prefab hierarchy is built.
	var root_go := _fid(((objs[root_tr].body) as Dictionary).get("m_GameObject"))
	var forced := ""
	for ac in mod.get("m_AddedComponents", []):
		if not (ac is Dictionary) or _fid((ac as Dictionary).get("targetCorrespondingSourceObject")) != root_go:
			continue
		var added := _fid((ac as Dictionary).get("addedObject"))
		if not scene_docs.has(added):
			continue
		var g := _script_guid(scene_docs[added])
		if g == S_CHEST:
			forced = "Area2D"
		elif g == S_POINT_CLICK:
			forced = "CharacterBody2D"

	var ctx := {}
	var node := _build_transform(root_tr, objs, parent, ctx, forced)
	if node == null:
		return null

	instance_src[inst.file_id] = guid
	for src_fid in ctx.keys():
		stripped_map["%d:%d" % [inst.file_id, src_fid]] = ctx[src_fid]

	for ac in mod.get("m_AddedComponents", []):
		if not (ac is Dictionary):
			continue
		var host: N = ctx.get(_fid((ac as Dictionary).get("targetCorrespondingSourceObject")))
		var added := _fid((ac as Dictionary).get("addedObject"))
		if host and added != 0 and scene_docs.has(added):
			_add_scene_component(host, scene_docs[added], ctx)

	for rm in mod.get("m_RemovedComponents", []):
		var t: N = ctx.get(_fid((rm as Dictionary).get("target"))) if rm is Dictionary else null
		if t:
			report.append("component removed from '%s'; nothing to port" % t.name)

	_apply_mods(ctx, mod.get("m_Modifications", []))
	return node


func _find_root_transform(objs: Dictionary) -> int:
	for fid in objs.keys():
		var d: Doc = objs[fid]
		if d.class_id == 4:
			var f = (d.body as Dictionary).get("m_Father")
			if f is Dictionary and int(f.get("fileID", -1)) == 0:
				return int(fid)
	return 0


func _add_scene_component(host: N, d: Doc, ctx: Dictionary) -> void:
	if d.class_id in [61, 58, 68]:
		if _truthy((d.body as Dictionary).get("m_IsTrigger", 0)):
			_add_collider(host, d)
		else:
			_add_collider(_sub(host, "Solid", "StaticBody2D"), d)
	elif d.class_id == 114:
		pending_scripts.append({"doc": d, "host": host, "ctx": ctx, "scene": true})


func _apply_mods(ctx: Dictionary, mods: Array) -> void:
	for m in mods:
		if not (m is Dictionary):
			continue
		var tgt: N = ctx.get(_fid((m as Dictionary).get("target")))
		if tgt == null:
			continue
		var objref: Variant = (m as Dictionary).get("objectReference", {})
		var val: Variant = (m as Dictionary).get("value")
		if objref is Dictionary and int((objref as Dictionary).get("fileID", 0)) != 0:
			val = objref
		_set_prop(tgt, str((m as Dictionary).get("propertyPath", "")), val)


## Renaming a prefab root has to re-derive the paths of the whole subtree, or
## every child's `parent=` attribute points at a node that no longer exists.
func _rename(node: N, new_name: String) -> void:
	node.name = new_name
	_repath(node)


func _repath(node: N) -> void:
	node.npath = (node.parent_path + "/" + node.name) if node.parent != null and node.parent != scene_root else node.name
	for c in node.children:
		c.parent_path = node.npath
		_repath(c)


## Reads back a stored vector property before a modification adjusts one axis.
func _pv(node: N, key: String, def: Vector2) -> Vector2:
	var v = node.props.get(key)
	return v if v is Vector2 else def


func _set_prop(node: N, path: String, val: Variant) -> void:
	var parts := path.split(".")
	var top: String = parts[0]
	var sub: String = parts[1] if parts.size() > 1 else ""

	match top:
		"m_Name":
			_rename(node, sanitize(str(val)))
		"m_IsActive":
			# Node.ProcessMode is serialised as a plain int in .tscn:
			# 0 INHERIT, 1 PAUSABLE, 2 WHEN_PAUSED, 3 ALWAYS, 4 DISABLED.
			node.props["process_mode"] = "3" if _truthy(val) else "4"
			if node.type in ["Sprite2D", "TileMapLayer"]:
				node.props["visible"] = "true" if _truthy(val) else "false"
		"m_LocalPosition":
			# Unity writes an explicit z on every transform; 2D never uses it.
			# The stored position is Godot-space, so Y is negated on the way in.
			if sub == "x" or sub == "y":
				var p: Vector2 = _pv(node, "position", Vector2.ZERO)
				if sub == "x":
					p.x = float(val)
				else:
					p.y = -float(val)
				node.props["position"] = p
		"m_LocalScale":
			if sub == "x" or sub == "y":
				var s: Vector2 = _pv(node, "scale", Vector2.ONE)
				s[sub] = float(val)
				node.props["scale"] = s
		"m_LocalRotation":
			if sub != "":
				var q: Dictionary = node.props.get("_quat", {})
				if q.is_empty():
					q = {"x": 0.0, "y": 0.0, "z": 0.0, "w": 1.0}
				q[sub] = float(val)
				_finalise_quat(node, q)
		"m_LocalEulerAnglesHint":
			pass  # Unity caches this beside the quaternion; redundant
		"m_SortingLayer":
			node.sort_layer = int(val)
			node.has_sort = true
		"m_SortingOrder":
			node.sort_order = int(val)
			node.has_sort = true
		"m_Layer":
			# Unity's Physics2D layer matrix has all of Default/Layer 1/Layer 2/
			# Layer 3 colliding with each other, so converting these to Godot
			# collision bits would only risk breaking collisions. Everything
			# stays on Godot's default layer.
			pass
		"m_FlipX":
			node.props["flip_h"] = "true" if _truthy(val) else "false"
		"m_FlipY":
			node.props["flip_v"] = "true" if _truthy(val) else "false"
		"m_Color":
			node.props["modulate"] = cols(_col(val))
		"m_Sprite":
			var p2 := _sprite_path(val)
			if p2 != "":
				_ref(node, "texture", "ext", _add_ext("Texture2D", p2))
		"m_Size":
			# Only sliced SpriteRenderers scale their frame to this size.
			if (sub == "x" or sub == "y") and node.props.has("_sliced_size"):
				var px: Vector2i = node.props["_native_px"]
				var target: Vector2 = node.props["_sliced_size"]
				target[sub] = float(val)
				node.props["_sliced_size"] = target
				node.props["scale"] = Vector2(target.x / float(maxi(px.x, 1)),
					target.y / float(maxi(px.y, 1)))
		"m_Offset":
			if (sub == "x" or sub == "y") and node.type == "CollisionShape2D":
				var o: Vector2 = _pv(node, "position", Vector2.ZERO)
				o[sub] = -float(val)
				node.props["position"] = o
		"m_RootOrder", "m_SortingLayerID", "m_SpriteSortPoint", "m_Enabled":
			pass


## Unity layers live on the GameObject, which Godot splits between a body and
## its collision shapes, so the bit is pushed onto whichever node holds it.
func _set_collision_layer(node: N, bit: int) -> void:
	if node.type.ends_with("Body2D") or node.type == "Area2D":
		node.props["collision_layer"] = str(bit)
	elif node.type in ["Node2D", "Sprite2D"]:
		var target := node
		if node.type == "Sprite2D" and node.parent != null:
			target = node.parent
		if target.type.ends_with("Body2D") or target.type == "Area2D":
			target.props["collision_layer"] = str(bit)
		else:
			for c in target.children:
				if c.type.ends_with("Body2D") or c.type == "Area2D":
					c.props["collision_layer"] = str(bit)


# =============================================================================
# Tilemaps
# =============================================================================

func _build_tilemap(host: N, tm: Dictionary, renderer) -> void:
	var asset_array: Array = tm.get("m_TileAssetArray", [])
	var cells: Array = tm.get("m_Tiles", [])
	if cells.is_empty():
		return

	# Each m_TileAssetArray entry points at a Tile asset (a MonoBehaviour whose
	# m_Sprite names the artwork), not at a sprite directly.
	var sources := []
	var asset_source := {}
	for i in asset_array.size():
		var tile := _tile_asset((asset_array[i] as Dictionary).get("m_Data", {}))
		var spr := _sprite_ref(tile.get("m_Sprite", {}))
		if spr.is_empty():
			continue
		var tex: String = spr["tex"]
		var tsize: Vector2i = spr["px_size"]
		var si := -1
		for j in sources.size():
			if (sources[j] as Dictionary)["tex"] == tex and (sources[j] as Dictionary)["size"] == tsize:
				si = j
				break
		if si < 0:
			si = sources.size()
			sources.append({"tex": tex, "size": tsize, "tiles": {}})
		asset_source[i] = si

	var raw_cells := []
	# Variants are cached per tilemap, not globally: source indices are local to
	# one tilemap, so a global key would let one layer hide another's tiles.
	var local_variants := {}
	for cell in cells:
		var pos: Dictionary = ((cell as Dictionary).get("first", {}))
		var data: Dictionary = ((cell as Dictionary).get("second", {}))
		var idx := int(data.get("m_TileIndex", -1))
		if not asset_source.has(idx):
			continue
		var si2: int = asset_source[idx]
		var tile2 := _tile_asset((asset_array[idx] as Dictionary).get("m_Data", {}))
		var spr2 := _sprite_ref(tile2.get("m_Sprite", {}))
		if spr2.is_empty():
			continue
		var region: Rect2 = spr2["region"]
		var tsize2: Vector2i = (sources[si2] as Dictionary)["size"]
		var ax := int(roundf(region.position.x / float(maxi(tsize2.x, 1))))
		var ay := int(roundf(region.position.y / float(maxi(tsize2.y, 1))))
		# One alternative id per Unity tile asset keeps two tiles that share
		# artwork but differ in tint or transform from colliding.
		var key := "%d|%d|%d|%d" % [si2, ax, ay, idx + 1]
		if not local_variants.has(key):
			local_variants[key] = {
				"modulate": _col(tile2.get("m_Color", {})),
				"transform": _mat(tile2.get("m_Transform", {})),
				"collider": int(tile2.get("m_ColliderType", 1)),
				"physics": spr2["physics"],
				"px": int(maxi(spr2["px_size"].x, spr2["px_size"].y)),
			}
			((sources[si2] as Dictionary)["tiles"] as Dictionary)[key] = true
		# Godot's grid runs Y-down, Unity's runs Y-up.
		raw_cells.append({
			"asset": idx,
			"cell": Vector2i(int(pos.get("x", 0)), -int(pos.get("y", 0)) - 1),
		})

	if raw_cells.is_empty():
		report.append("tilemap '%s' produced no cells" % host.name)
		return

	host.type = "TileMapLayer"
	if renderer != null and renderer is Doc:
		host.sort_layer = int(((renderer as Doc).body as Dictionary).get("m_SortingLayer", 0))
		host.sort_order = int(((renderer as Doc).body as Dictionary).get("m_SortingOrder", 0))
		host.has_sort = true

	# One TileSet per Unity tilemap: each can carry different collider rules.
	# Cells are recorded symbolically; the real tile_map_data blob is produced by
	# a live TileMapLayer later, because its packed encoding is internal.
	var payload := {"node_name": host.name, "sources": [], "tile_size": 32,
		"cells": [], "assets": {}}
	for si in sources.size():
		var variants := []
		for k in (((sources[si] as Dictionary)["tiles"]) as Dictionary).keys():
			var fields: PackedStringArray = (k as String).split("|")
			var v: Dictionary = local_variants[k].duplicate(true)
			v["coords"] = Vector2i(int(fields[1]), int(fields[2]))
			v["asset"] = int(fields[3]) - 1
			variants.append(v)
			payload["tile_size"] = maxi(int(payload["tile_size"]), int(v["px"]))
			(payload["assets"] as Dictionary)[int(fields[3]) - 1] = {
				"order": si, "coords": v["coords"], "alt": 0}
		payload["sources"].append({"tex": (sources[si] as Dictionary)["tex"],
			"size": (sources[si] as Dictionary)["size"], "tiles": variants, "_order": si})

	for cell in raw_cells:
		(payload["cells"] as Array).append({"asset": int(cell["asset"]), "cell": cell["cell"]})

	# A TileSet works in pixels; one Unity world unit is 32 of them, so the layer
	# is scaled down to keep one cell at one unit.
	var ppu := float(maxi(int(payload["tile_size"]), 1))
	host.props["scale"] = Vector2(1.0 / ppu, 1.0 / ppu)

	tileset_payloads.append(payload)
	_ref(host, "tile_set", "tileset", payload)
	host.props["_cell_payload"] = payload


## Resolves a reference to a Unity Tile asset (.asset) and returns its body.
var tile_cache := {}


func _tile_asset(c: Variant) -> Dictionary:
	if not (c is Dictionary):
		return {}
	var guid := str(c.get("guid", ""))
	var file_id := int(c.get("fileID", 0))
	if guid == "":
		return {}
	var key := "%s:%d" % [guid, file_id]
	if tile_cache.has(key):
		return tile_cache[key]
	var rel: String = guid_paths.get(guid, "")
	var body := {}
	if rel != "":
		var objs := _load_objs(rel)
		if objs.has(file_id):
			body = (objs[file_id] as Doc).body
		else:
			for k in objs.keys():
				body = (objs[k] as Doc).body
				break
	else:
		report.append("tile asset missing: %s" % key)
	tile_cache[key] = body
	return body


static func _mat(m: Variant) -> Transform2D:
	if not (m is Dictionary) or (m as Dictionary).is_empty():
		return Transform2D.IDENTITY
	var d: Dictionary = m
	return Transform2D(Vector2(float(d.get("e00", 1)), float(d.get("e01", 0))),
			Vector2(float(d.get("e10", 0)), float(d.get("e11", 1))),
			Vector2(float(d.get("e03", 0)), float(d.get("e13", 0))))


static func _ints(a: PackedInt32Array) -> PackedStringArray:
	var p := PackedStringArray()
	for v in a:
		p.append(str(v))
	return p


## TileMapLayer.tile_map_data serialises as a PackedByteArray: a two-byte
## format header followed by twelve bytes per cell (int16 x, y, source_id,
## atlas_x, atlas_y, alternative_tile).
static func _bytes(a: PackedByteArray) -> String:
	var p := PackedStringArray()
	for v in a:
		p.append(str(v))
	return ", ".join(p)


func _write_tilesets() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/tilesets"))
	for payload in tileset_payloads:
		var ts := TileSet.new()
		ts.tile_shape = TileSet.TILE_SHAPE_SQUARE
		ts.tile_layout = TileSet.TILE_LAYOUT_STACKED
		var ts_size := int(payload["tile_size"])
		ts.tile_size = Vector2i(ts_size, ts_size)
		ts.add_physics_layer(0)
		ts.set_physics_layer_collision_layer(0, 0xFFFFFFFF)
		ts.set_physics_layer_collision_mask(0, 0)

		for src_def in payload["sources"]:
			var tex_path := "res://assets/textures/" + ((src_def as Dictionary)["tex"] as String).get_file()
			var tex: Texture2D = load(tex_path)
			if tex == null:
				report.append("tilemap texture not imported: " + tex_path)
				continue
			var at := TileSetAtlasSource.new()
			at.texture = tex
			at.texture_region_size = (src_def as Dictionary)["size"]
			var src_id := ts.add_source(at)
			(src_def as Dictionary)["source_id"] = src_id
			for t in (src_def as Dictionary)["tiles"]:
				var coords: Vector2i = t["coords"]
				if not at.has_tile(coords):
					at.create_tile(coords)
				# Godot assigns alternative ids itself (0 is the base tile), and
				# those ids are what tile_map_data has to reference.
				var alt := at.create_alternative_tile(coords)
				var data := at.get_tile_data(coords, alt)
				data.modulate = t["modulate"]
				var m: Transform2D = t["transform"]
				if m != Transform2D.IDENTITY:
					data.transform = m
				_apply_tile_physics(data, int(t["collider"]), t)
				var asset_idx := int(t["asset"])
				var entry: Dictionary = (payload["assets"] as Dictionary)[asset_idx]
				entry["source_id"] = src_id
				entry["alt"] = alt
				(payload["assets"] as Dictionary)[asset_idx] = entry
		ResourceSaver.save(ts, _tileset_res_path(payload))
	print("  tilesets written: %d" % tileset_payloads.size())


## Unity keeps tile colliders as pixel-space outlines on the sprite, or as a
## full cell when the tile's ColliderType is Grid.
func _apply_tile_physics(data: TileData, collider_type: int, t: Dictionary) -> void:
	if collider_type == 0:
		return
	var px := float(t["px"])
	var polys := []
	for shape in t["physics"]:
		if shape is Array and (shape as Array).size() >= 3:
			polys.append(shape)
	if polys.is_empty():
		if collider_type != 1:
			return
		polys = [[[-px / 2.0, -px / 2.0], [px / 2.0, -px / 2.0], [px / 2.0, px / 2.0], [-px / 2.0, px / 2.0]]]
	var index := 0
	for poly in polys:
		# add_collision_polygon() and get_collision_polygons_count() both return
		# void in Godot 4.7, so the polygon index is tracked here.
		data.add_collision_polygon(0)
		var pts := PackedVector2Array()
		var arr: Array = poly
		for i in range(arr.size() - 1, -1, -1):
			pts.append(_flip_y(_v2(arr[i])))
		data.set_collision_polygon_points(0, index, pts)
		index += 1


# =============================================================================
# Post-passes
# =============================================================================

func _wire_player(player: N) -> void:
	var visual: N = null
	for c in player.children:
		if c.type == "Sprite2D":
			visual = c
			break
	if visual == null:
		report.append("player has no Sprite2D to animate")
		return
	visual.script_file = SCRIPT_DIR + "player_visual.gd"
	visual.props["base_scale"] = visual.props.get("scale", Vector2.ONE)
	visual.props["rest_height"] = "1.4"
	_player_facing_textures(visual)
	_ref(player, "visual_path", "node", visual)


## The Unity Animator held four stills from one sheet: "F" is the South view,
## "B" the North view and "S" the side view, which East reuses flipped.
func _player_facing_textures(visual: N) -> void:
	var key: String = visual.props.get("_sprite_key", "")
	if key == "" or not sprite_table.has(key):
		report.append("player sprite key unresolved")
		return
	var tex: String = (sprite_table[key] as Dictionary)["tex"]
	var by_suffix := {}
	for k in sprite_table.keys():
		var s: Dictionary = sprite_table[k]
		if (s["tex"] as String) != tex:
			continue
		var nm: String = s["name"]
		if nm.contains(" Shadow"):
			continue
		var suffix := nm.substr(nm.length() - 1)
		if suffix != "F" and suffix != "B" and suffix != "S":
			continue
		var pair: PackedStringArray = (k as String).split(":")
		by_suffix[suffix] = _atlas_path(pair[0], pair[1])
	for suffix in ["F", "B", "S"]:
		var prop: String = {"F": "south_texture", "B": "north_texture", "S": "west_texture"}[suffix]
		if by_suffix.has(suffix):
			_ref(visual, prop, "ext", _add_ext("Texture2D", by_suffix[suffix]))
		else:
			report.append("player facing texture missing: " + suffix)
	# East reuses the side view flipped, so both point at the same resource.
	_ref(visual, "east_texture", "ext", _add_ext("Texture2D", by_suffix.get("S", "")))


## The stairs triggers swap the player's sorting layer; bake the resulting
## z_index now that the player's own sorting order is known.
func _wire_stairs_z() -> void:
	var order := 0
	for nd in _find_by_script("point_and_click_controller.gd"):
		for c in nd.children:
			if c.has_sort:
				order = c.sort_order
				break
		break
	for nd in _find_by_script("stairs_layer_trigger.gd"):
		nd.props["z_upper"] = str(int(nd.props.get("_sort_upper", 2)) * SORT_STRIDE + order)
		nd.props["z_lower"] = str(int(nd.props.get("_sort_lower", 1)) * SORT_STRIDE + order)


func _find_by_script(fname: String) -> Array:
	var out := []
	var stack := [scene_root]
	while not stack.is_empty():
		var nd: N = stack.pop_back()
		if nd.script_file.ends_with(fname):
			out.append(nd)
		for c in nd.children:
			stack.append(c)
	return out


func _each(node: N, method: String) -> void:
	callv(method, [node])
	for c in node.children:
		_each(c, method)


# =============================================================================
# Resource registry + emission
# =============================================================================

func _add_ext(type: String, path: String) -> String:
	if path == "":
		return ""
	for e in ext_res:
		if e["type"] == type and e["path"] == path:
			return e["id"]
	var id := "%d_%s" % [ext_res.size() + 1, id_safe(path.get_file().get_basename())]
	ext_res.append({"id": id, "type": type, "path": path})
	return id


func _add_sub(type: String, lines: Array) -> String:
	var id := "%s_%d" % [type, sub_res.size()]
	sub_res.append({"id": id, "type": type, "lines": lines})
	return id


static func _tileset_res_path(payload) -> String:
	return "res://assets/tilesets/%s.tres" % sanitize((payload as Dictionary)["node_name"])


func _prescan(node: N) -> void:
	# "ext" refs already registered their id when they were created; only the
	# TileSet refs need registering up front so the header count is right.
	if node.script_file != "":
		_add_ext("Script", node.script_file)
	for p in node.props.values():
		if p is Ref and (p as Ref).kind == "tileset":
			_add_ext("TileSet", _tileset_res_path((p as Ref).value))
	for c in node.children:
		_prescan(c)


## TileMapLayer stores its cells in a packed internal format. Rather than
## reimplement it, load the freshly saved TileSet into a real TileMapLayer, set
## every cell through the public API, and read the resulting blob back.
func _encode_tilemaps() -> void:
	var nodes := []
	_collect_by_prop(scene_root, "_cell_payload", nodes)
	for host in nodes:
		var payload: Dictionary = (host as N).props["_cell_payload"]
		var path := _tileset_res_path(payload)
		var ts: TileSet = load(path)
		if ts == null:
			report.append("tilemap '%s' has no TileSet to encode" % (host as N).name)
			continue
		var layer := TileMapLayer.new()
		layer.tile_set = ts
		for cell in payload["cells"]:
			var asset_idx := int(cell["asset"])
			var entry: Dictionary = (payload["assets"] as Dictionary).get(asset_idx, {})
			if entry.is_empty() or not entry.has("source_id"):
				continue
			layer.set_cell(cell["cell"], int(entry["source_id"]),
					Vector2i(entry["coords"]), int(entry["alt"]))
		(host as N).props["tile_map_data"] = "PackedByteArray(%s)" % _bytes(layer.tile_map_data)
		print("  tilemap '%s': %d cells" % [(host as N).name, (payload["cells"] as Array).size()])
		layer.free()


func _collect_by_prop(node: N, prop: String, out: Array) -> void:
	if node.props.has(prop):
		out.append(node)
	for c in node.children:
		_collect_by_prop(c, prop, out)


func _write_scene() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes"))
	_encode_tilemaps()
	_prescan(scene_root)
	var out := "[gd_scene load_steps=%d format=3]\n\n" % (ext_res.size() + sub_res.size() + 1)
	for e in ext_res:
		out += "[ext_resource type=\"%s\" path=\"%s\" id=\"%s\"]\n" % [e["type"], e["path"], e["id"]]
	if not ext_res.is_empty():
		out += "\n"
	for s in sub_res:
		out += "[sub_resource type=\"%s\" id=\"%s\"]\n" % [s["type"], s["id"]]
		for l in s["lines"]:
			out += "%s\n" % l
		out += "\n"
	out += _emit(scene_root)
	var f := FileAccess.open(OUT_SCENE, FileAccess.WRITE)
	f.store_string(out)
	f.close()
	print("  scene: %s (%d nodes, %d bytes)" % [OUT_SCENE, _count(scene_root), out.length()])


func _count(nd: N) -> int:
	var c := 1
	for ch in nd.children:
		c += _count(ch)
	return c


func _emit(node: N) -> String:
	var attrs := PackedStringArray(["name=\"%s\"" % node.name, "type=\"%s\"" % node.type])
	# The root node must not name a parent, or PackedScene.instantiate refuses it.
	if node != scene_root:
		attrs.append("parent=\"%s\"" % node.parent_path)
	var out := "\n[node " + " ".join(attrs) + "]\n"
	if node.script_file != "":
		out += "script = ExtResource(\"%s\")\n" % _add_ext("Script", node.script_file)

	var lines := PackedStringArray()
	for k in node.props.keys():
		var key := str(k)
		if key.begins_with("_"):
			continue
		lines.append("%s = %s" % [key, _serialise(node, node.props[k])])
	lines.sort()
	for l in lines:
		out += l + "\n"

	if node.has_sort:
		out += "z_index = %d\n" % (node.sort_layer * SORT_STRIDE + node.sort_order)
		out += "z_as_relative = false\n"

	for c in node.children:
		out += _emit(c)
	return out


func _serialise(from_node: N, v: Variant) -> String:
	if v is Vector2:
		return v2s(v)
	if v is Vector2i:
		return "Vector2i(%s, %s)" % [n(v.x), n(v.y)]
	if v is Color:
		return cols(v)
	if not (v is Ref):
		return str(v)
	var r: Ref = v
	match r.kind:
		"ext":
			return "ExtResource(\"%s\")" % r.value
		"sub":
			return "SubResource(\"%s\")" % r.value
		"tileset":
			return "ExtResource(\"%s\")" % _add_ext("TileSet", _tileset_res_path(r.value))
		"node":
			return "NodePath(\"%s\")" % _esc(_rel_path(from_node, r.value))
		"nodelist":
			var parts := PackedStringArray()
			for target in r.value:
				parts.append("NodePath(\"%s\")" % _esc(_rel_path(from_node, target)))
			return "[%s]" % ", ".join(parts)
	return str(v)


static func _esc(s: String) -> String:
	return s.replace("\"", "&quot;")


func _rel_path(from_node: N, target: N) -> String:
	var a: PackedStringArray = from_node.npath.split("/")
	var b: PackedStringArray = target.npath.split("/")
	if a.size() > 1 and a[0] == ".":
		a = a.slice(1)
	if b.size() > 1 and b[0] == ".":
		b = b.slice(1)
	var i := 0
	while i < a.size() and i < b.size() and a[i] == b[i]:
		i += 1
	var ups := ""
	for _j in range(a.size() - i):
		ups += "../"
	return ups + "/".join(b.slice(i))


func _release() -> void:
	doc_cache.clear()
	scene_docs.clear()
	scene_nodes.clear()
	stripped_map.clear()
	instance_src.clear()
	tile_cache.clear()
	name_counts.clear()
	variant_cache.clear()
	pending_scripts.clear()
	ext_res.clear()
	sub_res.clear()
	sprite_table.clear()
	mat_tint.clear()
	guid_paths.clear()
	scene_root = null


func _write_report() -> void:
	var f := FileAccess.open("res://CONVERSION.md", FileAccess.WRITE)
	if f == null:
		return
	f.store_string("# Unity -> Godot conversion\n\nSource scene: `%s`\n\n" % SCENE_REL)
	f.store_string("- Sprite slices converted: %d\n" % sprite_table.size())
	f.store_string("- Nodes emitted: %d\n" % _count(scene_root))
	f.store_string("- External resources: %d\n" % ext_res.size())
	f.store_string("- Sub resources: %d\n\n" % sub_res.size())
	f.store_string("## Converter notes\n\n")
	if report.is_empty():
		f.store_string("None.\n")
	for r in report:
		f.store_string("- %s\n" % r)
	f.close()