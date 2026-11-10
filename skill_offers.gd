extends RefCounted
# Rarity and eligibility describe offers only; owned skills always keep their effects.
const RARE=["quickdraw","needle","wildfire","shatter","bulwark","contagion","critical_horizon","glacial_crusher","venom_edge","caustic_burn","frozen_precision","blood_harvest","shieldbreaker","warded_blade","ashen_charge","breakthrough","combustion","toxic_harvest","exposed_core"]
const EPIC=["steamglass","corrosive_flame","black_ice","toxic_spark","unbound_aim","toxic_glacier","frost_shatter"]
const HEAVY_NEW=["breakthrough","frost_shatter"]
const SPECIALIZED=["combustion","toxic_harvest","exposed_core"]
const NEW=["glacial_crusher","venom_edge","caustic_burn","frozen_precision","blood_harvest","shieldbreaker","warded_blade","ashen_charge","toxic_glacier"]
const REQUIREMENTS={
 "heavy_momentum":["heavy"],"combustion":["heavy","fire4"],"toxic_harvest":["poison4"],"exposed_core":["acid4"],
 "glacial_crusher":["heavy","ice"],"venom_edge":["dagger","poison"],"caustic_burn":["fire","acid"],
 "frozen_precision":["ice"],"blood_harvest":["poison","vampirism"],"shieldbreaker":["heavy"],
 "warded_blade":["sword"],"ashen_charge":["fire"],"toxic_glacier":["poison"],
 "breakthrough":["heavy"],"frost_shatter":["heavy","ice"]}
const FIXED_REQUIREMENTS=["heavy","dagger","sword","vampirism"]
const TRAINING=["attack","guard","fire","ice","acid","poison"]
const GENERAL_SKILLS=["precision","ruin","leech","ward","bloom","spark"]
const REQUIREMENT_LABELS={"heavy":"axe or greatblade","fire":"Fire","ice":"Frost","acid":"Acid","poison":"Poison","fire4":"4 Fire power","poison4":"4 Poison power","acid4":"4 Acid power"}
static func rarity(id: String) -> String:
 return "Epic" if id in EPIC else "Rare" if id in RARE else "Common"
# The same requirements drive offer eligibility and the preview's missing-build text.
static func missing_requirements(g,id: String,totals: Dictionary) -> Array:
 var idx=int(g.equipped.get("weapon",-1));var weapon=str(g.inventory[idx].get("archetype","unarmed")) if idx>=0 and idx<g.inventory.size() else "unarmed"
 var e=totals.get("element_totals",{});var build=totals.get("build",{});var rules=preload("res://element_rules.gd");var missing=[]
 for requirement in REQUIREMENTS.get(id,[]):
  match requirement:
   "heavy":if weapon not in ["axe","greatblade"]:missing.append(requirement)
   "dagger":if weapon!="dagger":missing.append(requirement)
   "sword":if weapon!="balanced":missing.append(requirement)
   "fire","ice","acid","poison":
    if float(e.get(requirement,0))<=0:missing.append(requirement)
   "fire4","poison4","acid4":
    var element=requirement.trim_suffix("4")
    if rules.element_power(build,element)<4:missing.append(requirement)
   "vampirism":if float(totals.get("vampirism",0))<=0:missing.append("vampirism")
 return missing
static func build_requirements(g,id: String,totals: Dictionary) -> Array:
 var result=[]
 for requirement in missing_requirements(g,id,totals):result.append(REQUIREMENT_LABELS.get(requirement,requirement))
 return result
static func requirement_note(id: String) -> String:
 var labels=[]
 for requirement in REQUIREMENTS.get(id,[]):labels.append(REQUIREMENT_LABELS.get(requirement,requirement))
 return " + ".join(labels)
static func has_build_requirement(id: String) -> bool:
 return REQUIREMENTS.has(id)
