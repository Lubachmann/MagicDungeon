extends RefCounted
const Presenter=preload("res://equipment_presenter.gd")
const Stats=preload("res://build_stats.gd")
var g
func _init(game):g=game
func table() -> Dictionary:return g.rooms[g.room].entities.get(g.puzzle_tile,{})
func eligible() -> Array:
 var result=[]
 for i in range(g.inventory.size()):
  if int(g.inventory[i].rarity)<2:result.append(i)
 return result
func cost(item: Dictionary) -> int:return 1+int(item.rarity)
func options(index: int) -> Array:
 if index<0 or index>=g.inventory.size():return []
 var item=g.inventory[index];var altar=table();var token=str(hash([item,index]));var cache=altar.get("offers",{})
 if cache.has(token):return cache[token]
 var pool=( ["crit_chance","crit_mult","speed","fire_dps","ice_slow","acid_strip","poison_weak","evade","vampirism"] if item.slot=="weapon" else ["health","armor","speed","crit_chance","crit_mult","evade","vampirism","fire_dps","ice_slow","acid_strip","poison_weak"] )
 for affix in item.affixes:pool.erase(affix)
 var relevance=[];var totals=Stats.calculate(g).get("element_totals",{})
 for element in ["fire","ice","acid","poison"]:
  var affix={"fire":"fire_dps","ice":"ice_slow","acid":"acid_strip","poison":"poison_weak"}[element]
  if float(totals.get(element,0))>0 and affix in pool:relevance.append(affix)
 if relevance.is_empty():
  for key in (["speed","crit_chance","crit_mult"] if item.slot=="weapon" else ["health","armor","evade"]):
   if key in pool:relevance.append(key)
 var rng=RandomNumberGenerator.new();rng.seed=absi(int(altar.get("seed",1))+hash(token))
 var result=[]
 if not relevance.is_empty():
  var chosen=relevance[rng.randi_range(0,relevance.size()-1)];result.append(chosen);pool.erase(chosen)
 while result.size()<3 and not pool.is_empty():result.append(pool.pop_at(rng.randi_range(0,pool.size()-1)))
 cache[token]=result;altar["offers"]=cache
 return result
func proposed(index: int,key: String) -> Dictionary:
 if index not in eligible() or key not in options(index):return {}
 var item=g.inventory[index].duplicate(true);item.rarity+=1;item.affixes.append(key);return item
func handle(id: String) -> bool:
 if g.mode!="decision" or table().get("kind","") not in ["rarity_altar","salvage"]:return false
 var altar=table()
 if id=="decision_leave" and altar.get("kind","")=="salvage":g.mode="equipment";return true
 if id=="rarity_page_prev":altar.page=maxi(0,int(altar.get("page",0))-1);return true
 if id=="rarity_page_next":altar.page=int(altar.get("page",0))+1;return true
 if id.begins_with("rarity_item:"):
  var index=int(id.get_slice(":",1))
  if index in eligible():altar.selected=index;altar.choice="";options(index)
  return true
 if id.begins_with("rarity_bonus:"):
  var index=int(altar.get("selected",-1));var key=id.get_slice(":",1)
  if key in options(index):altar.choice=key
  return true
 if id=="rarity_commit":
  var index=int(altar.get("selected",-1));var item=proposed(index,altar.get("choice",""))
  if item.is_empty() or g.forge_menu.used("rarity") or g.iron<cost(g.inventory[index]):return true
  g.iron-=cost(g.inventory[index]);g.inventory[index]=item;g.forge_menu.mark_used("rarity");altar.used=true if altar.kind=="rarity_altar" else false;g.recalculate_stats();g.mode="equipment" if altar.kind=="salvage" else "play";g.world_choices.record("rarity_upgrade");g.sfx("equip");g.log_line("%s is now %s."%[item.name,g.Gear.RARITIES[item.rarity]]);return true
 return false
