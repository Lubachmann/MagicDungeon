extends RefCounted
var g
var settings_group=0
var display_pending=false
var display_previous=0
var display_deadline=0
const TUTORIAL=[
	["Explore the dungeon","Move one tile with arrows or WASD. Collect blueprints and materials. Defeat the boss to reach the next floor."],
	["Choose your fights","Hover an enemy or press I to inspect it. Step into it to fight automatically. H uses a flask—even during combat. Your run levels reset. Blueprints, materials, crafted equipment and banked embers remain."]]

func _init(game):g=game
func overlay(rect: Rect2=Rect2(200,80,880,680)) -> void:
	g.draw_rect(Rect2(0,0,1280,840),Color(0.025,0.025,0.035,0.96))
	g.panel(rect)
func draw_mode() -> void:
	match g.mode:
		"title":draw_title()
		"confirm_new":draw_confirm_new()
		"pause":draw_pause()
		"tutorial":draw_tutorial()
		"controls":draw_controls()
		"shrine":draw_shrine()
func menu_backdrop() -> void:
	g.draw_rect(Rect2(0,0,1280,840),Color("0d0d12"))
	for y in range(14):
		for x in range(21):g.draw_texture_rect(g.textures["floor_worn" if (x+y)%4==0 else "floor"],Rect2(x*64,y*64,64,64),false,Color(0.22,0.20,0.25,0.65))
	g.draw_rect(Rect2(0,0,1280,840),Color(0.02,0.02,0.03,0.45))
	for at in [Vector2(18,24),Vector2(1210,24),Vector2(18,725),Vector2(1210,725)]:g.draw_texture_rect(g.textures.torch,Rect2(at,Vector2(48,80)),false)
func icon_button(rect: Rect2,icon: String,label: String,id: String,selected: bool=false,enabled: bool=true) -> void:
	g.button(rect,"",id,selected,enabled)
	var size=48 if rect.size.y>=75 else 32
	g.ui_icon(icon,rect.position+Vector2(14,(rect.size.y-size)/2),size)
	g.text(rect.position+Vector2(size+28,rect.size.y/2+8),label,22 if rect.size.y>=75 else 19,g.GOLD if enabled else Color("77717c"))
func draw_title() -> void:
	menu_backdrop()
	g.text(Vector2(75,100),"MAGIC DUNGEON",48,g.GOLD)
	g.text(Vector2(78,135),g.profiles.name_of(g.profiles.current),21,g.TEAL)
	g.panel(Rect2(75,190,410,460))
	for y in range(6):
		for x in range(5):
			var at=Vector2(100+x*72,215+y*66)
			g.draw_texture_rect(g.textures["wall" if x==0 or x==4 or y==0 else "floor"],Rect2(at,Vector2(72,66)),false)
	g.draw_texture_rect(g.textures.stairs,Rect2(244,281,72,66),false)
	g.draw_texture_rect(g.textures.player,Rect2(244,413,72,66),false)
	g.draw_texture_rect(g.textures.chest,Rect2(316,479,72,66),false)
	g.draw_texture_rect(g.textures.torch,Rect2(100,347,72,66),false)
	icon_button(Rect2(535,170,650,104),"boots","Continue","continue",g.session.has_run(),g.session.has_run())
	if g.session.has_run():
		var state=g.session.cached.state
		g.text(Vector2(612,255),"Floor %d / Lv %d / %d HP"%[state.floor_number,state.character_level,state.hp],16,g.TEAL)
	icon_button(Rect2(535,290,650,104),"attack","New expedition","expedition")
	icon_button(Rect2(535,415,315,86),"hammer","Smithy","smithy_open")
	icon_button(Rect2(870,415,315,86),"health","Characters","profiles")
	icon_button(Rect2(535,520,315,86),"ember","Ember Tree","skills")
	icon_button(Rect2(870,520,315,86),"map","Settings","settings")
	icon_button(Rect2(535,630,200,64),"ember","Hearth","sanctuary")
	icon_button(Rect2(760,630,200,64),"book","Chronicle","codex")
	icon_button(Rect2(985,630,200,64),"moon","Quit","quit")
	g.ui_icon("ember",Vector2(95,690),32);g.text(Vector2(140,719),str(g.bank),27,g.GOLD)
	g.ui_icon("sun",Vector2(280,690),32);g.text(Vector2(325,719),str(g.career.wins),27,g.TEAL)
	g.text(Vector2(75,800),"Arrows / D-pad     Enter / A",17)
	if Rect2(535,630,200,64).has_point(g.design_mouse()):g.text(Vector2(535,735),"Visit the sanctuary",19,g.TEAL)
	if g.session.error!="":g.draw_wrapped(g.session.error,Vector2(535,760),650,18,Color("ee9b88"),2)
