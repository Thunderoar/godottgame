class_name PixelArt
extends RefCounted
## Small procedural pixel-art toolkit.
##
## Most of the game's environmental art comes from the original Cainos atlas.
## Pets, monsters, the cottage upgrades, stalls, portals, the ship and all UI
## icons are generated here so they share one crisp 1-pixel language and can be
## recoloured or animated without shipping another atlas.

const PX := 1.0 / 32.0
const OUTLINE := Color("#241a1c")
static var CACHE: Dictionary = {}

# ------------------------------------------------------------------ utils

static func image(w: int, h: int) -> Image:
        var img := Image.create_empty(maxi(1, w), maxi(1, h), false, Image.FORMAT_RGBA8)
        img.fill(Color(0, 0, 0, 0))
        return img


static func texture(img: Image) -> ImageTexture:
        return ImageTexture.create_from_image(img)


static func cached_texture(key: String, builder: Callable) -> Texture2D:
        if CACHE.has(key):
                return CACHE[key]
        var img: Image = builder.call()
        var tex := texture(img)
        CACHE[key] = tex
        return tex


static func rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
        var x0 := maxi(0, x)
        var y0 := maxi(0, y)
        var x1 := mini(img.get_width(), x + w)
        var y1 := mini(img.get_height(), y + h)
        for py in range(y0, y1):
                for px in range(x0, x1):
                        img.set_pixel(px, py, color)


static func px(img: Image, x: int, y: int, color: Color) -> void:
        if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
                img.set_pixel(x, y, color)


static func hline(img: Image, x: int, y: int, w: int, color: Color) -> void:
        rect(img, x, y, w, 1, color)


static func vline(img: Image, x: int, y: int, h: int, color: Color) -> void:
        rect(img, x, y, 1, h, color)


static func ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, color: Color) -> void:
        for y in range(-ry, ry + 1):
                var span := int(round(float(rx) * sqrt(maxf(0.0, 1.0 - pow(float(y) / float(maxi(1, ry)), 2.0)))))
                hline(img, cx - span, cy + y, span * 2 + 1, color)


static func ellipse_outline(img: Image, cx: int, cy: int, rx: int, ry: int, color: Color) -> void:
        for y in range(-ry, ry + 1):
                var span := int(round(float(rx) * sqrt(maxf(0.0, 1.0 - pow(float(y) / float(maxi(1, ry)), 2.0)))))
                px(img, cx - span, cy + y, color)
                px(img, cx + span, cy + y, color)


