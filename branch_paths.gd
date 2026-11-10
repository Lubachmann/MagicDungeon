extends RefCounted
## A single optional side wing per floor; its destination is chosen at the threshold.
const ROOM=Vector2i(-1,0)
const NAMES={"weapon":"Weapon armory","armor":"Armor armory","fire":"Fire chamber","ice":"Frost chamber","acid":"Acid chamber","poison":"Poison chamber","vault":"Dangerous vault","rest":"Restful passage","mine":"Guarded mine"}
const AFFIX={"fire":"fire_dps","ice":"ice_slow","acid":"acid_strip","poison":"poison_weak"}
var g
func _init(game):g=game
func available() -> bool:return g.run_rules>=17
func at_entrance(from: Vector2i,to: Vector2i) -> bool:return available() and from==Vector2i.ZERO and to==ROOM
func prompt() -> void:
 g.floor_flags["branch_stage"]="main";g.mode="branch";g.log_line("Choose one side passage for this floor, or return later.")
func handle(id: String) -> bool:
 if g.mode!="branch":return false
 if id=="branch_leave":g.mode="play";return true
 if id=="branch_back":g.floor_flags["branch_stage"]="armory" if g.floor_flags.get("branch_stage","") in ["weapons","armors"] else "main";return true
 if id=="branch_armory":g.floor_flags["branch_stage"]="armory";return true
 if id=="branch_elements":g.floor_flags["branch_stage"]="elements";return true
 var chosen_weapon="";var chosen_armor=""
 if id.begins_with("branch_armor:"):
  chosen_armor=id.get_slice(":",1)
  if g.floor_flags.get("branch_stage","")!="armors" or chosen_armor not in ["shield","armor","helmet"]:return true
  id="branch_choose:armor"
 if id.begins_with("branch_weapon:"):
  chosen_weapon=id.get_slice(":",1)
  if g.floor_flags.get("branch_stage","")!="weapons" or chosen_weapon not in ["balanced","dagger","axe","greatblade","ember"]:return true
  id="branch_choose:weapon"
 if not id.begins_with("branch_choose:"):return false
 var choice=id.get_slice(":",1)
 if not NAMES.has(choice) or (choice=="mine" and g.run_rules<20):return true
 if choice=="weapon" and chosen_weapon=="" and g.sanctuary and g.sanctuary.active() and g.sanctuary.unlocked("smith"):
  g.floor_flags["branch_stage"]="weapons";return true
 if choice=="armor" and chosen_armor=="" and g.sanctuary and g.sanctuary.active() and g.sanctuary.unlocked("smith") and g.ember_tree.rank("tinkering")>0:
  g.floor_flags["branch_stage"]="armors";return true
 create_room(choice,chosen_weapon,chosen_armor)
 g.floor_flags["branch_choice"]=choice;g.floor_flags.erase("branch_stage")
 g.room=ROOM;g.pos=Vector2i(11,5);g.render_pos=Vector2(g.pos);g.visited[ROOM]=true;g.mode="play"
 if g.movement:g.movement.kill()
 if g.world_choices:g.world_choices.record("route_"+choice)
 g.sfx("door");g.log_line("Entered the "+NAMES[choice]+". Return through the door at any time.")
 return true
