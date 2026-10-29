class_name StatusStripChecks
extends RefCounted

static func run(game: Game, check: Callable) -> void:
	var autosave := GameState.autosave_enabled
	var ticking := game.is_processing()
	game.set_process(false)
	GameState.autosave_enabled = false
	# Retire the preceding world before replacing its journey data. _clear_world
	# captures living home monsters, and queued trees remain grouped for a frame.
	game._clear_world()
	await game.get_tree().process_frame
	var saved := GameState.data.duplicate(true)
	GameState.data = GameState._make_default("adam")
	GameState._emit_all()
	await game._load_lobby(false, true)
	var lobby := game.world as Lobby
	lobby.process_mode = Node.PROCESS_MODE_DISABLED
	var strip := game.hud._status_strip
	strip.refresh_world(lobby)
	var baseline := strip.counts.duplicate()
	check.call(baseline.npc_alive == baseline.npc_total and baseline.npc_total >= 20 and baseline.workers_alive == 4, "census includes service people and all four living specialists")
	check.call(baseline.trees_alive == 64 and baseline.trees_total == 64 and baseline.fires == 0 and baseline.monsters == 0, "peaceful village tallies its actual 64 trees and zero threats")
	check.call(baseline.homes_intact == 8 and baseline.homes_total == 12, "home tally includes the cottage, seven residences and four ruins, excluding shop tint targets")
	var resident := lobby._residents[0]
	resident.sheltered = true
	resident.hide()
	check.call(WorldTally.snapshot(lobby).npc_alive == baseline.npc_alive, "sheltered invisible residents remain counted as alive")
	GameState.damage_resident(resident.resident_name, 1000)
	strip.refresh_world(lobby)
	check.call(strip.counts.npc_alive == baseline.npc_alive - 1 and strip.counts.npc_total == baseline.npc_total, "resident death reduces the living numerator without erasing the population total")
	var tree := lobby._forest_trees[0]
	tree.take_attack_damage(1)
	strip.refresh_world(lobby)
	check.call(strip.counts.fires == 1 and strip.counts.trees_alive == 64, "ignition reports a burning living tree separately from tree loss")
	tree.take_physical_damage(99999)
	strip.refresh_world(lobby)
	check.call(not tree.is_in_group("forest_tree") and strip.counts.trees_alive == 63 and strip.counts.trees_total == 64 and strip.counts.fires == 0, "fallen trees stay in the denominator after leaving the global tree group")
	check.call(tree.replant(), "census fixture can replant its fallen tree")
	strip.refresh_world(lobby)
	check.call(strip.counts.trees_alive == 64 and strip.counts.saplings == 1 and strip.counts.fires == 0, "protected saplings count as living forest without false fires")
	var house: SettlementTarget
	for node in game.get_tree().get_nodes_in_group("structures"):
		if lobby.is_ancestor_of(node) and node is SettlementTarget and node.structure_kind == "house" and node.is_intact():
			house = node
			break
	GameState.damage_structure(house.structure_id, 99999)
	strip.refresh_world(lobby)
	check.call(strip.counts.homes_intact == baseline.homes_intact - 1 and strip.counts.homes_total == baseline.homes_total, "destroyed houses reduce shelter availability without changing house-site totals")
	GameState.repair_structure(house.structure_id)
	check.call(WorldTally.snapshot(lobby).homes_intact == baseline.homes_intact, "house repair restores the live intact-home tally")
	var monster := lobby.spawn_sea_urchin(lobby._layout.approach("jetty_landing"), false, true)
	strip.refresh_world(lobby)
	check.call(strip.counts.monsters == 1 and strip.counts.urchins == 1, "newly spawned monsters join the current-world tally")
	monster.dead = true
	monster.hp = 0
	game.hud._process(GameHUD.TALLY_REFRESH_SECONDS + 0.01)
	check.call(strip.counts.monsters == 0, "throttled HUD refresh removes dead monsters without requiring a currency or save signal")
	var outside := Enemy.new()
	outside.process_mode = Node.PROCESS_MODE_DISABLED
	game.add_child(outside)
	check.call(WorldTally.snapshot(lobby).monsters == 0, "actors outside the owned world cannot leak into its census")
	outside.queue_free()
	var before := GameState.data.duplicate(true)
	for i in 5: WorldTally.snapshot(lobby)
	check.call(GameState.data == before, "reading tallies never writes progression, forest, population or currency data")
	for amount in [0, 9999, 10000, 12500, 999999, 1000000, 1234567890]:
		check.call(HudStatusStrip.compact_amount(amount).length() <= 6, "large balance %d fits a compact currency chip" % amount)
	GameState.data.gold = 1234567
	game.hud.refresh_all()
	check.call(strip.gold_label.text == "1.2M" and strip.gold_label.tooltip_text.contains("1234567"), "compact balances retain the exact amount in their tooltip")
	await game._load_lobby(false)
	check.call(lobby.is_queued_for_deletion() and WorldTally.snapshot(lobby).is_empty() and strip.counts.npc_total == baseline.npc_total, "coexisting retiring worlds are excluded immediately during handoff")
	var portal := PortalDB.ordered_ids()[0] as String
	GameState.start_expedition(portal)
	await game._load_dungeon(portal, false)
	game.world.process_mode = Node.PROCESS_MODE_DISABLED
	strip.refresh_world(game.world)
	check.call(strip.counts.monsters > 0 and strip._chips.monsters.visible and not strip._chips.npc.visible and not strip._chips.trees.visible, "dungeon HUD shows local monsters without misleading village zeroes")
	game.hud.set_world(null)
	check.call(strip.counts.is_empty() and not strip._chips.monsters.visible, "world removal clears stale tallies immediately")
	game._clear_world()
	await game.get_tree().process_frame
	GameState.data = saved
	GameState._emit_all()
	await game._load_lobby(false)
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	GameState.autosave_enabled = autosave
	game.set_process(ticking)