static func line(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
        var dx := absi(x1 - x0)
        var sx := 1 if x0 < x1 else -1
        var dy := -absi(y1 - y0)
        var sy := 1 if y0 < y1 else -1
        var err := dx + dy
        while true:
                px(img, x0, y0, color)
                if x0 == x1 and y0 == y1:
                        break
                var e2 := err * 2
                if e2 >= dy:
                        err += dy
                        x0 += sx
                if e2 <= dx:
                        err += dx
                        y0 += sy


static func noise(img: Image, count: int, bounds: Rect2i, colors: Array[Color], seed_value: int) -> void:
        var rng := RandomNumberGenerator.new()
        rng.seed = seed_value
        for i in count:
                var x := rng.randi_range(bounds.position.x, bounds.position.x + bounds.size.x - 1)
                var y := rng.randi_range(bounds.position.y, bounds.position.y + bounds.size.y - 1)
                px(img, x, y, colors[rng.randi_range(0, colors.size() - 1)])


static func mix(a: Color, b: Color, t: float) -> Color:
        return a.lerp(b, clampf(t, 0.0, 1.0))


# ------------------------------------------------------------------ portraits & icons

static func portrait(character_id: String, size: int = 96) -> Texture2D:
        return cached_texture("portrait_%s_%d" % [character_id, size], func() -> Image:
                var character := CharacterDB.get_character(character_id)
                var img := image(size, size)
                var accent: Color = character.accent
                var skin: Color = character.tint
                var hair: Color = character.hair
                rect(img, 0, 0, size, size, Color("#17232b"))
                ellipse(img, size / 2, size / 2 + 6, 35, 35, Color("#243d45"))
                ellipse(img, size / 2, size / 2 + 7, 29, 29, Color("#2f555e"))
                # Shoulders and tunic.
                ellipse(img, size / 2, size - 6, 31, 24, Color("#2f3438"))
                rect(img, 21, size - 28, size - 42, 26, accent.darkened(0.35))
                rect(img, 38, size - 28, 20, 5, accent.darkened(0.5))
                # Head and neck.
                rect(img, 42, 66, 12, 9, skin.darkened(0.12))
                ellipse(img, size / 2, 45, 20, 23, OUTLINE)
                ellipse(img, size / 2, 45, 18, 21, skin)
                # Short masculine hair; Farhan has a short beard.
                ellipse(img, size / 2, 28, 19, 12, hair)
                rect(img, 29, 27, 5, 13, hair)
                rect(img, size - 34, 27, 5, 13, hair)
                if character_id == "qayyim":
                        rect(img, 43, 24, 12, 4, hair.lightened(0.08))
                elif character_id == "farhan":
                        rect(img, 36, 58, 24, 8, hair)
                        rect(img, 40, 64, 16, 7, hair.darkened(0.1))
                else:
                        rect(img, 28, 30, 6, 24, hair.darkened(0.12))
                # Eyes, nose, mouth.
                rect(img, 37, 43, 6, 3, OUTLINE)
                rect(img, 53, 43, 6, 3, OUTLINE)
                rect(img, 39, 43, 2, 2, Color("#e9ecdd"))
                rect(img, 55, 43, 2, 2, Color("#e9ecdd"))
                px(img, 47, 50, skin.darkened(0.16))
                hline(img, 43, 57, 10, Color("#82524e"))
                # Collar and weapon hint.
                rect(img, 41, 72, 14, 5, Color("#e5d59a"))
                match character_id:
                        "farhan":
                                line(img, 72, 39, 91, 17, Color("#6a4a2d"))
                                rect(img, 80, 12, 14, 12, Color("#798381"))
                                rect(img, 83, 15, 8, 6, Color("#b3bdb8"))
                        "ayiz":
                                line(img, 75, 18, 88, 50, Color("#9a6d3d"))
                                line(img, 75, 18, 82, 50, Color("#cbb38b"))
                                line(img, 88, 50, 82, 50, Color("#ece0c4"))
                        _:
                                line(img, 72, 66, 92, 34, Color("#cfd4cc"))
                                line(img, 74, 68, 94, 36, Color("#7e8787"))
                # Border.
                rect(img, 0, 0, size, 2, Color("#0b1115"))
                rect(img, 0, size - 2, size, 2, Color("#0b1115"))
                rect(img, 0, 0, 2, size, Color("#0b1115"))
                rect(img, size - 2, 0, 2, size, Color("#0b1115"))
                return img)


static func icon(kind: String, size: int = 16) -> Texture2D:
        # Sizes >= 24 use the detailed IconArt set (1px outline, 3-tone shading);
        # the compact 16px art below is unchanged so existing callers never differ.
        if size >= 24:
                return IconArt.icon(kind, size)
        return cached_texture("icon_%s_%d" % [kind, size], func() -> Image:
                var img := image(size, size)
                match kind:
                        "gold":
                                ellipse(img, 8, 8, 7, 7, Color("#8b5a1f"))
                                ellipse(img, 8, 8, 6, 6, Color("#f4c755"))
                                ellipse(img, 7, 7, 4, 4, Color("#ffe28a"))
                                hline(img, 5, 6, 5, Color("#fff3c2"))
                        "diamond":
                                var pts := [Vector2i(8, 1), Vector2i(14, 6), Vector2i(8, 15), Vector2i(2, 6)]
                                _fill_polygon(img, pts, Color("#87ecff"))
                                line(img, 8, 1, 8, 15, Color("#d9fbff"))
                                line(img, 2, 6, 14, 6, Color("#42a7c7"))
                                line(img, 2, 6, 8, 15, Color("#42a7c7"))
                                line(img, 14, 6, 8, 15, Color("#42a7c7"))
                        "heart":
                                ellipse(img, 5, 6, 4, 4, Color("#e65555"))
                                ellipse(img, 11, 6, 4, 4, Color("#e65555"))
                                _fill_polygon(img, [Vector2i(1, 7), Vector2i(15, 7), Vector2i(8, 15)], Color("#e65555"))
                                px(img, 4, 4, Color("#ffb0a8"))
                        "mana":
                                _fill_polygon(img, [Vector2i(8, 1), Vector2i(13, 8), Vector2i(8, 15), Vector2i(3, 8)], Color("#6ea7ee"))
                                px(img, 6, 5, Color("#bfe2ff"))
                        "sword":
                                line(img, 3, 13, 12, 4, Color("#d8d8d0"))
                                line(img, 4, 14, 13, 5, Color("#777d7d"))
                                line(img, 10, 12, 14, 8, Color("#c9964c"))
                                line(img, 2, 12, 5, 15, Color("#7e5230"))
                        "hammer":
                                line(img, 4, 14, 11, 4, Color("#7a5230"))
                                line(img, 3, 13, 10, 3, Color("#b07c45"))
                                rect(img, 8, 1, 7, 6, Color("#4d5656"))
                                rect(img, 9, 2, 5, 4, Color("#9ea8a3"))
                        "bow":
                                line(img, 5, 2, 11, 5, Color("#9a6d3d"))
                                line(img, 11, 5, 13, 8, Color("#9a6d3d"))
                                line(img, 13, 8, 11, 12, Color("#9a6d3d"))
                                line(img, 5, 2, 11, 12, Color("#d8c8a4"))
                                line(img, 3, 8, 13, 8, Color("#d8d8d0"))
                        "potion_red", "health_potion":
                                rect(img, 6, 2, 4, 4, Color("#cfd6cf"))
                                rect(img, 5, 5, 6, 3, Color("#6d5a4e"))
                                ellipse(img, 8, 10, 5, 5, Color("#8f2835"))
                                ellipse(img, 8, 10, 4, 4, Color("#ef5763"))
                                px(img, 6, 8, Color("#ffa2a8"))
                        "potion_blue", "mana_potion":
                                rect(img, 6, 2, 4, 4, Color("#cfd6cf"))
                                rect(img, 5, 5, 6, 3, Color("#6d5a4e"))
                                ellipse(img, 8, 10, 5, 5, Color("#243f79"))
                                ellipse(img, 8, 10, 4, 4, Color("#5889d7"))
                                px(img, 6, 8, Color("#b5d0ff"))
                        "revive":
                                rect(img, 6, 1, 4, 4, Color("#d8c892"))
                                rect(img, 5, 4, 6, 4, Color("#655b45"))
                                ellipse(img, 8, 10, 5, 5, Color("#4b7b5f"))
                                ellipse(img, 8, 10, 4, 4, Color("#8edb9c"))
                                line(img, 8, 7, 8, 13, Color("#efffd9"))
                                hline(img, 5, 10, 7, Color("#efffd9"))
                        "food":
                                ellipse(img, 8, 9, 6, 4, Color("#c58b45"))
                                ellipse(img, 8, 8, 5, 3, Color("#efc36e"))
                                line(img, 3, 6, 13, 6, Color("#8d5b30"))
                        "backpack":
                                rect(img, 3, 5, 10, 9, Color("#7b4b2c"))
                                rect(img, 4, 4, 8, 5, Color("#a5683d"))
                                rect(img, 5, 9, 6, 4, Color("#c28e58"))
                                hline(img, 4, 8, 8, Color("#3c281d"))
                                rect(img, 6, 2, 4, 3, Color("#4b3021"))
                        "armor":
                                _fill_polygon(img, [Vector2i(5, 3), Vector2i(11, 3), Vector2i(13, 6), Vector2i(11, 14), Vector2i(5, 14), Vector2i(3, 6)], Color("#6c7b7e"))
                                _fill_polygon(img, [Vector2i(6, 4), Vector2i(10, 4), Vector2i(11, 7), Vector2i(10, 12), Vector2i(6, 12), Vector2i(5, 7)], Color("#a5b3b0"))
                                hline(img, 6, 8, 5, Color("#38484c"))
                                px(img, 8, 6, Color("#e8d18a"))
                        "shield":
                                _fill_polygon(img, [Vector2i(4, 3), Vector2i(12, 3), Vector2i(14, 7), Vector2i(8, 15), Vector2i(2, 7)], Color("#5f4933"))
                                _fill_polygon(img, [Vector2i(5, 4), Vector2i(11, 4), Vector2i(12, 7), Vector2i(8, 13), Vector2i(4, 7)], Color("#a88a5c"))
                                line(img, 8, 4, 8, 12, Color("#e4c979"))
                                hline(img, 5, 7, 7, Color("#e4c979"))
                        "wood":
                                ellipse(img, 5, 9, 4, 4, Color("#6e4a2c"))
                                line(img, 5, 5, 13, 5, Color("#8d5c34"))
                                line(img, 5, 13, 13, 13, Color("#8d5c34"))
                                line(img, 4, 9, 13, 9, Color("#b07a45"))
                                line(img, 13, 5, 13, 13, Color("#55351f"))
                        "skull":
                                ellipse(img, 8, 7, 6, 6, Color("#d8d3bd"))
                                rect(img, 5, 9, 2, 2, Color("#352f31"))
                                rect(img, 9, 9, 2, 2, Color("#352f31"))
                                rect(img, 6, 12, 4, 2, Color("#bab3a0"))
                        "portal":
                                ellipse_outline(img, 8, 8, 6, 7, Color("#9d78d8"))
                                ellipse_outline(img, 8, 8, 4, 5, Color("#d6b9ff"))
                                px(img, 8, 4, Color("#ffffff"))
                                px(img, 8, 11, Color("#ffffff"))
                        "spark":
                                line(img, 8, 1, 8, 14, Color("#fff2b0"))
                                line(img, 1, 8, 14, 8, Color("#fff2b0"))
                                line(img, 4, 4, 12, 12, Color("#e6c85d"))
                                line(img, 12, 4, 4, 12, Color("#e6c85d"))
                        _:
                                ellipse(img, 8, 8, 6, 6, Color("#9aa3a1"))
                return img)


static func _fill_polygon(img: Image, points: Array, color: Color) -> void:
        var min_y := 99999
        var max_y := -1
        for p in points:
                min_y = mini(min_y, p.y)
                max_y = maxi(max_y, p.y)
        for y in range(min_y, max_y + 1):
                var nodes: Array[int] = []
                for i in points.size():
                        var a: Vector2i = points[i]
                        var b: Vector2i = points[(i + 1) % points.size()]
                        if (a.y < y and b.y >= y) or (b.y < y and a.y >= y):
                                var t := float(y - a.y) / float(b.y - a.y)
                                nodes.append(int(round(float(a.x) + t * float(b.x - a.x))))
                nodes.sort()
                for n in range(0, nodes.size() - 1, 2):
                        hline(img, nodes[n], y, maxi(1, nodes[n + 1] - nodes[n] + 1), color)


# ------------------------------------------------------------------ light

static func light_texture() -> Texture2D:
        return cached_texture("light", func() -> Image:
                var size := 128
                var img := image(size, size)
                var centre := Vector2(size * 0.5, size * 0.5)
                for y in size:
                        for x in size:
                                var d := Vector2(x + 0.5, y + 0.5).distance_to(centre) / (size * 0.5)
                                var a := pow(clampf(1.0 - d, 0.0, 1.0), 1.35)
                                img.set_pixel(x, y, Color(1, 1, 1, a))
                return img)


# ------------------------------------------------------------------ player characters

static func character_texture(character_id: String, facing: int, frame: int = 0) -> Texture2D:
        return cached_texture("character_%s_%d_%d" % [character_id, facing, frame], func() -> Image:
                var character := CharacterDB.get_character(character_id)
                var skin: Color = character.get("tint", Color("#f4dfc8"))
                var accent: Color = character.get("accent", Color("#ecb35f"))
                var hair := Color("#6f3f2b")
                var tunic := accent.darkened(0.35)
                var cloak := accent.darkened(0.55)
                var pants := Color("#3a3438")
                match character_id:
                        "farhan":
                                hair = Color("#252426")
                                tunic = Color("#7a3f2b")
                                cloak = Color("#44271e")
                                pants = Color("#2e2a26")
                        "ayiz":
                                hair = Color("#3a2b22")
                                tunic = Color("#4f6b3e")
                                cloak = Color("#31452a")
                                pants = Color("#34332f")
                        _:
                                hair = Color("#513326")
                                tunic = Color("#3f7f72")
                                cloak = Color("#2a4d4a")
                                pants = Color("#30373a")
                var img := image(32, 48)
                # Frame map: 0-3 walk cycle (contact / pass / contact / pass),
                # 4 idle stand, 5 idle blink, 6 hurt recoil. Old callers that
                # only ever passed 0/1 keep working.
                var step := 0
                var bob := 0
                match frame:
                        0:
                                step = 1
                                bob = 0
                        1:
                                step = 0
                                bob = 1
                        2:
                                step = -1
                                bob = 0
                        3:
                                step = 0
                                bob = 2
                        4:
                                step = 0
                                bob = 0
                        5:
                                step = 0
                                bob = 0
                        _:
                                step = 0
                                bob = 1
                var hurt := frame == 6
                var eyes_closed := frame == 5
                # Cloak / silhouette behind the body.
                ellipse(img, 16, 34 + bob, 8, 10, OUTLINE)
                ellipse(img, 16, 34 + bob, 7, 9, cloak)
                # Legs and boots.
                var leg_left := 3 + step
                var leg_right := 3 - step
                rect(img, 11, 36 + bob, 4, 9 + leg_left, pants)
                rect(img, 18, 36 + bob, 4, 9 + leg_right, pants)
                rect(img, 10, 44 + bob, 5, 4, OUTLINE)
                rect(img, 18, 44 + bob, 5, 4, OUTLINE)
                rect(img, 11, 44 + bob, 3, 3, Color("#584534"))
                rect(img, 19, 44 + bob, 3, 3, Color("#584534"))
                # Torso.
                rect(img, 9, 24 + bob, 14, 14, OUTLINE)
                rect(img, 10, 25 + bob, 12, 12, tunic)
                rect(img, 11, 26 + bob, 10, 3, tunic.lightened(0.08))
                rect(img, 9, 34 + bob, 14, 2, Color("#2b2426"))
                px(img, 15, 35 + bob, accent)
                # Chest clasp.
                rect(img, 14, 27 + bob, 4, 2, accent.darkened(0.15))
                # Arms.
                if facing == 2:
                        rect(img, 20, 26 + bob, 4, 9, OUTLINE)
                        rect(img, 20, 27 + bob, 3, 8, tunic.lightened(0.06))
                        rect(img, 20, 35 + bob, 3, 3, skin)
                else:
                        rect(img, 6, 26 + bob, 4, 9, OUTLINE)
                        rect(img, 7, 27 + bob, 3, 8, tunic.lightened(0.06))
                        rect(img, 7, 35 + bob, 3, 3, skin)
                        rect(img, 22, 26 + bob, 4, 10, OUTLINE)
                        rect(img, 22, 27 + bob, 3, 9, tunic)
                        rect(img, 22, 36 + bob, 3, 3, skin)
                # Neck and head.
                rect(img, 13, 22 + bob, 6, 4, skin.darkened(0.12))
                ellipse(img, 16, 16 + bob, 7, 8, OUTLINE)
                ellipse(img, 16, 16 + bob, 6, 7, skin)
                if facing == 1:
                        # Back of the head: hair and hood shadow.
                        ellipse(img, 16, 15 + bob, 6, 7, hair)
                        rect(img, 10, 15 + bob, 3, 8, hair.darkened(0.1))
                        rect(img, 19, 15 + bob, 3, 8, hair.darkened(0.1))
                        rect(img, 12, 24 + bob, 8, 2, accent.darkened(0.25))
                elif facing == 2:
                        # Profile facing right.
                        ellipse(img, 15, 14 + bob, 6, 6, hair)
                        rect(img, 10, 13 + bob, 4, 9, hair.darkened(0.08))
                        rect(img, 19, 15 + bob, 3, 2, skin)
                        rect(img, 21, 17 + bob, 2, 2, skin.darkened(0.06))
                        if eyes_closed:
                                hline(img, 17, 17 + bob, 3, OUTLINE)
                        else:
                                rect(img, 18, 16 + bob, 2, 2, OUTLINE)
                                px(img, 19, 16 + bob, accent.lightened(0.4))
                        if hurt:
                                rect(img, 17, 19 + bob, 3, 3, Color("#5e2f2f"))
                        else:
                                hline(img, 18, 20 + bob, 4, Color("#9a5a50"))
                        if character_id == "farhan":
                                rect(img, 10, 17 + bob, 7, 6, hair.darkened(0.05))
                else:
                        # Face and short hair from the front.
                        ellipse(img, 16, 12 + bob, 7, 5, hair)
                        rect(img, 9, 14 + bob, 4, 6, hair)
                        rect(img, 19, 14 + bob, 4, 6, hair)
                        hline(img, 11, 13 + bob, 10, hair.lightened(0.06))
                        rect(img, 14, 10 + bob, 4, 3, hair.darkened(0.1))
                        if character_id == "farhan":
                                # Short beard and heavier brow.
                                rect(img, 11, 20 + bob, 10, 4, hair.darkened(0.08))
                                rect(img, 13, 22 + bob, 6, 3, hair)
                                hline(img, 12, 16 + bob, 8, hair.darkened(0.2))
                        # Eyes, nose, mouth.
                        if eyes_closed:
                                hline(img, 12, 18 + bob, 3, OUTLINE)
                                hline(img, 18, 18 + bob, 3, OUTLINE)
                        else:
                                rect(img, 12, 17 + bob, 3, 2, OUTLINE)
                                rect(img, 18, 17 + bob, 3, 2, OUTLINE)
                                px(img, 13, 17 + bob, accent.lightened(0.5))
                                px(img, 19, 17 + bob, accent.lightened(0.5))
                        px(img, 16, 19 + bob, skin.darkened(0.18))
                        if hurt:
                                rect(img, 14, 20 + bob, 4, 3, Color("#5e2f2f"))
                        else:
                                hline(img, 14, 21 + bob, 5, Color("#8d4e4e"))
                # Scarf / collar.
                rect(img, 11, 23 + bob, 10, 2, accent.darkened(0.2))
                # Unique weapon silhouette.
                match character_id:
                        "farhan":
                                # Forgehammer over the right shoulder.
                                line(img, 23, 38 + bob, 29, 22 + bob, Color("#5b3c24"))
                                line(img, 24, 37 + bob, 30, 21 + bob, Color("#8b6136"))
                                rect(img, 25, 18 + bob, 9, 7, OUTLINE)
                                rect(img, 26, 19 + bob, 7, 5, Color("#8b9694"))
                                rect(img, 27, 20 + bob, 5, 2, Color("#ccd3cc"))
                        "ayiz":
                                # Hunting bow across the back.
                                line(img, 24, 24 + bob, 29, 34 + bob, Color("#8a5e35"))
                                line(img, 29, 34 + bob, 24, 43 + bob, Color("#8a5e35"))
                                line(img, 25, 25 + bob, 25, 42 + bob, Color("#ded2ad"))
                                px(img, 24, 24 + bob, accent.lightened(0.2))
                                px(img, 24, 43 + bob, accent.lightened(0.2))
                        _:
                                # Sword at the left hip.
                                line(img, 7, 31 + bob, 4, 42 + bob, Color("#4f5556"))
                                line(img, 8, 31 + bob, 5, 42 + bob, Color("#c4c9c2"))
                                line(img, 5, 33 + bob, 9, 33 + bob, accent.darkened(0.35))
                                px(img, 6, 32 + bob, Color("#e8d7a0"))
                return img)


# ------------------------------------------------------------------ pets

static func pet_texture(pet_id: String, frame: int = 0) -> Texture2D:
        # Frames 0/1 are the classic two-frame bob (existing callers). New frames:
        # 2 idle blink, 3 walk pass, 4 attack leap, 5 downed/dazed, 6 happy bounce.
        return cached_texture("pet_%s_%d" % [pet_id, frame], func() -> Image:
                var def := PetDB.get_pet(pet_id)
                var body: Color = def.get("body", Color("#d8783f"))
                var accent: Color = def.get("accent", Color("#ffd27a"))
                var img := image(32, 32)
                var bob := 1 if frame % 2 == 0 else 0
                # Soft outline and body.
                if pet_id == "luma":
                        ellipse(img, 11, 17 + bob, 8, 6, Color("#31546b"))
                        ellipse(img, 21, 17 + bob, 8, 6, Color("#31546b"))
                        ellipse(img, 11, 17 + bob, 6, 4, body)
                        ellipse(img, 21, 17 + bob, 6, 4, body)
                        ellipse(img, 16, 21 + bob, 4, 6, Color("#31546b"))
                        ellipse(img, 16, 21 + bob, 3, 5, body.lightened(0.12))
                        ellipse(img, 16, 12 + bob, 4, 4, accent)
                        px(img, 15, 12 + bob, OUTLINE)
                        px(img, 17, 12 + bob, OUTLINE)
                        line(img, 16, 8 + bob, 13, 5 + bob, accent)
                        line(img, 16, 8 + bob, 19, 5 + bob, accent)
                elif pet_id == "moss":
                        ellipse(img, 16, 22 + bob, 9, 6, OUTLINE)
                        ellipse(img, 16, 21 + bob, 8, 5, body)
                        ellipse(img, 16, 14 + bob, 7, 7, OUTLINE)
                        ellipse(img, 16, 14 + bob, 6, 6, body.lightened(0.08))
                        _fill_polygon(img, [Vector2i(9, 10 + bob), Vector2i(12, 4 + bob), Vector2i(15, 11 + bob)], OUTLINE)
                        _fill_polygon(img, [Vector2i(17, 11 + bob), Vector2i(20, 4 + bob), Vector2i(23, 10 + bob)], OUTLINE)
                        _fill_polygon(img, [Vector2i(10, 10 + bob), Vector2i(12, 6 + bob), Vector2i(14, 11 + bob)], body)
                        _fill_polygon(img, [Vector2i(18, 11 + bob), Vector2i(20, 6 + bob), Vector2i(22, 10 + bob)], body)
                        # Curled tail.
                        line(img, 24, 23 + bob, 28, 20 + bob, OUTLINE)
                        line(img, 28, 20 + bob, 27, 17 + bob, OUTLINE)
                        # Eyes and whiskers.
                        rect(img, 12, 13 + bob, 3, 2, accent)
                        rect(img, 18, 13 + bob, 3, 2, accent)
                        px(img, 13, 13 + bob, OUTLINE)
                        px(img, 19, 13 + bob, OUTLINE)
                        line(img, 10, 17 + bob, 6, 16 + bob, Color("#d7dfbf"))
                        line(img, 22, 17 + bob, 26, 16 + bob, Color("#d7dfbf"))
                else:
                        # Ember fox.
                        ellipse(img, 16, 23 + bob, 9, 5, OUTLINE)
                        ellipse(img, 16, 22 + bob, 8, 4, body)
                        ellipse(img, 16, 14 + bob, 7, 7, OUTLINE)
                        ellipse(img, 16, 14 + bob, 6, 6, body)
                        _fill_polygon(img, [Vector2i(9, 11 + bob), Vector2i(10, 4 + bob), Vector2i(15, 10 + bob)], OUTLINE)
                        _fill_polygon(img, [Vector2i(17, 10 + bob), Vector2i(22, 4 + bob), Vector2i(23, 11 + bob)], OUTLINE)
                        _fill_polygon(img, [Vector2i(10, 10 + bob), Vector2i(11, 6 + bob), Vector2i(14, 10 + bob)], body)
                        _fill_polygon(img, [Vector2i(18, 10 + bob), Vector2i(21, 6 + bob), Vector2i(22, 10 + bob)], body)
                        ellipse(img, 16, 16 + bob, 4, 3, Color("#f4e3c3"))
                        # Tail with ember tip.
                        line(img, 24, 22 + bob, 29, 18 + bob, OUTLINE)
                        line(img, 23, 22 + bob, 28, 18 + bob, body)
                        ellipse(img, 29, 17 + bob, 2, 2, accent)
                        # Eyes and nose.
                        rect(img, 12, 13 + bob, 2, 2, OUTLINE)
                        rect(img, 18, 13 + bob, 2, 2, OUTLINE)
                        px(img, 12, 13 + bob, accent)
                        px(img, 18, 13 + bob, accent)
                        px(img, 16, 17 + bob, OUTLINE)
                        px(img, 16, 18 + bob, Color("#f4e3c3"))
                        # Legs.
                        rect(img, 11, 25 + bob, 3, 3, OUTLINE)
                        rect(img, 18, 25 + bob, 3, 3, OUTLINE)
                return _pet_pose(img, pet_id, frame))


static func _pet_pose(img: Image, pet_id: String, frame: int) -> Image:
        # Pose post-processing shared by every companion: blinks, the attack
        # leap, the downed curl and the happy bounce are cheap whole-image
        # transforms so each species keeps its hand-drawn body.
        var eyes: Array = {
                "ember": [Vector2i(12, 13), Vector2i(18, 13)],
                "moss": [Vector2i(12, 13), Vector2i(18, 13)],
                "luma": [Vector2i(15, 12), Vector2i(17, 12)],
        }.get(pet_id, [Vector2i(12, 13), Vector2i(19, 13)])
        match frame:
                2:
                        for e in eyes:
                                hline(img, e.x - 1, e.y, 4, OUTLINE)
                4:
                        var lifted := image(32, 32)
                        lifted.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(0, -3))
                        return lifted
                5:
                        var squashed := image(32, 20)
                        squashed.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(0, 4))
                        for e in eyes:
                                hline(squashed, e.x - 1, e.y + 4, 4, Color("#3a3038"))
                        return squashed
                6:
                        var happy := image(32, 32)
                        happy.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(0, -2))
                        px(happy, 5, 8, Color("#fff2b0"))
                        px(happy, 26, 6, Color("#fff2b0"))
                        px(happy, 24, 24, Color("#ffd47b"))
                        return happy
        return img


