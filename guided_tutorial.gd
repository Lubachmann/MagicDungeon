extends RefCounted
var g
func _init(game):g=game
func active() -> bool:return int(g.run_metrics.get("guide_step",-1))>=0
func start() -> void:
 g.run_metrics["guide_step"]=0;g.run_metrics["guide_flask_found"]=false
 # Keep the first-room potion reachable without fighting or unlocking anything.
 var data=g.rooms[Vector2i.ZERO]
 for tile in data.entities.keys():
  if data.entities[tile].get("kind","")=="potion":
   var potion=data.entities[tile];data.entities.erase(tile)
   if g.world_choices.place_foundation(potion).x<0:data.entities[tile]=potion
   break
func finish(skipped:bool=false) -> void:
 g.run_metrics["guide_step"]=-1;g.career["guided_done"]=true
 g.save_progress()
 g.log_line("Tutorial skipped. Open Guide from the menu any time." if skipped else "Tutorial complete! Your flask is ready with H.")
func update() -> void:
 if not active():return
 var step=int(g.run_metrics.guide_step)
 if step==0 and g.equipped.has("weapon"):
  g.run_metrics.guide_step=1
  step=1
 if step==1 and g.mode in ["play","inspect"]:
  var tile=g.inspected_tile if g.mode=="inspect" else Vector2i(((g.design_mouse()-g.ORIGIN)/g.TILE).floor())
  if g.rooms[g.room].entities.get(tile,{}).get("kind","")=="enemy":g.run_metrics.guide_step=2
 if int(g.run_metrics.guide_step)==4 and g.run_metrics.get("guide_flask_found",false):finish()
func fight_started() -> void:
 if active() and int(g.run_metrics.guide_step) in [1,2]:g.run_metrics.guide_step=3
func enemy_defeated() -> void:
 if active() and int(g.run_metrics.guide_step)==3:
  g.run_metrics.guide_step=4
  if g.run_metrics.get("guide_flask_found",false):finish()
func potion_found() -> void:
 if not active():return
 g.run_metrics["guide_flask_found"]=true
 if int(g.run_metrics.guide_step)==4:finish()
func draw() -> void:
 if not active() or g.mode not in ["play","inspect","fight"]:return
 var step=int(g.run_metrics.guide_step)
 var instructions=[
  "The Hearth is fading. Use arrows or WASD; open the chest and equip its weapon.",
  "Hover over an enemy to inspect it. On keyboard, press I and move the cursor.",
  "Compare its HP, attack, armor and attack interval with yours. Step into it to fight.",
  "Combat is automatic. Watch both HP bars. Press H to use a flask if needed.",
  "Find and pick up the healing flask in this room. Press H to heal when hurt."]
 if step==0 and g.inventory.any(func(item):return item.get("slot","")=="weapon"):
  instructions[0]="Press %s to open Equipment, then select and equip your weapon."%(g.controls.label("inventory") if g.controls else "E")
 g.panel(Rect2(15,505,295,192),Color("23353b"));g.text(Vector2(30,536),"FIRST STEPS  %d / 5"%[step+1],21,g.GOLD)
 g.draw_wrapped(instructions[clampi(step,0,4)],Vector2(30,568),260,19,g.INK,4)
 g.button(Rect2(30,650,260,37),"Skip tutorial (F1)","guide_skip")
