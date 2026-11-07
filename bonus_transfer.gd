extends RefCounted
const Stats=preload("res://build_stats.gd")
var g
var donor_page=0
var recipient_page=0
func _init(game):g=game
func table() -> Dictionary:return g.rooms[g.room].entities.get(g.puzzle_tile,{})
func open(tile: Vector2i,return_mode: String="play") -> void:
	g.puzzle_tile=tile;g.run_metrics["transfer_draft"]={"donor":-1,"recipient":-1,"source":"","replace":"","return":return_mode};donor_page=0;recipient_page=0;g.mode="imprint"
func draft() -> Dictionary:return g.run_metrics.get("transfer_draft",{})
func candidates(donor: bool) -> Array:
	var result=[]
	for i in range(g.inventory.size()):
		var item=g.inventory[i]
		if item.rarity<1 or item.affixes.is_empty():continue
		if donor and (i in g.equipped.values() or item.get("kept",false)):continue
		result.append(i)
	return result
func ready() -> bool:
	var d=draft()
	if table().get("kind","") not in ["runesmith","salvage"] or g.forge_menu.used("transfer") or g.iron<1:return false
	if not int(d.get("donor",-1)) in candidates(true) or not int(d.get("recipient",-1)) in candidates(false) or d.donor==d.recipient:return false
	var donor=g.inventory[d.donor];var recipient=g.inventory[d.recipient]
	return d.source in donor.affixes and d.replace in recipient.affixes and d.source not in recipient.affixes
func proposed() -> Dictionary:
	var d=draft()
	if int(d.get("recipient",-1))<0:return {}
	var item=g.inventory[d.recipient].duplicate(true);var position=item.affixes.find(d.get("replace",""))
	if position>=0 and d.get("source","")!="":item.affixes[position]=d.source
	return item
func handle(id: String) -> bool:
	if g.mode!="imprint":return false
	if id=="transfer_close":
		g.mode=draft().get("return","play")
		if g.mode=="forge":g.mode="equipment"
		return true
	if not id.begins_with("transfer:"):return false
	var d=draft();var command=id.get_slice(":",1);var value=id.get_slice(":",2)
	match command:
		"donor":
			var index=int(value)
			if index not in candidates(true):return true
			d.donor=index;d.source=g.inventory[index].affixes[0]
			if d.recipient==index:d.recipient=-1;d.replace=""
		"recipient":
			var index=int(value)
			if index not in candidates(false):return true
			d.recipient=index;d.replace=g.inventory[index].affixes[0]
		"source":
			if d.donor>=0 and value in g.inventory[d.donor].affixes:d.source=value
		"replace":
			if d.recipient>=0 and value in g.inventory[d.recipient].affixes:d.replace=value
		"donor_page":donor_page=maxi(0,donor_page+int(value))
		"recipient_page":recipient_page=maxi(0,recipient_page+int(value))
		"commit":
			if not ready():g.log_line("Choose different Rare items, an unused table and 1 iron. Kept/equipped items cannot be donors.");return true
			var recipient_index=int(d.recipient);var donor_index=int(d.donor);var item=proposed();g.inventory[recipient_index]=item
			g.inventory.remove_at(donor_index)
			for slot in g.equipped:
				if g.equipped[slot]>donor_index:g.equipped[slot]-=1
			g.selected_item=recipient_index-1 if recipient_index>donor_index else recipient_index;g.equipment_slot=item.slot;g.iron-=1;g.forge_menu.mark_used("transfer");table()["used"]=true if table().kind=="runesmith" else false
			g.recalculate_stats();g.world_choices.record("bonus_transfer_"+d.source);g.run_metrics["bonus_transfers"]=int(g.run_metrics.get("bonus_transfers",0))+1
			g.mode="equipment";g.sfx("equip");g.log_line("Bonus transferred. Donor consumed. The new bonus scales with the receiving item.")
	return true
func requirement() -> String:
	var d=draft()
	if g.forge_menu.used("transfer"):return "Already used this floor. Find another table upstairs."
	if g.iron<1:return "Find 1 iron to transfer a bonus."
	if int(d.get("donor",-1))<0:return "Choose spare Rare gear. Equipped and protected gear cannot be donors."
	if int(d.get("recipient",-1))<0:return "Choose the item that receives the bonus."
	if d.donor==d.recipient:return "Choose two different items."
	if d.source in g.inventory[d.recipient].affixes:return "This item already has that bonus. Choose another bonus or item."
	return "The donor is destroyed. The new bonus uses the receiving item's level and rarity."