# ------------------------------------------------------------------ enemies

static func enemy_texture(kind: String, boss: bool = false, frame: int = 0) -> Texture2D:
        return cached_texture("enemy_%s_%s_%d" % [kind, str(boss), frame], func() -> Image:
                var size := 64 if boss else 32
                var img := image(size, size)
                var bob := 1 if frame % 2 == 0 else 0
                match kind:
                        "bogling":
                                var body := Color("#5b8c48") if not boss else Color("#47705b")
                                ellipse(img, 16, 22 + bob, 12, 8, Color("#1d2b21"))
                                ellipse(img, 16, 21 + bob, 11, 7, body)
                                ellipse(img, 16, 18 + bob, 8, 6, body.lightened(0.15))
                                rect(img, 10, 18 + bob, 3, 3, Color("#f2e6a3"))
                                rect(img, 19, 18 + bob, 3, 3, Color("#f2e6a3"))
                                px(img, 11, 19 + bob, OUTLINE)
                                px(img, 20, 19 + bob, OUTLINE)
                                hline(img, 14, 24 + bob, 5, Color("#273b28"))
                                # Drips.
                                px(img, 7, 26, body.darkened(0.2))
                                px(img, 24, 25, body.darkened(0.2))
                        "drowned":
                                rect(img, 12, 15, 9, 13, Color("#b9b39a"))
                                rect(img, 10, 16, 2, 12, Color("#777367"))
                                rect(img, 21, 16, 2, 12, Color("#777367"))
                                ellipse(img, 16, 10, 7, 7, Color("#d4ceb5"))
                                rect(img, 12, 10, 3, 3, Color("#64d4c0"))
                                rect(img, 18, 10, 3, 3, Color("#64d4c0"))
                                hline(img, 14, 15, 5, Color("#4b4941"))
                                line(img, 16, 4, 16, 1, Color("#6f8e88"))
                                line(img, 16, 19, 16, 28, Color("#777367"))
                        "grotto_warden":
                                rect(img, 17, 19, 30, 31, Color("#2b3537"))
                                rect(img, 20, 22, 24, 26, Color("#62756e"))
                                rect(img, 24, 15, 16, 15, Color("#2b3537"))
                                rect(img, 26, 17, 12, 11, Color("#869a8c"))
                                rect(img, 27, 21, 4, 3, Color("#b6ffe6"))
                                rect(img, 35, 21, 4, 3, Color("#b6ffe6"))
                                # Coral shoulders and fists.
                                ellipse(img, 11, 31, 7, 9, Color("#2b3537"))
                                ellipse(img, 53, 31, 7, 9, Color("#2b3537"))
                                line(img, 10, 27, 4, 16, Color("#c8bba1"))
                                line(img, 55, 27, 61, 15, Color("#c8bba1"))
                                line(img, 15, 44, 17, 52, Color("#a4957a"))
                                line(img, 48, 44, 46, 52, Color("#a4957a"))
                                hline(img, 26, 31, 13, Color("#2b3537"))
                        "drowned_king":
                                ellipse(img, 32, 30, 18, 20, Color("#22323a"))
                                rect(img, 19, 24, 26, 27, Color("#3f555c"))
                                ellipse(img, 32, 16, 11, 11, Color("#d3c9a6"))
                                _fill_polygon(img, [Vector2i(19, 10), Vector2i(24, 2), Vector2i(29, 9), Vector2i(32, 1), Vector2i(36, 9), Vector2i(42, 3), Vector2i(45, 11)], Color("#d6b75f"))
                                rect(img, 27, 15, 4, 3, Color("#83f2df"))
                                rect(img, 35, 15, 4, 3, Color("#83f2df"))
                                hline(img, 28, 23, 8, Color("#3b2d2d"))
                                line(img, 32, 34, 32, 50, Color("#d6b75f"))
                                line(img, 32, 38, 22, 33, Color("#8b7440"))
                                line(img, 32, 38, 42, 33, Color("#8b7440"))
                        "rubbish":
                                ellipse(img, 16, 24 + bob, 12, 6, Color("#20302a"))
                                ellipse(img, 16, 22 + bob, 11, 6, Color("#6f7e4d"))
                                # Cans, bottle and seaweed.
                                rect(img, 8, 17 + bob, 5, 7, Color("#9b6a3d"))
                                rect(img, 9, 18 + bob, 3, 5, Color("#d0a35e"))
                                rect(img, 17, 15 + bob, 4, 9, Color("#3c7d73"))
                                rect(img, 18, 13 + bob, 2, 3, Color("#d6e6d2"))
                                line(img, 12, 27 + bob, 8, 30, Color("#446b45"))
                                line(img, 20, 27 + bob, 24, 31, Color("#446b45"))
                                # Angry eyes.
                                rect(img, 12, 20 + bob, 3, 3, Color("#f2ebc0"))
                                rect(img, 18, 20 + bob, 3, 3, Color("#f2ebc0"))
                                px(img, 13, 21 + bob, OUTLINE)
                                px(img, 19, 21 + bob, OUTLINE)
                                hline(img, 13, 25 + bob, 6, OUTLINE)
                        "raider":
                                ellipse(img, 16, 24 + bob, 12, 7, Color("#1e1c23"))
                                ellipse(img, 16, 21 + bob, 10, 7, Color("#342b31"))
                                ellipse(img, 16, 15 + bob, 8, 7, Color("#47393e"))
                                _fill_polygon(img, [Vector2i(9, 11 + bob), Vector2i(10, 5 + bob), Vector2i(15, 11 + bob)], Color("#231e25"))
                                _fill_polygon(img, [Vector2i(17, 11 + bob), Vector2i(22, 5 + bob), Vector2i(23, 11 + bob)], Color("#231e25"))
                                rect(img, 11, 15 + bob, 3, 2, Color("#e06158"))
                                rect(img, 18, 15 + bob, 3, 2, Color("#e06158"))
                                hline(img, 13, 20 + bob, 6, Color("#d34e45"))
                                # Raider club.
                                line(img, 24, 27 + bob, 29, 16 + bob, Color("#5f422a"))
                                rect(img, 26, 13 + bob, 6, 5, Color("#3c3230"))
                        _:
                                if boss:
                                        _draw_generic_boss(img, kind, bob)
                                else:
                                        ellipse(img, size / 2, size / 2, 10, 10, Color("#9a5555"))
                return img)


