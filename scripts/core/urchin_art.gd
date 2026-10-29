class_name UrchinArt
extends RefCounted
## Finite original pixel poses. Presentation never owns combat timers.

static func texture(pose: String = "idle", frame: int = 0) -> Texture2D:
	var phase := posmod(frame, 4)
	return PixelArt.cached_texture("urchin/arrival_v1/%s/%d" % [pose, phase], func() -> Image:
		var img := PixelArt.image(32, 32)
		var down := 1 if pose in ["windup", "dead"] else 0
		var center := Vector2(16, 18 + down)
		var radius := 12.0 if pose == "windup" else (14.0 if pose == "attack" else 13.0)
		for i in 16:
			if pose == "spines" and i < 8: continue
			var angle := float(i) * TAU / 16.0
			var tip := center + Vector2.from_angle(angle) * (radius if i % 2 == 0 else radius - 2.0)
			if pose == "dead": tip.y = maxf(tip.y, 12.0)
			PixelArt.line(img, 16, int(center.y), roundi(tip.x), roundi(tip.y), Color("#343052"))
			if i in [9, 11, 14] and pose != "dead": PixelArt.px(img, roundi(tip.x), roundi(tip.y), Color("#a398bf"))
		if pose == "spines": return img
		PixelArt.ellipse(img, 16, 19 + down, 9 if pose != "windup" else 10, 8 if pose != "windup" else 6, Color("#41395e"))
		PixelArt.ellipse(img, 14, 16 + down, 6, 5, Color("#75628f"))
		var look := 1 if pose == "notice" or (pose == "idle" and phase == 3) else 0
		if pose == "dead":
			PixelArt.hline(img, 11, 19, 4, Color("#c5b5ce"))
			PixelArt.hline(img, 19, 19, 4, Color("#c5b5ce"))
		else:
			PixelArt.rect(img, 11 + look, 17 + down, 3, 2, Color("#f4df8a"))
			PixelArt.rect(img, 19 + look, 17 + down, 3, 2, Color("#f4df8a"))
			if pose == "windup": PixelArt.hline(img, 12, 16 + down, 10, Color("#41395e"))
		var rattle := 1 if phase in [1, 3] and pose in ["walk", "recover", "wobble"] else 0
		PixelArt.rect(img, 5, 21 + rattle, 5, 4, Color("#90aeb4"))
		PixelArt.hline(img, 5, 22 + rattle, 5, Color("#cf7a75"))
		PixelArt.rect(img, 23, 11 - rattle, 3, 5, Color("#429c9e"))
		if pose == "walk":
			PixelArt.rect(img, 10, 26, 3, 2 + (phase % 2), Color("#51466c"))
			PixelArt.rect(img, 20, 26, 3, 3 - (phase % 2), Color("#51466c"))
		return img)