func draw_confirm_new() -> void:
	menu_backdrop();g.panel(Rect2(260,220,760,410))
	g.ui_icon("attack",Vector2(600,255),64)
	g.text(Vector2(310,370),"REPLACE THIS RUN?",32,g.GOLD)
	g.text(Vector2(310,420),"Your tree and banked embers stay.",23,g.TEAL)
	icon_button(Rect2(310,510,330,65),"attack","New run","begin_run")
	icon_button(Rect2(670,510,300,65),"boots","Back","title")
func draw_pause() -> void:
	overlay(Rect2(350,140,580,570));g.ui_icon("moon",Vector2(610,170),48)
	g.text(Vector2(405,268),"PAUSED",36,g.GOLD)
	icon_button(Rect2(400,310,480,66),"boots","Resume","resume")
	icon_button(Rect2(400,400,480,66),"map","Settings","settings")
	icon_button(Rect2(400,490,480,66),"map","Save & title","title")
	icon_button(Rect2(400,580,480,66),"book","Save & quit","quit")
	if g.session.error!="":g.draw_wrapped(g.session.error,Vector2(400,680),480,18,Color("ee9b88"),2)
func draw_tutorial() -> void:
	overlay(Rect2(210,175,860,490))
	var info=TUTORIAL[clampi(g.tutorial_step,0,TUTORIAL.size()-1)]
	g.text(Vector2(260,230),"HOW TO PLAY / %d of %d"%[mini(g.tutorial_step+1,TUTORIAL.size()),TUTORIAL.size()],20,g.TEAL)
	g.text(Vector2(260,282),info[0],32,g.GOLD)
	g.draw_wrapped(info[1],Vector2(260,332),750,24,g.INK,6)
	g.button(Rect2(260,535,480,52),"Start exploring" if g.tutorial_step>=TUTORIAL.size()-1 else "Next","tutorial_next")
	g.button(Rect2(770,535,250,52),"Skip guide","tutorial_skip")
	g.text(Vector2(260,625),"You can reopen this guide from Settings.",18)
func display_begin() -> void:
	if display_pending:return
	display_previous=DisplayServer.window_get_mode();display_deadline=Time.get_ticks_msec()+15000;display_pending=true
	g.toggle_fullscreen();g.session.focused=0
func display_finish(keep: bool) -> void:
	if not display_pending:return
	if not keep:DisplayServer.window_set_mode(display_previous)
	display_pending=false;g.session.save_preferences();g.session.focused=0
func tick() -> void:
	if display_pending and Time.get_ticks_msec()>=display_deadline:
		display_finish(false);g.queue_redraw()
