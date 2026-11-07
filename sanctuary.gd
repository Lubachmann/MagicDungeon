extends RefCounted
const DISCOVERIES={
 "smith":{"name":"Mara, the smith","icon":"hammer","floor":1,"reward":"Armory passages offer a choice of weapon type.","found":"Mara: The flame found me first. Find me above."},
 "cartographer":{"name":"Iven, the cartographer","icon":"map","floor":1,"reward":"The map reveals chest tiers in adjacent rooms.","found":"Iven: The passages change, but treasure leaves a trace."},
 "fire":{"name":"Ember manuscript","icon":"fire","floor":1,"reward":"Adds Combustion and Fire-touched gear to future runs.","found":"A scorched page describes a flame that feeds on heat."},
 "ice":{"name":"Frost manuscript","icon":"ice","floor":2,"reward":"Adds Frost shatter and Frost-touched gear to future runs.","found":"A frozen page remembers the instant before a heart stops."},
 "acid":{"name":"Acid manuscript","icon":"acid","floor":3,"reward":"Adds Exposed core and Acid-touched gear to future runs.","found":"A corroded page reveals how to break what seems eternal."},
 "poison":{"name":"Poison manuscript","icon":"poison","floor":4,"reward":"Adds Toxic harvest and Poison-touched gear to future runs.","found":"A stained page speaks of poison that gathers strength."}}
const FRAGMENT_STORY=["The Warden held a fragment of the sanctuary flame. It remembers a voice calling it home.","The flame was divided deliberately. Each Warden was made to guard a piece.","The sanctuary was built above a prison, not a well. Its prisoner kept the village alive.","The Wardens were once its keepers. The flame is fading because its heart is waking.","The last fragment remembers the choice the keepers refused to make."]
const ROOMS={"smith":"Forge","cartographer":"Hammer","fire":"Armory","ice":"Fountain","acid":"Elite","poison":"Forge"}
const SKILLS={"combustion":"fire","frost_shatter":"ice","exposed_core":"acid","toxic_harvest":"poison"}
var g
var selected="elder"
var return_mode="title"
func _init(game):g=game
static func empty() -> Dictionary:return {"discoveries":{},"fragments":{},"ending":"","endings":{}}
static func migrate_old(career: Dictionary) -> Dictionary:
 var out=empty()
 for id in DISCOVERIES:out.discoveries[id]=true
 if int(career.get("wins",0))>0:
  for floor_number in range(1,6):out.fragments[str(floor_number)]=true
 return out
func progress() -> Dictionary:
 if not g.career.get("sanctuary") is Dictionary:g.career["sanctuary"]=empty()
 return g.career.sanctuary
func begin_run() -> void:
 if not g.session or not g.session.active or g.demo_run or g.run_settings.get("mode","")!="standard":return
 g.run_metrics["sanctuary_start"]=progress().get("discoveries",{}).duplicate(true)
 g.run_metrics["sanctuary_found"]=[];g.run_metrics["flame_found"]=[]
func active() -> bool:return g.run_metrics.has("sanctuary_start") and not g.demo_run
func unlocked(id: String) -> bool:return bool(g.run_metrics.get("sanctuary_start",{}).get(id,false))
func generate() -> void:
 if not active():return
 var missing=[]
 for id in DISCOVERIES:
  if int(DISCOVERIES[id].floor)!=g.floor_number or unlocked(id) or id in g.run_metrics.sanctuary_found:continue
  missing.append(id)
 for id in missing:
  var coords=[]
  for coord in g.dungeon_threads.distances_from(Vector2i.ZERO):
   if coord!=g.boss_room and coord.x>=0:coords.append(coord)
  var preferred=ROOMS[id]
  coords.sort_custom(func(a,b):
   var a_match=g.roles.get(a,"")==preferred;var b_match=g.roles.get(b,"")==preferred
   if a_match!=b_match:return a_match
   return int(g.distances.get(a,0))<int(g.distances.get(b,0)))
  var placed=false
  for coord in coords:
   if g.dungeon_threads.place(coord,{"kind":"sanctuary_discovery","discovery":id}).x>=0:placed=true;break
  if not placed:push_warning("Could not place sanctuary discovery: "+id)
