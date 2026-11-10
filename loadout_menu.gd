extends RefCounted
## Explicit preparation before starting an expedition; only crafted gear can be equipped.
var g
var slot="weapon"
var selected=""
var stats_page=0
var item_page=0
const PAGE_SIZE=24
var filter_index=0
const FILTERS=["All","Base","Keen","Swift","Bloodbound","Special"]
var back_mode="expedition"
var demo=false
var summary_open=false
var summary_snapshot={}
func _init(game):g=game
func open(from: String,is_demo: bool=false) -> void:
 g.replay.draft.mode="standard"
 summary_open=false;back_mode=from;demo=is_demo;slot="weapon";selected="";stats_page=0;item_page=0;filter_index=0;g.mode="loadout";g.session.focused=0
func is_daily() -> bool:return not demo and g.replay.draft.get("mode","")=="daily"
func handle(id: String) -> bool:
 if g.mode!="loadout" or id=="smithy_open":return false
 if summary_open:
  if id in ["loadout_summary_close","loadout_back"]:summary_open=false
  return true
 if id=="loadout_summary":summary_snapshot=summary_data();summary_open=true;return true
 if id=="loadout_back":g.mode=back_mode;return true
 if id.begins_with("loadout_slot:"):
  var s=id.trim_prefix("loadout_slot:")
  if s in g.Gear.SLOTS:slot=s;selected="";stats_page=0;item_page=0
  return true
 if id.begins_with("loadout_select:"):
  var key=id.trim_prefix("loadout_select:");var p=g.smithy.data()
  if not is_daily() and p.items.has(key) and g.smithy.RECIPES.has(key) and g.smithy.RECIPES[key][1]==slot:
   if selected!=key:stats_page=0
   selected=key
   if slot=="weapon" and preload("res://early_journey.gd").enabled(g):preload("res://early_journey.gd").progress(g).inspected=true
   if p.unseen_items.has(key):
    p.unseen_items.erase(key)
    if not g.session.commit_profile():p.unseen_items[key]=true
  return true
 if id=="loadout_filter":filter_index=posmod(filter_index+1,FILTERS.size());selected="";stats_page=0;item_page=0;return true
 if id=="loadout_items_prev":item_page=maxi(0,item_page-1);return true
 if id=="loadout_items_next":item_page=mini(maxi(0,ceili(float(filtered_ids().size())/PAGE_SIZE)-1),item_page+1);return true
 if id=="loadout_stats_prev":stats_page=maxi(0,stats_page-1);return true
 if id=="loadout_stats_next":stats_page+=1;return true
 if id=="loadout_equip":
  var p=g.smithy.data()
  if is_daily() or not p.items.has(selected) or not g.smithy.RECIPES.has(selected) or g.smithy.RECIPES[selected][1]!=slot:return true
  var old=p.loadout.duplicate();p.loadout[slot]=selected
  if not g.session.commit_profile():p.loadout=old;g.smithy.message="Could not save your loadout."
  return true
 if id=="loadout_unequip":
  var p=g.smithy.data()
  if is_daily() or slot=="weapon":return true
  var old=p.loadout.duplicate();p.loadout.erase(slot)
  if not g.session.commit_profile():p.loadout=old;g.smithy.message="Could not save your loadout."
  return true
 if id=="loadout_start":
  g.demo_run=demo
  if g.session.has_run():g.mode="confirm_new"
  else:g.session.start_run(demo)
  return true
 return true
func filtered_ids() -> Array:
 var p=g.smithy.data();var ids=[];var family=FILTERS[filter_index]
 for id in g.smithy.category_ids(slot):
  var special=g.smithy.SPECIALS.has(id)
  var matches=family=="All" or (family=="Base" and not g.smithy.VARIANTS.has(id) and not special) or (family=="Special" and special) or id.ends_with("_"+family.to_lower())
  if p.items.has(id) and (not is_daily() or id=="sword") and (is_daily() or matches):ids.append(id)
 return ids
# Pure equipment-only summary: does not use the active run's stats or mutate it.
func summary_data() -> Dictionary:
 var p=g.smithy.data();var loadout={"weapon":"sword"} if is_daily() else p.loadout;var items={};var totals={}
 for s in g.Gear.SLOTS:
  var id=str(loadout.get(s,""))
  if not g.smithy.RECIPES.has(id) or (not is_daily() and not p.items.has(id)):continue
  var item=g.smithy.make_item(id,1 if is_daily() else g.smithy.slot_level(id),"" if is_daily() else str(p.infusions.get(id,"")))
  items[s]=item
  var values=g.Gear.stats(item)
  for key in values:totals[key]=float(totals.get(key,0))+float(values[key])
 var preview=load("res://main.tscn").instantiate();preview.run_rules=20
 preview.run_skills={} if is_daily() else g.skills.duplicate(true)
 for s in g.Gear.SLOTS:
  if items.has(s):preview.inventory.append(items[s]);preview.equipped[s]=preview.inventory.size()-1
 preview.ember_tree=preload("res://ember_tree.gd").new(preview)
 var stats=preload("res://build_stats.gd").calculate(preview);preview.free()
 return {"items":items,"totals":totals,"stats":stats}