static func _draw_generic_boss(img: Image, kind: String, bob: int) -> void:
        var palette: Array = {
                "reef_charger": [Color("#6b3c2f"), Color("#d88652"), Color("#ffd47b")],
                "brine_witch": [Color("#2e4e4e"), Color("#67b8a5"), Color("#d5ffe8")],
                "kelp_colossus": [Color("#2b4935"), Color("#5e9a58"), Color("#c8ea8a")],
                "bone_captain": [Color("#4a4740"), Color("#c7bd9b"), Color("#85f1dc")],
                "storm_hermit": [Color("#303c55"), Color("#738cc1"), Color("#b9e8ff")],
                "coral_tyrant": [Color("#593240"), Color("#bc5c69"), Color("#ffc0a0")],
                "abyss_warden": [Color("#211f36"), Color("#584a7c"), Color("#c79cff")],
                "abyss_sovereign": [Color("#1c1b2c"), Color("#4c4169"), Color("#f0c66b")],
        }.get(kind, [Color("#333333"), Color("#777777"), Color("#d8d8d8")])
        var body: Color = palette[0]
        var plate: Color = palette[1]
        var glow: Color = palette[2]
        ellipse(img, 32, 48, 19, 9, Color(0, 0, 0, 0.3))
        ellipse(img, 32, 36 + bob, 18, 20, OUTLINE)
        ellipse(img, 32, 35 + bob, 16, 17, body)
        rect(img, 18, 24 + bob, 28, 24, body)
        rect(img, 22, 28 + bob, 20, 16, plate)
        ellipse(img, 32, 17 + bob, 12, 12, OUTLINE)
        ellipse(img, 32, 16 + bob, 10, 10, plate)
        rect(img, 27, 17 + bob, 4, 3, glow)
        rect(img, 35, 17 + bob, 4, 3, glow)
        hline(img, 29, 24 + bob, 8, OUTLINE)
        # Crown / horns.
        _fill_polygon(img, [
                Vector2i(21, 12 + bob), Vector2i(25, 2 + bob), Vector2i(30, 10 + bob),
                Vector2i(34, 1 + bob), Vector2i(39, 10 + bob), Vector2i(43, 3 + bob),
                Vector2i(45, 13 + bob),
        ], glow.darkened(0.25))
        # Arms / fists.
        ellipse(img, 11, 43 + bob, 7, 10, OUTLINE)
        ellipse(img, 53, 43 + bob, 7, 10, OUTLINE)
        ellipse(img, 12, 43 + bob, 5, 8, body)
        ellipse(img, 52, 43 + bob, 5, 8, body)
        line(img, 12, 49 + bob, 10, 56 + bob, plate)
        line(img, 52, 49 + bob, 54, 56 + bob, plate)
        # Chest sigil.
        ellipse(img, 32, 34 + bob, 5, 5, glow.darkened(0.35))
        ellipse(img, 32, 34 + bob, 3, 3, glow)
        # A few armour notches.
        hline(img, 21, 39 + bob, 22, body.darkened(0.2))
        hline(img, 24, 44 + bob, 16, body.darkened(0.15))


# ------------------------------------------------------------------ environment

static func npc_texture(kind: String) -> Texture2D:
        return cached_texture("npc_%s" % kind, func() -> Image:
                var palette: Array = {
                        "potion": [Color("#4b7658"), Color("#badb9e"), Color("#6a3f2f")],
                        "equipment": [Color("#7b4535"), Color("#d8a06e"), Color("#4e2d25")],
                        "pet": [Color("#5a457a"), Color("#c5a5df"), Color("#3d2e53")],
                        "builder": [Color("#46627a"), Color("#a8c4d6"), Color("#2e4152")],
                        "guard": [Color("#2e4c63"), Color("#8fb7c8"), Color("#1e2e3a")],
                        "fisher": [Color("#3d6d6a"), Color("#a8d5c7"), Color("#27443f")],
                        "gardener": [Color("#5f743d"), Color("#d7c46e"), Color("#3b4a28")],
                        "carpenter": [Color("#755132"), Color("#cfaf7a"), Color("#40301f")],
                        "woodcutter": [Color("#5b4a35"), Color("#b9915b"), Color("#33291d")],
                        "keeper": [Color("#6e5b3d"), Color("#d9c89e"), Color("#403322")],
                        "farmer": [Color("#6d6438"), Color("#d8c477"), Color("#423b22")],
                        "trader": [Color("#6a4b5c"), Color("#d6a8bb"), Color("#432e3a")],
                        "defender": [Color("#3b5368"), Color("#a8c8d8"), Color("#26343f")],
                        "resident": [Color("#5b5967"), Color("#c7c2d6"), Color("#34323d")],
                        "student": [Color("#b08a20"), Color("#ffe06a"), Color("#5a4312")],
                }.get(kind, [Color("#5c5c5c"), Color("#c9c9c9"), Color("#333333")])
                var robe: Color = palette[0]
                var accent: Color = palette[1]
                var dark: Color = palette[2]
                var img := image(24, 36)
                ellipse(img, 12, 32, 8, 4, Color(0, 0, 0, 0.25))
                _fill_polygon(img, [Vector2i(6, 35), Vector2i(8, 17), Vector2i(16, 17), Vector2i(18, 35)], dark)
                _fill_polygon(img, [Vector2i(7, 34), Vector2i(9, 18), Vector2i(15, 18), Vector2i(17, 34)], robe)
                rect(img, 8, 24, 8, 3, accent.darkened(0.15))
                ellipse(img, 12, 12, 7, 7, dark)
                ellipse(img, 12, 12, 6, 6, Color("#d9b18b"))
                # Hood / hair.
                ellipse(img, 12, 8, 7, 5, dark)
                rect(img, 5, 9, 3, 8, dark)
                rect(img, 16, 9, 3, 8, dark)
                rect(img, 9, 11, 2, 2, OUTLINE)
                rect(img, 14, 11, 2, 2, OUTLINE)
                hline(img, 11, 16, 3, Color("#8a5a50"))
                # Apron / tool.
                rect(img, 9, 27, 6, 6, accent.lightened(0.1))
                if kind == "builder":
                        line(img, 19, 20, 21, 31, Color("#8a6239"))
                        rect(img, 18, 20, 5, 3, Color("#9ba5a5"))
                elif kind == "potion":
                        rect(img, 19, 25, 2, 4, Color("#c44755"))
                        px(img, 19, 24, Color("#d8d0ba"))
                elif kind == "pet":
                        ellipse(img, 19, 29, 3, 2, Color("#b9a3cf"))
                return img)


