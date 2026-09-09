extends RefCounted
## Shared palette, procedural grime materials, and textures.

const BONE := Color(0.80, 0.77, 0.70)
const WALL := Color(0.52, 0.53, 0.49)
const FLOOR := Color(0.14, 0.15, 0.14)
const CEIL := Color(0.30, 0.30, 0.28)
const TEAL := Color(0.13, 0.30, 0.30)
const AMBER := Color(1.0, 0.62, 0.18)
const GOWN := Color(0.11, 0.12, 0.13)
const SKIN := Color(0.70, 0.66, 0.60)
const METAL := Color(0.35, 0.36, 0.38)
const WOOD := Color(0.23, 0.16, 0.11)

static var _noise_cache := {}

static func flat(color: Color, roughness: float = 0.9, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

static func grime(base: Color, contrast: float = 0.16, tex_size: int = 128) -> StandardMaterial3D:
	var key := "%s_%s" % [base.to_html(), contrast]
	if not _noise_cache.has(key):
		var img := Image.create(tex_size, tex_size, false, Image.FORMAT_L8)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(key)
		for y in tex_size:
			for x in tex_size:
				var v := 0.5 + contrast * (rng.randf() - 0.5) * 2.0
				if rng.randf() < 0.015:
					v *= 0.55
				img.set_pixel(x, y, Color(clampf(v, 0.0, 1.0), 0, 0))
		_noise_cache[key] = ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_color = base
	m.albedo_texture = _noise_cache[key]
	m.uv1_scale = Vector3(4.0, 4.0, 4.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.roughness = 0.95
	return m

static func glow(color: Color, strength: float = 1.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = strength
	return m
