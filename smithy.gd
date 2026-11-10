extends RefCounted
## Persistent workshop and expedition rewards. Run cargo lives in checkpointed run_metrics.
const RECIPES={
 "sword":["Sword","weapon","balanced"],"dagger":["Dagger","weapon","dagger"],"axe":["Axe","weapon","axe"],"greatblade":["Greatblade","weapon","greatblade"],"ember":["Ember blade","weapon","ember"],
 "shield":["Shield","shield","balanced"],"heavy_armor":["Heavy armor","armor","balanced"],"light_armor":["Light armor","armor","balanced"],"helmet":["Helmet","helmet","balanced"],"amulet":["Amulet","amulet","balanced"],
 "sword_keen":["Keen sword","weapon","balanced"],
 "sword_swift":["Swift sword","weapon","balanced"],
 "sword_bloodbound":["Bloodbound sword","weapon","balanced"],
 "dagger_keen":["Keen dagger","weapon","dagger"],
 "dagger_swift":["Swift dagger","weapon","dagger"],
 "dagger_bloodbound":["Bloodbound dagger","weapon","dagger"],
 "axe_keen":["Keen axe","weapon","axe"],
 "axe_swift":["Swift axe","weapon","axe"],
 "axe_bloodbound":["Bloodbound axe","weapon","axe"],
 "greatblade_keen":["Keen greatblade","weapon","greatblade"],
 "greatblade_swift":["Swift greatblade","weapon","greatblade"],
 "greatblade_bloodbound":["Bloodbound greatblade","weapon","greatblade"],
 "ember_keen":["Keen ember blade","weapon","ember"],
 "ember_swift":["Swift ember blade","weapon","ember"],
 "ember_bloodbound":["Bloodbound ember blade","weapon","ember"],
 "shield_keen":["Keen shield","shield","balanced"],
 "shield_swift":["Swift shield","shield","balanced"],
 "shield_bloodbound":["Bloodbound shield","shield","balanced"],
 "heavy_armor_keen":["Keen heavy armor","armor","balanced"],
 "heavy_armor_swift":["Swift heavy armor","armor","balanced"],
 "heavy_armor_bloodbound":["Bloodbound heavy armor","armor","balanced"],
 "light_armor_keen":["Keen light armor","armor","balanced"],
 "light_armor_swift":["Swift light armor","armor","balanced"],
 "light_armor_bloodbound":["Bloodbound light armor","armor","balanced"],
 "helmet_keen":["Keen helmet","helmet","balanced"],
 "helmet_swift":["Swift helmet","helmet","balanced"],
 "helmet_bloodbound":["Bloodbound helmet","helmet","balanced"],
 "amulet_keen":["Keen amulet","amulet","balanced"],
 "amulet_swift":["Swift amulet","amulet","balanced"],
 "amulet_bloodbound":["Bloodbound amulet","amulet","balanced"],
 "bloodletter":["Bloodletter","weapon","dagger"],
 "winterblade":["Winterblade","weapon","greatblade"],
 "caustic":["Caustic brand","weapon","ember"],
 "colossus_axe":["Colossus axe","weapon","axe"],
 "colossus_greatblade":["Colossus greatblade","weapon","greatblade"]}
const SPECIALS={
 "bloodletter":{"base":"dagger","variant":"bloodletter","mastery":"bloodletter"},
 "winterblade":{"base":"greatblade","variant":"winterblade","mastery":"winterblade"},
 "caustic":{"base":"ember","variant":"caustic","mastery":"caustic"},
 "colossus_axe":{"base":"axe","heavy_form":"colossus","floor":3},
 "colossus_greatblade":{"base":"greatblade","heavy_form":"colossus","floor":3}}