func touch(tile: Vector2i,e: Dictionary) -> bool:
 if e.get("kind","")!="sanctuary_discovery":return false
 var id=str(e.get("discovery",""))
 if not DISCOVERIES.has(id) or not active():return false
 if id not in g.run_metrics.sanctuary_found:g.run_metrics.sanctuary_found.append(id)
 g.rooms[g.room].entities.erase(tile);g.animate_move(tile);g.sfx("relic")
 g.run_metrics["last_discovery"]=id;g.mode="discovery"
 g.log_line(DISCOVERIES[id].found+" Returns to the sanctuary after this run.")
 return true
func defeated(enemy: Dictionary) -> void:
 if not active() or int(enemy.get("type",0))!=3 or g.floor_number>5:return
 var id=str(g.floor_number)
 if not progress().get("fragments",{}).has(id) and id not in g.run_metrics.flame_found:
  g.run_metrics.flame_found.append(id);g.log_line("Flame fragment recovered. It will return with you.")
func commit() -> void:
 if not active():return
 var p=progress()
 for id in g.run_metrics.get("sanctuary_found",[]):
  if DISCOVERIES.has(id):p.discoveries[id]=true
 for floor_id in g.run_metrics.get("flame_found",[]):
  if int(floor_id) in range(1,6):p.fragments[str(floor_id)]=true
func begin_ending() -> void:
 g.mode="ending";g.log_line("The flame's heart is before you. Choose its fate.")
func handle(id: String) -> bool:
 if id=="discovery_continue" and g.mode=="discovery":g.mode="play";return true
 if id=="sanctuary" and g.mode in ["title","dead","won"]:
  return_mode=g.mode;g.mode="sanctuary";selected="elder";return true
 if id=="sanctuary_back" and g.mode=="sanctuary":
  if return_mode in ["dead","won"]:g.session.title()
  else:g.mode=return_mode
  return true
 if id=="sanctuary_expedition" and g.mode=="sanctuary":g.mode="expedition";return true
 if id=="sanctuary_tree" and g.mode=="sanctuary":g.ember_tree.return_mode="sanctuary";g.mode="skills";return true
 if id.begins_with("sanctuary_select:") and g.mode=="sanctuary":selected=id.trim_prefix("sanctuary_select:");return true
 if id.begins_with("ending_choose:") and g.mode=="ending":
  var choice=id.get_slice(":",1)
  if choice not in ["rekindle","release"]:return true
  var p=progress();p.ending=choice;p.endings[choice]=true
  g.finish_run(true);return true
 return false
