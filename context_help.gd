extends RefCounted
var g
var topic=""
const CLOSE=Rect2(285,615,710,60)
const EMBERS=Rect2(625,4,220,38)
func _init(game):g=game
func show(id: String) -> void:
	topic=id;g.session.focused=1 if id=="playtest_export" else 0;g.sfx("click");g.queue_redraw()
func handle(id: String) -> bool:
	if id=="help:close":topic="";return true
	if id.begins_with("help:"):show(id.get_slice(":",1));return true
	return false
func input(event: InputEvent) -> bool:
	if topic=="":return false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:topic=""
		elif topic=="playtest_export" and event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_TAB]:g.session.focused=1-clampi(g.session.focused,0,1);g.menu_keyboard=true
		elif event.keycode in [KEY_ENTER,KEY_SPACE]:
			if topic=="playtest_export" and g.session.focused==0:g.action("report:open")
			else:topic=""
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index==JOY_BUTTON_B:topic=""
		elif event.button_index==JOY_BUTTON_A:
			if topic=="playtest_export" and g.session.focused==0:g.action("report:open")
			else:topic=""
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT  :
		var point=g.screen_to_design(event.position)
		for b in g.buttons:
			if b.id in ["help:close","report:open"] and b.rect.has_point(point):g.action(b.id);break
	return true
func content() -> Array:
	match topic:
		"playtest_export":return ["PLAYTEST REPORT SAVED",[["book","Saved locally. Nothing was uploaded or sent."],["map","Includes recent runs, seeds, builds, decisions and Ember Tree ranks."],["health","Does not include your character name or account information."],["settings","Use Open folder to find the JSON report. Share it only if you choose."]]]
		"endless":return ["UNLOCK ENDLESS",[["attack","Finish a full 5-floor run. Defeat the boss on floor 5."],["health","This unlock is for the current character. The Trial does not count."],["vault","Endless lets you keep climbing past floor 5, with stronger enemies each floor."]]]
		"vows":return ["UNLOCK VOWS",[["attack","Finish a full 5-floor run. Defeat the boss on floor 5."],["health","This unlock is for the current character. The Trial does not count."],["ember","Vows make runs harder. Each Threat gives +8% embers when the run ends."]]]
		"daily_vows":return ["VOWS IN DAILY RUNS",[["sun","Daily runs use the same rules for everyone. Vows are disabled."],["attack","Choose Dungeon to use Vows."]]]
		"craft_upgrade":return ["UPGRADE EQUIPMENT",[["iron","Spend 1 iron to raise the selected item by one level."],["hammer","Stand at or next to a forge, then open Equipment."],["book","Hover over Upgrade to preview the item and build changes."],["health","Iron and equipment last for this run."]]]
		"infuse":return ["GEAR INFUSIONS",[["fire","Add an element, critical stat, evade or vampirism to this item."],["book","Daily runs disable tree skills." if g.run_settings.get("mode","")=="daily" else "One free elemental imprint per floor. Rune Forge unlocks additional paid infusions."],["iron",("One elemental imprint is free this floor. Visit a forge to use it." if g.run_rules>=9 and not g.floor_flags.get("free_imprint_used",false) else "Cost: 1 iron + 4 carried embers. Visit a forge to use it.")],["hammer","Replaces the item's old infusion. Higher item levels make the bonus stronger."]]]
		"reforge":return ["CHANGE BONUS STATS",[["relic","Roll new bonus stats on Rare or Very rare gear. Level and rarity stay the same."],["book","Daily runs disable tree skills." if g.run_settings.get("mode","")=="daily" else "Requires Reforge in the Ember Tree."],["iron","Cost: 2 iron + 8 carried embers. Visit a forge to use it."]]]
		"scrap":
			var bonus=g.ember_tree.rank("salvage_master") if g.run_rules>=5 else 0
			return ["SCRAP SPARE GEAR",[["salvage","Scrapping destroys the item and gives fragments. Equipped and protected gear is protected."],["relic","Common: 1 fragment / Rare: 2 / Very rare: 3."+(" Scrapper adds +%d per item."%bonus if bonus>0 else "")],["iron","3 fragments = 1 iron. Use 1 iron to raise an item's level by 1."],["hammer","At a forge only. Uses left this floor: %d / 3."%g.salvage_charges]]]
		_:
			if g.run_rules>=20:return ["EQUIPMENT HELP",[["armor","Choose crafted equipment at the Hearth smithy before an expedition. Your loadout stays fixed during the run."],["book","Find equipment blueprints and elemental rune blueprints in chests and side passages."],["iron","Collect ore, monster parts and Warden cores. You keep them when you return, even after death."],["fire","At the smithy, craft, upgrade and infuse your equipment for future expeditions."]]]
			return ["EQUIPMENT HELP",[["armor","Equip gear in 5 slots. Compare shows your whole build before and after equipping."],["iron","1 iron raises an item's level by 1. This improves its stats."],["salvage","Protect prevents scrapping. Near a forge, use Upgrade, Imprint or Scrap in Equipment."],["health","Gear and iron last for this run. They are lost when you die."]]]
func draw() -> void:
	if topic=="":
		if g.mode in ["play","fight","inspect","bomb"] and EMBERS.has_point(g.design_mouse()):
			g.panel(Rect2(625,149,330,180));g.text(Vector2(645,185),"RUN EMBERS",23,g.GOLD)
			g.draw_wrapped("Spend these at forges. When the run ends, they are banked for the Ember Tree.",Vector2(645,220),290,18,g.INK,4)
			g.text(Vector2(645,310),"Already banked: %d"%g.bank,18,g.TEAL)
		return
	g.draw_rect(Rect2(0,0,1280,840),Color(0.02,0.02,0.03,0.9));g.panel(Rect2(245,140,790,560))
	var info=content();g.ui_icon("book",Vector2(285,177),48);g.text(Vector2(355,215),info[0],30,g.GOLD)
	for i in range(info[1].size()):
		var row=info[1][i];var at=Vector2(285,275+i*75)
		g.ui_icon(row[0],at,32);g.draw_wrapped(row[1],at+Vector2(50,24),650,21,g.INK,2)
	g.buttons.clear()
	if topic=="playtest_export":g.button(Rect2(285,615,330,60),"Open folder","report:open",g.menu_keyboard and g.session.focused==0);g.button(Rect2(650,615,345,60),"Got it / Esc","help:close",g.menu_keyboard and g.session.focused==1)
	else:g.button(CLOSE,"Got it / Enter or Esc","help:close",g.menu_keyboard)