static func stall_texture(kind: String) -> Texture2D:
        return cached_texture("stall_%s" % kind, func() -> Image:
                var palette: Array = {
                        "potion": [Color("#4a7a57"), Color("#9fd08c"), Color("#d8c05d")],
                        "equipment": [Color("#7b4633"), Color("#d59a64"), Color("#b5b9b5")],
                        "pet": [Color("#594078"), Color("#b992d3"), Color("#d9b76a")],
                        "house": [Color("#555d63"), Color("#c9b98d"), Color("#91b6c4")],
                }.get(kind, [Color("#4f5e5e"), Color("#a5b9b5"), Color("#d2b276")])
                var wood: Color = palette[0]
                var cloth: Color = palette[1]
                var trim: Color = palette[2]
                var img := image(112, 96)
                # Shadow.
                ellipse(img, 56, 88, 45, 8, Color(0, 0, 0, 0.22))
                # Back posts.
                rect(img, 12, 22, 5, 64, Color("#3a271c"))
                rect(img, 95, 22, 5, 64, Color("#3a271c"))
                # Counter.
                rect(img, 8, 59, 96, 7, Color("#3b281d"))
                rect(img, 10, 62, 92, 18, wood.darkened(0.15))
                for x in range(12, 101, 10):
                        hline(img, x, 66, 8, wood.darkened(0.4))
                        hline(img, x, 72, 8, wood.darkened(0.28))
                hline(img, 9, 60, 94, trim.darkened(0.2))
                # Awning stripes.
                for i in 7:
                        var x := 5 + i * 15
                        var color := cloth if i % 2 == 0 else Color("#eee3c2")
                        rect(img, x, 15, 15, 13, color)
                        rect(img, x, 26, 15, 4, color.darkened(0.18))
                        hline(img, x, 15, 15, color.lightened(0.15))
                rect(img, 4, 13, 104, 4, Color("#35251c"))
                # Goods.
                match kind:
                        "potion":
                                for p in [Vector2i(24, 52), Vector2i(40, 50), Vector2i(58, 53), Vector2i(75, 51)]:
                                        rect(img, p.x, p.y + 5, 4, 2, Color("#d9d2b9"))
                                        ellipse(img, p.x + 2, p.y + 10, 4, 4, Color("#94313d"))
                                        ellipse(img, p.x + 2, p.y + 10, 3, 3, Color("#dd5761"))
                        "equipment":
                                line(img, 25, 57, 41, 41, Color("#d9dad2"))
                                line(img, 28, 58, 44, 42, Color("#78818a"))
                                line(img, 33, 48, 37, 52, Color("#c99a55"))
                                rect(img, 55, 44, 16, 12, Color("#777d7b"))
                                rect(img, 58, 47, 10, 6, Color("#b9c0ba"))
                                ellipse(img, 79, 50, 8, 8, Color("#7d5630"))
                                ellipse(img, 79, 50, 6, 6, Color("#b7864e"))
                        "pet":
                                rect(img, 21, 48, 18, 12, Color("#77523a"))
                                rect(img, 24, 50, 12, 8, Color("#cda778"))
                                ellipse(img, 59, 51, 6, 4, Color("#b9a0ce"))
                                ellipse(img, 70, 51, 6, 4, Color("#b9a0ce"))
                                ellipse(img, 64, 50, 4, 4, Color("#e2d3f1"))
                                rect(img, 83, 45, 8, 13, Color("#c44755"))
                                rect(img, 85, 42, 4, 4, Color("#d8d0ba"))
                        "house":
                                # Blueprint roll, ruler and a small timber sample.
                                rect(img, 20, 43, 24, 14, Color("#e7ddc2"))
                                rect(img, 22, 45, 20, 3, Color("#678aa0"))
                                rect(img, 22, 50, 12, 2, Color("#678aa0"))
                                rect(img, 54, 46, 24, 6, Color("#c9a45c"))
                                rect(img, 54, 50, 24, 2, Color("#8d6834"))
                                rect(img, 83, 43, 5, 16, Color("#d8c38b"))
                                for y in range(45, 58, 4):
                                        hline(img, 83, y, 5, Color("#7f6b4b"))
                return img)


static func shop_interior_texture(kind: String) -> Texture2D:
        return cached_texture("shop_interior_%s" % kind, func() -> Image:
                var palette: Array = {
                        "potion": [Color("#2a3d2f"), Color("#1c2a20"), Color("#4a7a57"), Color("#d8c05d")],
                        "equipment": [Color("#3a2a22"), Color("#241a15"), Color("#7b4633"), Color("#d59a64")],
                        "pet": [Color("#332a44"), Color("#221b30"), Color("#594078"), Color("#d9b76a")],
                        "house": [Color("#2e3540"), Color("#1e232b"), Color("#555d63"), Color("#91b6c4")],
                }.get(kind, [Color("#333333"), Color("#222222"), Color("#555555"), Color("#aaaaaa")])
                var wall: Color = palette[0]
                var wall_dark: Color = palette[1]
                var wood: Color = palette[2]
                var trim: Color = palette[3]
                var img := image(448, 84)
                # Back wall with plank lines.
                rect(img, 0, 0, 448, 62, wall)
                for y in range(6, 62, 10):
                        hline(img, 0, y, 448, wall_dark)
                # Floor.
                rect(img, 0, 62, 448, 22, wall_dark)
                hline(img, 0, 62, 448, wood.darkened(0.3))
                for x in range(4, 448, 18):
                        vline(img, x, 63, 21, Color(0, 0, 0, 0.14))
                # Two shelf planks with goods.
                for sy in [22, 42]:
                        rect(img, 24, sy, 168, 3, wood.darkened(0.25))
                        hline(img, 24, sy, 168, trim.darkened(0.15))
                        for sx in range(30, 186, 22):
                                match kind:
                                        "potion":
                                                rect(img, sx, sy - 9, 4, 2, Color("#d9d2b9"))
                                                ellipse(img, sx + 2, sy - 4, 4, 4, Color("#94313d") if (sx / 2) % 2 else Color("#3d6bb0"))
                                        "equipment":
                                                line(img, sx, sy - 1, sx + 4, sy - 10, Color("#d9dad2"))
                                                line(img, sx + 1, sy - 1, sx + 5, sy - 10, Color("#78818a"))
                                        "pet":
                                                ellipse(img, sx + 2, sy - 5, 5, 4, Color("#b9a0ce") if (sx / 2) % 2 else Color("#cda778"))
                                        "house":
                                                rect(img, sx, sy - 8, 12, 8, Color("#e7ddc2"))
                                                hline(img, sx, sy - 5, 12, Color("#678aa0"))
                # Hanging goods from a top rail.
                rect(img, 232, 2, 150, 3, wood.darkened(0.4))
                for hx in range(242, 376, 26):
                        line(img, hx, 5, hx, 14, Color("#8a7a5c"))
                        match kind:
                                "potion":
                                        ellipse(img, hx, 20, 4, 5, Color("#94313d"))
                                "equipment":
                                        line(img, hx - 5, 16, hx + 5, 24, Color("#b9c0ba"))
                                "pet":
                                        ellipse(img, hx, 19, 5, 3, Color("#c5a5df"))
                                "house":
                                        rect(img, hx - 6, 15, 12, 5, Color("#c9a45c"))
                # Counter across the front with a lamp.
                rect(img, 0, 66, 448, 10, wood)
                hline(img, 0, 66, 448, trim)
                rect(img, 390, 46, 14, 20, wood.darkened(0.35))
                ellipse(img, 397, 44, 7, 7, trim.darkened(0.2))
                ellipse(img, 397, 44, 4, 4, Color("#ffe28a"))
                # A window with light on the far left.
                rect(img, 8, 12, 40, 26, wall_dark.darkened(0.2))
                rect(img, 11, 15, 34, 20, Color("#cfe3d2") if kind == "potion" else Color("#d8cfb0"))
                vline(img, 28, 15, 20, wall_dark)
                hline(img, 11, 25, 34, wall_dark)
                return img)


static func shopkeeper_bust(kind: String, blink := false) -> Texture2D:
        return cached_texture("bust_%s_%s" % [kind, str(blink)], func() -> Image:
                var palette: Array = {
                        "potion": [Color("#4b7658"), Color("#badb9e"), Color("#6a3f2f")],
                        "equipment": [Color("#7b4535"), Color("#d8a06e"), Color("#4e2d25")],
                        "pet": [Color("#5a457a"), Color("#c5a5df"), Color("#3d2e53")],
                        "house": [Color("#46627a"), Color("#a8c4d6"), Color("#2e4152")],
                }.get(kind, [Color("#5c5c5c"), Color("#c9c9c9"), Color("#333333")])
                var robe: Color = palette[0]
                var accent: Color = palette[1]
                var dark: Color = palette[2]
                var img := image(72, 88)
                # Shoulders.
                ellipse(img, 36, 84, 32, 22, dark)
                ellipse(img, 36, 82, 28, 19, robe)
                rect(img, 26, 72, 20, 6, accent.darkened(0.15))
                # Neck and head.
                rect(img, 32, 60, 8, 8, Color("#d9b18b"))
                ellipse(img, 36, 42, 17, 19, OUTLINE)
                ellipse(img, 36, 42, 15, 17, Color("#d9b18b"))
                # Hair / hood.
                ellipse(img, 36, 30, 16, 11, dark)
                rect(img, 20, 32, 6, 14, dark)
                rect(img, 46, 32, 6, 14, dark)
                # Face: eyes (blink state), brows, mouth.
                if blink:
                        hline(img, 26, 44, 7, OUTLINE)
                        hline(img, 39, 44, 7, OUTLINE)
                else:
                        rect(img, 27, 41, 5, 4, Color.WHITE)
                        rect(img, 40, 41, 5, 4, Color.WHITE)
                        px(img, 29, 42, OUTLINE)
                        px(img, 42, 42, OUTLINE)
                        hline(img, 26, 38, 6, dark.darkened(0.1))
                        hline(img, 40, 38, 6, dark.darkened(0.1))
                hline(img, 32, 51, 9, Color("#8a5a50"))
                # Apron hint and hands on the counter.
                rect(img, 24, 74, 24, 12, accent.lightened(0.1))
                ellipse(img, 22, 86, 6, 4, Color("#d9b18b"))
                ellipse(img, 50, 86, 6, 4, Color("#d9b18b"))
                # Per-keeper prop silhouettes (animated by ShopScene on top).
                match kind:
                        "equipment":
                                line(img, 56, 66, 64, 50, Color("#5b3c24"))
                                rect(img, 58, 44, 10, 8, Color("#8b9694"))
                        "potion":
                                ellipse(img, 58, 74, 6, 5, Color("#94313d"))
                                ellipse(img, 58, 74, 3, 2, Color("#dd5761"))
                        "pet":
                                ellipse(img, 58, 76, 6, 4, Color("#b9a0ce"))
                        "house":
                                rect(img, 54, 68, 16, 10, Color("#e7ddc2"))
                                hline(img, 54, 72, 16, Color("#678aa0"))
                return img)


static func portal_texture(portal_id: String) -> Texture2D:
        return cached_texture("portal_%s" % portal_id, func() -> Image:
                var img := image(80, 112)
                var stone := Color("#596563")
                var stone_light := Color("#88918b")
                var stone_dark := Color("#303b3b")
                var glow := Color("#9a6ae0") if portal_id == "tidebound_grotto" else Color("#4fc8c4")
                ellipse(img, 40, 108, 38, 5, Color(0, 0, 0, 0.25))
                # Pillars.
                rect(img, 10, 30, 17, 76, stone_dark)
                rect(img, 13, 32, 11, 72, stone)
                rect(img, 15, 36, 3, 64, stone_light)
                rect(img, 53, 30, 17, 76, stone_dark)
                rect(img, 56, 32, 11, 72, stone)
                rect(img, 58, 36, 3, 64, stone_light)
                for y in range(38, 98, 13):
                        hline(img, 11, y, 15, stone_dark)
                        hline(img, 54, y, 15, stone_dark)
                # Arch.
                rect(img, 8, 20, 64, 14, stone_dark)
                rect(img, 12, 22, 56, 9, stone)
                rect(img, 17, 24, 46, 3, stone_light)
                # Portal interior.
                ellipse(img, 40, 58, 20, 36, Color("#1a1425"))
                ellipse(img, 40, 58, 18, 34, glow.darkened(0.55))
                ellipse(img, 40, 58, 14, 29, glow.darkened(0.25))
                ellipse(img, 40, 58, 8, 20, glow)
                # Rune marks.
                for x in [17, 62]:
                        px(img, x, 60, glow.lightened(0.35))
                        px(img, x, 67, glow.lightened(0.35))
                        px(img, x - 1, 63, glow.darkened(0.2))
                # Steps.
                rect(img, 6, 101, 68, 7, stone_dark)
                rect(img, 12, 96, 56, 7, stone)
                return img)


