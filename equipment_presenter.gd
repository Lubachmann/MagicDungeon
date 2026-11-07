extends RefCounted
## Item-only numbers. Does not mutate equipment or consume preview RNG.
const Gear=preload("res://equipment.gd")
const Pacing=preload("res://combat_pacing.gd")
const LABELS={"impact_power":"Physical power","impact_rate":"Attack rate","fire_power":"Fire potency","frost_apply":"Frost power","acid_apply":"Acid power","poison_apply":"Poison power","base_interval":"Base interval","item_interval":"Item interval","attack":"Item attack","power":"Character power","armor":"Armor","health":"Max HP","speed":"Speed bonus","crit_chance":"Critical chance","crit_mult":"Critical damage","fire_dps":"Fire damage/s","ice_slow":"Enemy slow","acid_strip":"Armor removed/hit","poison_weak":"Less enemy damage","evade":"Evade chance","vampirism":"Vampirism"}
const ORDER=["base_interval","attack","power","item_interval","impact_power","impact_rate","armor","health","speed","crit_chance","crit_mult","fire_dps","ice_slow","acid_strip","poison_weak","fire_power","frost_apply","acid_apply","poison_apply","evade","vampirism"]
const PERCENT=["power","speed","impact_power","impact_rate","crit_chance","crit_mult","ice_slow","poison_weak","evade","vampirism"]
static func numbers(item: Dictionary) -> Dictionary:
	if item.is_empty():return {}
	var s=Gear.stats(item).duplicate()
	if item.slot=="weapon":
		var modern=int(item.get("balance",1))>=2
		s["base_interval"]=float(Pacing.INTERVALS.get(item.get("archetype","balanced"),2)) if modern else 1.0
		s["power"]=Pacing.power_scale(item.get("archetype","balanced"),int(item.get("balance",1))) if modern else 1.0
		s["item_interval"]=s.base_interval/(maxf(0.15,1.0+float(s.get("speed",0)))*maxf(0.15,1.0+float(s.get("impact_rate",0))))
	return s
static func keys(before: Dictionary,after: Dictionary) -> Array:
	var result=[]
	for key in ORDER:
		if key=="power":continue
		if key=="item_interval" and is_equal_approx(float(before.get("item_interval",0)),float(before.get("base_interval",0))) and is_equal_approx(float(after.get("item_interval",0)),float(after.get("base_interval",0))):continue
		if before.has(key) or after.has(key):result.append(key)
	return result
static func affected(before_item: Dictionary,after_item: Dictionary) -> Array:
	var rows=keys(numbers(before_item),numbers(after_item));var result=[]
	var mapping={"impact_power":"attack","impact_rate":"interval","fire_power":"fire","frost_apply":"ice","acid_apply":"acid","poison_apply":"poison","base_interval":"interval","item_interval":"interval","power":"attack","health":"max_hp","speed":"interval","fire_dps":"fire","ice_slow":"ice","acid_strip":"acid","poison_weak":"poison","evade":"evade"}
	for raw in rows:
		var key=mapping.get(raw,raw)
		if key not in result:
			result.append(key)
	return result
static func value(key: String,stats: Dictionary) -> String:
	if not stats.has(key):return "—"
	var n=float(stats[key])
	if key in ["base_interval","item_interval"]:return "%.2fs"%n
	if key in ["frost_apply","acid_apply","poison_apply"]:return ("%+d"%roundi(n)) if is_equal_approx(n,roundf(n)) else "%+.1f"%n
	if key=="fire_dps":return "%+.1f/s"%n
	if key in PERCENT:return "%+.1f%%"%(n*100) if key!="power" else "%.0f%%"%(n*100)
	return "%+.1f"%n if not is_equal_approx(n,roundf(n)) else "%+d"%roundi(n)
static func draw_item(g,item: Dictionary,origin: Vector2,width: float,height: float) -> void:
	var s=numbers(item);var rows=keys({},s)
	for i in range(rows.size()):
		var key=rows[i];var at=origin+Vector2((i%2)*width*0.5,int(i/2)*31)
		g.stat_ui.label(key,at,20);g.text(at+Vector2(23,-10),g.stat_ui.short_name(key),14,g.INK);g.text(at+Vector2(23,7),value(key,s),18,g.TEAL)
	g.stat_ui.scaling(item,origin+Vector2(0,height-12),width)
static func draw_comparison(g,before_item: Dictionary,after_item: Dictionary,origin: Vector2,width: float,height: float,paged: bool=false) -> bool:
	var total_height=height
	if after_item.get("slot","")=="weapon":height-=42
	var before=numbers(before_item);var after=numbers(after_item);var rows=keys(before,after)
	var pages=1
	if paged:
		var stamp=hash([before_item,after_item]);var per_page=maxi(1,int(height/24))
		if stamp!=g.build_view.item_compare_stamp:g.build_view.item_compare_stamp=stamp;g.build_view.item_compare_page=0
		pages=maxi(1,ceili(float(rows.size())/per_page));g.build_view.item_compare_page=clampi(g.build_view.item_compare_page,0,pages-1)
		rows=rows.slice(g.build_view.item_compare_page*per_page,(g.build_view.item_compare_page+1)*per_page)
	var step=mini(29,int(height/maxi(1,rows.size())))
	for i in range(rows.size()):
		var key=rows[i];var at=origin+Vector2(0,i*step)
		var a=float(before.get(key,0));var b=float(after.get(key,0));var delta=b-a
		var better=delta<0 if key in ["base_interval","item_interval"] else delta>0
		g.stat_ui.label(key,at,mini(24,maxi(18,step-2)))
		g.text(at+Vector2(30,0),g.stat_ui.short_name(key),18,g.INK)
		g.text(at+Vector2(width*0.56,0),value(key,before),18,g.INK)
		g.text(at+Vector2(width*0.80,0),value(key,after),20,g.INK if is_zero_approx(delta) else g.TEAL if better else Color("e88882"))
	g.stat_ui.scaling(after_item,origin+Vector2(0,total_height-12),width,before_item)
	if pages>1:
		g.button(Rect2(origin+Vector2(0,total_height+1),Vector2(55,30)),"<","item_stats_prev",false,g.build_view.item_compare_page>0)
		g.text(origin+Vector2(85,total_height+22),"Stats %d / %d"%[g.build_view.item_compare_page+1,pages],18)
		g.button(Rect2(origin+Vector2(width-55,total_height+1),Vector2(55,30)),">","item_stats_next",false,g.build_view.item_compare_page<pages-1)
	return pages>1