static func eligible(g,id: String,totals: Dictionary) -> bool:
 if g.run_rules>=20:
  for requirement in missing_requirements(g,id,totals):
   if requirement in FIXED_REQUIREMENTS:return false
  return true
 var weapon=str(totals.get("build",{}).get("weapon",""))
 # BuildStats derives the equipped archetype independently of the UI.
 var index=int(g.equipped.get("weapon",-1))
 weapon=str(g.inventory[index].get("archetype","unarmed")) if index>=0 and index<g.inventory.size() else "unarmed"
 var e=totals.element_totals
 # Future-facing offers allow deliberate investments; their descriptions retain requirements.
 if g.run_rules>=18 and id in ["combustion","toxic_harvest","exposed_core","glacial_crusher","venom_edge","caustic_burn","frozen_precision","blood_harvest","shieldbreaker","breakthrough","frost_shatter","warded_blade","ashen_charge","toxic_glacier"]:return true
 match id:
  "combustion":return weapon in ["axe","greatblade"] and preload("res://element_rules.gd").element_power(totals.build,"fire")>=4
  "toxic_harvest":return preload("res://element_rules.gd").element_power(totals.build,"poison")>=4
  "exposed_core":return preload("res://element_rules.gd").element_power(totals.build,"acid")>=4
  "glacial_crusher":return weapon in ["axe","greatblade"] and e.ice>0
  "venom_edge":return weapon=="dagger" and e.poison>0
  "caustic_burn":return e.fire>0 and e.acid>0
  "frozen_precision":return e.ice>0 and totals.crit_raw>0
  "blood_harvest":return e.poison>0 and totals.vampirism>0
  "shieldbreaker":return weapon in ["axe","greatblade"]
  "breakthrough":return weapon in ["axe","greatblade"]
  "frost_shatter":return weapon in ["axe","greatblade"] and e.ice>0
  "warded_blade":return weapon=="balanced" and (not g.inventory[index].get("plain",false) or "bulwark" in g.relics or "black_ice" in g.relics)
  "ashen_charge":return e.fire>0
  "toxic_glacier":return e.ice>0 and e.poison>0
 return true
static func pool(g) -> Array:
 var totals=preload("res://build_stats.gd").calculate(g);var result=[]
 for id in g.RELICS:
  if id in g.relics:continue
  if g.sanctuary and g.sanctuary.active() and g.sanctuary.SKILLS.has(id) and not g.sanctuary.unlocked(g.sanctuary.SKILLS[id]):continue
  if g.run_rules<18 and id in ["heavy_momentum","quickdraw"]:continue
  if g.run_rules<17 and id in SPECIALIZED:continue
  if g.run_rules<14 and id in HEAVY_NEW:continue
  if rarity(id)=="Rare" and g.reward_level<4:continue
  if rarity(id)=="Epic" and g.reward_level<7:continue
  if id=="critical_horizon" and (g.reward_level<5 or totals.crit_raw<0.35):continue
  if id=="unbound_aim" and (g.reward_level<9 or "critical_horizon" not in g.relics or totals.crit_raw<0.55):continue
  if eligible(g,id,totals):result.append(id)
 return result
static func choose(g,excluded: Array=[]) -> Array:
 var all=pool(g);var candidates=[]
 for id in all:
  if id not in excluded:candidates.append(id)
 var count=4 if g.ember_tree.rank("insight")>0 else 3
 if candidates.size()<count:
  for id in excluded:
   if id in all and id not in candidates:candidates.append(id)
 var result=[];var rare_luck=0.10*g.ember_tree.rank("transmutation");var epic_luck=0.10*g.ember_tree.rank("convergence")
 while result.size()<count and not candidates.is_empty():
  var rare_chance=clampf((0.12 if g.reward_level<6 else 0.32)+rare_luck,0.0,0.70) if g.reward_level>=4 else 0.0
  var epic_chance=clampf(0.08+epic_luck,0.0,0.30) if g.reward_level>=7 else 0.0
  var roll=g.rng.randf();var wanted="Epic" if roll<epic_chance else "Rare" if roll<epic_chance+rare_chance else "Common"
  var bucket=[]
  for id in candidates:
   if rarity(id)==wanted:bucket.append(id)
  if bucket.is_empty():bucket=candidates.duplicate()
  var picked=bucket[g.rng.randi_range(0,bucket.size()-1)];result.append(picked);candidates.erase(picked)
 if g.run_rules>=18 and not result.is_empty():
  var fallback=GENERAL_SKILLS
  var found=false
  for id in result:
   if id in fallback:found=true
  if not found:
   var available=[]
   for id in candidates:
    if id in fallback:available.append(id)
   if not available.is_empty():result[result.size()-1]=available[g.rng.randi_range(0,available.size()-1)]
 if g.run_rules>=20:
  # Exhausted skill pools still grant a useful level; blessings are repeatable.
  if not result.any(func(id):return id in GENERAL_SKILLS):
   var useful="guard" if "attack" in excluded else "attack"
   if result.size()==count:result[result.size()-1]=useful
   else:result.append(useful)
  var training=[]
  for id in TRAINING:
   if id not in result and id not in excluded:training.append(id)
  for id in TRAINING:
   if id not in result and id not in training:training.append(id)
  while result.size()<count and not training.is_empty():result.append(training.pop_front())
 return result

static func repair_saved_choices(g) -> bool:
 if g.run_rules<20:return false
 var totals=preload("res://build_stats.gd").calculate(g);var changed=false
 var replacements=pool(g)+TRAINING
 for i in range(g.choices.size()):
  var id=str(g.choices[i])
  if id in TRAINING or (g.RELICS.has(id) and eligible(g,id,totals)):continue
  for replacement in replacements:
   if replacement not in g.choices:
    g.choices[i]=replacement;changed=true;break
 return changed