func draw_settings() -> void:
	if display_pending:
		menu_backdrop();overlay(Rect2(280,240,720,350))
		g.text(Vector2(325,310),"KEEP DISPLAY SETTING?",28,g.GOLD)
		g.text(Vector2(325,365),"Reverts automatically in %d seconds."%maxi(0,ceili(float(display_deadline-Time.get_ticks_msec())/1000.0)),20,g.INK)
		g.button(Rect2(325,475,290,60),"Keep","display_confirm")
		g.button(Rect2(645,475,290,60),"Revert","display_revert");return
	menu_backdrop();g.text(Vector2(90,85),"SETTINGS",36,g.GOLD)
	var groups=["Display & access","Audio","Controls & help"]
	for i in range(groups.size()):g.button(Rect2(90+i*370,110,340,60),groups[i],"settings_tab:%d"%i,settings_group==i)
	if settings_group==0:
		icon_button(Rect2(90,220,530,72),"vault","Stone" if g.ui_theme==0 else "Parchment","toggle_theme")
		icon_button(Rect2(660,220,530,72),"map","Fullscreen / windowed","display_toggle")
		icon_button(Rect2(90,320,530,72),"book","Large text" if g.session.preferences.large_text else "Standard text","text_size")
		icon_button(Rect2(660,320,530,72),"ice","Calm effects" if g.session.preferences.reduced_flashes else "Full effects","reduce_flashes")
		g.draw_wrapped("Large text increases minimum menu text size. Calm effects reduces flashes and camera movement.",Vector2(90,445),1000,20,g.TEAL,3)
	elif settings_group==1:
		var labels=["Effects","Ambience","Music"];var values=[g.sound.volume,g.sound.ambience_volume,g.sound.music_volume]
		var minus=["volume_down","ambience_down","music_down"];var plus=["volume_up","ambience_up","music_up"]
		for i in range(3):
			var y=215+i*100;g.text(Vector2(90,y+38),"%s  %d%%"%[labels[i],roundi(values[i]*100)],23,g.GOLD)
			g.button(Rect2(660,y,245,65),"−",minus[i]);g.button(Rect2(945,y,245,65),"+",plus[i])
		icon_button(Rect2(90,550,530,72),"moon","Muted" if g.muted else "Sound on","sound_toggle")
	else:
		icon_button(Rect2(90,220,530,72),"attack","Controls and bindings","controls")
		icon_button(Rect2(660,220,530,72),"book","How to play","tutorial_review")
		icon_button(Rect2(90,320,530,72),"relic","Credits","show_credits")
		icon_button(Rect2(660,320,530,72),"book","Export playtest report","export_playtest")
		g.draw_wrapped("Select Controls to change individual keyboard bindings. Controller buttons are listed there too.",Vector2(90,445),1000,20,g.TEAL,3)
	icon_button(Rect2(90,730,530,60),"boots","Back","close_menu")
	var tip="Select a category above.";var focused=""
	if g.menu_keyboard and not g.buttons.is_empty():focused=str(g.buttons[clampi(g.session.focused,0,g.buttons.size()-1)].id)
	else:
		for entry in g.buttons:
			if entry.rect.has_point(g.design_mouse()):focused=str(entry.id);break
	var help={"text_size":"Change the minimum menu text size.","reduce_flashes":"Reduce flashes and camera movement.","display_toggle":"Preview fullscreen or windowed mode; unconfirmed changes revert.","controls":"Change keyboard bindings or read controller controls.","sound_toggle":"Toggle all game audio.","tutorial_review":"Review the controls and the permanent progression guide.","export_playtest":"Save a local playtest report."}
	tip=str(help.get(focused,tip))
	g.text(Vector2(90,700),tip,16,g.TEAL)
func draw_controls() -> void:
	overlay(Rect2(140,65,1000,710))
	g.text(Vector2(185,120),"CONTROLS",32,g.GOLD)
	g.text(Vector2(185,158),"Select a binding, then press a key. Esc cancels. Duplicate keys swap.",18)
	var i=0
	for name in g.controls.bindings:
		var at=Vector2(185+(i%2)*470,195+(i/2)*62)
		g.button(Rect2(at,Vector2(365,48)),name.capitalize()+": "+("Press a key..." if g.controls.capture==name else g.controls.label(name)),"bind:"+name,false,name!="pause")
		g.button(Rect2(at+Vector2(375,0),Vector2(65,48)),"Reset","bind_reset:"+name,false,name!="pause")
		i+=1
	g.text(Vector2(185,601),"Controller: stick/D-pad move | A confirm / gear | B back | Start pause",20)
	g.text(Vector2(185,633),"X inspect | Y map | LB flask. Combat resolves automatically.",20)
	g.button(Rect2(185,680,440,48),"Restore default bindings","reset_bindings")
	g.button(Rect2(655,680,440,48),"Back","controls_back")
func draw_shrine() -> void:
	preload("res://shrine_preview.gd").draw(g)