const PAGE_SIZE=18
const VARIANTS={
 "sword_keen":["sword","crit_chance",1,2,"alloy"],
 "sword_swift":["sword","speed",1,3,"essence"],
 "sword_bloodbound":["sword","vampirism",2,4,"relic"],
 "dagger_keen":["dagger","crit_chance",1,2,"alloy"],
 "dagger_swift":["dagger","speed",1,3,"essence"],
 "dagger_bloodbound":["dagger","vampirism",2,4,"relic"],
 "axe_keen":["axe","crit_chance",1,2,"alloy"],
 "axe_swift":["axe","speed",1,3,"essence"],
 "axe_bloodbound":["axe","vampirism",2,4,"relic"],
 "greatblade_keen":["greatblade","crit_chance",1,2,"alloy"],
 "greatblade_swift":["greatblade","speed",1,3,"essence"],
 "greatblade_bloodbound":["greatblade","vampirism",2,4,"relic"],
 "ember_keen":["ember","crit_chance",1,2,"alloy"],
 "ember_swift":["ember","speed",1,3,"essence"],
 "ember_bloodbound":["ember","vampirism",2,4,"relic"],
 "shield_keen":["shield","crit_chance",1,2,"alloy"],
 "shield_swift":["shield","speed",1,3,"essence"],
 "shield_bloodbound":["shield","vampirism",2,4,"relic"],
 "heavy_armor_keen":["heavy_armor","crit_chance",1,2,"alloy"],
 "heavy_armor_swift":["heavy_armor","speed",1,3,"essence"],
 "heavy_armor_bloodbound":["heavy_armor","vampirism",2,4,"relic"],
 "light_armor_keen":["light_armor","crit_chance",1,2,"alloy"],
 "light_armor_swift":["light_armor","speed",1,3,"essence"],
 "light_armor_bloodbound":["light_armor","vampirism",2,4,"relic"],
 "helmet_keen":["helmet","crit_chance",1,2,"alloy"],
 "helmet_swift":["helmet","speed",1,3,"essence"],
 "helmet_bloodbound":["helmet","vampirism",2,4,"relic"],
 "amulet_keen":["amulet","crit_chance",1,2,"alloy"],
 "amulet_swift":["amulet","speed",1,3,"essence"],
 "amulet_bloodbound":["amulet","vampirism",2,4,"relic"]
}
const MATERIALS=["ore","monster","boss","alloy","essence","relic"]
const LABELS={"ore":"Ore","monster":"Parts","boss":"Cores","alloy":"Guard alloy","essence":"Imp essence","relic":"Mire gel"}
# Existing artwork is used as a temporary visual marker until dedicated material sprites exist.
const MATERIAL_ICONS={"ore":"iron","monster":"attack","boss":"relic","alloy":"armor","essence":"ice","relic":"poison"}
const MATERIAL_HELP={"ore":"Mined from deposits or found at old forges. The guarded mine contains two deposits.","monster":"Dropped by defeated enemies. Elite enemies drop extra parts.","boss":"Dropped by Wardens. Some chest and reliquary rewards can also contain cores.","alloy":"Dropped by guard-type enemies from floor 2 onward.","essence":"Dropped by imp-type enemies from floor 3 onward.","relic":"Dropped by slime-type enemies from floor 4 onward."}
var g
var page=0
var message=""
var infusion_item=""
var detail_item=""
var tab="weapon"
var selected_blueprint=""
var stats_page=0
var filter_index=0
const FILTERS=["All","Craftable","Owned","Undiscovered","Keen","Swift","Bloodbound","Special"]
var return_mode="sanctuary"
var notices: Array=[]
var notice_time=0.0
const NOTICE_SECONDS=3.5
const ELEMENTS=["fire","ice","acid","poison"]
func _init(game):g=game
static func empty() -> Dictionary:return {"blueprints":{"sword":true},"items":{"sword":1},"loadout":{"weapon":"sword"},"materials":{"ore":0,"monster":0,"boss":0,"alloy":0,"essence":0,"relic":0},"elements":{},"infusions":{},"goal":{},"unseen_blueprints":{},"unseen_items":{},"unseen_runes":{},"metrics":{},"slot_levels":{"weapon":1,"shield":1,"armor":1,"helmet":1,"amulet":1}}
func data() -> Dictionary:
 if not g.career.has("workshop") or not g.career.workshop is Dictionary:g.career["workshop"]=empty()
 var p=g.career.workshop;var defaults=empty()
 # Older saves stored upgrades on individual items. Keep the best level in each slot.
 if not p.get("slot_levels") is Dictionary:
  var migrated=defaults.slot_levels.duplicate()
  if p.get("items") is Dictionary:
   for id in p.items:
    if RECIPES.has(id):
     var slot=RECIPES[id][1];migrated[slot]=maxi(int(migrated[slot]),clampi(int(p.items[id]),1,5))
  p["slot_levels"]=migrated
 for key in defaults:
  if not p.get(key) is Dictionary:p[key]=defaults[key].duplicate(true)
 for key in defaults.materials:
  if not p.materials.has(key):p.materials[key]=0
 for slot in g.Gear.SLOTS:
  p.slot_levels[slot]=clampi(int(p.slot_levels.get(slot,1)),1,5)
 # Migrate completed masteries and grant newly completed ones idempotently.
 # Blueprint ownership is the receipt; inspecting it never grants duplicate ore.
 var goals=preload("res://build_mastery.gd").GOALS
 for id in SPECIALS:
  var mastery_id=str(SPECIALS[id].get("mastery",""))
  if mastery_id=="" or p.blueprints.has(id):continue
  var goal=goals[mastery_id]
  if int(g.career.get("mastery",{}).get(goal.metric,0))>=int(goal.target):
   p.blueprints[id]=true;p.unseen_blueprints[id]=true
 return p
func cargo() -> Dictionary:
 if not g.run_metrics.get("cargo") is Dictionary:g.run_metrics["cargo"]={"blueprints":{},"ore":0,"monster":0,"boss":0,"committed":false}
 var c=g.run_metrics.cargo
 if not c.get("elements") is Dictionary:c["elements"]={}
 for material in MATERIALS:
  if not c.has(material):c[material]=0
 return c
func recipe_id(item: Dictionary) -> String:
 var slot=str(item.get("slot","weapon"))
 if slot=="weapon":return str(item.get("archetype","balanced")) if item.get("archetype","balanced")!="balanced" else "sword"
 if slot=="armor":return "light_armor" if item.get("armor_class","")=="light" else "heavy_armor"
 return slot if RECIPES.has(slot) else "sword"
func reward(item: Dictionary,amount: int=1) -> String:
 var id=recipe_id(item);var c=cargo();var p=data()
 var element=str(item.get("blueprint_element",""))
 if element in ELEMENTS:
  if p.elements.has(element) or c.elements.has(element):c.ore+=3+amount;return "Known "+element.capitalize()+" rune: +%d ore"%(3+amount)
  c.elements[element]=true;show_discovery("rune",element);return element.capitalize()+" rune blueprint discovered"
 var max_rarity=clampi(int(item.get("rarity",0)),0,2)
 var pool=discovery_candidates(id,max_rarity,g.floor_number)
 var unseen=[]
 for key in pool:
  if not p.blueprints.has(key) and not c.blueprints.has(key):unseen.append(key)
 if not unseen.is_empty():id=unseen[g.rng.randi_range(0,unseen.size()-1)]
 if p.blueprints.has(id) or c.blueprints.has(id):c.ore+=2+amount;return "Known blueprint: +%d ore"%(2+amount)
 c.blueprints[id]=true;show_discovery("equipment",id);return "Blueprint discovered: "+RECIPES[id][0]