func draw() -> void:
 var p=progress();var found=p.get("discoveries",{});var fragments=p.get("fragments",{})
 g.front_end.menu_backdrop();g.text(Vector2(70,80),"THE LAST HEARTH",38,g.GOLD)
 g.text(Vector2(72,115),"Flame fragments %d / 5"%fragments.size(),21,g.TEAL)
 g.panel(Rect2(70,140,590,520))
 for y in range(6):
  for x in range(7):g.draw_texture_rect(g.textures["wall" if y==0 or x==0 or x==6 else "floor"],Rect2(91+x*78,160+y*77,78,77),false,Color("998981"))
 var light=Color("8ccfe5") if p.get("ending","")=="release" else Color("ffc87f") if fragments.size()>0 else Color("7b7777")
 g.draw_texture_rect(g.textures.shrine,Rect2(302,210,96,96),false,light)
 if fragments.size()>0:g.draw_circle(Vector2(350,265),24+fragments.size()*4,Color(light,0.10))
 g.draw_rest_icon(Vector2(317,240),64,false);g.draw_texture_rect(g.textures.player,Rect2(315,470,64,64),false)
 g.button(Rect2(115,355,150,105),"","sanctuary_select:smith");g.ui_icon("hammer",Vector2(165,365),42,Color.WHITE if found.has("smith") else Color("625c66"));g.text(Vector2(129,445),"MARA" if found.has("smith") else "???",19,g.GOLD if found.has("smith") else g.INK)
 g.button(Rect2(455,355,150,105),"","sanctuary_select:cartographer");g.ui_icon("map",Vector2(505,365),42,Color.WHITE if found.has("cartographer") else Color("625c66"));g.text(Vector2(468,445),"IVEN" if found.has("cartographer") else "???",19,g.GOLD if found.has("cartographer") else g.INK)
 g.button(Rect2(265,545,190,50),"The flame","sanctuary_select:elder")
 g.panel(Rect2(680,140,530,520));g.text(Vector2(710,180),"HEARTH JOURNAL",26,g.GOLD)
 var body="The Last Hearth keeps the village alive. Something below consumes its flame. Descend, bring back what you can, and find its heart. The flame carries you home when you fall."
 if selected=="smith":body="Mara has returned. Armory passages let you choose a weapon type on future runs." if found.has("smith") else "Mara vanished near the forge on floor 1. Find her and bring her story home."
 elif selected=="cartographer":body="Iven has returned. Your map reveals chest tiers in adjacent rooms on future runs." if found.has("cartographer") else "Iven vanished near the hammer chamber on floor 1. Their knowledge could guide future expeditions."
 elif selected in DISCOVERIES:body=DISCOVERIES[selected].reward if found.has(selected) else "Find this manuscript near the %s on floor %d. It unlocks a new skill and gear bonuses for future runs."%[ROOMS[selected],DISCOVERIES[selected].floor]
 elif selected.begins_with("fragment:"):
  var floor_number=int(selected.get_slice(":",1));body=FRAGMENT_STORY[floor_number-1] if fragments.has(str(floor_number)) else "Defeat the Warden on floor %d and return to recover this fragment."%floor_number
 if selected=="elder" and p.get("ending","")!="":body="You rekindled the hearth. The village is warm again, but the voices remain." if p.ending=="rekindle" else "You freed the captive flame. The hearth burns differently now: it belongs to no one."
 g.draw_wrapped(body,Vector2(710,220),465,21,g.INK,7);g.text(Vector2(710,400),"MANUSCRIPTS",19,g.GOLD)
 for i in range(4):
  var element=["fire","ice","acid","poison"][i];var at=Vector2(710+i*112,415)
  g.button(Rect2(at,Vector2(100,65)),"","sanctuary_select:"+element);g.ui_icon(element,at+Vector2(10,12),36,Color.WHITE if found.has(element) else Color("625c66"))
 g.text(Vector2(710,520),"FRAGMENTS",19,g.GOLD)
 for i in range(5):
  var at=Vector2(710+i*90,535);g.button(Rect2(at,Vector2(78,65)),"","sanctuary_select:fragment:"+str(i+1));g.ui_icon("ember",at+Vector2(20,10),36,Color.WHITE if fragments.has(str(i+1)) else Color("625c66"))
 g.front_end.icon_button(Rect2(70,695,260,60),"boots","Title" if return_mode in ["dead","won"] else "Back","sanctuary_back")
 g.front_end.icon_button(Rect2(350,695,390,60),"ember","Ember Tree","sanctuary_tree")
 g.front_end.icon_button(Rect2(760,695,450,60),"attack","Enter dungeon","sanctuary_expedition")
func draw_ending() -> void:
 g.front_end.overlay(Rect2(170,130,940,580));g.ui_icon("ember",Vector2(605,175),64)
 g.text(Vector2(250,285),"THE HEART OF THE FLAME",34,g.GOLD)
 g.draw_wrapped("The Wardens were its jailers. The hearth was fed by a living flame held here for generations. Bind it again, or set it free and trust it to stay.",Vector2(250,335),780,23,g.INK,4)
 g.button(Rect2(250,490,780,70),"Rekindle the hearth / bind the flame","ending_choose:rekindle")
 g.button(Rect2(250,580,780,70),"Release the flame / let it choose","ending_choose:release")

func draw_discovery() -> void:
 var id=str(g.run_metrics.get("last_discovery",""));var info=DISCOVERIES.get(id,{})
 if info.is_empty():return
 g.panel(Rect2(360,195,560,420));g.ui_icon(info.icon,Vector2(390,225),64)
 g.text(Vector2(475,253),"DISCOVERY",21,g.GOLD)
 g.text(Vector2(390,328),info.name,29,g.GOLD)
 g.draw_wrapped(info.found,Vector2(390,370),495,21,g.INK,3)
 g.draw_wrapped("Returns to the Hearth after this run. "+info.reward,Vector2(390,455),495,20,g.TEAL,3)
 g.button(Rect2(390,548,500,50),"Continue / Enter","discovery_continue")