func draw_summary() -> void:
 var data=summary_snapshot;var totals=data.stats
 g.front_end.menu_backdrop();g.panel(Rect2(70,90,1140,630));g.text(Vector2(105,145),"YOUR LOADOUT",32,g.GOLD)
 g.text(Vector2(105,181),"Starting stats include equipped items and permanent skills" if not is_daily() else "Daily starts with a fixed sword and no permanent skills",18,g.TEAL)
 g.text(Vector2(105,225),"EQUIPPED ITEMS",20,g.GOLD);g.text(Vector2(675,225),"STARTING STATS",20,g.GOLD)
 for i in range(g.Gear.SLOTS.size()):
  var slot_id=g.Gear.SLOTS[i];var at=Vector2(105,250+i*70);var item=data.items.get(slot_id,{})
  g.gear_icon(slot_id,at,42,g.Gear.COLORS[item.rarity] if not item.is_empty() else g.INK,item)
  g.text(at+Vector2(55,20),slot_id.capitalize()+": "+(str(item.name) if not item.is_empty() else "Empty"),20,g.INK)
  if not item.is_empty() and item.get("infusion","") in g.smithy.ELEMENTS:
   g.ui_icon(item.infusion,at+Vector2(55,28),20);g.text(at+Vector2(82,45),str(item.infusion).capitalize()+" rune",16,g.TEAL)
 var keys=["max_hp","attack","armor","interval","crit_chance","crit_mult","evade","vampirism"]
 for element in ["fire","ice","acid","poison"]:
  if float(totals.element_totals.get(element,0))>0:keys.append(element)
 for i in range(keys.size()):
  var key=keys[i];var at=Vector2(675+(i%2)*245,270+int(i/2)*50)
  g.stat_ui.label(key,at,21);g.text(at+Vector2(25,0),g.stat_ui.short_name(key),16,g.INK)
  g.text(at+Vector2(25,21),g.build_view.value(key,totals),18,g.TEAL)
 g.text(Vector2(105,650),"Mode: "+("Daily / fixed sword" if is_daily() else str(g.replay.draft.mode).capitalize())+" / Threat %d"%g.replay.threat(g.replay.draft),18,g.TEAL)
 var vows=[]
 if not is_daily():
  for id in g.replay.VOWS:
   var rank=int(g.replay.draft.get("vows",{}).get(id,0))
   if rank>0:vows.append(g.replay.VOWS[id][0]+" %d"%rank)
 g.draw_wrapped("Vows: "+(" / ".join(vows) if not vows.is_empty() else "None"),Vector2(105,682),1000,17,g.INK,2)
 g.button(Rect2(105,750,300,50),"Back to loadout","loadout_summary_close")
