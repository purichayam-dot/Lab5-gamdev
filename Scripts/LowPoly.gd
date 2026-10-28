class_name LowPoly
extends RefCounted
# ตัวช่วยสร้าง mesh สไตล์ Low-Poly (flat shading + สีต่อหน้าแบบสุ่มเล็กน้อย)
# ใช้สร้างเกาะ/แท่น/หนาม/เสา แบบ procedural ทำให้ไฟล์เกมเล็กมาก

static var _mat_cache := {}

static func vertex_color_material(emission := 0.0, roughness := 0.85) -> StandardMaterial3D:
	var key := "%s_%s" % [emission, roughness]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = roughness
	if emission > 0.0:
		m.emission_enabled = true
		m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
		m.emission = Color.WHITE
		m.emission_energy_multiplier = emission
		m.emission_on_uv2 = false
	_mat_cache[key] = m
	return m

static func _hash3(p: Vector3, s: int) -> float:
	var h := sin(p.x * 12.9898 + p.y * 78.233 + p.z * 37.719 + float(s) * 4.1414) * 43758.5453
	return h - floor(h)

## แปลง PrimitiveMesh เป็น ArrayMesh แบบ flat-shaded พร้อมสีต่อหน้า
## jitter = สุ่มความสว่างต่อหน้า, wobble = บิดตำแหน่ง vertex ให้ดูเป็นหิน (สอดคล้องกันตามตำแหน่ง)
static func flat(src: Mesh, color: Color, jitter := 0.07, sd := 0, wobble := 0.0, wobble_keep_top := true, emission := 0.0) -> ArrayMesh:
	var arrays: Array
	if src is PrimitiveMesh:
		arrays = (src as PrimitiveMesh).get_mesh_arrays()
	else:
		arrays = src.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if wobble > 0.0:
		var top := -INF
		for v in verts:
			top = max(top, v.y)
		for i in verts.size():
			var v := verts[i]
			if wobble_keep_top and v.y >= top - 0.001:
				continue
			var k := Vector3(snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001))
			var d := Vector3(_hash3(k, sd) - 0.5, (_hash3(k, sd + 7) - 0.5) * 0.6, _hash3(k, sd + 13) - 0.5)
			verts[i] = v + d * wobble
	var out_v := PackedVector3Array()
	var out_n := PackedVector3Array()
	var out_c := PackedColorArray()
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	var count := idx.size() if idx.size() > 0 else verts.size()
	for i in range(0, count, 3):
		var a := verts[idx[i]] if idx.size() > 0 else verts[i]
		var b := verts[idx[i + 1]] if idx.size() > 0 else verts[i + 1]
		var c := verts[idx[i + 2]] if idx.size() > 0 else verts[i + 2]
		var pl := Plane(a, b, c)
		var n := pl.normal
		if n == Vector3.ZERO:
			continue
		var f := 1.0 + rng.randf_range(-jitter, jitter)
		# หน้าที่หันขึ้นจะสว่างขึ้นเล็กน้อย ให้ดูมีมิติ
		f *= 1.0 + max(n.y, 0.0) * 0.06
		var col := Color(color.r * f, color.g * f, color.b * f, color.a)
		for v in [a, b, c]:
			out_v.append(v)
			out_n.append(n)
			out_c.append(col)
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = out_v
	out[Mesh.ARRAY_NORMAL] = out_n
	out[Mesh.ARRAY_COLOR] = out_c
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
	mesh.surface_set_material(0, vertex_color_material(emission))
	return mesh

static func cylinder(top_r: float, bottom_r: float, h: float, sides: int) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top_r
	m.bottom_radius = bottom_r
	m.height = h
	m.radial_segments = sides
	m.rings = 0
	return m

static func box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m

## สร้าง MeshInstance3D แบบ flat-shaded แล้วเพิ่มเป็นลูกของ parent
static func add_mesh(parent: Node, src: Mesh, color: Color, pos := Vector3.ZERO, sd := 0, wobble := 0.0, jitter := 0.07, emission := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = flat(src, color, jitter, sd, wobble, true, emission)
	mi.position = pos
	parent.add_child(mi)
	return mi