func discovery_candidates(base: String,rarity: int,floor_number: int) -> Array:
 var result=[base]
 for id in VARIANTS:
  var v=VARIANTS[id]
  if v[0]==base and int(v[2])<=rarity and int(v[3])<=floor_number:result.append(id)
 for id in SPECIALS:
  var special=SPECIALS[id]
  if not special.has("mastery") and special.base==base and rarity>=1 and floor_number>=int(special.floor):result.append(id)
 return result
func base_recipe(id: String) -> String:
 if SPECIALS.has(id):return str(SPECIALS[id].base)
 return str(VARIANTS[id][0]) if VARIANTS.has(id) else id
func show_discovery(kind: String,id: String) -> void:
 notices.append({"kind":kind,"id":id})
 if notices.size()==1:notice_time=NOTICE_SECONDS
func clear_notices() -> void:
 notices.clear();notice_time=0.0
func tick_notices(delta: float) -> void:
 if notices.is_empty() or g.mode not in ["play","fight","inspect"]:return
 notice_time-=delta
 if notice_time<=0:
  notices.pop_front()
  notice_time=NOTICE_SECONDS if not notices.is_empty() else 0.0
func draw_notice() -> void:
 if notices.is_empty() or g.mode not in ["play","fight","inspect"]:return
 var entry=notices[0];var id=str(entry.id);var at=Vector2(405,174)
 g.panel(Rect2(at,Vector2(470,100)))
 if entry.kind=="rune":
  g.ui_icon(id,at+Vector2(18,22),56)
  g.text(at+Vector2(90,62),id.capitalize()+" rune",24,g.GOLD)
 else:
  var item=make_item(id,1);var rarity=int(item.rarity)
  g.gear_icon(item.slot,at+Vector2(18,22),56,g.Gear.COLORS[rarity],item)
  g.text(at+Vector2(90,62),RECIPES[id][0],24,g.Gear.COLORS[rarity])
 g.text(at+Vector2(90,30),"NEW BLUEPRINT",17,g.TEAL)
 g.text(at+Vector2(90,84),"Take it to the Hearth smithy",16,g.INK)
func commit() -> void:
 var c=cargo()
 if c.committed:return
 c.committed=true
 if g.demo_run or g.run_settings.get("mode","")=="daily":return
 var p=data()
 for id in c.blueprints:
  if RECIPES.has(id):
   if not p.blueprints.has(id):p.unseen_blueprints[id]=true
   p.blueprints[id]=true
 for element in c.elements:
  if element in ELEMENTS:
   if not p.elements.has(element):p.unseen_runes[element]=true
   p.elements[element]=true
 for key in MATERIALS:p.materials[key]=int(p.materials.get(key,0))+maxi(0,int(c.get(key,0)))
func make_item(id: String,level: int,element: String="") -> Dictionary:
 var spec=RECIPES[id]
 # Crafted equipment must be deterministic; g.make_gear randomly rolls amulets.
 var variant=VARIANTS.get(id,[])
 var rarity=1 if SPECIALS.has(id) else int(variant[2]) if not variant.is_empty() else 0
 var affixes=[variant[1]] if not variant.is_empty() else []
 var item=g.Gear.make(spec[1],level,rarity,affixes,spec[2]);item["balance"]=7;item.name=spec[0]
 if not variant.is_empty():
  item["forge_style"]=id.get_slice("_",id.get_slice_count("_")-1)
  if spec[1]=="weapon":item["family_revision"]=2
 if SPECIALS.has(id):
  for key in ["variant","heavy_form"]:
   if SPECIALS[id].has(key):item[key]=SPECIALS[id][key]
 if spec[1]=="armor":item.armor_class="light" if id.begins_with("light_armor") else "heavy"
 if element in ELEMENTS:item["infusion"]=element
 return item
func style_description(item: Dictionary) -> String:
 if item.get("heavy_form","")=="colossus":return "Colossus: stronger physical hits, slower attacks."
 match item.get("variant",""):
  "bloodletter":return "Bloodletter: lifesteal replaces innate evade."
  "winterblade":return "Winterblade: Frost power, less item attack."
  "caustic":return "Caustic brand: Acid power, less Fire potency."
 var style=str(item.get("forge_style",""));var slot=str(item.get("slot",""))
 if slot=="weapon":
  match style:
   "keen":return "Keen: stronger critical hits and higher crit chance."
   "swift":return "Swift: faster combos and triggers; 5% less item attack."
   "bloodbound":return "Bloodbound: lifesteal; 10% less item attack."
 elif slot in ["shield","armor","helmet"]:
  match style:
   "keen":return "Keen: crit chance and armor; slower attacks."
   "swift":return "Swift: speed and evade; less armor."
   "bloodbound":return "Bloodbound: lifesteal and health; less armor."
 elif slot=="amulet":
  match style:
   "keen":return "Keen: crit chance and crit damage."
   "swift":return "Swift: faster attacks and evade."
   "bloodbound":return "Bloodbound: lifesteal and health."
 return ""
