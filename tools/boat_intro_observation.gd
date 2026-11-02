extends Node
func _ready() -> void:
 if not TestEnvironment.require_isolation(): get_tree().quit(1); return
 GameState.autosave_enabled = false
 GameState.data = GameState._make_default("adam")
 var title := TitleScreen.new()
 add_child(title)
 title._show_page(TitleScreen.Page.HEROES, false)
 await get_tree().process_frame
 var cards: Array[String] = []
 for card in title._card_buttons: cards.append(str(card.name))
 print("CARDS=", JSON.stringify(cards))
 GameState.data.campaign.arjun_rescued = true
 GameState.data.campaign.mei_ling_rescued = true
 title._refresh_hero_locks()
 cards.clear()
 for card in title._card_buttons: cards.append(str(card.name))
 print("RESCUED_CARDS=", JSON.stringify(cards))
 var story := StorySequence.new()
 add_child(story)
 story.set_process(false)
 print("INTRO_COUNT=",story.lines().size())
 for index in 4:
  story.page = index
  story._render()
  print("BEAT_", index, "=", story._caption.text.replace("\n", " | "))
 story.finish()
 await get_tree().process_frame
 get_tree().quit(0)
