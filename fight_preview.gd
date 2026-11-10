extends RefCounted
## Future rolls are sampled on private copies; inspection never changes combat or room RNG.
var g
var cached_key=0
var cached={}
func _init(game):g=game
func estimate(enemy: Dictionary) -> Dictionary:
	var target=enemy.duplicate(true)
	if g.mode=="bomb":
		target.hp=maxf(0,float(target.hp)-20)
		if target.hp<=0:return {"label":"Favorable","low_loss":0,"high_loss":0,"wins":7}
	var state=g.battle.duplicate(true) if g.mode=="fight" else g.Combat.begin(target,g.hp,g.max_hp,g.attack,g.armor,g.speed,g.relics,g.combat_build())
	var key=hash(var_to_bytes(state))
	if key==cached_key and not cached.is_empty():return cached
	var wins=0;var health=[];var initial=float(state.hp)
	for i in range(7):
		var copy=state.duplicate(true);copy.roll=104729*(i+1);copy["evade_roll"]=15485863*(i+1)
		var result=g.Combat.predict(copy)
		if result.won:wins+=1
		health.append(float(result.hp))
	health.sort()
	var label="Favorable" if wins==7 and health[0]>=initial*0.35 else ("Dangerous" if wins>=2 else "Deadly")
	cached_key=key;cached={"label":label,"low_loss":maxi(0,int(initial-health[-1])),"high_loss":maxi(0,int(initial-health[0])),"wins":wins}
	return cached
func draw(enemy: Dictionary) -> void:
	if g.mode=="bomb" and not g.valid_bomb_target(Vector2i(((g.design_mouse()-g.ORIGIN)/g.TILE).floor())):
		g.text(Vector2(988,477),"BOMB OUT OF REACH",18,Color("d68b7e"));return
	var p=estimate(enemy);g.text(Vector2(988,452),"Estimated risk",18)
	var label={"Favorable":"LOW RISK","Dangerous":"RISKY","Deadly":"DEADLY"}.get(p.label,"RISKY")
	g.text(Vector2(988,477),label,23,g.TEAL if label=="LOW RISK" else Color("e3ab83"))
	g.text(Vector2(988,502),"~%d–%d HP / no flask"%[p.low_loss,p.high_loss],15,g.INK)
	g.stat_ui.register("health",Rect2(988,435,225,75),"Estimated risk","Seven simulated fights sample possible outcomes without using a flask. Actual damage and the outcome can vary.")
