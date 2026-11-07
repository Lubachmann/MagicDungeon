extends SceneTree
var checks=0
var failures=[]
func check(ok:bool,msg:String):
 checks+=1
 if not ok:failures.append(msg)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-user-icons";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.new_run(56)
 var mapping={"armor":"armor_stat_shield","health":"health_heart","potion":"healing_flask","iron":"iron_ingot","boots":"boots","book":"book","map":"map","relic":"relic_gem","vault":"treasure_chest"}
 for key in mapping:
  check(g.icons[key] is Texture2D and g.icons[key].resource_path.ends_with("/"+mapping[key]+".png"),"Creator icon loads: "+key)
 for key in ["weapon","shield","armor","light_armor","helmet","amulet"]:check(g.gear_icons[key] is Texture2D and "/user_icons/" in g.gear_icons[key].resource_path,"Creator equipment icon loads: "+key)
 for key in ["balanced","greatblade","axe"]:check(g.weapon_icons[key] is Texture2D and "/user_icons/" in g.weapon_icons[key].resource_path,"Creator weapon icon loads: "+key)
 for key in ["dagger","ember"]:check(g.weapon_icons[key] is Texture2D and "/pixel_icons/" in g.weapon_icons[key].resource_path,"Unmatched weapon keeps its existing icon: "+key)
 for key in ["attack","stat_attack","speed","crit","crit_damage","vampirism","evade","fire","stat_fire","ice","stat_ice","acid","stat_acid","poison","stat_poison"]:check(g.icons[key] is Texture2D and "/user_icons/" in g.icons[key].resource_path,"New creator stat icon loads: "+key)
 for key in ["crit_chance","crit_mult","evade","vampirism"]:check(g.stat_ui.info(key)[0]=={"crit_chance":"crit","crit_mult":"crit_damage","evade":"evade","vampirism":"vampirism"}[key],"Distinct stat icon: "+key)
 g.inventory=[g.make_gear("armor",1,0),g.make_gear("weapon",1,0,[],"axe")];g.inventory[0].armor_class="light";g.selected_item=0;g.open_equipment();g.queue_redraw();await process_frame;await process_frame
 check(g.mode=="equipment" and not g.buttons.is_empty(),"Equipment screen renders with creator icons")
 print(JSON.stringify({"checks":checks,"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
