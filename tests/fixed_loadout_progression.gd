extends SceneTree
const Offers=preload("res://skill_offers.gd")
const Stats=preload("res://build_stats.gd")
const SAVE="res://tests/.fixed_loadout_progression"
var g
var checks=0
var failures=[]
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures.append(message)
func cleanup() -> void:
 for suffix in ["", ".tmp", ".run", ".run.bak", ".run.tmp"]:
  if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(SAVE+suffix)
func _initialize():call_deferred("run")
func equip(weapon: String) -> void:
 g.inventory=[g.smithy.make_item(weapon,1)];g.equipped={"weapon":0};g.recalculate_stats()
func redraw() -> void:
 g.queue_redraw();await process_frame;await process_frame
func run() -> void:
 cleanup()
 g=load("res://main.tscn").instantiate();g.save_path=SAVE;root.add_child(g);await process_frame
 g.session.enabled=false;g.session.active=false;g.set_process(false);g.muted=true
 g.career=g.replay.new_career();g.skills={};g.new_run(721);g.reward_level=10
 var heavy=["heavy_momentum","combustion","glacial_crusher","shieldbreaker","breakthrough","frost_shatter"]
 for weapon in ["sword","dagger","axe","greatblade","ember"]:
  equip(weapon);var pool=Offers.pool(g)
  for id in heavy:check((id in pool)==(weapon in ["axe","greatblade"]),weapon+" offer eligibility for "+id)
  check(("venom_edge" in pool)==(weapon=="dagger"),"Venom edge requires fixed dagger")
  check(("warded_blade" in pool)==(weapon=="sword"),"Warded blade requires fixed sword")
  check("blood_harvest" not in pool,"Blood harvest cannot acquire missing lifesteal mid-run")
  check("toxic_harvest" in pool and "caustic_burn" in pool and "toxic_glacier" in pool,"Future elemental investments remain available")
  for seed in range(30):
   g.rng.seed=seed;var choices=Offers.choose(g)
   check(choices.size()==3 and choices.all(func(id):return Offers.eligible(g,id,Stats.calculate(g))),"All sampled offers fit "+weapon)
   check(choices.any(func(id):return id in Offers.GENERAL_SKILLS or id in ["attack","guard"]),"Offers retain a useful general choice")
 equip("dagger_bloodbound")
 check("blood_harvest" in Offers.pool(g),"Fixed lifesteal permits future Poison synergy")
 check(Offers.build_requirements(g,"blood_harvest",Stats.calculate(g))==["Poison"],"Eligibility and UI share missing requirements")
 equip("axe")
 check(Offers.build_requirements(g,"combustion",Stats.calculate(g))==["4 Fire power"],"Compatible heavy weapon still explains elemental threshold")
 g.base_elements.fire=4
 check(Offers.build_requirements(g,"combustion",Stats.calculate(g)).is_empty(),"Elemental investment completes the requirement")
 g.base_elements.fire=0;equip("sword");g.run_rules=19
 check("venom_edge" in Offers.pool(g) and "glacial_crusher" in Offers.pool(g),"Swappable-equipment saves retain future weapon offers")
 g.run_rules=20

 # Depleted pools use the real blessing calculation and action path, including rerolls.
 g.relics=g.RELICS.keys();g.recalculate_stats();g.run_skills.insight=1
 var choices=Offers.choose(g)
 check(choices.size()==4 and choices.all(func(id):return id in Offers.TRAINING),"Exhausted pool still offers four repeatable training choices")
 g.choices=choices;g.mode="relic";g.rerolls_left=1
 check(g.choice_ui.can_reroll(),"Training-only offers can be rerolled")
 g.action("relic_reroll")
 check(g.rerolls_left==0 and g.choices!=choices and g.choices.size()==4,"Reroll spends once and presents alternative training")
 for id in Offers.TRAINING:
  var before=Stats.calculate(g);var expected=Stats.upgrade_preview(g,id)
  g.mode="relic";g.choices=[id];g.choice_ui.skip_level_intro();g.action("relic0")
  var actual=Stats.calculate(g)
  for key in ["attack","armor","speed","fire","ice","acid","poison"]:
   check(is_equal_approx(float(actual[key]),float(expected[key])),"Training preview matches selected "+id+" / "+key)
  check(not g.relics.has(id),"Training is not recorded as a one-time relic")
  if id=="attack":check(actual.attack>before.attack,"Attack training increases physical power")
 g.mode="relic";g.choices=["attack","guard","fire","ice"];await redraw()
 check(g.buttons.any(func(b):return b.id=="relic3"),"Training choices render as selectable level-up cards")
 g.new_run(722);check(g.bonus.attack==0 and g.base_elements.fire==0,"Training resets on the next expedition")

 # Existing pending offers are repaired without consuming RNG or changing valid choices.
 g.reward_level=10;g.mode="relic";g.choices=["venom_edge","toxic_harvest","blood_harvest"]
 g.session.enabled=true;g.session.active=true
 check(g.session.checkpoint(),"Save pending fixed-loadout choices")
 var rng_before=g.rng.state
 check(g.session.continue_run(),"Load saved pending choices")
 check(g.choices[1]=="toxic_harvest" and g.choices.all(func(id):return Offers.eligible(g,id,Stats.calculate(g))),"Restore replaces impossible offers and preserves achievable investments")
 check(g.rng.state==rng_before,"Offer migration does not reroll future encounters or loot")
 var restored=g.choices.duplicate();check(g.session.checkpoint() and g.session.continue_run() and g.choices==restored,"Repaired choices remain stable after another save/load")
 g.mode="relic";g.choices=["attack","guard","fire"]
 check(g.session.checkpoint() and g.session.continue_run() and g.choices==["attack","guard","fire"],"Training choices survive save/load")
 g.session.enabled=false;g.session.active=false;g.session.cached={}

 # Old completed masteries migrate on workshop access; incomplete ones do not.
 g.career=g.replay.new_career();g.new_run(723)
 for id in ["bloodletter","winterblade","caustic"]:
  var goal=g.mastery.GOALS[id]
  g.career.mastery[goal.metric]=goal.target-1
  check(not g.smithy.data().blueprints.has(id),"Incomplete mastery does not unlock "+id)
  g.mastery.add(goal.metric,1)
  check(g.smithy.data().blueprints.has(id) and g.smithy.data().unseen_blueprints.has(id),"Completing mastery immediately unlocks "+id)
 var p=g.smithy.data();var materials=p.materials.duplicate();p.unseen_blueprints.clear()
 for id in ["bloodletter","winterblade","caustic"]:g.mastery.add(g.mastery.GOALS[id].metric,1)
 check(p.unseen_blueprints.is_empty() and p.materials==materials,"Completed masteries never duplicate notifications or pay duplicate ore")
 for id in ["bloodletter","winterblade","caustic"]:p.blueprints.erase(id)
 check(g.save_progress(),"Save pre-migration completed mastery profile")
 g.load_progress();p=g.smithy.data()
 check(["bloodletter","winterblade","caustic"].all(func(id):return p.blueprints.has(id)),"Old completed masteries receive all missing blueprints")
 check(g.save_progress(),"Persist migrated blueprint ownership")
 g.load_progress();p=g.smithy.data();p.unseen_blueprints.clear();g.smithy.data()
 check(p.unseen_blueprints.is_empty(),"Reloaded ownership is an idempotent migration receipt")
 g.career=g.replay.new_career();g.run_settings.mode="daily";g.mastery.add("vamp_healed",60)
 check(not g.smithy.data().blueprints.has("bloodletter"),"Daily cannot grant permanent mastery blueprints")
 g.run_settings.mode="standard";g.demo_run=true;g.mastery.add("vamp_healed",60)
 check(not g.smithy.data().blueprints.has("bloodletter"),"Practice cannot grant permanent mastery blueprints")
 g.demo_run=false;g.new_run(724)

 # Colossus uses the real reward pool, rarity/floor gates and cargo lifecycle.
 for base in ["axe","greatblade"]:
  var special="colossus_"+base
  check(special not in g.smithy.discovery_candidates(base,2,2),"Colossus cannot drop before floor 3")
  check(special not in g.smithy.discovery_candidates(base,0,5),"Common rewards cannot drop Colossus")
  check(special in g.smithy.discovery_candidates(base,1,3),"Rare matching floor-3 rewards can drop Colossus")
  check("winterblade" not in g.smithy.discovery_candidates(base,2,5),"Mastery blueprints never enter random chest pools")
  var reward=g.make_gear("weapon",1,1,[],base);g.floor_number=3
  for i in range(g.smithy.discovery_candidates(base,1,3).size()):g.smithy.reward(reward)
  check(g.smithy.cargo().blueprints.has(special) and not g.smithy.data().blueprints.has(special),"Colossus reward waits in expedition cargo")
 g.finish_run(false);p=g.smithy.data()
 check(p.blueprints.has("colossus_axe") and p.blueprints.has("colossus_greatblade"),"Death retains discovered Colossus blueprints")

 # Craft all specials, preserve their exact properties, and carry them through saves/runes/slots.
 for id in ["bloodletter","winterblade","caustic"]:g.career.mastery[g.mastery.GOALS[id].metric]=g.mastery.GOALS[id].target
 p=g.smithy.data();p.materials={"ore":100,"monster":100,"boss":0,"alloy":100,"essence":100,"relic":100}
 g.mode="smithy";g.action("smithy_make:bloodletter")
 check(not p.items.has("bloodletter"),"Special crafting requires a Warden core")
 p.materials.boss=20
 for id in g.smithy.SPECIALS:
  var core_before=int(p.materials.boss);g.mode="smithy";g.action("smithy_make:"+id)
  check(p.items.has(id) and p.materials.boss==core_before-1,"Crafting "+id+" consumes exactly one core")
  var costs_before=p.materials.duplicate();g.action("smithy_make:"+id)
  check(p.materials==costs_before,"Cannot craft the same special twice")
  var spec=g.smithy.SPECIALS[id]
  for level in [1,3,5]:
   var item=g.smithy.make_item(id,level,"poison")
   var expected=g.smithy.make_item(spec.base,level,"poison");expected.rarity=1
   if spec.has("variant"):expected.variant=spec.variant
   if spec.has("heavy_form"):expected.heavy_form=spec.heavy_form
   check(g.Gear.stats(item)==g.Gear.stats(expected),"Special identity, rune and level preserved for "+id)
  p.slot_levels.weapon=3;p.elements.poison=true
  g.action("smithy_runes:"+id);g.action("smithy_infuse:poison")
  g.loadout_menu.open("expedition");g.action("loadout_select:"+id);g.action("loadout_equip");g.new_run(725)
  var equipped=g.inventory[g.equipped.weapon]
  check(equipped.name==g.smithy.RECIPES[id][0] and equipped.level==3 and equipped.infusion=="poison","Crafted special can be equipped with shared upgrades and rune: "+id)
  g.session.enabled=true;g.session.active=true
  check(g.session.checkpoint() and g.session.continue_run() and g.inventory[g.equipped.weapon]==equipped,"Special loadout survives checkpoint: "+id)
  g.session.enabled=false;g.session.active=false;g.session.cached={};p=g.smithy.data()
 preload("res://tools/historical_run.gd").start_mode(g,726,"daily")
 check(g.inventory.size()==1 and g.inventory[0].archetype=="balanced" and g.inventory[0].level==1 and not g.inventory[0].has("variant"),"Daily still starts with its fixed ordinary sword")
 g.replay.draft.mode="standard";g.new_run(727);p=g.smithy.data()
 for id in g.smithy.category_ids("weapon"):p.blueprints[id]=true;p.items[id]=1
 g.mode="title";g.action("smithy_open");await redraw()
 check(g.buttons.any(func(b):return b.id=="smithy_next") and g.buttons.any(func(b):return b.id=="smithy_upgrade_slot:weapon"),"Paginated smithy retains slot-upgrade controls")
 g.action("smithy_next");await redraw()
 check(g.buttons.any(func(b):return b.id=="smithy_select:colossus_greatblade"),"Last special weapon is accessible on smithy page 2")
 g.action("smithy_select:colossus_greatblade");await redraw()
 g.loadout_menu.open("expedition");await redraw()
 check(g.buttons.any(func(b):return b.id=="loadout_items_next"),"Expanded loadout catalogue has pagination")
 g.action("loadout_items_next");await redraw()
 check(g.buttons.any(func(b):return b.id=="loadout_select:colossus_greatblade"),"Last special weapon is accessible on loadout page 2")
 g.loadout_menu.filter_index=g.loadout_menu.FILTERS.find("Special");g.loadout_menu.item_page=0;await redraw()
 check(g.loadout_menu.filtered_ids().size()==5,"Special filter contains exactly the five special recipes")
 g.loadout_menu.filter_index=g.loadout_menu.FILTERS.find("Base")
 check(g.loadout_menu.filtered_ids().size()==5,"Base filter excludes special weapons")
 g.free();cleanup()
 print(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