func create_room(choice: String,chosen_weapon: String="",chosen_armor: String="") -> void:
 var data={"walls":{},"entities":{},"cleared":false,"seen_crack":false,"seen_water":false,"layout":0,"bounds":Rect2i(0,0,13,11),"gate":Vector2i(-1,-1),"horizontal_gate":false,"cache":Vector2i(-1,-1),"water_cache":Vector2i(-1,-1),"special":Vector2i(3,5),"decor":{},"chest":Vector2i(-1,-1),"atmosphere":[],"branch_choice":choice}
 g.links[ROOM]=[Vector2i.ZERO];g.links[Vector2i.ZERO].append(ROOM);g.roles[ROOM]=NAMES[choice];g.distances[ROOM]=1
 g.rooms[ROOM]=data
 if choice=="rest":
  data.entities[Vector2i(4,5)]={"kind":"rest_site","used":false}
  if g.run_rules<18:data.entities[Vector2i(9,3)]={"kind":"potion"}
  for tile in [Vector2i(3,3),Vector2i(3,7),Vector2i(6,2),Vector2i(6,8)]:data.walls[tile]=true
  return
 # A narrow guarded passage makes the reward a real encounter, not a free pickup.
 for y in range(1,10):
  if y!=5:data.walls[Vector2i(7,y)]=true
 var guard_at=Vector2i(7,5);var enemy=g.make_enemy(g.theme_enemy_type(),2,mini(6,3+(1 if choice=="vault" else 0)))
 enemy.name="Vault guardian" if choice=="vault" else "Passage guardian";enemy["gatekeeper"]=true
 if choice=="vault":enemy.hp=ceili(float(enemy.hp)*1.25);enemy.max=enemy.hp;enemy.attack=ceilf(float(enemy.attack)*1.15);enemy.elite=true
 data.entities[guard_at]=enemy;data.gate=guard_at
 if choice=="mine":
  data.entities[Vector2i(3,4)]={"kind":"ore_deposit"}
  data.entities[Vector2i(3,6)]={"kind":"ore_deposit"}
  return
 var chest_at=Vector2i(3,5);var tier=2 if choice=="vault" else 1
 var slot="weapon" if choice=="weapon" else ["armor","helmet","shield"][g.rng.randi_range(0,2)] if choice=="armor" else ""
 if chosen_armor!="":slot=chosen_armor
 var item=g.chest_item(tier,choice=="vault",slot)
 if chosen_weapon!="":
  item.archetype=chosen_weapon;item.name={"balanced":"Sword","dagger":"Dagger","axe":"Axe","greatblade":"Greatblade","ember":"Ember blade"}[chosen_weapon]
  item.erase("variant");item.erase("heavy_form")
 if choice=="vault" and int(item.rarity)<1:
  item.rarity=1
  if item.affixes.is_empty():item.affixes.append(g.Gear.AFFIXES[g.rng.randi_range(0,g.Gear.AFFIXES.size()-1)])
 if AFFIX.has(choice):
  if g.run_rules>=20:item["blueprint_element"]=choice
  item.rarity=maxi(1,int(item.rarity));var affix=AFFIX[choice]
  if affix not in item.affixes:
   if item.affixes.size()>=int(item.rarity):item.affixes[0]=affix
   else:item.affixes.append(affix)
 data.entities[chest_at]={"kind":"chest","tier":tier,"style":"guardian","guardian":guard_at,"item":item}
 data.chest=chest_at
 for tile in [Vector2i(3,2),Vector2i(3,8),Vector2i(5,3),Vector2i(5,7),Vector2i(10,2),Vector2i(10,8)]:data.walls[tile]=true
func draw() -> void:
 g.front_end.overlay(Rect2(210,115,860,610))
 g.text(Vector2(250,165),"CHOOSE A SIDE PASSAGE",32,g.GOLD)
 var stage=g.floor_flags.get("branch_stage","main")
 if stage=="main":
  g.draw_wrapped("Choose one for this floor. The other passages close; the main dungeon stays open.",Vector2(250,205),780,20,g.INK,2)
  var offers=[["hammer","ARMORY","Fight for a weapon or armor blueprint.","branch_armory"],["fire","ELEMENTAL CHAMBER","Fight for an elemental blueprint.","branch_elements"],["vault","DANGEROUS VAULT","A stronger guardian protects rare blueprints.","branch_choose:vault"],["potion","RESTFUL PASSAGE","No guardian. Rest, gain a flask or train." if g.run_rules>=18 else "No guardian. Find a flask and a rest site.","branch_choose:rest"]]
  if g.run_rules>=20:offers.append(["iron","GUARDED MINE","Fight a guardian to reach two ore deposits.","branch_choose:mine"])
  var spacing=74 if offers.size()>4 else 92
  for i in range(offers.size()):
   var at=Vector2(250,245+i*spacing);g.button(Rect2(at,Vector2(780,68 if offers.size()>4 else 80)),"",offers[i][3]);g.ui_icon(offers[i][0],at+Vector2(14,10),40)
   g.text(at+Vector2(75,28),offers[i][1],21,g.GOLD);g.text(at+Vector2(75,53),offers[i][2],17,g.INK)
 else:
  g.text(Vector2(250,215),"Choose a reward focus. A guardian protects the chest.",20,g.INK)
  var choices=["weapon","armor"] if stage=="armory" else (["balanced","dagger","axe","greatblade","ember"] if stage=="weapons" else (["shield","armor","helmet"] if stage=="armors" else ["fire","ice","acid","poison"]))
  for i in range(choices.size()):
   var choice=choices[i];var at=Vector2(250,255+i*(68 if stage=="weapons" else 82))
   g.button(Rect2(at,Vector2(780,60 if stage=="weapons" else 70)),"",("branch_weapon:" if stage=="weapons" else "branch_armor:" if stage=="armors" else "branch_choose:")+choice)
   g.ui_icon("attack" if stage=="weapons" else "armor" if stage=="armors" else {"weapon":"attack","armor":"armor","fire":"fire","ice":"ice","acid":"acid","poison":"poison"}[choice],at+Vector2(15,10),38)
   g.text(at+Vector2(80,40),{"balanced":"Sword","dagger":"Dagger","axe":"Axe","greatblade":"Greatblade","ember":"Ember blade"}[choice] if stage=="weapons" else choice.capitalize() if stage=="armors" else NAMES[choice],25,g.GOLD)
  g.button(Rect2(250,625,350,52),"Back to passages","branch_back")
 g.button(Rect2(660,625,370,52),"Leave / decide later","branch_leave")