func draw() -> void:
 if summary_open:draw_summary();return
 var p=g.smithy.data();var loadout={"weapon":"sword"} if is_daily() else p.loadout
 g.front_end.menu_backdrop();g.text(Vector2(60,68),"PREPARE YOUR LOADOUT",34,g.GOLD)
 g.text(Vector2(60,102),"Daily expedition: fixed sword and no other gear." if is_daily() else "Choose crafted equipment for this expedition. Your choices stay equipped until changed.",19,g.TEAL)
 for i in range(g.Gear.SLOTS.size()):
  var s=g.Gear.SLOTS[i];var id=str(loadout.get(s,""));var rect=Rect2(60+i*232,125,218,72)
  g.button(rect,"","loadout_slot:"+s,slot==s);g.gear_icon(s,rect.position+Vector2(12,12),42,g.INK,g.smithy.make_item(id,g.smithy.slot_level(id),str(p.infusions.get(id,""))) if g.smithy.RECIPES.has(id) else {})
  var name="Empty" if not g.smithy.RECIPES.has(id) else str(g.smithy.RECIPES[id][0])
  if name.length()>15:name=name.left(12)+"..."
  g.text(rect.position+Vector2(65,30),s.capitalize(),18,g.GOLD);g.text(rect.position+Vector2(65,54),name,15,g.TEAL)
 g.panel(Rect2(60,215,570,475));g.panel(Rect2(650,215,570,475))
 g.text(Vector2(80,248),"CRAFTED "+slot.to_upper(),20,g.GOLD)
 if not is_daily():g.button(Rect2(415,220,195,35),"Filter: "+FILTERS[filter_index],"loadout_filter")
 var ids=filtered_ids();var item_pages=maxi(1,ceili(float(ids.size())/PAGE_SIZE));item_page=clampi(item_page,0,item_pages-1)
 if ids.is_empty():
  g.draw_wrapped("No equipment crafted for this slot yet. Visit the Smithy to make some." if filter_index==0 else "No items match this filter.",Vector2(90,300),485,21,g.INK,4)
  if not is_daily():g.button(Rect2(90,365,300,52),"Open smithy","smithy_open")
 var inspected=selected
 for i in range(mini(PAGE_SIZE,ids.size()-item_page*PAGE_SIZE)):
  var id=ids[item_page*PAGE_SIZE+i];var item=g.smithy.make_item(id,g.smithy.slot_level(id),str(p.infusions.get(id,"")));var at=Vector2(82+(i%6)*87,270+int(i/6)*92);var rect=Rect2(at,Vector2(76,76))
  g.button(rect,"","loadout_select:"+id,selected==id or loadout.get(slot,"")==id,not is_daily())
  g.gear_icon(item.slot,at+Vector2(13,12),50,g.Gear.COLORS[item.rarity],item)
  if p.unseen_items.has(id):g.text(at+Vector2(8,70),"NEW",12,g.GOLD)
  if not g.menu_keyboard and rect.has_point(g.design_mouse()):inspected=id
 if item_pages>1:
  g.button(Rect2(82,640,120,38),"Previous","loadout_items_prev",false,item_page>0)
  g.text(Vector2(248,667),"%d / %d"%[item_page+1,item_pages],18,g.TEAL)
  g.button(Rect2(420,640,120,38),"Next","loadout_items_next",false,item_page<item_pages-1)
 if is_daily():inspected="sword"
 if inspected=="":inspected=str(loadout.get(slot,""))
 if g.smithy.RECIPES.has(inspected):
  var item=g.smithy.make_item(inspected,g.smithy.slot_level(inspected) if not is_daily() else 1,str(p.infusions.get(inspected,"")) if not is_daily() else "")
  g.gear_icon(item.slot,Vector2(680,245),64,g.Gear.COLORS[item.rarity],item);g.text(Vector2(760,272),item.name,24,g.GOLD)
  g.text(Vector2(760,300),"Level %d / %s"%[item.level,g.Gear.RARITIES[item.rarity]],18,g.TEAL)
  var identity=g.smithy.style_description(item)
  if identity!="":g.text(Vector2(680,325),identity,16,g.GOLD)
  if item.slot=="weapon":g.draw_wrapped(g.choice_ui.weapon_description(item),Vector2(680,348 if identity!="" else 335),500,18,g.INK,2 if identity!="" else 3)
  var rune=str(item.get("infusion",""))
  if rune in g.smithy.ELEMENTS:g.ui_icon(rune,Vector2(680,380),22)
  g.text(Vector2(710 if rune in g.smithy.ELEMENTS else 680,399),"Rune: "+rune.capitalize() if rune in g.smithy.ELEMENTS else "Rune: None",17,g.TEAL)
  var presenter=preload("res://equipment_presenter.gd");var stats=presenter.numbers(item)
  var equipped_id=str(loadout.get(slot,""));var compare=equipped_id!="" and equipped_id!=inspected and g.smithy.RECIPES.has(equipped_id)
  var before=presenter.numbers(g.smithy.make_item(equipped_id,g.smithy.slot_level(equipped_id),str(p.infusions.get(equipped_id,"")))) if compare else {}
  var rows=presenter.comparison_keys(before,stats) if compare else presenter.keys({},stats)
  var pages=maxi(1,ceili(float(rows.size())/5.0));stats_page=clampi(stats_page,0,pages-1)
  g.text(Vector2(955,420),"EQUIPPED / THIS" if compare else "ITEM STATS",16,g.TEAL)
  for i in range(mini(5,rows.size()-stats_page*5)):
   var key=rows[stats_page*5+i];var y=440+i*29;g.stat_ui.label(key,Vector2(680,y),22);g.text(Vector2(710,y),g.stat_ui.short_name(key),17,g.INK)
   var delta=float(stats.get(key,0))-float(before.get(key,0));var better=delta<0 if key in ["base_interval","item_interval"] else delta>0
   g.text(Vector2(955,y),presenter.value(key,before)+" / "+presenter.value(key,stats) if compare else presenter.value(key,stats),18,g.INK if compare and is_zero_approx(delta) else g.TEAL if not compare or better else Color("e88882"))
  if pages>1:
   g.button(Rect2(680,660,48,26),"<","loadout_stats_prev",false,stats_page>0)
   g.text(Vector2(742,680),"Stats %d/%d"%[stats_page+1,pages],16,g.TEAL)
   g.button(Rect2(860,660,48,26),">","loadout_stats_next",false,stats_page<pages-1)
  g.button(Rect2(680,610,240,48),"Equip selected","loadout_equip",false,not is_daily() and selected==inspected and loadout.get(slot,"")!=selected)
  g.button(Rect2(940,610,235,48),"Unequip","loadout_unequip",false,not is_daily() and slot!="weapon" and loadout.has(slot))
 else:g.draw_wrapped("Select a crafted item to see its stats.",Vector2(680,300),480,22,g.INK,4)
 g.button(Rect2(60,750,230,50),"Back","loadout_back")
 g.button(Rect2(325,750,240,50),"Loadout summary","loadout_summary")
 g.text(Vector2(590,782),"Threat %d / %d slots"%[g.replay.threat(g.replay.draft),loadout.size()],18,g.INK)
 g.button(Rect2(910,738,300,62),"Begin expedition","loadout_start",false,is_daily() or (p.loadout.has("weapon") and p.items.has(p.loadout.weapon)))