static func portal_theme_palette(theme_id: String) -> Dictionary:
        # One palette per PortalDB theme. No portal-id special cases anywhere.
        var table := {
                "grotto": {"stone": "#5a6a72", "stone_light": "#8b9aa0", "glow": "#9a6ae0", "glow_light": "#d6b9ff", "mote": "#c9a8ff"},
                "crypt": {"stone": "#5c6470", "stone_light": "#8f97a4", "glow": "#64c8e8", "glow_light": "#b8f0ff", "mote": "#9fe0f0"},
                "reef": {"stone": "#6b5a52", "stone_light": "#a08a76", "glow": "#ff8a5c", "glow_light": "#ffc9a0", "mote": "#ffb08a"},
                "brine": {"stone": "#586a5e", "stone_light": "#8aa492", "glow": "#67b8a5", "glow_light": "#d5ffe8", "mote": "#a8e8d0"},
                "kelp": {"stone": "#54624e", "stone_light": "#84966e", "glow": "#5e9a58", "glow_light": "#c8ea8a", "mote": "#b0d888"},
                "bone": {"stone": "#6a655c", "stone_light": "#a89f8c", "glow": "#85f1dc", "glow_light": "#d8fff4", "mote": "#e8e2c8"},
                "storm": {"stone": "#4e5a70", "stone_light": "#7e8ca8", "glow": "#8fe8ff", "glow_light": "#d8f4ff", "mote": "#b9e8ff"},
                "coral": {"stone": "#6a5260", "stone_light": "#a4828f", "glow": "#ff7f9c", "glow_light": "#ffc0d0", "mote": "#ffa8b8"},
                "abyss": {"stone": "#4a4a60", "stone_light": "#7a7a9c", "glow": "#8a72d8", "glow_light": "#c9c2ff", "mote": "#b0a8e8"},
                "throne": {"stone": "#5e5a4e", "stone_light": "#9a9482", "glow": "#f0c66b", "glow_light": "#ffe8a8", "mote": "#ffd88a"},
                "pet": {"stone": "#4e6a72", "stone_light": "#84aab4", "glow": "#4fc8c4", "glow_light": "#a8f5ea", "mote": "#8fe8e0"},
        }
        var data: Dictionary = table.get(theme_id, table["grotto"]) as Dictionary
        return {
                "stone": Color(str(data.get("stone", "#5a6a72"))),
                "stone_light": Color(str(data.get("stone_light", "#8b9aa0"))),
                "glow": Color(str(data.get("glow", "#9a6ae0"))),
                "glow_light": Color(str(data.get("glow_light", "#d6b9ff"))),
                "mote": Color(str(data.get("mote", "#c9a8ff"))),
        }


static func portal_frame_texture(theme_id: String, locked := false) -> Texture2D:
        # The static stone arch. The locked variant is sealed: darker stone, a slab
        # where the swirl would be and chains across the opening.
        return cached_texture("portal_frame_%s_%s" % [theme_id, str(locked)], func() -> Image:
                var palette := portal_theme_palette(theme_id)
                var stone: Color = palette["stone"]
                var stone_light: Color = palette["stone_light"]
                var stone_dark := (palette["stone"] as Color).darkened(0.42)
                var img := image(80, 112)
                if locked:
                        stone = stone.darkened(0.25)
                        stone_light = stone_light.darkened(0.3)
                ellipse(img, 40, 108, 38, 5, Color(0, 0, 0, 0.25))
                # Pillars with theme-tinted stone.
                for side in [Vector2i(10, 0), Vector2i(53, 0)]:
                        rect(img, side.x, 30, 17, 76, stone_dark)
                        rect(img, side.x + 3, 32, 11, 72, stone)
                        rect(img, side.x + 5, 36, 3, 64, stone_light)
                        for y in range(38, 98, 13):
                                hline(img, side.x + 1, y, 15, stone_dark)
                # Arch.
                rect(img, 8, 20, 64, 14, stone_dark)
                rect(img, 12, 22, 56, 9, stone)
                rect(img, 17, 24, 46, 3, stone_light)
                # Keystone sigil glowing with the theme colour.
                rect(img, 36, 14, 8, 9, stone_dark)
                var sigil: Color = (palette["glow"] as Color).darkened(0.2) if not locked else Color("#3a4147")
                ellipse(img, 40, 18, 3, 3, sigil)
                px(img, 40, 17, Color.WHITE if not locked else Color("#555c62"))
                if locked:
                        # Sealed slab and chains.
                        ellipse(img, 40, 58, 19, 35, Color("#232a2e"))
                        ellipse(img, 40, 58, 17, 33, stone.darkened(0.5))
                        for y in [40, 56, 72]:
                                for x in range(22, 58):
                                        if int(sin(float(x) * 0.5 + float(y)) * 2.0) == 0:
                                                px(img, x, y + int(sin(float(x) * 0.3) * 2.0), Color("#7d8590"))
                        hline(img, 24, 47, 32, Color("#6a727c"))
                        hline(img, 24, 66, 32, Color("#6a727c"))
                # Steps.
                rect(img, 6, 101, 68, 7, stone_dark)
                rect(img, 12, 96, 56, 7, stone)
                return img)


static func portal_swirl_texture(theme_id: String, frame: int) -> Texture2D:
        # Eight baked frames of a rotating spiral interior, cycled at ~9 fps.
        return cached_texture("portal_swirl_%s_%d" % [theme_id, frame], func() -> Image:
                var palette := portal_theme_palette(theme_id)
                var glow: Color = palette["glow"]
                var glow_light: Color = palette["glow_light"]
                var img := image(48, 76)
                # Interior void.
                ellipse(img, 24, 38, 22, 34, Color("#141020"))
                ellipse(img, 24, 38, 20, 32, glow.darkened(0.62))
                # Rotating spiral arms: phase advances a quarter turn per frame pair.
                var phase := TAU * float(frame) / 8.0
                for arm in 3:
                        var arm_phase := phase + TAU * float(arm) / 3.0
                        for step in 14:
                                var t := float(step) / 13.0
                                var r := 2.0 + t * 17.0
                                var a := arm_phase + t * 3.4
                                var cx := 24.0 + cos(a) * r
                                var cy := 38.0 + sin(a) * r * 1.55
                                var col := glow_light if step % 4 == 0 else glow
                                px(img, int(cx), int(cy), col)
                                if step % 4 == 0:
                                        px(img, int(cx + 1), int(cy), Color(col.r, col.g, col.b, 0.6))
                # Bright heart.
                ellipse(img, 24, 38, 4, 7, glow)
                ellipse(img, 24, 38, 2, 3, glow_light)
                px(img, 24, 37, Color.WHITE)
                return img)


static func portal_emblem_texture(theme_id: String) -> Texture2D:
        # Boss-arena floor emblem: a rune ring in the portal theme.
        return cached_texture("portal_emblem_%s" % theme_id, func() -> Image:
                var palette := portal_theme_palette(theme_id)
                var glow: Color = palette["glow"]
                var img := image(96, 48)
                ellipse_outline(img, 48, 24, 42, 19, glow.darkened(0.25))
                ellipse_outline(img, 48, 24, 34, 14, glow.darkened(0.45))
                for i in 8:
                        var a := TAU * float(i) / 8.0
                        px(img, 48 + int(cos(a) * 38.0), 24 + int(sin(a) * 17.0), glow.lightened(0.25))
                        px(img, 48 + int(cos(a) * 30.0), 24 + int(sin(a) * 12.0), Color.WHITE if i % 2 == 0 else glow)
                ellipse(img, 48, 24, 5, 3, glow.lightened(0.3))
                return img)


