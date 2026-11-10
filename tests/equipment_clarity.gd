extends SceneTree
const View=preload("res://equipment_presenter.gd")
const Stats=preload("res://build_stats.gd")
const Roster=preload("res://enemy_roster.gd")
var failures=[]
var checks=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
	var g=load("res://main.tscn").instantiate();g.save_path="res://tests/.clarity013.json";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.new_run(42);g.run_skills={};g.recalculate_stats()
	check(g.equipped.has("weapon") and g.inventory[g.equipped.weapon].get("archetype","")=="balanced" and g.armor==0,"Fresh character starts with the crafted sword and no armor")
	var expected={"balanced":[14.0,2.0],"dagger":[7.0,1.0],"axe":[21.0,3.0]}
	for weapon in expected:
		var item=g.make_gear("weapon",1,0,[],weapon);g.inventory=[item];g.equipped={"weapon":0};g.recalculate_stats()
		var s=Stats.calculate(g);var raw=View.numbers(item)
		check(is_equal_approx(s.attack,expected[weapon][0]) and is_equal_approx(s.interval,expected[weapon][1]),"Total base + weapon power: "+weapon)
		check(raw.has("base_interval") and raw.base_interval==expected[weapon][1],"Item always exposes base cadence: "+weapon)
		check(is_equal_approx(s.weapon_dps,s.attack/s.interval),"Weapon DPS includes base and equipment")
	var helmet=g.make_gear("helmet",5,0);var same=helmet.duplicate(true)
	check("armor" in View.affected(helmet,same),"Identical armor remains relevant")
	check("armor" in View.keys(View.numbers(helmet),View.numbers(same)),"Identical own armor has before and after cells")
	var dagger=g.make_gear("weapon",3,2,["speed","fire_dps"],"dagger");var upgraded=dagger.duplicate(true);upgraded.level+=1
	var snapshot=var_to_bytes([g.inventory,g.equipped,g.hp,g.rng.state]);var before=View.numbers(dagger);var after=View.numbers(upgraded)
	check(after.attack>before.attack and after.get("fire_power",after.get("fire_dps",0))>=before.get("fire_power",before.get("fire_dps",0)) and after.item_interval<before.item_interval,"Iron preview includes own damage, element and item cadence")
	check(snapshot==var_to_bytes([g.inventory,g.equipped,g.hp,g.rng.state]),"Item previews do not mutate run or RNG")
	check(g.Combat.damage(20,0)==20 and g.Combat.damage(20,12)==10 and g.Combat.damage(20,24)==7,"Armor formula without a hard reduction cap")
	var sprites=[]
	for type in [0,1,2]:
		var e=g.make_enemy(type,0);sprites.append(Roster.sprite(e));check(Roster.level(e,1)>0,"Base enemy level")
	for i in range(5):
		var e=g.make_enemy(0,0);g.Combat.Flow.assign_family(e,i);sprites.append(Roster.sprite(e))
		g.floor_number=i+1;var boss=g.make_enemy(3,4);sprites.append(Roster.sprite(boss));check(Roster.title(boss)==boss.name,"Boss title matches roster")
	var unique={}
	for sprite in sprites:
		unique[sprite]=true;check(g.animation_sets.has(sprite) and g.animation_sets[sprite].size()==4,"Animated art exists: "+sprite)
	check(unique.size()==13,"Three base types, five floor enemies and five bosses have distinct art")
	g.floor_number=1;var early=g.make_enemy(0,0);g.floor_number=5;var late=g.make_enemy(0,0)
	check(Roster.level(late)>Roster.level(early),"Enemy level increases across floors")
	var old=g.Gear.make("weapon",1,0);old.balance=2;g.run_rules=7;g.inventory=[old];g.equipped={"weapon":0};g.recalculate_stats()
	check(g.attack==14 and g.armor==1,"Continued rules-7 runs retain their balance")
	g.mode="play";var tile=Vector2i(7,5);g.rooms[g.room].entities[tile]=g.make_enemy(1,2)
	var hovered=g.context_entity(g.ORIGIN+(Vector2(tile)+Vector2(0.5,0.5))*g.TILE)
	check(g.context_entity(Vector2(1000,550))==hovered,"Enemy panel stays inspectable when pointer enters it")
	g.enemy_ability_open=true
	check(g.context_entity(Vector2(965,550))==hovered,"Ability panel remains reachable across its bridge")
	g.mode="inspect"
	check(g.context_entity(Vector2(965,550)).is_empty(),"Keyboard inspection follows its cursor instead of the cached hover target")
	g.mode="play"
	g.rooms[g.room].entities.erase(tile)
	check(g.context_entity(Vector2(1000,550)).is_empty(),"Defeated enemies are not retained as stale inspection data")
	g.free();print(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