func draw() -> void:
	g.front_end.menu_backdrop();g.panel(Rect2(65,65,1150,710));g.text(Vector2(95,112),"TRANSFER A BONUS",32,g.GOLD)
	g.draw_wrapped("Use two different Rare items (or better). Consume the donor to replace one bonus. Cost: 1 iron, once per floor.",Vector2(95,150),1080,19,g.INK,2)
	var d=draft()
	for side in range(2):
		var at=Vector2(95+side*350,205);g.panel(Rect2(at,Vector2(330,360)));g.text(at+Vector2(15,33),"DONOR / CONSUMED" if side==0 else "RECEIVING ITEM",20,g.GOLD)
		var list=candidates(side==0);var pages=maxi(1,ceili(list.size()/4.0))
		if side==0:donor_page=clampi(donor_page,0,pages-1)
		else:recipient_page=clampi(recipient_page,0,pages-1)
		var page=donor_page if side==0 else recipient_page
		for row in range(4):
			var entry=page*4+row
			if entry>=list.size():break
			var index=int(list[entry]);var item=g.inventory[index];var pos=at+Vector2(10,55+row*61)
			g.button(Rect2(pos,Vector2(310,54)),"","transfer:"+("donor:" if side==0 else "recipient:")+str(index),index==int(d.donor if side==0 else d.recipient))
			g.gear_icon(item.slot,pos+Vector2(8,8),32,g.Gear.COLORS[item.rarity],item);g.text(pos+Vector2(52,23),item.name,19,g.Gear.COLORS[item.rarity]);g.text(pos+Vector2(52,45),"Level %d / %s"%[item.level,item.slot],18)
			if index in g.equipped.values():g.text(pos+Vector2(220,45),"EQUIPPED",16,g.TEAL)
		g.button(Rect2(at+Vector2(10,305),Vector2(145,40)),"Previous","transfer:"+("donor_page:-1" if side==0 else "recipient_page:-1"),false,page>0)
		g.button(Rect2(at+Vector2(175,305),Vector2(145,40)),"Next","transfer:"+("donor_page:1" if side==0 else "recipient_page:1"),false,page+1<pages)
		var index=int(d.donor if side==0 else d.recipient)
		if index>=0:
			for i in range(g.inventory[index].affixes.size()):
				var key=g.inventory[index].affixes[i];var y=590+i*44
				g.button(Rect2(at.x,y,330,38),"","transfer:"+("source:" if side==0 else "replace:")+key,key==(d.source if side==0 else d.replace))
				var item=g.inventory[index];var stat=g.Gear.stat_key(key,item);var values=g.Gear.stats(item)
				var without=item.duplicate(true);without.affixes.erase(key)
				var amount=float(values.get(stat,0))-float(g.Gear.stats(without).get(stat,0))
				g.stat_ui.icon(stat,Vector2(at.x+12,y+7),24)
				g.text(Vector2(at.x+55,y+27),preload("res://equipment_presenter.gd").value(stat,{stat:amount}),22,g.TEAL)
	g.panel(Rect2(795,205,390,430));g.text(Vector2(815,242),"BUILD IF EQUIPPED",21,g.GOLD)
	g.text(Vector2(983,268),"NOW",18,g.INK);g.text(Vector2(1074,268),"AFTER",18,g.TEAL)
	var item=proposed()
	if not item.is_empty():g.build_view.draw_compare(d.recipient,{int(d.recipient):item},Vector2(815,287),350,280)
	else:g.draw_wrapped("Select a donor bonus and the bonus you want to replace. Protected gear is hidden from the donor list.",Vector2(815,300),340,20,g.INK,7)
	g.draw_wrapped(requirement(),Vector2(815,590),340,18,g.TEAL,2)
	g.front_end.icon_button(Rect2(795,655,390,65),"iron","Transfer / 1 iron" if not g.forge_menu.used("transfer") else "Already used this floor","transfer:commit",false,ready())
	g.button(Rect2(95,700,330,48),"Back to equipment" if table().get("kind","")=="salvage" else "Back / Esc","transfer_close")
