class_name PaperFX
extends RefCounted
## The "paper theater" look: shared noise textures and helpers that wrap drawn nodes in a
## CanvasGroup with the paper material (scripts/visual/paper.gdshader). Everything is
## generated at runtime, so there are no image files to keep in sync.

const PAPER_SHADER := preload("res://scripts/visual/paper.gdshader")
const SKY_SHADER := preload("res://scripts/visual/sky_wash.gdshader")
const VIGNETTE_SHADER := preload("res://scripts/visual/vignette.gdshader")

static var _grain: Texture2D
static var _fiber: Texture2D
static var _wash: Texture2D


## Fine, even grain like cold-press paper.
static func grain() -> Texture2D:
	if _grain == null:
		_grain = _noise(FastNoiseLite.TYPE_VALUE, 0.9, 256, 11)
	return _grain


## Long soft streaks, like fibers in rag paper.
static func fiber() -> Texture2D:
	if _fiber == null:
		_fiber = _noise(FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.08, 256, 23)
	return _fiber


## Big soft blotches for watercolor washes.
static func wash() -> Texture2D:
	if _wash == null:
		_wash = _noise(FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.02, 256, 37, 3)
	return _wash


static func _noise(kind: int, freq: float, size: int, seed_value: int, octaves: int = 1) -> Texture2D:
	var n := FastNoiseLite.new()
	n.noise_type = kind
	n.frequency = freq
	n.seed = seed_value
	n.fractal_octaves = octaves
	var t := NoiseTexture2D.new()
	t.width = size
	t.height = size
	t.seamless = true
	t.noise = n
	return t


## A paper material. params override the shader defaults (see paper.gdshader).
static func material(params: Dictionary = {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = PAPER_SHADER
	m.set_shader_parameter("grain_tex", grain())
	m.set_shader_parameter("fiber_tex", fiber())
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


## A CanvasGroup with the paper material; add drawn nodes to it as children.
static func group(params: Dictionary = {}, margin: float = 28.0) -> CanvasGroup:
	var g := CanvasGroup.new()
	g.fit_margin = margin
	g.clear_margin = margin
	g.use_mipmaps = true
	g.material = material(params)
	return g


static func sky_material(top: Color, bottom: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SKY_SHADER
	m.set_shader_parameter("top_color", top)
	m.set_shader_parameter("bottom_color", bottom)
	m.set_shader_parameter("wash_tex", wash())
	m.set_shader_parameter("grain_tex", grain())
	return m


## Full-screen warm lamp light and dark corners.
static func vignette(size: Vector2 = Vector2(1920, 1080)) -> ColorRect:
	var r := ColorRect.new()
	r.size = size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = VIGNETTE_SHADER
	m.set_shader_parameter("aspect", size.x / size.y)
	r.material = m
	return r
