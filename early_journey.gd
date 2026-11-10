extends RefCounted
## Per-character milestones; guidance never gates actions or expedition access.
static func progress(g) -> Dictionary:
 if not g.career.get("journey") is Dictionary:g.career["journey"]={}
 var p=g.career.journey
 for key in ["skipped","inspected","ability_seen","tried_alternate"]:
  if not p.get(key) is bool:p[key]=false
 return p
static func enabled(g) -> bool:
 return g.run_rules>=20 and not g.demo_run and g.run_settings.get("mode","")=="standard" and not progress(g).skipped
static func alternative(g,owned:bool=false,include_cargo:bool=false) -> String:
 var p=g.smithy.data();var designs=p.items if owned else p.blueprints
 for id in g.smithy.category_ids("weapon"):
  if id!="sword" and (designs.has(id) or include_cargo and g.smithy.cargo().blueprints.has(id)):return id
 return ""
static func first_victory(g) -> void:
 if not enabled(g) or g.floor_number!=1 or alternative(g,false,true)!="":return
 var c=g.smithy.cargo()
 g.smithy.reward(g.Gear.make("weapon",1,0,[],"dagger"));c.ore+=3;c.monster+=1
 g.log_line("First crafting discovery: Dagger blueprint, 3 Ore and 1 extra Part. Keep these after returning or falling.")
static func begin_run(g) -> void:
 if not enabled(g):return
 if str(g.smithy.data().loadout.get("weapon","sword"))!="sword":progress(g).tried_alternate=true
static func info(g) -> Dictionary:
 if not enabled(g):return {}
 var p=g.smithy.data();var journey=progress(g);var known=alternative(g);var owned=alternative(g,true)
 if known=="":
  if alternative(g,false,true)!="":return {"stage":"return","title":"Bring your discovery home","text":"Your blueprint and materials are kept after returning or falling. Return from the floor entrance, then craft your Dagger at the Hearth.","action":"Visit the smithy"}
  if not journey.inspected:return {"stage":"inspect","title":"Learn your starting weapon","text":"Open Equipment to inspect your sword. Every four successful hits grant a shield. Find an enemy you can safely defeat.","action":"Prepare an expedition"}
  return {"stage":"discover","title":"Find your first alternative","text":"Defeat an enemy on floor 1 for a Dagger blueprint and crafting materials. Your sword gains a shield every four successful hits.","action":"Prepare an expedition"}
 if owned=="":return {"stage":"craft","recipe":known,"title":"Craft your next weapon","text":"Your blueprint and materials are permanent. Select "+g.smithy.RECIPES[known][0]+" at the smithy, then choose Craft.","action":"Craft "+g.smithy.RECIPES[known][0]}
 if str(p.loadout.get("weapon","sword"))=="sword":return {"stage":"equip","recipe":owned,"title":"Try your crafted weapon","text":"Choose your new weapon in preparation, then Equip selected. Equipment stays fixed during each expedition.","action":"Choose equipment"}
 if p.goal.is_empty():return {"stage":"goal","title":"Choose what to find next","text":"Select a smithy recipe and Track recipe, or track a slot upgrade. Your journal shows missing materials and their sources.","action":"Choose a crafting goal"}
 if not journey.tried_alternate:return {"stage":"expedition","title":"Take your build into the dungeon","text":"Your crafted weapon is equipped and your next goal is tracked. Begin an expedition and try its weapon ability.","action":"Prepare an expedition"}
 if not journey.ability_seen:return {"stage":"ability","title":"Watch your weapon ability","text":"Watch the combat panel for your next combo, shield or heavy strike. Keep pursuing your tracked goal.","action":"Prepare an expedition"}
 return {}
static func handle(g,id:String) -> bool:
 if id=="journey_skip":
  progress(g).skipped=true
  if g.guided and g.guided.active():g.guided.finish(true)
  if g.session:g.session.commit_profile()
  return true
 if id!="journey_next" or g.mode!="sanctuary":return false
 var hint=info(g)
 if hint.is_empty():return true
 match hint.stage:
  "craft","return","goal":
   g.action("smithy_open")
   var recipe=str(hint.get("recipe","shield"))
   g.action("smithy_tab:"+str(g.smithy.RECIPES[recipe][1]));g.action("smithy_select:"+recipe)
   g.smithy.message="Choose Track recipe to set your next goal." if hint.stage=="goal" else "Select the blueprint, then Craft. Materials and crafted equipment are permanent."
  "equip":
   g.loadout_menu.open("sanctuary");g.action("loadout_select:"+str(hint.recipe))
  _:g.action("sanctuary_expedition")
 return true
static func draw(g) -> void:
 if g.mode!="play" or g.guided and g.guided.active():return
 var hint=info(g)
 if hint.is_empty():return
 g.panel(Rect2(15,480,295,237),Color("23353b"));g.text(Vector2(30,508),"YOUR NEXT STEP",21,g.GOLD)
 g.draw_wrapped(hint.text,Vector2(30,538),260,18,g.INK,5)
 g.button(Rect2(30,674,260,32),"Skip guidance / F1","journey_skip")