func start_loadout() -> void:
 var p=data();var selected=p.loadout if g.run_settings.get("mode","")!="daily" else {"weapon":"sword"}
 for slot in g.Gear.SLOTS:
  var id=str(selected.get(slot,""))
  if not RECIPES.has(id) or not p.items.has(id) and g.run_settings.get("mode","")!="daily":continue
  var level=int(p.slot_levels.get(slot,1)) if g.run_settings.get("mode","")!="daily" else 1
  var element=str(p.infusions.get(id,"")) if g.run_settings.get("mode","")!="daily" else ""
  var item=make_item(id,level,element)
  g.inventory.append(item);g.equipped[slot]=g.inventory.size()-1
func slot_level(id: String) -> int:
 return int(data().slot_levels.get(RECIPES[id][1],1)) if RECIPES.has(id) else 1
func cost_for(id: String,level: int) -> Dictionary:
 var costs={"ore":3+level*3,"monster":2+level*2,"boss":1 if level>=2 else 0}
 if VARIANTS.has(id):
  var v=VARIANTS[id];costs[v[4]]=1+int(level/2)
 if SPECIALS.has(id):costs.boss=maxi(1,int(costs.boss))
 return costs
func slot_cost(slot: String) -> Dictionary:
 var level=int(data().slot_levels.get(slot,1))
 return {"ore":3+level*3,"monster":2+level*2,"boss":1 if level>=2 else 0}
func blueprint_source(id: String) -> String:
 if SPECIALS.has(id):
  var special=SPECIALS[id]
  if special.has("mastery"):return "Mastery: "+preload("res://build_mastery.gd").GOALS[special.mastery].requirement
  return "F%d+ %s reward / Rare+ / chance"%[special.floor,RECIPES[special.base][0]]
 var v=VARIANTS.get(id,[]);var base_id=str(v[0]) if not v.is_empty() else id
 var base_name=str(RECIPES[base_id][0])
 var floor_number=int(v[3]) if not v.is_empty() else 1
 var rarity="Rare+ " if not v.is_empty() and int(v[2])==1 else "Very rare " if not v.is_empty() else ""
 return "F%d+ %s reward / %s / chance"%[floor_number,base_name,rarity.strip_edges() if rarity!="" else "any rarity"]
func goal_info(include_cargo: bool=false) -> Dictionary:
 var p=data();var goal=p.goal;var kind=str(goal.get("kind",""));var id=str(goal.get("id",""))
 var title="";var costs={};var finished=false;var blueprint_missing=false
 var live=include_cargo and not g.demo_run and g.run_settings.get("mode","")!="daily" and not cargo().get("committed",false)
 if kind=="craft" and RECIPES.has(id):
  title=RECIPES[id][0];costs=cost_for(id,0);finished=p.items.has(id)
  blueprint_missing=not p.blueprints.has(id) and not (live and cargo().blueprints.has(id))
 elif kind=="slot" and id in g.Gear.SLOTS:
  title=id.capitalize()+" slot";costs=slot_cost(id);finished=int(p.slot_levels[id])>=int(goal.get("target",5))
 else:return {}
 var lines=[];var entries=[];var sources=[];var ready=not blueprint_missing
 if blueprint_missing:sources.append(blueprint_source(id))
 for material in MATERIALS:
  var needed=int(costs.get(material,0))
  if needed<=0:continue
  var held=int(p.materials.get(material,0))+(int(cargo().get(material,0)) if live else 0)
  if held<needed:
   ready=false
   sources.append({"ore":"Ore: deposits / Forges","monster":"Parts: enemies","boss":"Cores: Wardens","alloy":"Alloy: guard-type foes F2+","essence":"Essence: imp-type foes F3+","relic":"Gel: slime-type foes F4+"}.get(material,material))
  lines.append("%s %d/%d"%[LABELS[material],mini(held,needed),needed])
  entries.append({"id":material,"value":"%d/%d"%[mini(held,needed),needed]})
 return {"kind":kind,"id":id,"title":title,"lines":lines,"entries":entries,"blueprint_missing":blueprint_missing,"ready":ready and not finished,"finished":finished,"sources":sources}
func material_entries(amounts: Dictionary) -> Array:
 var result=[]
 for material in MATERIALS:
  if int(amounts.get(material,0))>0:result.append({"id":material,"value":str(amounts[material])})
 return result
func cost_progress_entries(costs: Dictionary) -> Array:
 var result=[];var stored=data().materials
 for material in MATERIALS:
  var needed=int(costs.get(material,0))
  if needed>0:result.append({"id":material,"value":"%d/%d"%[int(stored.get(material,0)),needed],"short":int(stored.get(material,0))<needed})
 return result
func draw_materials(entries: Array,at: Vector2,cell_width: float=180.0,size: int=20) -> void:
 for i in range(entries.size()):
  var entry=entries[i];var id=str(entry.get("id",""))
  if not MATERIAL_ICONS.has(id):continue
  var pos=at+Vector2(i*cell_width,0)
  g.ui_icon(MATERIAL_ICONS[id],pos,size)
  g.stat_ui.register(MATERIAL_ICONS[id],Rect2(pos,Vector2(size,size)).grow(3),LABELS[id],MATERIAL_HELP[id])
  g.text(pos+Vector2(size+4,size-3),LABELS[id]+" "+str(entry.get("value","")),15,Color("e88882") if entry.get("short",false) else g.TEAL)
func discovery_pool_size(id: String) -> int:
 if SPECIALS.has(id) and SPECIALS[id].has("mastery"):return 1
 var v=VARIANTS.get(id,[]);var base=base_recipe(id)
 var minimum_floor=int(v[3]) if not v.is_empty() else 1;var rarity=int(v[2]) if not v.is_empty() else 0
 if SPECIALS.has(id):minimum_floor=int(SPECIALS[id].floor);rarity=1
 var p=data();var count=0
 for key in discovery_candidates(base,rarity,minimum_floor):
  if not p.blueprints.has(key):count+=1
 return maxi(1,count)