static func house_texture(level: int) -> Texture2D:
        return cached_texture("house_%d" % level, func() -> Image:
                var lvl := clampi(level, 1, 5)
                var img := image(224, 176)
                var width := 102 + (lvl - 1) * 15
                var wall_h := 55 + (lvl - 1) * 6
                var base_y := 151
                var wall_top := base_y - wall_h
                var roof_h := 38 + (lvl - 1) * 4
                var roof_top := wall_top - roof_h
                var left := 112 - width / 2
                var right := left + width
                var shadow_alpha := 0.26
                ellipse(img, 112, base_y + 4, width / 2 + 12, 10, Color(0, 0, 0, shadow_alpha))
                var wall := Color("#6d4a30") if lvl > 1 else Color("#4e392a")
                var wall_dark := Color("#38271d")
                var wall_light := Color("#8c613b")
                var roof := Color("#47413b") if lvl <= 2 else Color("#5b4639")
                var roof_dark := Color("#282725")
                var roof_light := Color("#8d6a4e")
                # Foundation / porch.
                rect(img, left - 4, base_y - 7, width + 8, 8, wall_dark)
                rect(img, left, base_y - 10, width, 4, wall_light.darkened(0.3))
                # Wall body.
                rect(img, left, wall_top, width, wall_h, wall_dark)
                rect(img, left + 2, wall_top + 2, width - 4, wall_h - 3, wall)
                for y in range(wall_top + 5, base_y - 7, 6):
                        hline(img, left + 2, y, width - 4, wall_dark)
                        if lvl >= 3:
                                hline(img, left + 3, y + 1, width - 6, wall_light.darkened(0.15))
                # Vertical corner beams.
                rect(img, left, wall_top, 5, wall_h, wall_dark)
                rect(img, right - 5, wall_top, 5, wall_h, wall_dark)
                # Roof silhouette: stepped gable with shingles.
                for row in range(roof_h):
                        var span := int(round(float(width + 20) * (float(row) / float(roof_h))))
                        var rx := 112 - span / 2
                        var y := roof_top + row
                        hline(img, rx, y, span, roof_dark)
                        if row >= 2:
                                hline(img, rx + 2, y, maxi(1, span - 4), roof)
                        if row % 4 == 0 and row > 3:
                                hline(img, rx + 4, y, maxi(1, span - 8), roof_light.darkened(0.18))
                hline(img, left - 10, wall_top - 1, width + 20, roof_dark)
                # Door.
                var door_w := 18 if lvl < 4 else 22
                var door_h := mini(wall_h - 10, 34 if lvl < 4 else 40)
                rect(img, 112 - door_w / 2, base_y - door_h - 5, door_w, door_h, Color("#2b1c17"))
                rect(img, 112 - door_w / 2 + 2, base_y - door_h - 4, door_w - 4, door_h - 2, Color("#6e4529"))
                rect(img, 112 - 1, base_y - door_h / 2 - 5, 2, 2, Color("#e4bb62"))
                if lvl == 1:
                        # Board over the door, missing shingles.
                        rect(img, 102, base_y - 26, 24, 4, Color("#8a633c"))
                        for p in [Vector2i(63, roof_top + 15), Vector2i(78, roof_top + 19), Vector2i(141, roof_top + 22), Vector2i(154, roof_top + 14)]:
                                rect(img, p.x, p.y, 5, 3, Color(0, 0, 0, 0))
                # Windows.
                var window_y := wall_top + 16
                for wx in [left + 16, right - 28]:
                        rect(img, wx, window_y, 13, 13, Color("#2d1e18"))
                        var glass := Color("#e8c56b") if lvl >= 3 else Color("#3e5559")
                        rect(img, wx + 2, window_y + 2, 9, 9, glass)
                        hline(img, wx + 6, window_y + 2, 2, Color("#3a2b22"))
                        vline(img, wx + 2, window_y + 6, 2, Color("#3a2b22"))
                        rect(img, wx - 2, window_y + 13, 17, 3, wall_light)
                # Porch deck and posts.
                if lvl >= 2:
                        rect(img, 112 - 31, base_y - 9, 62, 6, Color("#a17446"))
                        for x in range(112 - 30, 112 + 31, 7):
                                vline(img, x, base_y - 8, 5, Color("#6f4c2d"))
                        rect(img, 112 - 34, base_y - 12, 6, 12, wall_dark)
                        rect(img, 112 + 28, base_y - 12, 6, 12, wall_dark)
                        # Steps.
                        rect(img, 100, base_y + 4, 24, 3, Color("#8b643f"))
                        rect(img, 96, base_y + 7, 32, 3, Color("#6f4c2d"))
                # Chimney and smoke.
                if lvl >= 3:
                        rect(img, right - 24, roof_top + 2, 12, 22, Color("#4b403b"))
                        rect(img, right - 21, roof_top - 6, 7, 11, Color("#5f5148"))
                        rect(img, right - 22, roof_top - 8, 9, 4, Color("#2b2825"))
                        for i in 3:
                                ellipse(img, right - 18 + i * 3, roof_top - 14 - i * 7, 3 + i, 2 + i, Color(0.75, 0.8, 0.78, 0.10 + i * 0.03))
                # Flower boxes and garden.
                if lvl >= 3:
                        for wx in [left + 14, right - 30]:
                                rect(img, wx, window_y + 15, 17, 4, Color("#6f4a2d"))
                                for i in 3:
                                        px(img, wx + 3 + i * 5, window_y + 13, Color("#e7b955"))
                                        px(img, wx + 4 + i * 5, window_y + 12, Color("#e57171"))
                if lvl >= 4:
                        # White fence.
                        for x in range(left - 22, right + 23, 9):
                                rect(img, x, base_y + 5, 3, 12, Color("#d8d0b8"))
                                px(img, x + 1, base_y + 4, Color("#eee7d2"))
                        hline(img, left - 22, base_y + 9, width + 45, Color("#c9bea2"))
                        # Garden bushes.
                        for p in [Vector2i(left - 18, base_y + 2), Vector2i(right + 14, base_y + 1), Vector2i(right + 26, base_y + 4)]:
                                ellipse(img, p.x, p.y, 6, 4, Color("#3e673f"))
                                ellipse(img, p.x - 1, p.y - 2, 4, 3, Color("#56834e"))
                if lvl >= 5:
                        # Lanterns on the porch and fresh paint details.
                        for x in [left + 9, right - 13]:
                                vline(img, x, roof_top + 14, 4, Color("#2e2a24"))
                                rect(img, x - 3, roof_top + 18, 7, 8, Color("#2e2a24"))
                                rect(img, x - 2, roof_top + 19, 5, 6, Color("#ffd77a"))
                        rect(img, 108, base_y - 4, 8, 3, Color("#e7c56a"))
                        hline(img, left + 2, wall_top + 3, width - 4, Color("#b58454"))
                # Weeds / damage for level 1.
                if lvl == 1:
                        for p in [Vector2i(left + 6, base_y - 4), Vector2i(right - 12, base_y - 6), Vector2i(left + 34, base_y - 3), Vector2i(right - 42, base_y - 8)]:
                                line(img, p.x, p.y, p.x - 2, p.y - 6, Color("#6b7343"))
                                line(img, p.x, p.y, p.x + 2, p.y - 5, Color("#8b8a4f"))
                        # Crack in the wall.
                        line(img, left + 7, wall_top + 12, left + 12, wall_top + 20, Color("#2d2119"))
                        line(img, left + 12, wall_top + 20, left + 9, wall_top + 27, Color("#2d2119"))
                # Warm window light at night is handled by the scene with a glow sprite.
                return img)


static func ship_texture() -> Texture2D:
        return cached_texture("ship", func() -> Image:
                var img := image(208, 128)
                var hull := Color("#5b3c26")
                var hull_dark := Color("#352319")
                var hull_light := Color("#8b5f3a")
                ellipse(img, 104, 113, 76, 7, Color(0, 0, 0, 0.24))
                # Hull.
                _fill_polygon(img, [Vector2i(28, 82), Vector2i(180, 82), Vector2i(160, 111), Vector2i(48, 111)], hull_dark)
                _fill_polygon(img, [Vector2i(32, 84), Vector2i(176, 84), Vector2i(156, 106), Vector2i(52, 106)], hull)
                hline(img, 40, 90, 128, hull_light)
                hline(img, 44, 97, 120, hull_dark)
                # Bowsprit.
                line(img, 178, 82, 200, 67, Color("#3c291c"))
                # Mast.
                rect(img, 101, 16, 5, 69, Color("#3b281b"))
                rect(img, 96, 84, 15, 4, Color("#2a1c14"))
                # Sails.
                _fill_polygon(img, [Vector2i(106, 20), Vector2i(168, 41), Vector2i(106, 67)], Color("#d9caa7"))
                _fill_polygon(img, [Vector2i(100, 29), Vector2i(49, 51), Vector2i(100, 74)], Color("#c5b28e"))
                line(img, 106, 22, 162, 41, Color("#f0e4c8"))
                line(img, 100, 31, 55, 51, Color("#f0e4c8"))
                for y in range(31, 64, 9):
                        hline(img, 107, y, 48 - (y - 31), Color("#b09c7b"))
                # Ropes.
                line(img, 104, 18, 38, 83, Color("#7b6850"))
                line(img, 104, 18, 174, 83, Color("#7b6850"))
                # Flag.
                _fill_polygon(img, [Vector2i(101, 16), Vector2i(101, 5), Vector2i(122, 10)], Color("#b04848"))
                # Lanterns.
                for x in [58, 145]:
                        rect(img, x, 75, 7, 9, Color("#2f241c"))
                        rect(img, x + 2, 77, 3, 5, Color("#ffd981"))
                return img)


static func dock_texture() -> Texture2D:
        return cached_texture("dock", func() -> Image:
                var img := image(256, 96)
                var wood := Color("#88613d")
                var dark := Color("#553b28")
                var light := Color("#b08452")
                for row in 4:
                        var y := 8 + row * 18
                        for x in range(8, 248, 30):
                                rect(img, x, y, 28, 16, dark)
                                rect(img, x + 1, y + 1, 26, 14, wood)
                                hline(img, x + 3, y + 5, 20, light.darkened(0.1))
                                hline(img, x + 3, y + 11, 20, dark.lightened(0.1))
                                px(img, x + 5, y + 8, Color("#4b3524"))
                # Posts and rope.
                for x in [16, 78, 142, 206, 240]:
                        rect(img, x, 2, 8, 88, dark)
                        rect(img, x + 2, 3, 4, 84, wood.lightened(0.1))
                        ellipse(img, x + 4, 5, 5, 4, Color("#4d5b59"))
                # Mooring rope.
                line(img, 240, 12, 228, 34, Color("#b9a47b"))
                line(img, 228, 34, 232, 56, Color("#b9a47b"))
                return img)


static func bed_texture() -> Texture2D:
        return cached_texture("bed", func() -> Image:
                var img := image(64, 40)
                ellipse(img, 32, 35, 26, 5, Color(0, 0, 0, 0.22))
                rect(img, 6, 12, 52, 20, Color("#4a3021"))
                rect(img, 9, 14, 46, 15, Color("#7b5438"))
                rect(img, 10, 14, 44, 7, Color("#dad0bb"))
                rect(img, 12, 15, 40, 5, Color("#f1e7d1"))
                rect(img, 12, 22, 40, 5, Color("#7c4d57"))
                hline(img, 12, 25, 40, Color("#9e6670"))
                rect(img, 5, 10, 5, 27, Color("#3a261a"))
                rect(img, 54, 10, 5, 27, Color("#3a261a"))
                return img)


static func loot_texture(kind: String) -> Texture2D:
        match kind:
                "gold":
                        return icon("gold", 16)
                "diamond":
                        return icon("diamond", 16)
                _:
                        return icon("spark", 16)


static func grass_tuft_texture() -> Texture2D:
        return cached_texture("grass_tuft", func() -> Image:
                var img := image(16, 12)
                for p in [Vector2i(3, 10), Vector2i(6, 9), Vector2i(9, 10), Vector2i(12, 8), Vector2i(4, 6), Vector2i(10, 5)]:
                        line(img, p.x, p.y, p.x - 1, p.y - 5, Color("#5f793c"))
                        line(img, p.x, p.y, p.x + 1, p.y - 6, Color("#728c47"))
                return img)


static func slash_arc_texture(kind: String) -> Texture2D:
        return cached_texture("slash_arc_%s" % kind, func() -> Image:
                var img := image(64, 64)
                match kind:
                        "lr":
                                # Crescent sweeping left-to-right.
                                for i in 22:
                                        var a := deg_to_rad(-70.0 + i * 5.2)
                                        var r := 20.0 + sin(float(i) / 22.0 * PI) * 9.0
                                        var p := Vector2i(14 + int(cos(a) * r), 32 + int(sin(a) * r))
                                        ellipse(img, p.x, p.y, 2, 2, Color(1.0, 0.97, 0.72, 0.9 - float(i) * 0.012))
                                        px(img, p.x, p.y - 1, Color(1, 1, 1, 0.95))
                                for i in 12:
                                        var a := deg_to_rad(-58.0 + i * 4.4)
                                        var p := Vector2i(14 + int(cos(a) * 13.0), 32 + int(sin(a) * 13.0))
                                        px(img, p.x, p.y, Color(1.0, 0.9, 0.55, 0.55))
                        "rl":
                                for i in 22:
                                        var a := deg_to_rad(10.0 + i * 5.2)
                                        var r := 20.0 + sin(float(i) / 22.0 * PI) * 9.0
                                        var p := Vector2i(50 - int(cos(a) * r), 32 + int(sin(a) * r))
                                        ellipse(img, p.x, p.y, 2, 2, Color(1.0, 0.97, 0.72, 0.9 - float(i) * 0.012))
                                        px(img, p.x, p.y - 1, Color(1, 1, 1, 0.95))
                                for i in 12:
                                        var a := deg_to_rad(22.0 + i * 4.4)
                                        var p := Vector2i(50 - int(cos(a) * 13.0), 32 + int(sin(a) * 13.0))
                                        px(img, p.x, p.y, Color(1.0, 0.9, 0.55, 0.55))
                        "thrust":
                                # Forward streak with a bright tip.
                                for i in 16:
                                        var x := 8 + i * 3
                                        ellipse(img, x, 32, 2 if i < 12 else 3, 2, Color(1.0, 0.98, 0.8, 0.35 + float(i) * 0.04))
                                ellipse(img, 56, 32, 4, 3, Color(1, 1, 0.95, 0.95))
                                px(img, 54, 30, Color.WHITE)
                                px(img, 58, 33, Color.WHITE)
                        "slam":
                                # Downward crush burst.
                                for i in 20:
                                        var a := -PI * 0.5 + (float(i) / 19.0 - 0.5) * 2.4
                                        var r := 14.0 + absf(sin(float(i) / 19.0 * PI)) * 8.0
                                        var p := Vector2i(32 + int(cos(a) * r), 18 + int(sin(a) * r * 1.6))
                                        ellipse(img, p.x, p.y, 2, 3, Color(1.0, 0.85, 0.5, 0.9))
                                for i in 26:
                                        var x := 8 + i * 2
                                        hline(img, x, 52 + (2 if i % 3 == 0 else 0), 2, Color(0.85, 0.7, 0.45, 0.5))
                        "shot":
                                # Bow release flash.
                                ellipse(img, 18, 32, 3, 6, Color(1.0, 0.95, 0.75, 0.9))
                                for i in 10:
                                        var x := 24 + i * 3
                                        hline(img, x, 32, 1, Color(1, 0.95, 0.7, 0.6 - float(i) * 0.05))
                return img)