func draw() -> void:
 var altar=table();var index=int(altar.get("selected",-1));var list=eligible();var pages=maxi(1,ceili(list.size()/4.0));altar.page=clampi(int(altar.get("page",0)),0,pages-1)
 g.front_end.overlay(Rect2(55,55,1170,730));g.text(Vector2(90,105),"RAISE RARITY" if altar.kind=="salvage" else "RARITY ALTAR",32,g.GOLD)
 g.draw_wrapped("Choose gear and a new bonus. One upgrade per floor.",Vector2(90,137),1090,19,g.INK,1)
 g.stat_ui.icon("iron",Vector2(90,145),22);g.text(Vector2(120,164),"Common → Rare: 1 iron  /  Rare → Very rare: 2 iron",18,g.TEAL)
 g.panel(Rect2(85,175,340,385));g.text(Vector2(105,205),"CHOOSE EQUIPMENT",21,g.GOLD)
 for row in range(4):
  var n=altar.page*4+row
  if n>=list.size():break
  var i=list[n];var item=g.inventory[i];var at=Vector2(100,220+row*65)
  g.button(Rect2(at,Vector2(310,58)),"","rarity_item:"+str(i),i==index)
  g.gear_icon(item.slot,at+Vector2(7,8),34,g.Gear.COLORS[item.rarity],item);g.text(at+Vector2(50,24),item.name,19,g.Gear.COLORS[item.rarity]);g.text(at+Vector2(50,46),"%s / Level %d"%[g.Gear.RARITIES[item.rarity],item.level],17)
  if i in g.equipped.values():g.text(at+Vector2(220,46),"EQUIPPED",16,g.TEAL)
 g.button(Rect2(100,497,140,42),"Previous","rarity_page_prev",false,altar.page>0);g.button(Rect2(255,497,140,42),"Next","rarity_page_next",false,altar.page+1<pages)
 g.panel(Rect2(445,175,335,385));g.text(Vector2(465,205),"CHOOSE A BONUS",21,g.GOLD)
 if index in list:
  var item=g.inventory[index];var choices=options(index)
  for i in range(choices.size()):
   var key=choices[i];var stat=g.Gear.stat_key(key,item);var future=proposed(index,key);var prior=item.duplicate(true);prior.rarity+=1
   var amount=float(g.Gear.stats(future).get(stat,0))-float(g.Gear.stats(prior).get(stat,0));var at=Vector2(460,225+i*72)
   g.button(Rect2(at,Vector2(305,64)),"","rarity_bonus:"+key,key==altar.get("choice",""));g.stat_ui.icon(stat,at+Vector2(10,12),26);g.text(at+Vector2(46,26),g.stat_ui.short_name(stat),20,g.INK);g.text(at+Vector2(46,50),Presenter.value(stat,{stat:amount}),21,g.TEAL)
  g.text(Vector2(465,495),"%s → %s"%[g.Gear.RARITIES[item.rarity],g.Gear.RARITIES[item.rarity+1]],19,g.GOLD)
  g.stat_ui.icon("iron",Vector2(465,507),22);g.text(Vector2(495,526),"%d iron"%cost(item),19,g.TEAL)
 else:g.draw_wrapped("Choose Common or Rare gear. Very rare gear is already at maximum rarity.",Vector2(465,245),280,19,g.INK,5)
 g.panel(Rect2(800,175,390,385));g.text(Vector2(820,205),"ITEM / BEFORE → AFTER",20,g.GOLD)
 var candidate=proposed(index,altar.get("choice",""))
 if not candidate.is_empty():
  g.text(Vector2(1015,235),"NOW",16);g.text(Vector2(1090,235),"AFTER",16,g.TEAL)
  Presenter.draw_comparison(g,g.inventory[index],candidate,Vector2(820,260),350,205,true)
 else:g.draw_wrapped("Select gear and a bonus to preview the item changes.",Vector2(820,260),340,19,g.INK,4)
 if not candidate.is_empty():
  g.text(Vector2(100,590),"BUILD IF EQUIPPED",20,g.GOLD);g.text(Vector2(438,610),"NOW",16);g.text(Vector2(610,610),"AFTER",16,g.TEAL)
  g.build_view.draw_compare(index,{index:candidate},Vector2(100,630),665,70)
 g.front_end.icon_button(Rect2(800,650,390,58),"iron","Upgrade / %d iron"%cost(g.inventory[index]) if index in list else "Choose equipment", "rarity_commit",false,not candidate.is_empty() and index in list and g.iron>=cost(g.inventory[index]) and not g.forge_menu.used("rarity"))
 g.button(Rect2(85,718,340,48),"Back to equipment" if altar.kind=="salvage" else "Leave / decide later","decision_leave")