func cost_text(costs: Dictionary) -> String:
 var parts=[]
 for material in MATERIALS:
  if int(costs.get(material,0))>0:parts.append("%d %s"%[costs[material],LABELS[material]])
 return " / ".join(parts)
func handle(id:String) -> bool:
 if id=="smithy_open" and g.mode in ["sanctuary","title","dead","won","loadout"]:
  return_mode=g.mode;g.mode="smithy";page=0;tab="weapon";selected_blueprint="";infusion_item="";detail_item="";message="";return true
 if g.mode!="smithy":return false
 if id=="smithy_back":
  if infusion_item!="":infusion_item=""
  elif detail_item!="":detail_item=""
  else:g.mode=return_mode
  return true
 if id.begins_with("smithy_tab:"):
  var slot=id.trim_prefix("smithy_tab:")
  if slot in g.Gear.SLOTS:tab=slot;page=0;stats_page=0;selected_blueprint="";message=""
  return true
 if id.begins_with("smithy_select:"):
  var key=id.trim_prefix("smithy_select:")
  if RECIPES.has(key) and RECIPES[key][1]==tab:
   if selected_blueprint!=key:stats_page=0
   selected_blueprint=key;message=""
   var p=data()
   if p.unseen_blueprints.has(key):
    p.unseen_blueprints.erase(key)
    if not g.session.commit_profile():p.unseen_blueprints[key]=true
  return true
 if id=="smithy_filter":filter_index=posmod(filter_index+1,FILTERS.size());page=0;selected_blueprint="";message="";return true
 if id=="smithy_stats_prev":stats_page=maxi(0,stats_page-1);return true
 if id=="smithy_stats_next":stats_page+=1;return true
 if id.begins_with("smithy_track:"):
  var key=id.trim_prefix("smithy_track:");var p=data()
  if not RECIPES.has(key) or p.items.has(key):return true
  var old=p.goal.duplicate(true);p.goal={"kind":"craft","id":key}
  if not g.session.commit_profile():p.goal=old;message="Could not save tracked goal.";return true
  message="Tracking "+RECIPES[key][0]+". Check your expedition screen and journal.";return true
 if id.begins_with("smithy_track_slot:"):
  var target=id.trim_prefix("smithy_track_slot:");var p=data()
  if target not in g.Gear.SLOTS or int(p.slot_levels[target])>=5:return true
  var old=p.goal.duplicate(true);p.goal={"kind":"slot","id":target,"target":int(p.slot_levels[target])+1}
  if not g.session.commit_profile():p.goal=old;message="Could not save tracked goal.";return true
  message="Tracking "+target+" slot upgrade.";return true
 if id=="smithy_untrack":
  var p=data();var old=p.goal.duplicate(true);p.goal={}
  if not g.session.commit_profile():p.goal=old;message="Could not clear tracked goal.";return true
  message="Tracking cleared.";return true
 if id.begins_with("smithy_details:"):
  var key=id.trim_prefix("smithy_details:")
  if RECIPES.has(key) and data().blueprints.has(key):detail_item=key
  return true
 if id.begins_with("smithy_runes:"):
  var key=id.trim_prefix("smithy_runes:")
  if data().items.has(key) and RECIPES.has(key):infusion_item=key;message=""
  return true
 if id=="smithy_runes_seen":
  var p=data();var old=p.unseen_runes.duplicate(true);p.unseen_runes.clear()
  if not g.session.commit_profile():p.unseen_runes=old;message="Could not save rune markers."
  else:message="Rune discoveries marked as seen."
  return true
 if id.begins_with("smithy_infuse:"):
  var element=id.trim_prefix("smithy_infuse:");var p=data()
  if not p.items.has(infusion_item) or element not in ELEMENTS or not p.elements.has(element):return true
  if str(p.infusions.get(infusion_item,""))==element:message=element.capitalize()+" rune is already applied. No materials spent.";return true
  var cost=maxi(1,3-g.ember_tree.rank("runeforge",false))
  if p.materials.ore<cost or p.materials.monster<2:message="Not enough materials.";return true
  var before=p.duplicate(true);p.materials.ore-=cost;p.materials.monster-=2;p.infusions[infusion_item]=element
  if not g.session.commit_profile():g.career.workshop=before;message="Could not save infusion; materials restored.";return true
  message="Applied: "+element.capitalize()+" rune on "+RECIPES[infusion_item][0]+". Saved for future runs.";return true
 if id=="smithy_next":page=mini(maxi(0,int((filtered_ids(tab).size()-1)/PAGE_SIZE)),page+1);return true
 if id=="smithy_prev":page=maxi(0,page-1);return true
 if id.begins_with("smithy_make:"):
  var key=id.trim_prefix("smithy_make:");var p=data()
  if not RECIPES.has(key) or not p.blueprints.has(key) or p.items.has(key):return true
  var costs=cost_for(key,0)
  for material in costs:
   if int(p.materials.get(material,0))<int(costs[material]):message="Need "+str(costs[material])+" "+LABELS[material]+".";return true
  var before=p.duplicate(true)
  for material in costs:p.materials[material]-=costs[material]
  p.items[key]=1;p.unseen_items[key]=true
  if g.playtest:g.playtest.crafted(p,key)
  if not g.session.commit_profile():g.career.workshop=before;message="Could not save crafting; materials restored.";return true
  message=RECIPES[key][0]+" crafted. It uses the shared "+RECIPES[key][1]+" slot level.";return true
 if id.begins_with("smithy_upgrade_slot:"):
  var slot=id.trim_prefix("smithy_upgrade_slot:");var p=data()
  if slot not in g.Gear.SLOTS:return true
  var level=int(p.slot_levels[slot]);if level>=5:message="Maximum slot level reached.";return true
  var costs={"ore":3+level*3,"monster":2+level*2,"boss":1 if level>=2 else 0}
  for material in costs:
   if int(p.materials.get(material,0))<int(costs[material]):message="Need "+str(costs[material])+" "+LABELS[material]+".";return true
  var before=p.duplicate(true)
  for material in costs:p.materials[material]-=costs[material]
  p.slot_levels[slot]=level+1
  if not g.session.commit_profile():g.career.workshop=before;message="Could not save upgrade; materials restored.";return true
  message=slot.capitalize()+" slot upgraded to level %d. All its items benefit."%(level+1);return true
 if id.begins_with("smithy_equip:"):
  var key=id.trim_prefix("smithy_equip:");var p=data()
  if not RECIPES.has(key) or not p.items.has(key):return true
  var slot=RECIPES[key][1];var before=p.loadout.duplicate();p.loadout[slot]=key
  if not g.session.commit_profile():p.loadout=before;message="Could not save loadout.";return true
  message=RECIPES[key][0]+" equipped for the next expedition.";return true
 return true