static func vignette_texture() -> Texture2D:
        return cached_texture("vignette", func() -> Image:
                var size := 320
                var img := image(size, size)
                var centre := Vector2(size * 0.5, size * 0.5)
                for y in size:
                        for x in size:
                                var d := Vector2(x + 0.5, y + 0.5).distance_to(centre) / (size * 0.5)
                                var a := clampf((d - 0.55) / 0.45, 0.0, 1.0)
                                if a > 0.0:
                                        img.set_pixel(x, y, Color(0.72, 0.1, 0.12, a * a * 0.85))
                return img)


static func slash_texture() -> Texture2D:
        return cached_texture("slash", func() -> Image:
                var img := image(64, 64)
                for i in 18:
                        var a := deg_to_rad(-55.0 + i * 6.0)
                        var r := 22.0 + sin(float(i) / 18.0 * PI) * 8.0
                        var p := Vector2i(12 + int(cos(a) * r), 32 + int(sin(a) * r))
                        ellipse(img, p.x, p.y, 2, 2, Color(1.0, 0.95, 0.65, 0.85))
                        px(img, p.x, p.y - 1, Color(1, 1, 1, 0.9))
                return img)


static func arrow_texture() -> Texture2D:
        return cached_texture("arrow", func() -> Image:
                var img := image(24, 8)
                hline(img, 2, 4, 15, Color("#c9ad74"))
                hline(img, 2, 3, 15, Color("#8a6a3d"))
                _fill_polygon(img, [Vector2i(16, 1), Vector2i(23, 4), Vector2i(16, 7)], Color("#cfd8d4"))
                line(img, 3, 4, 1, 1, Color("#e7dcc4"))
                line(img, 3, 4, 1, 7, Color("#e7dcc4"))
                return img)


static func rubbish_texture(frame: int = 0) -> Texture2D:
        return cached_texture("rubbish_%d" % frame, func() -> Image:
                var img := image(16, 16)
                var bob := 1 if frame % 2 == 0 else 0
                rect(img, 4, 6 + bob, 6, 7, Color("#8a643c"))
                rect(img, 5, 5 + bob, 4, 2, Color("#d1c7a1"))
                rect(img, 7, 3 + bob, 3, 4, Color("#5c8a81"))
                rect(img, 10, 8 + bob, 4, 5, Color("#b04f4f"))
                line(img, 2, 12 + bob, 13, 12 + bob, Color("#7d8b6a"))
                return img)


static func fence_texture() -> Texture2D:
        return cached_texture("fence", func() -> Image:
                var img := image(48, 32)
                rect(img, 2, 5, 5, 25, Color("#4a3220"))
                rect(img, 3, 6, 3, 23, Color("#8a6138"))
                rect(img, 41, 5, 5, 25, Color("#4a3220"))
                rect(img, 42, 6, 3, 23, Color("#8a6138"))
                hline(img, 5, 10, 38, Color("#6f4b2b"))
                hline(img, 5, 20, 38, Color("#6f4b2b"))
                hline(img, 5, 11, 38, Color("#a37848"))
                hline(img, 5, 21, 38, Color("#a37848"))
                px(img, 24, 9, Color("#d3c79c"))
                return img)


static func garden_texture() -> Texture2D:
        return cached_texture("garden", func() -> Image:
                var img := image(64, 32)
                rect(img, 2, 6, 60, 24, Color("#5b3f28"))
                rect(img, 4, 8, 56, 20, Color("#7a5735"))
                for row in 3:
                        hline(img, 6, 11 + row * 6, 52, Color("#4d3524"))
                        for x in range(9, 56, 11):
                                px(img, x, 10 + row * 6, Color("#76a34e"))
                                px(img, x + 1, 9 + row * 6, Color("#8fbf5d"))
                                px(img, x - 1, 9 + row * 6, Color("#668d43"))
                hline(img, 2, 5, 60, Color("#b69a65"))
                return img)


static func animal_texture(kind: String, frame: int = 0) -> Texture2D:
        return cached_texture("animal_%s_%d" % [kind, frame], func() -> Image:
                var img := image(20, 20)
                var bob := 1 if frame % 2 == 0 else 0
                if kind == "chicken":
                        ellipse(img, 10, 14 + bob, 5, 4, Color("#d8c699"))
                        ellipse(img, 13, 8 + bob, 3, 3, Color("#e9dab0"))
                        _fill_polygon(img, [Vector2i(14, 5), Vector2i(17, 3), Vector2i(17, 7)], Color("#c84e4e"))
                        rect(img, 15, 8 + bob, 2, 1, Color("#e8a34c"))
                        px(img, 14, 7 + bob, OUTLINE)
                        line(img, 7, 16 + bob, 6, 19, Color("#b58a43"))
                        line(img, 11, 16 + bob, 12, 19, Color("#b58a43"))
                elif kind == "goat":
                        ellipse(img, 10, 13 + bob, 6, 5, Color("#d7d0bc"))
                        ellipse(img, 15, 8 + bob, 4, 4, Color("#e2dcc9"))
                        line(img, 14, 5 + bob, 13, 2 + bob, Color("#6d5a45"))
                        line(img, 17, 5 + bob, 18, 2 + bob, Color("#6d5a45"))
                        line(img, 7, 17 + bob, 6, 20, Color("#7b6c55"))
                        line(img, 12, 17 + bob, 13, 20, Color("#7b6c55"))
                        px(img, 16, 8 + bob, OUTLINE)
                elif kind == "horse":
                        ellipse(img, 9, 11 + bob, 7, 4, Color("#8d5a3b"))
                        ellipse(img, 15, 7 + bob, 3, 3, Color("#a66a43"))
                        rect(img, 17, 7 + bob, 3, 2, Color("#b97b50"))
                        line(img, 5, 13 + bob, 4, 18, Color("#5a3826"))
                        line(img, 8, 14 + bob, 8, 19, Color("#5a3826"))
                        line(img, 12, 14 + bob, 12, 19, Color("#5a3826"))
                        line(img, 15, 13 + bob, 16, 18, Color("#5a3826"))
                        line(img, 3, 10 + bob, 1, 14, Color("#3d2719"))
                        line(img, 13, 4 + bob, 14, 7 + bob, Color("#3d2719"))
                        rect(img, 8, 9 + bob, 4, 2, Color("#d2a65d"))
                        px(img, 16, 6 + bob, OUTLINE)
                else:
                        ellipse(img, 10, 12, 7, 5, Color("#c2a77c"))
                return img)


static func leaf_texture() -> Texture2D:
        return cached_texture("leaf_small", func() -> Image:
                var img := image(5, 3)
                line(img, 0, 2, 4, 0, Color("#688b43"))
                rect(img, 1, 0, 3, 2, Color("#a1bb60"))
                px(img, 2, 1, Color("#537541"))
                return img)


static func mote_texture() -> Texture2D:
        return cached_texture("mote_small", func() -> Image:
                var img := image(3, 3)
                rect(img, 1, 1, 1, 1, Color.WHITE)
                return img)


static func turtle_texture() -> Texture2D:
        return cached_texture("beach_turtle", func() -> Image:
                var img := image(42, 30)
                # Broad flippers, olive shell, sandy highlights and a quiet resting head.
                for at in [Vector2i(9, 7), Vector2i(9, 23), Vector2i(28, 6), Vector2i(28, 24)]:
                        ellipse(img, at.x, at.y, 6, 3, OUTLINE)
                        ellipse(img, at.x, at.y - 1, 5, 2, Color("#7f9862"))
                ellipse(img, 35, 15, 6, 4, OUTLINE)
                ellipse(img, 35, 14, 5, 3, Color("#94ad72"))
                line(img, 37, 13, 39, 13, OUTLINE)
                ellipse(img, 19, 15, 15, 11, OUTLINE)
                ellipse(img, 19, 14, 14, 10, Color("#526844"))
                ellipse(img, 18, 12, 11, 7, Color("#7e8c50"))
                for x in [12, 19, 26]:
                        line(img, x, 7, x - 2, 14, Color("#465b3c"))
                        line(img, x - 2, 14, x + 1, 21, Color("#465b3c"))
                line(img, 7, 14, 31, 14, Color("#465b3c"))
                line(img, 12, 7, 23, 6, Color("#b4b56c"))
                return img)


static func besut_sign_texture() -> Texture2D:
        return cached_texture("besut_sign_board", func() -> Image:
                var img := image(104, 54)
                rect(img, 18, 24, 7, 30, OUTLINE)
                rect(img, 79, 24, 7, 30, OUTLINE)
                rect(img, 20, 25, 3, 28, Color("#765339"))
                rect(img, 81, 25, 3, 28, Color("#765339"))
                rect(img, 1, 1, 102, 32, OUTLINE)
                rect(img, 3, 3, 98, 28, Color("#775136"))
                hline(img, 4, 4, 96, Color("#b58a53"))
                hline(img, 4, 29, 96, Color("#503c2b"))
                for x in [6, 96]:
                        px(img, x, 7, Color("#d4ba86"))
                        px(img, x, 26, Color("#d4ba86"))
                var letters := [
                        ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
                        ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
                        ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
                        ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
                        ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
                ]
                for letter in letters.size():
                        for y in 7:
                                for x in 5:
                                        if letters[letter][y][x] == "1":
                                                rect(img, 23 + letter * 12 + x * 2, 9 + y * 2, 2, 2, Color("#fff0c2"))
                return img)


static func interaction_marker_texture() -> Texture2D:
        return cached_texture("interaction_chevron", func() -> Image:
                var img := image(9, 5)
                line(img, 1, 0, 4, 3, OUTLINE)
                line(img, 4, 3, 7, 0, OUTLINE)
                line(img, 2, 0, 4, 2, Color("#e0d6b2"))
                line(img, 4, 2, 6, 0, Color("#e0d6b2"))
                return img)


static func net_texture() -> Texture2D:
        return cached_texture("coastal_net", func() -> Image:
                var img := image(16, 16)
                ellipse_outline(img, 8, 6, 5, 5, Color("#90bcc0"))
                for x in [5, 8, 11]:
                        line(img, x, 3, x, 9, Color("#62868d"))
                for y in [4, 7]:
                        line(img, 4, y, 12, y, Color("#62868d"))
                line(img, 8, 10, 8, 15, Color("#80603e"))
                return img)