func category_ids(slot: String) -> Array:
 var ids=[]
 for id in RECIPES:
  if RECIPES[id][1]==slot:ids.append(id)
 return ids
func filtered_ids(slot: String) -> Array:
 var p=data();var result=[];var filter=FILTERS[filter_index]
 for id in category_ids(slot):
  var known=p.blueprints.has(id);var owned=p.items.has(id);var can_craft=known and not owned
  if can_craft:
   for material in cost_for(id,0):
    if int(p.materials.get(material,0))<int(cost_for(id,0)[material]):can_craft=false
  if filter=="Craftable" and not can_craft:continue
  if filter=="Owned" and not owned:continue
  if filter=="Undiscovered" and known:continue
  if filter in ["Keen","Swift","Bloodbound"] and not id.ends_with("_"+filter.to_lower()):continue
  if filter=="Special" and not SPECIALS.has(id):continue
  result.append(id)
 return result
func material_sources(costs: Dictionary) -> String:
 var sources={"ore":"Ore: deposits / forge","monster":"Parts: enemies","boss":"Cores: Wardens","alloy":"Alloy: guards F2+","essence":"Essence: imps F3+","relic":"Gel: slimes F4+"};var parts=[];var p=data()
 for material in MATERIALS:
  if int(costs.get(material,0))>int(p.materials.get(material,0)):parts.append(sources[material])
 return "  /  ".join(parts)
func blueprint_count(p: Dictionary,slot: String="") -> int:
 var count=0
 for id in RECIPES:
  if (slot=="" or RECIPES[id][1]==slot) and p.blueprints.has(id):count+=1
 return count
func draw() -> void:
 g.front_end.menu_backdrop();var p=data();g.text(Vector2(60,68),"THE SMITHY",34,g.GOLD)
 g.ui_icon("book",Vector2(880,39),26);g.text(Vector2(914,60),"BLUEPRINTS %d / %d"%[blueprint_count(p),RECIPES.size()],18,g.TEAL)
 var resources=[]
 for material in MATERIALS:resources.append({"id":material,"value":str(p.materials[material])})
 draw_materials(resources,Vector2(60,84),192)
 if infusion_item!="":
  var current=str(p.infusions.get(infusion_item,""));var level=slot_level(infusion_item)
  var presenter=preload("res://equipment_presenter.gd");var base=presenter.numbers(make_item(infusion_item,level))
  g.text(Vector2(70,175),"RUNES / "+RECIPES[infusion_item][0].to_upper(),26,g.GOLD)
  if current in ELEMENTS:g.ui_icon(current,Vector2(72,191),28)
  g.text(Vector2(110,214),"Applied: "+(current.capitalize() if current in ELEMENTS else "None"),21,g.TEAL)
  g.draw_wrapped("Choose a discovered rune. It replaces the current rune and stays on this item.",Vector2(70,252),1050,20,g.INK,2)
  g.text(Vector2(70,286),"Cost to apply:",18,g.INK)
  draw_materials(material_entries({"ore":maxi(1,3-g.ember_tree.rank("runeforge",false)),"monster":2}),Vector2(220,267),165,22)
  for i in range(ELEMENTS.size()):
   var e=ELEMENTS[i];var at=Vector2(80+(i%2)*550,315+int(i/2)*125);var known=p.elements.has(e)
   var stat={"fire":"fire_power","ice":"frost_apply","acid":"acid_apply","poison":"poison_apply"}[e]
   var after=presenter.numbers(make_item(infusion_item,level,e));var delta=float(after.get(stat,0))-float(base.get(stat,0))
   g.button(Rect2(at,Vector2(510,100)),"","smithy_infuse:"+e,current==e,known and current!=e)
   g.ui_icon(e,at+Vector2(15,20),48)
   if known:g.stat_ui.register(e,Rect2(at+Vector2(15,20),Vector2(48,48)),e.capitalize()+" rune",preload("res://element_rules.gd").brief(e,true))
   g.text(at+Vector2(80,38),e.capitalize()+(" / APPLIED" if current==e else "")+(" / NEW" if p.unseen_runes.has(e) else "") if known else "Undiscovered rune",22,g.GOLD if known else g.INK)
   if known:g.text(at+Vector2(80,72),presenter.value(stat,{stat:delta})+" "+g.stat_ui.short_name(stat),18,g.TEAL)
  g.text(Vector2(70,710),message,18,g.TEAL);g.button(Rect2(70,744,260,50),"Back to smithy","smithy_back")
  if not p.unseen_runes.is_empty():g.button(Rect2(360,744,300,50),"Mark runes seen","smithy_runes_seen")
  return
 for i in range(g.Gear.SLOTS.size()):
  var slot=g.Gear.SLOTS[i];var rect=Rect2(60+i*232,125,218,55)
  g.button(rect,"","smithy_tab:"+slot,tab==slot);g.gear_icon(slot,rect.position+Vector2(10,9),32);g.text(rect.position+Vector2(52,34),slot.capitalize(),19,g.GOLD if tab==slot else g.INK)
 g.panel(Rect2(60,195,570,485));g.panel(Rect2(650,195,570,485))
 g.text(Vector2(80,227),tab.to_upper()+" BLUEPRINTS  %d / %d"%[blueprint_count(p,tab),category_ids(tab).size()],19,g.GOLD)
 g.button(Rect2(415,200,195,35),"Filter: "+FILTERS[filter_index],"smithy_filter")
 var ids=filtered_ids(tab);var pages=maxi(1,ceili(float(ids.size())/PAGE_SIZE));page=clampi(page,0,pages-1)
 var inspected=selected_blueprint
 if ids.is_empty():g.draw_wrapped("No blueprints match this filter.",Vector2(90,290),460,20,g.INK,2)
 for i in range(PAGE_SIZE):
  var index=page*PAGE_SIZE+i
  if index>=ids.size():break
  var id=ids[index];var known=p.blueprints.has(id);var at=Vector2(82+(i%6)*87,245+int(i/6)*91);var rect=Rect2(at,Vector2(76,76))
  g.button(rect,"","smithy_select:"+id,selected_blueprint==id,true)
  if known:
   var item=make_item(id,int(p.slot_levels[tab]),str(p.infusions.get(id,"")))
   g.gear_icon(item.slot,at+Vector2(13,12),50,g.Gear.COLORS[item.rarity],item)
   if p.unseen_blueprints.has(id):g.text(at+Vector2(8,70),"NEW",12,g.GOLD)
   elif p.items.has(id):g.text(at+Vector2(8,70),"OWNED",12,g.TEAL)
  else:g.text(at+Vector2(26,47),"?",25,Color("737078"))
  if not g.menu_keyboard and rect.has_point(g.design_mouse()):inspected=id
 if pages>1:
  g.button(Rect2(82,535,120,40),"Previous","smithy_prev",false,page>0);g.text(Vector2(248,562),"%d / %d"%[page+1,pages],18,g.TEAL);g.button(Rect2(420,535,120,40),"Next","smithy_next",false,page<pages-1)
 var slot_lv=int(p.slot_levels[tab]);var slot_cost={"ore":3+slot_lv*3,"monster":2+slot_lv*2,"boss":1 if slot_lv>=2 else 0}
 if slot_lv>=5:g.text(Vector2(82,606),"Slot upgrade: Maximum level",15,g.TEAL)
 else:draw_materials(cost_progress_entries(slot_cost),Vector2(82,600),165,18)
 g.button(Rect2(82,625,350,40),tab.capitalize()+" slot / level %d"%slot_lv+(" / MAX" if slot_lv>=5 else " → %d"%(slot_lv+1)),"smithy_upgrade_slot:"+tab,false,slot_lv<5)
 g.button(Rect2(442,625,130,40),"Track","smithy_track_slot:"+tab,false,slot_lv<5)
 if inspected!="" and RECIPES.has(inspected):draw_grid_details(p,inspected)
 else:g.draw_wrapped("Select a blueprint to see its effects, crafting cost and where to find it.",Vector2(685,270),490,22,g.INK,5)
 var footer=message
 if footer=="" and inspected!="" and RECIPES.has(inspected) and not p.items.has(inspected):
  footer=material_sources(cost_for(inspected,0))
  if not p.blueprints.has(inspected):
   if SPECIALS.has(inspected) and SPECIALS[inspected].has("mastery"):footer="Guaranteed blueprint when its mastery is completed.  "+footer
   else:footer="At earliest floor and minimum rarity: 1 in %d eligible unseen designs.  "%discovery_pool_size(inspected)+footer
 if footer!="":
  g.panel(Rect2(60,686,1160,40));g.draw_wrapped(footer,Vector2(75,713),1120,18,g.GOLD if message!="" else g.TEAL,1)
 g.button(Rect2(60,750,240,48),"Back","smithy_back")
 if not p.goal.is_empty():g.button(Rect2(1000,750,200,48),"Clear goal","smithy_untrack")
 g.text(Vector2(330,781),"Alloy: guards F2+ / Essence: imps F3+ / Gel: slimes F4+",16,g.INK)
func draw_grid_details(p: Dictionary,id: String) -> void:
 var owned=p.items.has(id);var known=p.blueprints.has(id);var level=int(p.slot_levels[RECIPES[id][1]]);var next=mini(5,level+1) if owned else level;var item=make_item(id,level,str(p.infusions.get(id,"")));var candidate=make_item(id,next,str(p.infusions.get(id,"")))
 g.gear_icon(item.slot,Vector2(680,225),64,g.Gear.COLORS[item.rarity],item);g.text(Vector2(760,247),item.name,23,g.GOLD)
 g.text(Vector2(760,278),["Common","Rare","Very rare"][item.rarity]+(" / Slot level %d"%level if owned else " / Not crafted" if known else " / Undiscovered"),17,g.TEAL)
 var variant=VARIANTS.get(id,[])
 if not known:g.text(Vector2(680,302),blueprint_source(id),16,g.TEAL)
 elif SPECIALS.has(id):g.text(Vector2(680,302),"Special blueprint / Warden core required",16,g.TEAL)
 elif not variant.is_empty():g.text(Vector2(680,302),"Blueprint: floor %d+ / %s required"%[variant[3],LABELS[variant[4]]],16,g.TEAL)
 var identity=style_description(item)
 if identity!="":g.text(Vector2(680,330),identity,16,g.GOLD)
 if item.slot=="weapon":g.draw_wrapped(g.choice_ui.weapon_description(item),Vector2(680,355 if identity!="" else 330),500,18,g.INK,2 if identity!="" else 3)
 var presenter=preload("res://equipment_presenter.gd")
 var base_id=base_recipe(id) if VARIANTS.has(id) or SPECIALS.has(id) else ""
 var old=presenter.numbers(make_item(base_id,level)) if base_id!="" else {}
 var next_stats=presenter.numbers(item);var rows=presenter.comparison_keys(old,next_stats) if base_id!="" else presenter.keys(old,next_stats)
 var pages=maxi(1,ceili(float(rows.size())/4.0));stats_page=clampi(stats_page,0,pages-1)
 g.text(Vector2(680,406),"ITEM STATS",17,g.GOLD);g.text(Vector2(955,406),"BASE / THIS" if base_id!="" else "THIS ITEM",16,g.TEAL)
 for i in range(mini(4,rows.size()-stats_page*4)):
  var key=rows[stats_page*4+i];var y=439+i*28;g.stat_ui.label(key,Vector2(680,y),22);g.text(Vector2(710,y),g.stat_ui.short_name(key),17,g.INK)
  g.text(Vector2(955,y),presenter.value(key,old)+" / "+presenter.value(key,next_stats) if base_id!="" else presenter.value(key,next_stats),17,g.TEAL)
 if pages>1:
  g.button(Rect2(680,640,50,35),"<","smithy_stats_prev",false,stats_page>0)
  g.text(Vector2(740,664),"Stats %d/%d"%[stats_page+1,pages],16,g.TEAL)
  g.button(Rect2(855,640,50,35),">","smithy_stats_next",false,stats_page<pages-1)
 if owned:
  var rune=str(p.infusions.get(id,""))
  if rune in ELEMENTS:g.ui_icon(rune,Vector2(680,544),22)
  g.text(Vector2(710 if rune in ELEMENTS else 680,565),"Rune: "+rune.capitalize() if rune in ELEMENTS else "Rune: None",16,g.TEAL)
 else:draw_materials(cost_progress_entries(cost_for(id,0)),Vector2(680,548),165,18)
 g.button(Rect2(680,585,230,52),"Craft" if not owned else "Crafted","smithy_make:"+id,false,known and not owned and selected_blueprint==id)
 g.button(Rect2(930,585,245,52),"Choose rune","smithy_runes:"+id,false,owned and selected_blueprint==id)
 g.button(Rect2(930,640,245,35),"Track recipe","smithy_track:"+id,false,not owned and selected_blueprint==id)
 if pages==1:g.text(Vector2(680,660),"Find blueprint first." if not known else "Select, then craft.",16,g.TEAL)

func draw_details(p: Dictionary) -> void:
 var id=detail_item;var spec=RECIPES[id];var level=int(p.items.get(id,0));var next=mini(5,maxi(1,level+1));var element=str(p.infusions.get(id,""))
 var current=make_item(id,maxi(1,level),element);var candidate=make_item(id,next,element)
 var presenter=preload("res://equipment_presenter.gd");var before=presenter.numbers(current) if level>0 else {};var after=presenter.numbers(candidate);var rows=presenter.keys(before,after)
 g.panel(Rect2(65,165,1150,535));g.gear_icon(spec[1],Vector2(90,190),64,g.INK,current)
 g.text(Vector2(175,218),spec[0]+(" / Level %d"%level if level>0 else " / Not crafted"),28,g.GOLD)
 var v=VARIANTS.get(id,[])
 g.text(Vector2(175,251),(["Common","Rare","Very rare"][int(v[2])] if not v.is_empty() else "Common")+" / Rune: "+("None" if element=="" else element.capitalize()),18,g.TEAL)
 if not v.is_empty():g.text(Vector2(90,282),"Found from floor %d / requires %s"%[v[3],LABELS[v[4]]],18,g.TEAL)
 if spec[1]=="weapon":g.draw_wrapped(g.choice_ui.weapon_description(candidate),Vector2(90,320),1050,20,g.INK,3)
 g.text(Vector2(90,420),"ITEM STATS",20,g.GOLD);g.text(Vector2(690,420),"CURRENT",18,g.TEAL);g.text(Vector2(900,420),"LEVEL %d"%next,18,g.TEAL)
 for i in range(mini(rows.size(),6)):
  var key=rows[i];var y=455+i*32
  g.stat_ui.label(key,Vector2(90,y),23);g.text(Vector2(125,y),g.stat_ui.short_name(key),18,g.INK)
  g.text(Vector2(690,y),presenter.value(key,before),18,g.INK);g.text(Vector2(900,y),presenter.value(key,after),18,g.TEAL)
 if level>=5:g.text(Vector2(90,675),"Maximum level reached.",18,g.TEAL)
 g.button(Rect2(70,744,260,50),"Back to smithy","smithy_back")
