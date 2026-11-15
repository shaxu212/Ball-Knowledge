extends Node2D
## BOOM BOOM v3 - whimsical cyberpunk bounce-and-pop game (Godot 4.x)
## Everything is drawn and played from code: no image or sound files needed.
##
## NEW in v3: title page with mascot (BOOMY), main menu (start / instructions /
## options / leaderboard / quit), name entry, saved leaderboard, and a different
## background scene for every level (cities, hills, mountains, desert, beach,
## forest, arctic, cherry garden, carnival, storm).
##
## You lose ONLY when every ball is gone.
## Pop eyeball-bots to make more balls. Coloured bots have power-ups!

const W := 1152.0
const H := 648.0
const PADDLE_Y := 585.0
const PADDLE_H := 22.0
const BALL_R := 12.0
const MAX_BALLS := 10
const BOUNCE_H := 460.0     # how high a ball flies after bouncing off the box
const MIX_RATE := 16000     # audio sample rate for generated sounds
const NUM_LEVELS := 10
const NET_Y := 622.0        # height of the safety net power-up
const MAX_NAME := 12
const MAX_SCORES := 10
const SAVE_PATH := "user://boom_boom_scores.json"
const UI_STATES := ["title", "menu", "instructions", "options", "leaderboard", "name"]

class Ball:
	var pos := Vector2.ZERO
	var prev := Vector2.ZERO
	var vel := Vector2.ZERO
	var hue := 0.5
	var trail: Array = []

class Target:
	var base := Vector2.ZERO
	var pos := Vector2.ZERO
	var phase := 0.0
	var kind := "normal"   # normal, armor, virus, multi, wide, slow, bomb, net
	var hp := 1

class Particle:
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var life := 0.0
	var max_life := 1.0
	var color := Color.WHITE
	var size := 4.0

class FloatText:
	var pos := Vector2.ZERO
	var text := ""
	var life := 1.0
	var color := Color.WHITE

# ---------------------------------------------------------------- LEVEL INFO
var level_names := [
	"NOODLE ALLEY", "RUBBER DUCK MAINFRAME", "KARAOKE CYBERDOME", "DISCO FIREWALL",
	"TOASTER DISTRICT", "HOLOGRAM HIGHWAY", "PIZZA SERVER FARM", "NEON SEWER SPA",
	"GLITCH CARNIVAL", "THE ANGRY CLOUD",
]
var level_tags := [
	"Easy mode. Enjoy it while it lasts.",
	"The ducks are watching you.",
	"The bots have started dancing. Rude.",
	"Things are getting spicy AND fast.",
	"The toasters are plotting something.",
	"Traffic is mostly holograms. Mostly.",
	"Do not ask what the servers are cooking.",
	"Relax. Breathe. Pop things.",
	"Everything is slightly broken. On purpose.",
	"The cloud is furious. Do not ask why.",
]
var level_hints := [
	"Pop the eyeball-bots! You only lose when ALL your balls are gone.",
	"Coloured bots give POWER-UPS: x3 balls, WIDE box, SLOW-MO, BOOM, NET.",
	"",
	"Armoured bots need 2 hits.",
	"Red VIRUS bots delete any ball that touches them. Avoid!",
	"", "", "", "", "",
]

var levels: Array = []
var power_kinds := ["multi", "wide", "slow", "bomb", "net"]
var kind_labels := {"multi": "x3", "wide": "WIDE", "slow": "SLOW", "bomb": "BOOM", "net": "NET", "virus": "VIRUS"}
var power_texts := {"multi": "TRIPLE BALL!", "wide": "WIDE BOX!", "slow": "SLOW-MO!", "bomb": "KABOOM!", "net": "SAFETY NET!"}

var neon := [
	Color(1.0, 0.2, 0.8), Color(0.2, 0.9, 1.0), Color(1.0, 0.9, 0.2),
	Color(0.4, 1.0, 0.5), Color(1.0, 0.5, 0.15),
]

# ---------------------------------------------------------------- FUNNY MESSAGES
var game_over_msgs := [
	"Your balls have left the chat. All of them.",
	"Gravity: 1. You: 0.",
	"The balls filed for emotional damages and moved to Neo-Tokyo.",
	"Error 404: catching skills not found.",
	"Even the rubber duck in the mainframe is laughing at you.",
	"Your box was just vibing. Unfortunately, so was the floor.",
	"Ball.exe has stopped working. So have your reflexes.",
	"Somewhere, a neon noodle shop owner just whispered 'skill issue'.",
	"Plot twist: the floor was lava. Cyber-lava. Extra rude.",
	"Your balls took the express elevator to Level Down.",
	"That was less 'boom boom' and more 'bonk... splat.'",
	"The robots held a meeting. You were the agenda.",
	"Have you tried turning your hands off and on again?",
	"A pigeon with a cybernetic eye saw that. It is telling everyone.",
	"The last ball said 'I need space' and took it. All of it. Downward.",
	"Breaking news: local box fails to be a box. More at 11.",
	"Your high score has been uploaded to the dark web. They were not impressed.",
	"All balls lost. Dignity lost. Wi-Fi still fine, though.",
	"The eyeball-bots saw everything. They have opinions.",
	"Congratulations! You have unlocked the achievement 'Gravity Wins Again'.",
	"The balls chose freedom. The floor chose violence.",
	"Your reflexes are on a 30-day free trial that just expired.",
	"Even the spare ball gave up on you. That one hurts.",
	"The virus bots will be sending you a thank-you card.",
	"The cloud sends its regards. And a small drizzle of disappointment.",
	"Your balls have unionized and gone on strike.",
	"Neon noodle delivery arrived. Your balls did not.",
	"The ball asked for a refund. Denied by the floor.",
	"Your last ball just ghosted you. Seen at 11:42.",
	"Ctrl+Z does not work on gravity. We checked.",
	"The balls would like to speak to the manager.",
	"Mission failed successfully. Mostly failed, actually.",
	"A toaster in Level 5 just laughed. You heard it too.",
	"Your reflexes were last seen buffering at 99%.",
	"The robots are placing bets on you. Nobody picked you.",
	"That ball had a family. Well, a few other balls. Still.",
	"Your box did its best. Your hands did something else.",
	"Somewhere, a hologram taxi drove away from your dreams.",
	"Local box swears the ball was 'right there a second ago'.",
	"The balls have moved out. They left a note: 'It's not us, it's you.'",
	"Physics is undefeated. You are 0 for ever.",
	"You have been rated 'Mostly Harmless' by the Galactic Ball Council.",
	"Your skills have been sent to the cloud. The cloud lost them.",
	"Breaking: local player loses all balls in tragic neon accident.",
	"The rubber ducks gave you a 1-star review. 'Too much falling.'",
	"Even the disco firewall felt bad for you. It stopped dancing.",
	"You blinked. The balls did not wait.",
	"Congratulations, you invented a new way to lose! It's called 'all at once'.",
	"Server farm update: your balls were fed to the pizza ovens.",
	"Your thumbs have requested a performance improvement plan.",
	"The neon sewer spa offers you a free massage. You need it.",
	"Gravity sends a sympathy card. It is addressed to the floor.",
	"Beep boop. Translation: 'lol'.",
	"Have you considered playing with your eyes open?",
	"The eyeball-bots saw you fail and are still staring. Awkward.",
	"Your box tried. Then it stopped trying. Then it fell asleep.",
	"Boom boom? More like doom doom.",
	"The glitch carnival called. They want their clown back.",
	"Cybernetic pigeons: 1. Your balls: 0.",
	"You didn't lose. You just generously donated balls to gravity.",
	"All balls have achieved terminal velocity. Terminal, indeed.",
	"Neo-Tokyo news at nine: balls gone, nobody surprised.",
	"This message was generated just for you. It says: 'oops'.",
	"Your balls took the long way home. The very long way. Down.",
	"Achievement unlocked: 'Gravity Enthusiast (Level 1 Fan)'.",
	"The floor says thanks for dropping by!",
	"New high score in 'balls lost per minute'. Congratulations?",
	"Roses are red, balls are gone, the floor is cold, try again, move on.",
	"The robots will remember this fondly. As a joke.",
]

var over_titles := [
	"GAME OVER", "OOF.", "BALLS: GONE", "SKILL ISSUE", "WASTED", "NOPE.", "RIP BALLS",
	"BONK.", "WHOOPS", "OH NO", "404 BALLS", "FAHHHH", "DEFEAT", "SPLAT.",
]

var over_tips := [
	"Hit the ball with the EDGE of the box to aim it sideways.",
	"Grab a NET bot when you are feeling shaky.",
	"Red VIRUS bots are not your friends.",
	"A WIDE box makes everything easier. Cheating, but legal.",
	"BOOM bots clear virus bots safely.",
	"More balls = more points. Also more panic.",
	"Blinking is optional. Watching the ball is not.",
	"Try breathing. It helps. Sometimes.",
	"The floor is not your friend. Stop visiting it.",
	"The box has googly eyes. They are judging you.",
	"SLOW-MO gives you time to question your choices.",
	"Quick pops make a COMBO. Combos make points.",
]

var win_titles := [
	"YOU WIN!", "VICTORY!", "LEGEND!", "BOOM BOOM!", "CHAMPION!", "YAYYY!", "NICE ONE!",
]

var win_msgs := [
	"You defeated the Angry Cloud! It is now a mildly annoyed drizzle.",
	"Congratulations! The robots have named a noodle after you.",
	"All 10 levels cleared! Somewhere a rubber duck is crying tears of joy.",
	"Boom Boom champion! Collect your imaginary trophy from the nearest neon vending machine.",
	"The balls have asked to be your emotional support balls forever.",
	"The city lights are blinking in your honor. Mostly the ones that were already blinking.",
	"The Angry Cloud has been reclassified as 'Mild Inconvenience'.",
	"Victory! The toasters have burned a bagel in your honor.",
	"The rubber ducks demand a victory lap. Please comply.",
	"You're a legend. The robots carved your name into a noodle bowl.",
	"The balls are crying happy tears. Cyber-tears. Very shiny.",
	"The eyeball-bots formed a fan club. They are obsessed. And watching.",
	"The city lights spelled your name. Then went back to flickering.",
	"Achievement unlocked: 'Ball Whisperer'.",
	"Final boss defeated. Final snack deserved.",
	"Your box has requested a promotion. To 'Mega Box'.",
	"The universe says: 'Okay, fine, you're good.'",
	"Server farm celebration: all pizzas free. (For robots only.)",
	"The hologram highway is now named after you. Toll: one high five.",
	"You have been awarded an imaginary medal made of 100% neon.",
	"The Glitch Carnival declares you Grand Champion. It is a compliment. Probably.",
]

var boom_words := ["BOOM!", "BOOM BOOM!", "KABLAM!", "ZAP!", "BZZT!", "POP!", "KAPOW!"]

# ---------------------------------------------------------------- STATE
var font: Font
# title, menu, instructions, options, leaderboard, name, ready, play, clear, over, win
var state := "title"
var paused := false
var state_time := 0.0
var timer := 0.0
var t := 0.0
var world_t := 0.0     # time that targets move by (slowed by SLOW-MO)
var shake := 0.0
var flash := 0.0
var level_idx := 0
var hits := 0
var score := 0
var best_score := 0
var combo := 0
var combo_timer := 0.0
var had_multi := false
var paddle_x := W / 2.0
var paddle_w := 200.0
var base_paddle_w := 200.0
var wide_timer := 0.0
var slow_timer := 0.0
var net_timer := 0.0
var balls: Array = []
var targets: Array = []
var particles: Array = []
var texts: Array = []
var rain: Array = []
var buildings: Array = []
var windows: Array = []
var msg := ""
var bags := {}
var over_title := "GAME OVER"
var over_tip := ""
var win_title := "YOU WIN!"

# menus / player / leaderboard
var menu_items := ["START GAME", "INSTRUCTIONS", "OPTIONS", "LEADERBOARD", "QUIT"]
var menu_sel := 0
var opt_rows := ["MUSIC", "MUSIC VOLUME", "SOUND FX", "SOUND FX VOLUME", "CONTROLS", "FULLSCREEN", "BACK"]
var opt_sel := 0
var control_mode := 0          # 0 = mouse + keyboard, 1 = mouse only, 2 = keyboard only
var music_vol := 1.0
var sfx_vol := 1.0
var player_name := ""
var name_text := ""
var scores: Array = []
var last_rank := -1
var mouse_pos := Vector2(W / 2.0, H / 2.0)

# backgrounds
var themes: Array = []
var scenes: Array = []
var stars: Array = []
var clouds: Array = []
var bolt := 0.0
var bolt_timer := 3.0
var bolt_pts := PackedVector2Array()

# audio
var sfx := {}
var sfx_players: Array = []
var sfx_next := 0
var music_player: AudioStreamPlayer
var music_cache := {}
var gen_next := 1
var current_track := -1
var music_on := true
var sfx_on := true


func _ready() -> void:
	font = ThemeDB.fallback_font
	_setup_fullscreen()
	_build_levels()
	_setup_audio()
	_make_city()
	_build_themes()
	_build_scenes()
	for i in 120:
		rain.append(Vector2(randf() * W, randf() * H))
	for i in 90:
		stars.append([Vector2(randf() * W, randf() * H * 0.4), randf() * TAU])
	for i in 7:
		clouds.append([randf() * (W + 400.0), randf_range(60.0, 260.0), randf_range(0.8, 1.5), randf_range(6.0, 18.0)])
	_load_scores()
	_set_track(0)


func _is_ui() -> bool:
	return UI_STATES.has(state)


func _setup_fullscreen() -> void:
	RenderingServer.set_default_clear_color(Color(0.02, 0.0, 0.06))
	var win := get_window()
	win.content_scale_size = Vector2i(int(W), int(H))
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.mode = Window.MODE_FULLSCREEN


func _toggle_fullscreen() -> void:
	var win := get_window()
	if win.mode == Window.MODE_FULLSCREEN or win.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		win.mode = Window.MODE_WINDOWED
	else:
		win.mode = Window.MODE_FULLSCREEN


func _is_fullscreen() -> bool:
	var m := get_window().mode
	return m == Window.MODE_FULLSCREEN or m == Window.MODE_EXCLUSIVE_FULLSCREEN


func _build_levels() -> void:
	for i in NUM_LEVELS:
		var virus_count := 0
		if i >= 4:
			virus_count = mini(1 + int((i - 4) / 2.0), 3)
		var armor_chance := 0.0
		if i >= 3:
			armor_chance = 0.12 + 0.03 * i
		var sway := 0.0
		if i > 0:
			sway = 50.0 + 20.0 * i
		levels.append({
			"name": level_names[i],
			"tag": level_tags[i],
			"hint": level_hints[i],
			"g": 1000.0 + 85.0 * i,            # gravity: higher = faster
			"hspeed": 360.0 + 28.0 * i,        # sideways speed off the box
			"paddle": 235.0 - 12.0 * i,        # box width
			"targets": 4 + int(i / 3.0),       # bots on screen
			"tr": 36.0 - 1.3 * i,              # bot size
			"sway": sway,                      # sideways wiggle
			"vsway": 7.0 * i,                  # up/down wiggle
			"need": 6 + int(round(i * 1.5)),   # pops to clear
			"virus": virus_count,
			"armor": armor_chance,
			"power": 0.28 - 0.01 * i,          # chance a bot is a power-up
		})


func _make_city() -> void:
	var window_colors := [Color(0.2, 0.9, 1.0), Color(1.0, 0.2, 0.8), Color(1.0, 0.9, 0.3)]
	var x := -10.0
	while x < W:
		var bw := randf_range(60.0, 130.0)
		var bh := randf_range(130.0, 330.0)
		var r := Rect2(x, H - bh, bw, bh)
		buildings.append(r)
		var wy := r.position.y + 16.0
		while wy < H - 30.0:
			var wx := r.position.x + 10.0
			while wx < r.end.x - 14.0:
				if randf() < 0.55:
					windows.append([Vector2(wx, wy), randf() * TAU, window_colors.pick_random()])
				wx += 18.0
			wy += 22.0
		x += bw + randf_range(4.0, 14.0)


# ---------------------------------------------------------------- HELPERS
func _lvl_col() -> Color:
	return neon[level_idx % neon.size()]


func _bot_r() -> float:
	var cfg: Dictionary = levels[level_idx]
	return float(cfg["tr"])


func _kind_color(kind: String, lvl_col: Color) -> Color:
	match kind:
		"multi":
			return Color(0.4, 1.0, 0.5)
		"wide":
			return Color(0.35, 0.65, 1.0)
		"slow":
			return Color(1.0, 0.9, 0.3)
		"bomb":
			return Color(1.0, 0.35, 0.25)
		"net":
			return Color(0.3, 1.0, 0.95)
		"virus":
			return Color(0.95, 0.1, 0.2)
	return lvl_col


# ---------------------------------------------------------------- LEADERBOARD
func _load_scores() -> void:
	scores.clear()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if data is Array:
		for e in data:
			if e is Dictionary and e.has("name") and e.has("score"):
				scores.append({"name": str(e["name"]), "score": int(e["score"]), "id": int(e.get("id", 0))})
	_sort_scores()
	if scores.size() > 0:
		best_score = int(scores[0]["score"])


func _sort_scores() -> void:
	scores.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))


func _write_scores() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(scores))


# Adds the current score under the current player's name; highest score stays on top.
func _save_score() -> void:
	last_rank = -1
	if score <= 0:
		return
	var id := randi()
	scores.append({"name": player_name, "score": score, "id": id})
	_sort_scores()
	if scores.size() > MAX_SCORES:
		scores.resize(MAX_SCORES)
	for i in scores.size():
		if int(scores[i]["id"]) == id:
			last_rank = i
	_write_scores()


# ---------------------------------------------------------------- MENUS
func _menu_rect(i: int) -> Rect2:
	return Rect2(W / 2.0 - 220.0, 230.0 + i * 64.0, 440.0, 52.0)


func _opt_rect(i: int) -> Rect2:
	return Rect2(W / 2.0 - 300.0, 180.0 + i * 58.0, 600.0, 48.0)


func _hover(pos: Vector2) -> void:
	if state == "menu":
		for i in menu_items.size():
			if _menu_rect(i).has_point(pos) and menu_sel != i:
				menu_sel = i
				_play("clink")
	elif state == "options":
		for i in opt_rows.size():
			if _opt_rect(i).has_point(pos) and opt_sel != i:
				opt_sel = i
				_play("clink")


func _menu_activate(i: int) -> void:
	_play("newball")
	match i:
		0:
			name_text = player_name
			state = "name"
			state_time = t
		1:
			state = "instructions"
		2:
			opt_sel = 0
			state = "options"
		3:
			state = "leaderboard"
		4:
			get_tree().quit()


func _step_vol(v: float, dir: int) -> float:
	if dir == 0:
		v += 0.1
		if v > 1.05:
			v = 0.0
	else:
		v = clampf(v + dir * 0.1, 0.0, 1.0)
	return clampf(snappedf(v, 0.1), 0.0, 1.0)


func _opt_change(i: int, dir: int) -> void:
	match i:
		0:
			music_on = not music_on
			_apply_music_pause()
		1:
			music_vol = _step_vol(music_vol, dir)
			_apply_volumes()
		2:
			sfx_on = not sfx_on
			_play("bounce")
		3:
			sfx_vol = _step_vol(sfx_vol, dir)
			_apply_volumes()
			_play("bounce")
		4:
			control_mode = posmod(control_mode + (dir if dir != 0 else 1), 3)
		5:
			_toggle_fullscreen()
		6:
			if dir == 0:
				state = "menu"


func _to_menu() -> void:
	state = "menu"
	paused = false
	state_time = t
	particles.clear()
	texts.clear()
	balls.clear()
	targets.clear()
	_set_track(0)
	_apply_music_pause()


func _name_key(k: InputEventKey) -> void:
	if k.echo and k.keycode != KEY_BACKSPACE:
		return
	match k.keycode:
		KEY_ENTER, KEY_KP_ENTER:
			if t - state_time < 0.25:
				return
			player_name = name_text.strip_edges()
			if player_name == "":
				player_name = "PLAYER"
			_new_game()
			return
		KEY_ESCAPE:
			state = "menu"
			return
		KEY_BACKSPACE:
			if name_text.length() > 0:
				name_text = name_text.substr(0, name_text.length() - 1)
			return
	if k.unicode >= 32 and k.unicode < 127 and name_text.length() < MAX_NAME:
		name_text += char(k.unicode).to_upper()


# ---------------------------------------------------------------- INPUT
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		mouse_pos = mm.position
		if control_mode != 2:
			paddle_x = clampf(mm.position.x, paddle_w / 2.0, W - paddle_w / 2.0)
		_hover(mm.position)
		return
	var confirm := false
	var back := false
	var click := false
	var cpos := Vector2.ZERO
	var nav := Vector2i.ZERO
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			confirm = true
			click = true
			cpos = mb.position
	elif event is InputEventKey:
		var k := event as InputEventKey
		if not k.pressed:
			return
		if state == "name":
			_name_key(k)
			return
		var nav_key := k.keycode == KEY_UP or k.keycode == KEY_DOWN or k.keycode == KEY_LEFT or k.keycode == KEY_RIGHT
		if k.echo and not nav_key:
			return
		match k.keycode:
			KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
				confirm = true
			KEY_UP, KEY_W:
				nav.y = -1
			KEY_DOWN, KEY_S:
				nav.y = 1
			KEY_LEFT, KEY_A:
				nav.x = -1
			KEY_RIGHT, KEY_D:
				nav.x = 1
			KEY_M:
				music_on = not music_on
				_apply_music_pause()
			KEY_N:
				sfx_on = not sfx_on
			KEY_F, KEY_F11:
				_toggle_fullscreen()
			KEY_ESCAPE:
				back = true
			KEY_P:
				if state == "ready" or state == "play" or state == "clear":
					paused = not paused
					_apply_music_pause()
			KEY_Q:
				if paused:
					_save_score()
					_to_menu()
	else:
		return

	match state:
		"title":
			if confirm:
				_play("newball")
				state = "menu"
				state_time = t
		"menu":
			if nav.y != 0:
				menu_sel = posmod(menu_sel + nav.y, menu_items.size())
				_play("clink")
			if confirm:
				if click:
					var hit := -1
					for i in menu_items.size():
						if _menu_rect(i).has_point(cpos):
							hit = i
					if hit < 0:
						return
					menu_sel = hit
				_menu_activate(menu_sel)
			elif back and _is_fullscreen():
				get_window().mode = Window.MODE_WINDOWED
		"instructions", "leaderboard":
			if confirm or back:
				_play("clink")
				state = "menu"
		"options":
			if nav.y != 0:
				opt_sel = posmod(opt_sel + nav.y, opt_rows.size())
				_play("clink")
			if nav.x != 0:
				_opt_change(opt_sel, nav.x)
			elif back:
				state = "menu"
			elif confirm:
				if click:
					var hit2 := -1
					for i in opt_rows.size():
						if _opt_rect(i).has_point(cpos):
							hit2 = i
					if hit2 < 0:
						return
					opt_sel = hit2
					var dirc := 0
					if hit2 == 1 or hit2 == 3:
						dirc = -1 if cpos.x < W / 2.0 else 1
					_opt_change(hit2, dirc)
				else:
					_opt_change(opt_sel, 0)
		"over", "win":
			if back:
				_to_menu()
			elif confirm and t - state_time > 0.8:
				_new_game()
		_:
			if back and _is_fullscreen():
				get_window().mode = Window.MODE_WINDOWED


func _new_game() -> void:
	level_idx = 0
	score = 0
	last_rank = -1
	paused = false
	particles.clear()
	texts.clear()
	_start_level()


func _start_level() -> void:
	var cfg: Dictionary = levels[level_idx]
	base_paddle_w = cfg["paddle"]
	paddle_w = base_paddle_w
	hits = 0
	combo = 0
	combo_timer = 0.0
	had_multi = false
	wide_timer = 0.0
	slow_timer = 0.0
	net_timer = 0.0
	balls.clear()
	targets.clear()
	for i in int(cfg["targets"]):
		_spawn_target()
	for i in int(cfg["virus"]):
		_spawn_target("virus")
	var start_balls := 1 + mini(int(level_idx / 3.0), 2)   # later levels start with more balls
	for i in start_balls:
		var b := Ball.new()
		b.pos = Vector2(paddle_x, 380.0)
		b.prev = b.pos
		b.hue = 0.5 if i == 0 else randf()
		balls.append(b)
	state = "ready"
	timer = 2.0
	state_time = t
	_set_track(level_idx)


func _spawn_target(force_kind: String = "") -> void:
	var cfg: Dictionary = levels[level_idx]
	var margin: float = float(cfg["sway"]) + 70.0
	var tg := Target.new()
	var tries := 0
	var ok := false
	while not ok and tries < 10:
		tries += 1
		tg.base = Vector2(randf_range(margin, W - margin), randf_range(170.0 + float(cfg["vsway"]), 400.0))
		ok = true
		for o in targets:
			var other: Target = o
			if other.base.distance_to(tg.base) < 90.0:
				ok = false
	tg.phase = randf() * TAU
	tg.pos = tg.base
	var kind := force_kind
	if kind == "":
		kind = "normal"
		var roll := randf()
		var power_c: float = cfg["power"]
		var armor_c: float = cfg["armor"]
		if roll < power_c:
			kind = power_kinds.pick_random()
		elif roll < power_c + armor_c:
			kind = "armor"
	tg.kind = kind
	tg.hp = 2 if kind == "armor" else 1
	targets.append(tg)


# ---------------------------------------------------------------- UPDATE
func _process(delta: float) -> void:
	t += delta
	_update_mouse_mode()
	if _is_ui():
		# builds one sound / music track per frame while on the title / menu screens
		if not sfx.has("fah"):
			sfx["fah"] = _make_fah()
		elif not sfx.has("yay"):
			sfx["yay"] = _make_yay()
		elif gen_next < NUM_LEVELS:
			_get_track(gen_next)
			gen_next += 1
	if paused:
		queue_redraw()
		return
	shake = maxf(0.0, shake - delta * 40.0)
	flash = maxf(0.0, flash - delta * 4.0)
	_update_fx(delta)
	match state:
		"ready":
			_move_paddle(delta)
			world_t += delta
			_move_targets()
			timer -= delta
			for i in balls.size():
				var b: Ball = balls[i]
				b.pos = Vector2(paddle_x + (i - (balls.size() - 1) / 2.0) * 36.0, 380.0)
				b.prev = b.pos
			if timer <= 0.0:
				for bo in balls:
					var b2: Ball = bo
					b2.vel = Vector2(randf_range(-120.0, 120.0), 0.0)
				state = "play"
				_play("go")
		"play":
			_update_play(delta)
		"clear":
			timer -= delta
			if timer <= 0.0:
				level_idx += 1
				_start_level()
	queue_redraw()


func _update_mouse_mode() -> void:
	if (state == "play" or state == "ready") and not paused:
		if Input.mouse_mode != Input.MOUSE_MODE_HIDDEN:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _move_paddle(delta: float) -> void:
	var dir := 0.0
	if control_mode != 1:
		if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
			dir -= 1.0
		if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
			dir += 1.0
	var target_w := base_paddle_w * (1.55 if wide_timer > 0.0 else 1.0)
	paddle_w = lerpf(paddle_w, target_w, minf(1.0, delta * 8.0))
	paddle_x += dir * 950.0 * delta
	paddle_x = clampf(paddle_x, paddle_w / 2.0, W - paddle_w / 2.0)


func _move_targets() -> void:
	var cfg: Dictionary = levels[level_idx]
	var sw: float = cfg["sway"]
	var vs: float = cfg["vsway"]
	var spd := 1.0 + level_idx * 0.2
	for tgo in targets:
		var tg: Target = tgo
		tg.pos = tg.base + Vector2(sin(world_t * 1.3 * spd + tg.phase) * sw, cos(world_t * 1.7 * spd + tg.phase) * vs)


func _update_play(delta: float) -> void:
	var cfg: Dictionary = levels[level_idx]
	var g: float = cfg["g"]
	var hspeed: float = cfg["hspeed"]
	var r_bot := _bot_r()
	_move_paddle(delta)
	wide_timer = maxf(0.0, wide_timer - delta)
	slow_timer = maxf(0.0, slow_timer - delta)
	net_timer = maxf(0.0, net_timer - delta)
	combo_timer -= delta
	if combo_timer <= 0.0:
		combo = 0
	var sd := delta * (0.5 if slow_timer > 0.0 else 1.0)
	world_t += sd
	_move_targets()
	for bo in balls.duplicate():
		var b: Ball = bo
		b.prev = b.pos
		b.vel.y += g * sd
		b.pos += b.vel * sd
		b.trail.push_front(b.pos)
		if b.trail.size() > 10:
			b.trail.pop_back()
		# walls and ceiling
		if b.pos.x < BALL_R:
			b.pos.x = BALL_R
			b.vel.x = absf(b.vel.x)
		if b.pos.x > W - BALL_R:
			b.pos.x = W - BALL_R
			b.vel.x = -absf(b.vel.x)
		if b.pos.y < BALL_R:
			b.pos.y = BALL_R
			b.vel.y = absf(b.vel.y)
		# bounce on the box
		if b.vel.y > 0.0 and b.prev.y + BALL_R <= PADDLE_Y + 4.0 and b.pos.y + BALL_R >= PADDLE_Y \
				and absf(b.pos.x - paddle_x) <= paddle_w / 2.0 + BALL_R:
			var off := clampf((b.pos.x - paddle_x) / (paddle_w / 2.0), -1.0, 1.0)
			b.vel.y = -sqrt(2.0 * g * BOUNCE_H)
			b.vel.x = off * hspeed
			if absf(off) < 0.08:
				b.vel.x = randf_range(-80.0, 80.0)
			b.pos.y = PADDLE_Y - BALL_R
			shake = 3.0
			flash = 1.0
			_burst(Vector2(b.pos.x, PADDLE_Y), Color(0.2, 0.95, 1.0), 6)
			_play("bounce", randf_range(0.95, 1.1))
		# safety net power-up
		if net_timer > 0.0 and b.vel.y > 0.0 and b.pos.y + BALL_R >= NET_Y and b.prev.y + BALL_R < NET_Y + 30.0:
			b.vel.y = -sqrt(2.0 * g * BOUNCE_H * 0.75)
			b.pos.y = NET_Y - BALL_R
			_burst(Vector2(b.pos.x, NET_Y), Color(0.3, 1.0, 0.95), 10)
			_play("bounce", 0.7)
		# bots
		var dead := false
		for tgo in targets.duplicate():
			var tg: Target = tgo
			if not targets.has(tg):
				continue
			if b.pos.distance_to(tg.pos) >= r_bot + BALL_R:
				continue
			if tg.kind == "virus":
				_kill_ball(b, tg)
				dead = true
				break
			elif tg.kind == "armor" and tg.hp > 1:
				_hit_armor(tg, b, r_bot)
			else:
				_pop_target(tg, true)
				if state != "play":
					return
		if dead:
			continue
		# fell off the bottom
		if b.pos.y - BALL_R > H:
			_drop_ball(b)
	if state == "play":
		if balls.size() > 1:
			had_multi = true
		if balls.is_empty():
			_game_over()   # you lose only when NO balls are left


func _hit_armor(tg: Target, b: Ball, r_bot: float) -> void:
	tg.hp -= 1
	var n := (b.pos - tg.pos).normalized()
	if b.vel.dot(n) < 0.0:
		b.vel = b.vel.bounce(n)
	b.pos = tg.pos + n * (r_bot + BALL_R + 2.0)
	_burst(tg.pos, Color(1.0, 1.0, 1.0), 10)
	_float_text(tg.pos, "CRACK!", Color(1.0, 1.0, 1.0))
	_play("clink")


func _kill_ball(b: Ball, tg: Target) -> void:
	balls.erase(b)
	targets.erase(tg)
	_burst(tg.pos, Color(0.95, 0.1, 0.2), 30)
	_float_text(tg.pos, "VIRUS ATE YOUR BALL!", Color(0.95, 0.2, 0.3))
	_play("virus")
	shake = 10.0
	_spawn_target("virus")


func _drop_ball(b: Ball) -> void:
	balls.erase(b)
	_burst(Vector2(clampf(b.pos.x, 0.0, W), H - 20.0), Color(1.0, 0.2, 0.4), 16)
	_float_text(Vector2(clampf(b.pos.x, 150.0, W - 150.0), H - 90.0), "BALL LOST!", Color(1.0, 0.3, 0.4))
	_play("drop")
	shake = 8.0


func _add_balls(pos: Vector2, n: int) -> void:
	var added := 0
	for i in n:
		if balls.size() >= MAX_BALLS:
			break
		var nb := Ball.new()
		nb.pos = pos
		nb.prev = pos
		nb.vel = Vector2(randf_range(-340.0, 340.0), -randf_range(200.0, 520.0))
		nb.hue = randf()
		balls.append(nb)
		added += 1
	if added > 0:
		var label := "+%d BALL" % added
		if added > 1:
			label += "S"
		_float_text(pos + Vector2(0.0, -34.0), label + "!", Color(0.4, 1.0, 0.6))
		_play("newball")


func _pop_target(tg: Target, give_ball: bool = true) -> void:
	if not targets.has(tg):
		return
	var col := _kind_color(tg.kind, _lvl_col())
	targets.erase(tg)
	if tg.kind == "virus":
		# only happens when a BOOM bot blows a virus up
		score += 25
		shake = 6.0
		_burst(tg.pos, col, 20)
		_float_text(tg.pos, "VIRUS DELETED!", col)
		_play("pop", 0.7)
		return
	var cfg: Dictionary = levels[level_idx]
	hits += 1
	combo += 1
	combo_timer = 2.5
	var mult := 1.0 + 0.25 * float(mini(combo - 1, 8))
	score += int(10.0 * balls.size() * mult)
	shake = 8.0
	_burst(tg.pos, col, 26)
	_float_text(tg.pos, boom_words.pick_random(), col)
	_play("pop", randf_range(0.9, 1.15))
	var extra := 1
	match tg.kind:
		"multi":
			extra = 3
		"wide":
			wide_timer = 10.0
		"slow":
			slow_timer = 6.0
		"net":
			net_timer = 9.0
	if power_texts.has(tg.kind):
		_float_text(tg.pos + Vector2(0.0, -62.0), power_texts[tg.kind], col)
		if tg.kind != "bomb":
			_play("power")
	if give_ball:
		_add_balls(tg.pos, extra)
	if tg.kind == "bomb":
		_explode(tg.pos)
	if state != "play":
		return
	if hits >= int(cfg["need"]):
		_level_clear()
		return
	_spawn_target()


func _explode(pos: Vector2) -> void:
	shake = 16.0
	_burst(pos, Color(1.0, 0.5, 0.2), 50)
	_play("boom")
	for o in targets.duplicate():
		var other: Target = o
		if state != "play":
			return
		if other.pos.distance_to(pos) < 200.0:
			_pop_target(other, false)


func _level_clear() -> void:
	score += 50 * (level_idx + 1)
	for tgo in targets:
		var tg: Target = tgo
		_burst(tg.pos, _kind_color(tg.kind, _lvl_col()), 14)
	targets.clear()
	for bo in balls:
		var b: Ball = bo
		_burst(b.pos, Color.from_hsv(b.hue, 0.6, 1.0), 10)
	balls.clear()
	if level_idx >= NUM_LEVELS - 1:
		_win()
		return
	state = "clear"
	timer = 2.4
	shake = 10.0
	_play("clear")


func _win() -> void:
	state = "win"
	state_time = t
	best_score = maxi(best_score, score)
	_save_score()
	msg = _pick(win_msgs, "win_msg")
	win_title = _pick(win_titles, "win_title")
	_play("win")
	_play("yay")
	for i in 8:
		_burst(Vector2(randf_range(100.0, W - 100.0), randf_range(100.0, 400.0)), Color.from_hsv(randf(), 0.7, 1.0), 30)


func _game_over() -> void:
	state = "over"
	state_time = t
	best_score = maxi(best_score, score)
	_save_score()
	# a different message, title and tip every time (no repeats until all were shown)
	msg = _pick(game_over_msgs, "over_msg")
	over_title = _pick(over_titles, "over_title")
	over_tip = _pick(over_tips, "over_tip")
	shake = 18.0
	_play("fah")
	music_player.stop()
	current_track = -1
	for n in 4:
		_burst(Vector2(randf_range(100.0, W - 100.0), H - 20.0), Color(1.0, 0.2, 0.4), 20)


func _burst(pos: Vector2, color: Color, n: int) -> void:
	if particles.size() > 500:
		return
	for i in n:
		var p := Particle.new()
		p.pos = pos
		var a := randf() * TAU
		p.vel = Vector2(cos(a), sin(a)) * randf_range(80.0, 420.0)
		p.max_life = randf_range(0.4, 0.9)
		p.life = p.max_life
		p.color = color
		p.size = randf_range(2.0, 5.0)
		particles.append(p)


func _float_text(pos: Vector2, txt: String, col: Color) -> void:
	var f := FloatText.new()
	f.pos = pos
	f.text = txt
	f.color = col
	f.life = 1.0
	texts.append(f)


func _update_fx(delta: float) -> void:
	var th := _theme_idx()
	var d: Dictionary = themes[th]
	var kind: String = d["precip"]
	if kind != "none":
		var pv: Vector2 = d["pv"]
		for i in rain.size():
			var r: Vector2 = rain[i]
			r += pv * delta
			if kind == "fireflies":
				if r.x > W + 10.0:
					r.x = -10.0
			else:
				if r.y > H:
					r = Vector2(randf() * (W + 200.0), -10.0)
				elif r.x < -20.0:
					r.x += W + 40.0
			rain[i] = r
	# storm lightning
	bolt = maxf(0.0, bolt - delta)
	if th == 9:
		bolt_timer -= delta
		if bolt_timer <= 0.0:
			_spawn_bolt()
			bolt_timer = randf_range(2.5, 6.0)
	for i in range(particles.size() - 1, -1, -1):
		var p: Particle = particles[i]
		p.life -= delta
		if p.life <= 0.0:
			particles.remove_at(i)
			continue
		p.vel.y += 700.0 * delta
		p.pos += p.vel * delta
	for i in range(texts.size() - 1, -1, -1):
		var f: FloatText = texts[i]
		f.life -= delta
		if f.life <= 0.0:
			texts.remove_at(i)
			continue
		f.pos.y -= 60.0 * delta


func _spawn_bolt() -> void:
	bolt = 0.35
	bolt_pts = PackedVector2Array()
	var p := Vector2(randf_range(150.0, W - 150.0), 140.0)
	bolt_pts.append(p)
	while p.y < 480.0:
		p += Vector2(randf_range(-40.0, 40.0), randf_range(30.0, 60.0))
		bolt_pts.append(p)


# ---------------------------------------------------------------- BACKGROUND THEMES
# One scene per level: 0 city night, 1 green hills, 2 snowy mountains, 3 desert,
# 4 tropical beach, 5 pine forest, 6 arctic aurora, 7 cherry garden + Fuji,
# 8 carnival city, 9 storm. Menu pages slowly cycle through all of them.
func _th(top: Color, bot: Color, precip: String, pv: Vector2, stars_on: bool, city: bool, cloud: Color, cs: float) -> Dictionary:
	return {"top": top, "bot": bot, "precip": precip, "pv": pv, "stars": stars_on, "city": city, "cloud": cloud, "cs": cs}


func _build_themes() -> void:
	var none := Color(0.0, 0.0, 0.0, 0.0)
	themes = [
		_th(Color(0.05, 0.02, 0.16), Color(0.34, 0.04, 0.40), "rain", Vector2(-120.0, 650.0), false, true, none, 1.0),
		_th(Color(0.10, 0.18, 0.45), Color(0.98, 0.55, 0.40), "none", Vector2.ZERO, false, false, Color(1.0, 0.75, 0.7, 0.35), 1.0),
		_th(Color(0.02, 0.03, 0.14), Color(0.28, 0.14, 0.45), "none", Vector2.ZERO, true, false, Color(0.6, 0.5, 0.9, 0.12), 1.0),
		_th(Color(0.22, 0.04, 0.34), Color(1.0, 0.52, 0.22), "none", Vector2.ZERO, false, false, Color(1.0, 0.7, 0.5, 0.22), 1.0),
		_th(Color(0.04, 0.08, 0.30), Color(1.0, 0.45, 0.50), "none", Vector2.ZERO, true, false, Color(1.0, 0.6, 0.6, 0.30), 1.0),
		_th(Color(0.03, 0.10, 0.20), Color(0.35, 0.70, 0.55), "fireflies", Vector2(18.0, 0.0), true, false, none, 1.0),
		_th(Color(0.0, 0.02, 0.12), Color(0.06, 0.25, 0.35), "snow", Vector2(-25.0, 70.0), true, false, none, 1.0),
		_th(Color(0.25, 0.12, 0.42), Color(1.0, 0.68, 0.75), "petals", Vector2(-70.0, 80.0), false, false, Color(1.0, 0.85, 0.9, 0.30), 1.0),
		_th(Color(0.10, 0.0, 0.30), Color(0.80, 0.10, 0.55), "none", Vector2.ZERO, true, true, none, 1.0),
		_th(Color(0.03, 0.03, 0.07), Color(0.28, 0.22, 0.34), "rain", Vector2(-220.0, 950.0), false, false, Color(0.10, 0.10, 0.16, 0.9), 1.8),
	]


func _theme_idx() -> int:
	if _is_ui():
		return int(t / 8.0) % NUM_LEVELS
	return level_idx


func _build_scenes() -> void:
	scenes.clear()
	for i in NUM_LEVELS:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7000 + i * 31
		var items: Array = []
		match i:
			0, 8:
				_scene_city(items, i)
			1:
				_scene_meadow(items, rng)
			2:
				_scene_mountains(items, rng)
			3:
				_scene_desert(items, rng)
			4:
				_scene_beach(items, rng)
			5:
				_scene_forest(items, rng)
			6:
				_scene_arctic(items, rng)
			7:
				_scene_cherry(items, rng)
			9:
				_scene_storm(items, rng)
		scenes.append(items)


# --- scene item helpers (everything is pre-built once, then just drawn)
func _i_poly(items: Array, pts: PackedVector2Array, col: Color) -> void:
	items.append({"t": "poly", "p": pts, "c": col})


func _i_circ(items: Array, pos: Vector2, r: float, col: Color) -> void:
	items.append({"t": "circ", "a": pos, "r": r, "c": col})


func _i_line(items: Array, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	items.append({"t": "line", "a": a, "b": b, "c": col, "w": w})


func _i_rect(items: Array, r: Rect2, col: Color) -> void:
	items.append({"t": "rect", "r": r, "c": col})


# rolling hill silhouette; returns its shape so things can stand on it
func _hill(items: Array, rng: RandomNumberGenerator, base_y: float, amp: float, col: Color) -> Dictionary:
	var h := {
		"b": base_y, "a": amp,
		"p1": rng.randf() * TAU, "p2": rng.randf() * TAU,
		"f1": rng.randf_range(0.004, 0.008), "f2": rng.randf_range(0.011, 0.02),
	}
	var pts := PackedVector2Array()
	pts.append(Vector2(-20.0, H + 20.0))
	var x := -20.0
	while x <= W + 20.0:
		pts.append(Vector2(x, _hy(h, x)))
		x += 24.0
	pts.append(Vector2(W + 20.0, H + 20.0))
	_i_poly(items, pts, col)
	return h


func _hy(h: Dictionary, x: float) -> float:
	return float(h["b"]) - float(h["a"]) * (0.6 * sin(x * float(h["f1"]) + float(h["p1"])) + 0.4 * sin(x * float(h["f2"]) + float(h["p2"])))


func _mountain(items: Array, x: float, base_y: float, w: float, h: float, col: Color, snow: Color = Color(0.0, 0.0, 0.0, 0.0)) -> void:
	_i_poly(items, PackedVector2Array([Vector2(x - w, base_y), Vector2(x, base_y - h), Vector2(x + w, base_y)]), col)
	if snow.a > 0.0:
		var top := base_y - h
		var sh := h * 0.3
		var sw := w * 0.3
		_i_poly(items, PackedVector2Array([
			Vector2(x, top), Vector2(x + sw, top + sh), Vector2(x + sw * 0.45, top + sh * 0.72),
			Vector2(x, top + sh), Vector2(x - sw * 0.4, top + sh * 0.72), Vector2(x - sw, top + sh),
		]), snow)


func _pine(items: Array, x: float, base_y: float, h: float, col: Color) -> void:
	_i_rect(items, Rect2(x - h * 0.04, base_y - h * 0.15, h * 0.08, h * 0.15), col.darkened(0.4))
	for k in 3:
		var yb := base_y - h * 0.12 - k * h * 0.26
		var wd := h * (0.30 - 0.07 * k)
		_i_poly(items, PackedVector2Array([Vector2(x - wd, yb), Vector2(x, yb - h * 0.38), Vector2(x + wd, yb)]), col)


func _round_tree(items: Array, x: float, base_y: float, h: float, leaf: Color) -> void:
	_i_rect(items, Rect2(x - h * 0.05, base_y - h * 0.45, h * 0.1, h * 0.45), leaf.darkened(0.5))
	_i_circ(items, Vector2(x, base_y - h * 0.65), h * 0.36, leaf)
	_i_circ(items, Vector2(x - h * 0.22, base_y - h * 0.52), h * 0.26, leaf)
	_i_circ(items, Vector2(x + h * 0.22, base_y - h * 0.52), h * 0.26, leaf)


func _cherry(items: Array, rng: RandomNumberGenerator, x: float, base_y: float, h: float) -> void:
	_i_rect(items, Rect2(x - 7.0, base_y - h * 0.6, 14.0, h * 0.6), Color(0.15, 0.08, 0.12))
	var pinks := [Color(1.0, 0.6, 0.75, 0.92), Color(1.0, 0.72, 0.82, 0.88), Color(0.95, 0.5, 0.7, 0.92)]
	for k in 8:
		var a := rng.randf() * TAU
		var d := rng.randf() * h * 0.35
		var c := Vector2(x + cos(a) * d * 1.3, base_y - h * 0.72 + sin(a) * d * 0.8)
		_i_circ(items, c, h * rng.randf_range(0.16, 0.26), pinks[k % 3])


func _palm(items: Array, x: float, base_y: float, h: float, lean: float) -> void:
	var trunk := Color(0.06, 0.07, 0.08)
	var leaf := Color(0.04, 0.22, 0.15)
	var top := Vector2(x + lean, base_y - h)
	var mid := Vector2(x + lean * 0.25, base_y - h * 0.5)
	_i_line(items, Vector2(x, base_y), mid, trunk, 7.0)
	_i_line(items, mid, top, trunk, 5.0)
	for k in 7:
		var a := -PI / 2.0 + (k - 3.0) * 0.55
		var ctrl := top + Vector2(cos(a) * h * 0.22, sin(a) * h * 0.22)
		var tip := top + Vector2(cos(a) * h * 0.42, sin(a) * h * 0.18 + h * 0.2)
		_i_line(items, top, ctrl, leaf, 5.0)
		_i_line(items, ctrl, tip, leaf, 4.0)


func _cactus(items: Array, x: float, base_y: float, h: float, col: Color) -> void:
	_i_rect(items, Rect2(x - 7.0, base_y - h, 14.0, h), col)
	_i_circ(items, Vector2(x, base_y - h), 7.0, col)
	_i_rect(items, Rect2(x - 26.0, base_y - h * 0.55, 20.0, 8.0), col)
	_i_rect(items, Rect2(x - 26.0, base_y - h * 0.55 - 22.0, 8.0, 30.0), col)
	_i_circ(items, Vector2(x - 22.0, base_y - h * 0.55 - 22.0), 4.0, col)
	_i_rect(items, Rect2(x + 6.0, base_y - h * 0.4, 20.0, 8.0), col)
	_i_rect(items, Rect2(x + 18.0, base_y - h * 0.4 - 18.0, 8.0, 26.0), col)
	_i_circ(items, Vector2(x + 22.0, base_y - h * 0.4 - 18.0), 4.0, col)


func _torii(items: Array, x: float, base_y: float) -> void:
	var red := Color(0.85, 0.12, 0.15)
	_i_rect(items, Rect2(x - 62.0, base_y - 130.0, 12.0, 130.0), red)
	_i_rect(items, Rect2(x + 50.0, base_y - 130.0, 12.0, 130.0), red)
	_i_rect(items, Rect2(x - 82.0, base_y - 144.0, 164.0, 14.0), red.darkened(0.15))
	_i_rect(items, Rect2(x - 66.0, base_y - 108.0, 132.0, 9.0), red)


func _island(items: Array, cx: float, base_y: float, w: float, h: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 24
	for i in range(steps + 1):
		var dx := -w + 2.0 * w * i / steps
		pts.append(Vector2(cx + dx, base_y - h * cos(dx / w * PI * 0.5)))
	_i_poly(items, pts, col)


# --- the ten scenes
func _scene_city(items: Array, th: int) -> void:
	if th == 0:
		_i_circ(items, Vector2(W * 0.5, 360.0), 190.0, Color(1.0, 0.25, 0.6, 0.12))
		_i_circ(items, Vector2(W * 0.5, 360.0), 130.0, Color(1.0, 0.5, 0.3, 0.18))
	else:
		_i_circ(items, Vector2(W * 0.22, 150.0), 90.0, Color(1.0, 0.8, 1.0, 0.10))
		_i_circ(items, Vector2(W * 0.22, 150.0), 62.0, Color(1.0, 0.9, 1.0, 0.25))
		_i_circ(items, Vector2(W * 0.22, 150.0), 40.0, Color(1.0, 0.95, 1.0, 0.8))


func _scene_meadow(items: Array, rng: RandomNumberGenerator) -> void:
	var sc := Vector2(W * 0.72, 400.0)
	_i_circ(items, sc, 150.0, Color(1.0, 0.6, 0.3, 0.12))
	_i_circ(items, sc, 100.0, Color(1.0, 0.7, 0.35, 0.20))
	_i_circ(items, sc, 56.0, Color(1.0, 0.85, 0.5, 0.95))
	var far := _hill(items, rng, 470.0, 50.0, Color(0.20, 0.28, 0.48))
	for k in 6:
		var x := rng.randf_range(20.0, W - 20.0)
		_round_tree(items, x, _hy(far, x) + 4.0, rng.randf_range(30.0, 45.0), Color(0.14, 0.24, 0.42))
	var mid := _hill(items, rng, 530.0, 45.0, Color(0.10, 0.34, 0.24))
	for k in 8:
		var x2 := rng.randf_range(20.0, W - 20.0)
		_round_tree(items, x2, _hy(mid, x2) + 4.0, rng.randf_range(55.0, 85.0), Color(0.06, 0.26, 0.18))
	var near := _hill(items, rng, 595.0, 30.0, Color(0.05, 0.24, 0.14))
	var fcols := [Color(1.0, 0.5, 0.8, 0.9), Color(1.0, 0.9, 0.3, 0.9), Color(1.0, 1.0, 1.0, 0.85)]
	for k in 80:
		var fx := rng.randf_range(0.0, W)
		var fy := rng.randf_range(_hy(near, fx) + 8.0, H - 8.0)
		_i_circ(items, Vector2(fx, fy), rng.randf_range(1.8, 3.2), fcols[k % 3])


func _scene_mountains(items: Array, rng: RandomNumberGenerator) -> void:
	var mc := Vector2(W * 0.22, 170.0)
	_i_circ(items, mc, 110.0, Color(0.7, 0.7, 1.0, 0.08))
	_i_circ(items, mc, 78.0, Color(0.8, 0.8, 1.0, 0.12))
	_i_circ(items, mc, 52.0, Color(0.95, 0.95, 1.0, 0.95))
	_i_circ(items, mc + Vector2(-14.0, -8.0), 9.0, Color(0.8, 0.8, 0.92, 0.9))
	_i_circ(items, mc + Vector2(16.0, 12.0), 12.0, Color(0.8, 0.8, 0.92, 0.9))
	_i_circ(items, mc + Vector2(8.0, -24.0), 6.0, Color(0.8, 0.8, 0.92, 0.9))
	for k in 7:
		_mountain(items, k * 190.0 - 40.0 + rng.randf_range(-30.0, 30.0), 480.0, rng.randf_range(130.0, 200.0), rng.randf_range(160.0, 260.0), Color(0.20, 0.16, 0.40), Color(0.85, 0.85, 1.0, 0.9))
	_i_rect(items, Rect2(-20.0, 480.0, W + 40.0, H - 460.0), Color(0.20, 0.16, 0.40))
	for k in 6:
		_mountain(items, k * 215.0 + rng.randf_range(-30.0, 30.0), 530.0, rng.randf_range(110.0, 170.0), rng.randf_range(110.0, 200.0), Color(0.12, 0.09, 0.28), Color(0.6, 0.6, 0.9, 0.85))
	_i_rect(items, Rect2(-20.0, 530.0, W + 40.0, H - 510.0), Color(0.12, 0.09, 0.28))
	var near := _hill(items, rng, 595.0, 28.0, Color(0.04, 0.04, 0.12))
	for k in 14:
		var x := rng.randf_range(0.0, W)
		_pine(items, x, _hy(near, x) + 8.0, rng.randf_range(90.0, 150.0), Color(0.03, 0.05, 0.12))


func _scene_desert(items: Array, rng: RandomNumberGenerator) -> void:
	var sc := Vector2(W * 0.5, 360.0)
	_i_circ(items, sc, 190.0, Color(1.0, 0.5, 0.2, 0.12))
	_i_circ(items, sc, 140.0, Color(1.0, 0.6, 0.2, 0.20))
	_i_circ(items, sc, 95.0, Color(1.0, 0.85, 0.4, 0.95))
	_mountain(items, W * 0.20, 505.0, 110.0, 130.0, Color(0.55, 0.25, 0.20))
	_mountain(items, W * 0.30, 505.0, 70.0, 85.0, Color(0.50, 0.22, 0.20))
	_mountain(items, W * 0.82, 510.0, 95.0, 110.0, Color(0.52, 0.24, 0.20))
	_i_rect(items, Rect2(-20.0, 505.0, W + 40.0, 160.0), Color(0.60, 0.28, 0.18))
	_hill(items, rng, 505.0, 25.0, Color(0.60, 0.28, 0.18))
	_hill(items, rng, 555.0, 35.0, Color(0.45, 0.20, 0.14))
	var d3 := _hill(items, rng, 605.0, 28.0, Color(0.30, 0.12, 0.10))
	for k in 6:
		var x := rng.randf_range(40.0, W - 40.0)
		_cactus(items, x, _hy(d3, x) + 8.0, rng.randf_range(60.0, 100.0), Color(0.07, 0.15, 0.09))


func _scene_beach(items: Array, rng: RandomNumberGenerator) -> void:
	var sc := Vector2(W * 0.5, 440.0)
	_i_circ(items, sc, 170.0, Color(1.0, 0.5, 0.4, 0.12))
	_i_circ(items, sc, 120.0, Color(1.0, 0.6, 0.35, 0.20))
	_i_circ(items, sc, 80.0, Color(1.0, 0.85, 0.5, 0.95))
	for k in 8:
		_i_rect(items, Rect2(-20.0, 440.0 + k * 26.0, W + 40.0, 27.0), Color(0.55, 0.20, 0.40).lerp(Color(0.03, 0.06, 0.22), k / 7.0))
	_island(items, 700.0, 446.0, 70.0, 14.0, Color(0.15, 0.10, 0.25))
	_island(items, 130.0, 520.0, 190.0, 90.0, Color(0.05, 0.12, 0.12))
	_island(items, 1030.0, 515.0, 210.0, 100.0, Color(0.05, 0.12, 0.12))
	for dx in [-60.0, 10.0, 70.0]:
		_palm(items, 130.0 + dx, 520.0 - 90.0 * cos(dx / 190.0 * PI * 0.5) + 6.0, rng.randf_range(120.0, 150.0), rng.randf_range(-30.0, 30.0))
	for dx in [-70.0, 0.0, 80.0]:
		_palm(items, 1030.0 + dx, 515.0 - 100.0 * cos(dx / 210.0 * PI * 0.5) + 6.0, rng.randf_range(120.0, 160.0), rng.randf_range(-30.0, 30.0))


func _scene_forest(items: Array, rng: RandomNumberGenerator) -> void:
	var mc := Vector2(W * 0.78, 130.0)
	_i_circ(items, mc, 60.0, Color(0.9, 1.0, 0.9, 0.08))
	_i_circ(items, mc, 40.0, Color(0.95, 1.0, 0.9, 0.9))
	var cols := [Color(0.08, 0.22, 0.28), Color(0.05, 0.17, 0.20), Color(0.03, 0.11, 0.13)]
	for l in 3:
		var base := 400.0 + l * 70.0
		var h := _hill(items, rng, base + 30.0, 12.0, cols[l])
		var count := 14 + l * 3
		for k in count:
			var x := (k + rng.randf()) * W / count
			_pine(items, x, _hy(h, x) + 6.0, rng.randf_range(110.0, 150.0) + l * 30.0, cols[l])
		_i_rect(items, Rect2(-20.0, base - 10.0, W + 40.0, 60.0), Color(0.7, 0.95, 0.85, 0.06))
	_pine(items, 50.0, 650.0, 300.0, Color(0.02, 0.07, 0.09))
	_pine(items, 1100.0, 650.0, 320.0, Color(0.02, 0.07, 0.09))
	_pine(items, 170.0, 655.0, 230.0, Color(0.02, 0.07, 0.09))
	_pine(items, 985.0, 655.0, 240.0, Color(0.02, 0.07, 0.09))


func _scene_arctic(items: Array, rng: RandomNumberGenerator) -> void:
	var mc := Vector2(W * 0.82, 150.0)
	_i_circ(items, mc, 70.0, Color(0.8, 0.9, 1.0, 0.10))
	_i_circ(items, mc, 45.0, Color(0.92, 0.97, 1.0, 0.92))
	for k in 6:
		_mountain(items, k * 210.0 - 30.0 + rng.randf_range(-30.0, 30.0), 480.0, rng.randf_range(130.0, 190.0), rng.randf_range(160.0, 260.0), Color(0.18, 0.30, 0.45), Color(0.92, 0.97, 1.0, 0.95))
	_i_rect(items, Rect2(-20.0, 480.0, W + 40.0, H - 460.0), Color(0.18, 0.30, 0.45))
	for k in 5:
		_mountain(items, k * 260.0 + rng.randf_range(-30.0, 30.0), 545.0, rng.randf_range(110.0, 160.0), rng.randf_range(110.0, 190.0), Color(0.12, 0.22, 0.36), Color(1.0, 1.0, 1.0, 0.95))
	_i_rect(items, Rect2(-20.0, 545.0, W + 40.0, H - 525.0), Color(0.12, 0.22, 0.36))
	var ice := _hill(items, rng, 600.0, 14.0, Color(0.30, 0.52, 0.66))
	for k in 8:
		var x := rng.randf_range(0.0, W)
		_pine(items, x, _hy(ice, x) + 6.0, rng.randf_range(70.0, 110.0), Color(0.08, 0.20, 0.28))


func _scene_cherry(items: Array, rng: RandomNumberGenerator) -> void:
	var sc := Vector2(W * 0.30, 250.0)
	_i_circ(items, sc, 140.0, Color(1.0, 0.6, 0.7, 0.15))
	_i_circ(items, sc, 90.0, Color(1.0, 0.75, 0.75, 0.30))
	_i_circ(items, sc, 55.0, Color(1.0, 0.95, 0.85, 0.95))
	_mountain(items, W * 0.66, 520.0, 380.0, 300.0, Color(0.36, 0.26, 0.52), Color(1.0, 0.95, 1.0, 0.95))
	_i_rect(items, Rect2(-20.0, 520.0, W + 40.0, 140.0), Color(0.30, 0.20, 0.45))
	_hill(items, rng, 525.0, 28.0, Color(0.30, 0.20, 0.45))
	var mid := _hill(items, rng, 570.0, 24.0, Color(0.16, 0.12, 0.30))
	_torii(items, 250.0, _hy(mid, 250.0) + 6.0)
	var near := _hill(items, rng, 612.0, 16.0, Color(0.08, 0.05, 0.16))
	for x in [70.0, 420.0, 880.0, 1070.0]:
		_cherry(items, rng, x, _hy(near, x) + 6.0, rng.randf_range(130.0, 170.0))


func _scene_storm(items: Array, rng: RandomNumberGenerator) -> void:
	for k in 6:
		_mountain(items, k * 210.0 - 20.0 + rng.randf_range(-30.0, 30.0), 500.0, rng.randf_range(120.0, 190.0), rng.randf_range(140.0, 230.0), Color(0.10, 0.10, 0.18))
	_i_rect(items, Rect2(-20.0, 500.0, W + 40.0, H - 480.0), Color(0.10, 0.10, 0.18))
	for k in 5:
		_mountain(items, k * 270.0 + rng.randf_range(-30.0, 30.0), 548.0, rng.randf_range(110.0, 170.0), rng.randf_range(90.0, 150.0), Color(0.06, 0.06, 0.12))
	_i_rect(items, Rect2(-20.0, 548.0, W + 40.0, H - 528.0), Color(0.06, 0.06, 0.12))
	var near := _hill(items, rng, 598.0, 22.0, Color(0.03, 0.03, 0.07))
	for k in 9:
		var x := rng.randf_range(0.0, W)
		_pine(items, x, _hy(near, x) + 6.0, rng.randf_range(80.0, 130.0), Color(0.02, 0.03, 0.05))


# ---------------------------------------------------------------- DRAW
func _draw() -> void:
	var off := Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	draw_set_transform(off, 0.0, Vector2.ONE)
	_draw_background()
	match state:
		"title":
			_draw_title_page()
			return
		"menu":
			_draw_main_menu()
			return
		"instructions":
			_draw_instructions()
			return
		"options":
			_draw_options()
			return
		"leaderboard":
			_draw_leaderboard()
			return
		"name":
			_draw_name_page()
			return
	_draw_targets()
	_draw_paddle()
	_draw_net()
	_draw_balls()
	_draw_fx()
	_draw_hud()
	_draw_overlays()


func _draw_background() -> void:
	var th := _theme_idx()
	var d: Dictionary = themes[th]
	# sky gradient
	var top: Color = d["top"]
	var bot: Color = d["bot"]
	var stripes := 32
	for i in stripes:
		var c := top.lerp(bot, float(i) / stripes)
		var y := -20.0 + i * (H + 40.0) / stripes
		draw_rect(Rect2(-20.0, y, W + 40.0, (H + 40.0) / stripes + 1.0), c)
	if bool(d["stars"]):
		_draw_stars()
	if th == 6:
		_draw_aurora()
	var cc: Color = d["cloud"]
	if cc.a > 0.0:
		_draw_clouds(cc, float(d["cs"]))
	_draw_items(scenes[th])
	if th == 8:
		_draw_ferris()
	if bool(d["city"]):
		_draw_city(th)
	if th == 4:
		_draw_shimmer()
	if th == 9:
		_draw_angry_cloud()
		_draw_lightning()
	_draw_precip(th, d)
	# danger strip (the floor you do NOT want to touch)
	draw_rect(Rect2(-20.0, H - 6.0, W + 40.0, 26.0), Color(1.0, 0.1, 0.3, 0.35 + 0.25 * sin(t * 5.0)))


func _draw_items(items: Array) -> void:
	for io in items:
		var it: Dictionary = io
		match it["t"]:
			"poly":
				draw_colored_polygon(it["p"], it["c"])
			"circ":
				draw_circle(it["a"], it["r"], it["c"])
			"line":
				draw_line(it["a"], it["b"], it["c"], it["w"])
			"rect":
				draw_rect(it["r"], it["c"])


func _draw_stars() -> void:
	for so in stars:
		var s: Array = so
		var p: Vector2 = s[0]
		var a := 0.35 + 0.35 * sin(t * 2.0 + float(s[1]))
		draw_circle(p, 1.4, Color(1.0, 1.0, 1.0, a))


func _draw_clouds(col: Color, cs: float) -> void:
	for co in clouds:
		var c: Array = co
		var s: float = float(c[2]) * cs
		var x := fmod(float(c[0]) + t * float(c[3]), W + 400.0) - 200.0
		var y: float = float(c[1])
		draw_circle(Vector2(x, y), 36.0 * s, col)
		draw_circle(Vector2(x - 42.0 * s, y + 10.0 * s), 28.0 * s, col)
		draw_circle(Vector2(x + 44.0 * s, y + 12.0 * s), 30.0 * s, col)
		draw_circle(Vector2(x + 8.0 * s, y - 20.0 * s), 30.0 * s, col)
		draw_circle(Vector2(x - 15.0 * s, y + 18.0 * s), 26.0 * s, col)
		draw_circle(Vector2(x + 25.0 * s, y + 20.0 * s), 24.0 * s, col)


func _draw_aurora() -> void:
	var aur := [Color(0.3, 1.0, 0.6), Color(0.3, 0.8, 1.0), Color(0.8, 0.4, 1.0)]
	for k in 3:
		var pts := PackedVector2Array()
		var x := -20.0
		while x <= W + 20.0:
			pts.append(Vector2(x, 130.0 + k * 45.0 + sin(x * 0.008 + t * 0.6 + k * 1.7) * 38.0 + sin(x * 0.02 - t * 0.9) * 10.0))
			x += 24.0
		var c: Color = aur[k]
		draw_polyline(pts, Color(c, 0.08), 46.0)
		draw_polyline(pts, Color(c, 0.16), 22.0)
		draw_polyline(pts, Color(c, 0.35), 6.0)


func _draw_city(th: int) -> void:
	var edge := Color(1.0, 0.2, 0.8, 0.55)
	if th == 8:
		edge = Color(0.3, 0.95, 1.0, 0.6)
	if not _is_ui():
		# flickering neon sign
		var sign_a := 0.16
		if sin(t * 31.0) < -0.93:
			sign_a = 0.04
		draw_string(font, Vector2(0.0, 120.0), "BOOM BOOM", HORIZONTAL_ALIGNMENT_CENTER, W, 70, Color(1.0, 0.3, 0.9, sign_a))
	for bo in buildings:
		var r: Rect2 = bo
		draw_rect(r, Color(0.03, 0.02, 0.09, 0.93))
		draw_line(r.position, Vector2(r.end.x, r.position.y), edge, 2.0)
	for w in windows:
		var wc: Color = w[2]
		var a := 0.22 + 0.2 * sin(t * 0.8 + float(w[1]))
		var wp: Vector2 = w[0]
		draw_rect(Rect2(wp, Vector2(8.0, 10.0)), Color(wc, maxf(a, 0.05)))
	if th == 8:
		# party lights across the top
		var x := 0.0
		while x <= W:
			var y := 10.0 + 6.0 * sin(x * 0.03)
			var bc: Color = neon[int(x / 40.0) % 5]
			draw_circle(Vector2(x, y), 4.0, Color(bc, 0.5 + 0.5 * sin(t * 3.0 + x * 0.1)))
			x += 40.0


func _draw_ferris() -> void:
	var c := Vector2(W * 0.78, 345.0)
	var r := 125.0
	var col := Color(1.0, 0.3, 0.8)
	draw_line(c, c + Vector2(-70.0, 230.0), Color(col, 0.5), 4.0)
	draw_line(c, c + Vector2(70.0, 230.0), Color(col, 0.5), 4.0)
	draw_arc(c, r, 0.0, TAU, 48, Color(col, 0.8), 3.0)
	draw_arc(c, r * 0.55, 0.0, TAU, 32, Color(col, 0.4), 2.0)
	var rot := t * 0.25
	for k in 10:
		var a := rot + k * TAU / 10.0
		var p := c + Vector2(cos(a), sin(a)) * r
		draw_line(c, p, Color(col, 0.5), 2.0)
		var gc: Color = neon[k % 5]
		draw_rect(Rect2(p.x - 9.0, p.y, 18.0, 14.0), Color(gc, 0.9))
		draw_circle(p, 3.0, Color(1.0, 1.0, 0.8, 0.9))
	draw_circle(c, 9.0, col)


func _draw_shimmer() -> void:
	for k in 18:
		var y := 448.0 + k * 10.5
		var x := W * 0.5 + sin(t * 1.5 + k) * 14.0
		var wd := 26.0 + k * 7.0
		draw_line(Vector2(x - wd, y), Vector2(x + wd, y), Color(1.0, 0.75, 0.45, maxf(0.0, 0.32 - k * 0.016)), 2.0)
	for k in 14:
		var wy := 460.0 + k * 13.0
		var wx := fmod(k * 173.0 + t * (10.0 + k), W + 120.0) - 60.0
		draw_line(Vector2(wx, wy), Vector2(wx + 40.0, wy), Color(1.0, 0.8, 0.9, 0.12), 2.0)


func _draw_angry_cloud() -> void:
	var c := Vector2(W * 0.5, 150.0 + sin(t * 0.8) * 8.0)
	var col := Color(0.16, 0.14, 0.24, 0.95)
	var dark := Color(0.05, 0.0, 0.1)
	draw_circle(c, 70.0, col)
	draw_circle(c + Vector2(-90.0, 20.0), 55.0, col)
	draw_circle(c + Vector2(90.0, 20.0), 55.0, col)
	draw_circle(c + Vector2(-45.0, -35.0), 50.0, col)
	draw_circle(c + Vector2(50.0, -30.0), 52.0, col)
	draw_rect(Rect2(c.x - 140.0, c.y + 20.0, 280.0, 45.0), col)
	for sx in [-1.0, 1.0]:
		var ep := c + Vector2(sx * 42.0, 8.0)
		draw_circle(ep, 20.0, Color(1.0, 0.95, 0.85))
		var ld := _eye_dir(ep)
		draw_circle(ep + ld * 7.0, 9.0, Color(0.9, 0.1, 0.15))
		draw_circle(ep + ld * 7.0, 4.0, dark)
	draw_line(c + Vector2(-72.0, -22.0), c + Vector2(-20.0, -4.0), dark, 6.0)
	draw_line(c + Vector2(72.0, -22.0), c + Vector2(20.0, -4.0), dark, 6.0)
	draw_arc(c + Vector2(0.0, 62.0), 30.0, PI + 0.4, TAU - 0.4, 14, dark, 5.0)


func _draw_lightning() -> void:
	if bolt <= 0.0:
		return
	var a := bolt / 0.35
	draw_rect(Rect2(-20.0, -20.0, W + 40.0, H + 40.0), Color(0.8, 0.85, 1.0, 0.22 * a))
	if bolt_pts.size() > 1:
		draw_polyline(bolt_pts, Color(0.7, 0.8, 1.0, 0.5 * a), 12.0)
		draw_polyline(bolt_pts, Color(1.0, 1.0, 1.0, a), 3.0)


func _draw_precip(th: int, d: Dictionary) -> void:
	var kind: String = d["precip"]
	if kind == "none":
		return
	var pv: Vector2 = d["pv"]
	for ro in rain:
		var rp: Vector2 = ro
		match kind:
			"rain":
				var rc := Color(0.65, 0.35, 1.0, 0.30)
				if th == 9:
					rc = Color(0.65, 0.75, 1.0, 0.38)
				draw_line(rp, rp + pv * 0.022, rc, 1.5)
			"snow":
				draw_circle(rp + Vector2(sin(t * 1.5 + rp.y * 0.03) * 6.0, 0.0), 2.2, Color(1.0, 1.0, 1.0, 0.8))
			"petals":
				draw_circle(rp + Vector2(sin(t * 2.0 + rp.y * 0.05) * 10.0, 0.0), 3.0, Color(1.0, 0.7, 0.8, 0.8))
			"fireflies":
				var fy := 250.0 + rp.y / H * 330.0 + sin(t * 1.3 + rp.x * 0.05) * 10.0
				var a := 0.4 + 0.5 * sin(t * 3.0 + rp.x)
				draw_circle(Vector2(rp.x, fy), 5.0, Color(1.0, 0.95, 0.4, a * 0.25))
				draw_circle(Vector2(rp.x, fy), 2.0, Color(1.0, 0.95, 0.5, clampf(a, 0.1, 1.0)))


# ---------------------------------------------------------------- GAME DRAWING
func _hex(c: Vector2, r: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 7:
		var a := rot + i * TAU / 6.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


func _eye_dir(from: Vector2) -> Vector2:
	var best := Vector2.DOWN
	var bd := 1e9
	for bo in balls:
		var b: Ball = bo
		var d := from.distance_to(b.pos)
		if d < bd and d > 0.1:
			bd = d
			best = (b.pos - from).normalized()
	return best


func _draw_targets() -> void:
	var base_r := _bot_r()
	var lvl_col := _lvl_col()
	for tgo in targets:
		var tg: Target = tgo
		var col := _kind_color(tg.kind, lvl_col)
		var r := base_r * (1.0 + 0.06 * sin(t * 6.0 + tg.phase))
		draw_circle(tg.pos, r * 1.7, Color(col, 0.10))
		draw_circle(tg.pos, r * 1.3, Color(col, 0.16))
		draw_circle(tg.pos, r * 0.95, Color(0.06, 0.03, 0.14))
		var line_w := 3.0
		if tg.kind == "armor":
			line_w = 6.0 if tg.hp > 1 else 2.0
		draw_polyline(_hex(tg.pos, r, t * 0.8 + tg.phase), col, line_w, true)
		if tg.kind == "armor" and tg.hp > 1:
			draw_polyline(_hex(tg.pos, r * 0.78, -t * 0.8 + tg.phase), col, 2.0, true)
		# a big nosy eye that follows the nearest ball
		var look := _eye_dir(tg.pos)
		var eye_col := Color(0.95, 0.95, 1.0)
		if tg.kind == "virus":
			eye_col = Color(1.0, 0.75, 0.75)
		draw_circle(tg.pos, r * 0.55, eye_col)
		draw_circle(tg.pos + look * r * 0.2, r * 0.26, Color(0.05, 0.0, 0.1))
		draw_circle(tg.pos + look * r * 0.2 + Vector2(-r * 0.07, -r * 0.08), r * 0.08, Color.WHITE)
		if tg.kind == "virus":
			# angry eyebrow
			draw_line(tg.pos + Vector2(-r * 0.6, -r * 0.62), tg.pos + Vector2(r * 0.55, -r * 0.3), col, 3.0)
		if kind_labels.has(tg.kind):
			draw_string(font, tg.pos + Vector2(-50.0, -r * 1.15), kind_labels[tg.kind], HORIZONTAL_ALIGNMENT_CENTER, 100.0, 15, col)


func _draw_paddle() -> void:
	var pr := Rect2(paddle_x - paddle_w / 2.0, PADDLE_Y, paddle_w, PADDLE_H)
	var pc := Color(0.2, 0.95, 1.0).lerp(Color.WHITE, flash)
	if wide_timer > 0.0:
		pc = Color(0.35, 0.65, 1.0).lerp(Color.WHITE, flash)
	draw_rect(pr.grow(8.0), Color(pc, 0.10))
	draw_rect(pr.grow(4.0), Color(pc, 0.18))
	draw_rect(pr, Color(0.05, 0.07, 0.18))
	draw_rect(pr, pc, false, 3.0)
	draw_rect(Rect2(pr.position.x + 6.0, pr.end.y + 4.0, pr.size.x - 12.0, 4.0), Color(1.0, 0.2, 0.8, 0.75))
	# little rocket thrusters
	for sx in [-1.0, 1.0]:
		var tp := Vector2(paddle_x + sx * (paddle_w / 2.0 - 14.0), pr.end.y + 14.0)
		draw_circle(tp, 6.0 + 2.0 * sin(t * 40.0 + sx), Color(1.0, 0.6, 0.1, 0.85))
	# googly eyes that watch the ball
	var ed := _eye_dir(Vector2(paddle_x, PADDLE_Y))
	for ex in [-14.0, 14.0]:
		var ep := Vector2(paddle_x + ex, PADDLE_Y + 11.0)
		draw_circle(ep, 6.0, Color.WHITE)
		draw_circle(ep + ed * 2.5, 3.0, Color(0.05, 0.0, 0.1))


func _draw_net() -> void:
	if net_timer <= 0.0:
		return
	var a := 0.85
	if net_timer < 2.0 and sin(t * 25.0) < 0.0:
		a = 0.15
	var c := Color(0.3, 1.0, 0.95, a)
	draw_line(Vector2(0.0, NET_Y), Vector2(W, NET_Y), Color(c, a * 0.25), 14.0)
	draw_line(Vector2(0.0, NET_Y), Vector2(W, NET_Y), c, 3.0)
	var x := fmod(t * 40.0, 30.0)
	while x < W + 20.0:
		draw_line(Vector2(x, NET_Y), Vector2(x - 14.0, NET_Y + 14.0), Color(c, a * 0.5), 1.5)
		x += 30.0


func _draw_balls() -> void:
	for bo in balls:
		var b: Ball = bo
		var c := Color.from_hsv(b.hue, 0.65, 1.0)
		for i in b.trail.size():
			var tp: Vector2 = b.trail[i]
			var k := 1.0 - float(i) / b.trail.size()
			draw_circle(tp, BALL_R * 0.8 * k, Color(c, 0.25 * k))
		draw_circle(b.pos, BALL_R * 2.4, Color(c, 0.10))
		draw_circle(b.pos, BALL_R * 1.6, Color(c, 0.22))
		draw_circle(b.pos, BALL_R, c)
		draw_circle(b.pos + Vector2(-3.0, -3.0), BALL_R * 0.35, Color(1.0, 1.0, 1.0, 0.9))


func _draw_fx() -> void:
	for po in particles:
		var p: Particle = po
		var a := p.life / p.max_life
		draw_circle(p.pos, p.size * a + 0.5, Color(p.color, a))
	for fo in texts:
		var f: FloatText = fo
		var a := clampf(f.life * 2.0, 0.0, 1.0)
		draw_string(font, f.pos - Vector2(200.0, 0.0), f.text, HORIZONTAL_ALIGNMENT_CENTER, 400.0, 26, Color(f.color, a))


func _draw_ability_bar(label: String, left: float, total: float, col: Color, y: float) -> void:
	draw_string(font, Vector2(24.0, y), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, col)
	draw_rect(Rect2(130.0, y - 11.0, 160.0, 8.0), Color(1.0, 1.0, 1.0, 0.12))
	draw_rect(Rect2(130.0, y - 11.0, 160.0 * left / total, 8.0), col)


func _draw_hud() -> void:
	var cfg: Dictionary = levels[level_idx]
	var col := _lvl_col()
	var need: int = cfg["need"]
	draw_string(font, Vector2(24.0, 40.0), "LEVEL %d/%d - %s" % [level_idx + 1, NUM_LEVELS, cfg["name"]], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, col)
	draw_rect(Rect2(24.0, 52.0, 300.0, 10.0), Color(1.0, 1.0, 1.0, 0.12))
	draw_rect(Rect2(24.0, 52.0, 300.0 * float(hits) / need, 10.0), col)
	draw_rect(Rect2(24.0, 52.0, 300.0, 10.0), Color(col, 0.8), false, 1.5)
	draw_string(font, Vector2(W - 424.0, 40.0), "SCORE %d" % score, HORIZONTAL_ALIGNMENT_RIGHT, 400.0, 24, Color.WHITE)
	draw_string(font, Vector2(W - 424.0, 66.0), "BALLS %d / %d" % [balls.size(), MAX_BALLS], HORIZONTAL_ALIGNMENT_RIGHT, 400.0, 18, Color(0.2, 0.9, 1.0))
	draw_string(font, Vector2(W - 424.0, 90.0), "PLAYER: " + player_name, HORIZONTAL_ALIGNMENT_RIGHT, 400.0, 16, Color(1.0, 0.5, 0.9))
	# active power-ups
	var y := 92.0
	if wide_timer > 0.0:
		_draw_ability_bar("WIDE BOX", wide_timer, 10.0, Color(0.35, 0.65, 1.0), y)
		y += 22.0
	if slow_timer > 0.0:
		_draw_ability_bar("SLOW-MO", slow_timer, 6.0, Color(1.0, 0.9, 0.3), y)
		y += 22.0
	if net_timer > 0.0:
		_draw_ability_bar("SAFETY NET", net_timer, 9.0, Color(0.3, 1.0, 0.95), y)
		y += 22.0
	# combo
	if combo >= 2 and state == "play":
		var ca := clampf(combo_timer, 0.2, 1.0)
		_center("COMBO x%d" % combo, 100.0, 34, Color(1.0, 0.9, 0.3, ca))
	# warning when only one ball is left
	if state == "play" and balls.size() == 1 and had_multi and fmod(t, 0.6) < 0.35:
		_center("LAST BALL!", 150.0, 30, Color(1.0, 0.3, 0.4))


func _title(txt: String, y: float, size: int, col: Color) -> void:
	draw_string(font, Vector2(-4.0, y), txt, HORIZONTAL_ALIGNMENT_CENTER, W, size, Color(0.1, 0.9, 1.0, 0.8 * col.a))
	draw_string(font, Vector2(4.0, y), txt, HORIZONTAL_ALIGNMENT_CENTER, W, size, Color(1.0, 0.2, 0.8, 0.8 * col.a))
	draw_string(font, Vector2(0.0, y), txt, HORIZONTAL_ALIGNMENT_CENTER, W, size, col)


func _center(txt: String, y: float, size: int, col: Color) -> void:
	draw_string(font, Vector2(0.0, y), txt, HORIZONTAL_ALIGNMENT_CENTER, W, size, col)


func _draw_overlays() -> void:
	var cfg: Dictionary = levels[level_idx]
	match state:
		"ready":
			var a := clampf(timer * 2.0, 0.0, 1.0)
			_title("LEVEL %d" % (level_idx + 1), 250.0, 72, Color(1.0, 1.0, 1.0, a))
			_center(str(cfg["name"]), 300.0, 34, Color(_lvl_col(), a))
			_center(str(cfg["tag"]), 345.0, 22, Color(1.0, 1.0, 1.0, a * 0.85))
			_center(str(cfg["hint"]), 385.0, 20, Color(1.0, 0.9, 0.3, a))
		"clear":
			_title("LEVEL %d CLEAR!" % (level_idx + 1), 260.0, 72, Color(1.0, 1.0, 1.0))
			_center("Ball count reset. You're welcome.", 315.0, 24, Color(0.4, 1.0, 0.6))
		"over":
			draw_rect(Rect2(-20.0, -20.0, W + 40.0, H + 40.0), Color(0.02, 0.0, 0.08, 0.72))
			_title(over_title, 190.0, 88 if over_title.length() <= 10 else 62, Color(1.0, 0.3, 0.5))
			draw_multiline_string(font, Vector2((W - 900.0) / 2.0, 290.0), msg, HORIZONTAL_ALIGNMENT_CENTER, 900.0, 30, -1, Color.WHITE)
			_center("%s   |   SCORE %d   |   BEST %d   |   LEVEL %d" % [player_name, score, best_score, level_idx + 1], 420.0, 24, Color(0.2, 0.9, 1.0))
			_center("TIP: " + over_tip, 462.0, 20, Color(1.0, 1.0, 1.0, 0.75))
			if last_rank >= 0:
				_center("LEADERBOARD RANK #%d!" % (last_rank + 1), 505.0, 26, Color(0.4, 1.0, 0.6))
			if t - state_time > 0.8 and fmod(t, 1.0) < 0.7:
				_center("Click or press SPACE to try again", 560.0, 24, Color(1.0, 0.9, 0.3))
			_center("ESC = main menu", 595.0, 18, Color(1.0, 1.0, 1.0, 0.6))
		"win":
			draw_rect(Rect2(-20.0, -20.0, W + 40.0, H + 40.0), Color(0.02, 0.0, 0.08, 0.55))
			_title(win_title, 190.0, 96 if win_title.length() <= 10 else 62, Color(0.4, 1.0, 0.6))
			draw_multiline_string(font, Vector2((W - 900.0) / 2.0, 290.0), msg, HORIZONTAL_ALIGNMENT_CENTER, 900.0, 30, -1, Color.WHITE)
			_center("%s   |   FINAL SCORE %d   |   BEST %d" % [player_name, score, best_score], 420.0, 24, Color(0.2, 0.9, 1.0))
			if last_rank >= 0:
				_center("LEADERBOARD RANK #%d!" % (last_rank + 1), 465.0, 26, Color(1.0, 0.9, 0.3))
			if t - state_time > 0.8 and fmod(t, 1.0) < 0.7:
				_center("Click or press SPACE to play again", 525.0, 24, Color(1.0, 0.9, 0.3))
			_center("ESC = main menu", 565.0, 18, Color(1.0, 1.0, 1.0, 0.6))
	if paused:
		draw_rect(Rect2(-20.0, -20.0, W + 40.0, H + 40.0), Color(0.02, 0.0, 0.08, 0.7))
		_title("PAUSED", 300.0, 80, Color.WHITE)
		_center("Press P to continue", 360.0, 24, Color(1.0, 0.9, 0.3))
		_center("Press Q to quit to the main menu", 400.0, 20, Color(1.0, 1.0, 1.0, 0.7))


# ---------------------------------------------------------------- MENU PAGES
func _draw_panel(r: Rect2) -> void:
	draw_rect(r, Color(0.02, 0.0, 0.08, 0.78))
	draw_rect(r, Color(1.0, 0.2, 0.8, 0.6), false, 2.0)


# BOOMY the eyeball-bot: the game mascot. His eye follows your mouse.
func _draw_character(c: Vector2, s: float) -> void:
	var r := 70.0 * s
	var col := Color(0.2, 0.95, 1.0)
	var mag := Color(1.0, 0.2, 0.8)
	# antenna
	var wob := sin(t * 3.0) * r * 0.08
	draw_line(c + Vector2(0.0, -r * 0.9), c + Vector2(wob, -r * 1.45), col, 3.0 * s)
	var ap := c + Vector2(wob, -r * 1.5)
	draw_circle(ap, r * 0.22, Color(mag, 0.25 + 0.15 * sin(t * 6.0)))
	draw_circle(ap, r * 0.12, mag)
	# waving arms
	for sx in [-1.0, 1.0]:
		var wave := sin(t * 5.0 + sx) * r * 0.22
		var hand := c + Vector2(sx * r * 1.55, -r * 0.25 + wave)
		draw_line(c + Vector2(sx * r * 0.95, r * 0.1), hand, col, 4.0 * s)
		draw_circle(hand, r * 0.13, mag)
	# rocket thrusters
	for sx in [-1.0, 1.0]:
		var fp := c + Vector2(sx * r * 0.4, r * 1.25)
		draw_circle(fp, r * 0.26, Color(1.0, 0.6, 0.1, 0.18))
		draw_circle(fp, r * 0.14 + 2.0 * sin(t * 40.0 + sx), Color(1.0, 0.6, 0.1, 0.85))
	# body
	draw_circle(c, r * 1.5, Color(col, 0.08))
	draw_circle(c, r * 1.25, Color(col, 0.14))
	draw_circle(c, r * 0.98, Color(0.06, 0.03, 0.14))
	draw_polyline(_hex(c, r, t * 0.4), col, 4.0 * s, true)
	draw_polyline(_hex(c, r * 0.82, -t * 0.4), Color(mag, 0.7), 2.0 * s, true)
	# eye that follows the mouse (and blinks)
	var look := mouse_pos - c
	var ld := Vector2.DOWN
	if look.length() > 1.0:
		ld = look.normalized()
	if fmod(t, 3.6) > 3.45:
		draw_line(c + Vector2(-r * 0.5, -r * 0.12), c + Vector2(r * 0.5, -r * 0.12), Color.WHITE, 4.0 * s)
	else:
		var ec := c + Vector2(0.0, -r * 0.12)
		draw_circle(ec, r * 0.5, Color(0.95, 0.95, 1.0))
		draw_circle(ec + ld * r * 0.18, r * 0.24, Color(0.05, 0.0, 0.1))
		draw_circle(ec + ld * r * 0.18 + Vector2(-r * 0.07, -r * 0.08), r * 0.07, Color.WHITE)
	# smile and cheeks
	draw_arc(c + Vector2(0.0, r * 0.28), r * 0.3, 0.35, PI - 0.35, 14, mag, 3.0 * s)
	draw_circle(c + Vector2(-r * 0.62, r * 0.3), r * 0.1, Color(1.0, 0.4, 0.6, 0.5))
	draw_circle(c + Vector2(r * 0.62, r * 0.3), r * 0.1, Color(1.0, 0.4, 0.6, 0.5))


func _draw_nametag(cx: float, y: float, s: float) -> void:
	var rect := Rect2(cx - 100.0 * s, y, 200.0 * s, 40.0 * s)
	draw_rect(rect, Color(0.05, 0.03, 0.15, 0.9))
	draw_rect(rect, Color(1.0, 0.2, 0.8), false, 2.0)
	draw_string(font, Vector2(rect.position.x, y + 30.0 * s), "BOOMY", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, int(26.0 * s), Color.WHITE)
	draw_string(font, Vector2(rect.position.x, y + 62.0 * s), "the eyeball-bot", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, int(16.0 * s), Color(1.0, 1.0, 1.0, 0.7))


func _draw_title_page() -> void:
	_title("BOOM BOOM", 165.0, 100, Color.WHITE)
	_center("a whimsical neon bouncy-ball disaster", 205.0, 24, Color(1.0, 0.5, 0.9))
	var bounce := absf(sin(t * 2.4)) * 34.0
	_draw_character(Vector2(W / 2.0, 395.0 - bounce), 1.1)
	_draw_nametag(W / 2.0, 512.0, 1.0)
	if fmod(t, 1.2) < 0.8:
		_center("PRESS ENTER TO START", 618.0, 32, Color(1.0, 0.9, 0.3))


func _draw_main_menu() -> void:
	_title("BOOM BOOM", 120.0, 76, Color.WHITE)
	_center("MAIN MENU", 170.0, 26, Color(1.0, 0.5, 0.9))
	for i in menu_items.size():
		var r := _menu_rect(i)
		var sel := i == menu_sel
		var col := Color(0.75, 0.85, 1.0, 0.85)
		if sel:
			col = Color(0.2, 0.95, 1.0)
		draw_rect(r, Color(0.04, 0.02, 0.14, 0.85))
		if sel:
			draw_rect(r.grow(4.0), Color(0.2, 0.95, 1.0, 0.15))
			draw_rect(r, Color(0.2, 0.95, 1.0, 0.22))
		draw_rect(r, Color(col, 0.95 if sel else 0.5), false, 3.0 if sel else 2.0)
		draw_string(font, Vector2(r.position.x, r.position.y + 36.0), menu_items[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 28, col)
		if sel:
			var bob := sin(t * 8.0) * 4.0
			draw_string(font, Vector2(r.position.x + 14.0 + bob, r.position.y + 36.0), ">", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28, Color(1.0, 0.9, 0.3))
			draw_string(font, Vector2(r.end.x - 30.0 - bob, r.position.y + 36.0), "<", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28, Color(1.0, 0.9, 0.3))
	# mascot on the left
	_draw_character(Vector2(W * 0.15, 360.0 - absf(sin(t * 2.4)) * 14.0), 0.8)
	_draw_nametag(W * 0.15, 458.0, 0.8)
	# top 3 on the right
	var panel := Rect2(W - 300.0, 250.0, 260.0, 190.0)
	_draw_panel(panel)
	draw_string(font, Vector2(panel.position.x, panel.position.y + 36.0), "TOP PLAYERS", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 22, Color(1.0, 0.9, 0.3))
	if scores.is_empty():
		draw_string(font, Vector2(panel.position.x, panel.position.y + 110.0), "No scores yet!", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 18, Color(1.0, 1.0, 1.0, 0.7))
	for i in mini(3, scores.size()):
		var e: Dictionary = scores[i]
		var yy := panel.position.y + 80.0 + i * 34.0
		draw_string(font, Vector2(panel.position.x + 16.0, yy), "%d. %s" % [i + 1, e["name"]], HORIZONTAL_ALIGNMENT_LEFT, 150.0, 18, Color.WHITE)
		draw_string(font, Vector2(panel.position.x, yy), str(e["score"]), HORIZONTAL_ALIGNMENT_RIGHT, panel.size.x - 16.0, 18, Color(0.2, 0.9, 1.0))
	_center("UP / DOWN + ENTER, or use the MOUSE", 610.0, 18, Color(1.0, 1.0, 1.0, 0.6))


func _draw_bot_icon(p: Vector2, col: Color) -> void:
	draw_circle(p, 22.0, Color(col, 0.15))
	draw_circle(p, 15.0, Color(0.06, 0.03, 0.14))
	draw_polyline(_hex(p, 16.0, t * 0.8), col, 3.0, true)
	draw_circle(p, 7.0, Color(0.95, 0.95, 1.0))
	draw_circle(p + Vector2(1.0, 2.0), 3.5, Color(0.05, 0.0, 0.1))


func _draw_instructions() -> void:
	_draw_panel(Rect2(90.0, 80.0, W - 180.0, 520.0))
	_title("HOW TO PLAY", 150.0, 56, Color.WHITE)
	var lines := [
		"GOAL: pop the eyeball-bots to fill the bar and clear all 10 levels.",
		"Every pop makes a NEW ball. You only lose when ALL your balls are gone!",
		"MOVE the box with the MOUSE, or the LEFT / RIGHT arrows, or A / D.",
		"Hit the ball with the EDGE of the box to aim it sideways.",
	]
	for i in lines.size():
		draw_string(font, Vector2(130.0, 200.0 + i * 30.0), lines[i], HORIZONTAL_ALIGNMENT_LEFT, W - 260.0, 20, Color(0.85, 0.95, 1.0))
	_center("POWER-UPS AND BADDIES", 345.0, 24, Color(1.0, 0.9, 0.3))
	var info := [
		["multi", "x3 BALL", "Triple ball!"],
		["wide", "WIDE", "Bigger box for 10 seconds"],
		["slow", "SLOW", "Slow-mo for 6 seconds"],
		["bomb", "BOOM", "Blows up bots nearby"],
		["net", "NET", "Safety net for 9 seconds"],
		["virus", "VIRUS", "Eats any ball. AVOID!"],
		["armor", "ARMOR", "Takes 2 hits to pop"],
	]
	for i in info.size():
		var e: Array = info[i]
		var col := _kind_color(str(e[0]), Color(1.0, 0.5, 0.9))
		var cx := 150.0
		var row := i
		if i >= 4:
			cx = 610.0
			row = i - 4
		var cy := 395.0 + row * 44.0
		_draw_bot_icon(Vector2(cx, cy - 6.0), col)
		draw_string(font, Vector2(cx + 34.0, cy), str(e[1]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, col)
		draw_string(font, Vector2(cx + 135.0, cy), str(e[2]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color.WHITE)
	_center("P = pause    M = music    N = sound effects    F = fullscreen", 570.0, 18, Color(1.0, 1.0, 1.0, 0.65))
	if fmod(t, 1.2) < 0.8:
		_center("Press ENTER or ESC to go back", 630.0, 22, Color(1.0, 0.9, 0.3))


func _draw_options() -> void:
	_title("OPTIONS", 130.0, 64, Color.WHITE)
	var modes := ["MOUSE + KEYBOARD", "MOUSE ONLY", "KEYBOARD ONLY"]
	for i in opt_rows.size():
		var r := _opt_rect(i)
		var sel := i == opt_sel
		var col := Color(0.75, 0.85, 1.0, 0.9)
		if sel:
			col = Color(0.2, 0.95, 1.0)
		draw_rect(r, Color(0.04, 0.02, 0.14, 0.85))
		if sel:
			draw_rect(r.grow(3.0), Color(0.2, 0.95, 1.0, 0.15))
			draw_rect(r, Color(0.2, 0.95, 1.0, 0.18))
		draw_rect(r, Color(col, 0.95 if sel else 0.5), false, 3.0 if sel else 2.0)
		if i == 6:
			draw_string(font, Vector2(r.position.x, r.position.y + 33.0), "BACK", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 26, col)
			continue
		draw_string(font, Vector2(r.position.x + 24.0, r.position.y + 33.0), opt_rows[i], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, col)
		var val := ""
		match i:
			0:
				val = "ON" if music_on else "OFF"
			1:
				val = "%d%%" % int(round(music_vol * 100.0))
			2:
				val = "ON" if sfx_on else "OFF"
			3:
				val = "%d%%" % int(round(sfx_vol * 100.0))
			4:
				val = modes[control_mode]
			5:
				val = "ON" if _is_fullscreen() else "OFF"
		var txt := val
		if sel:
			txt = "< %s >" % val
		draw_string(font, Vector2(r.position.x, r.position.y + 33.0), txt, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 24.0, 24, Color(1.0, 0.9, 0.3))
		if i == 1 or i == 3:
			var v := music_vol if i == 1 else sfx_vol
			var bar := Rect2(r.position.x + 270.0, r.position.y + 18.0, 150.0, 12.0)
			draw_rect(bar, Color(1.0, 1.0, 1.0, 0.15))
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * v, bar.size.y)), Color(0.2, 0.95, 1.0))
			draw_rect(bar, Color(col, 0.8), false, 1.5)
	_center("UP / DOWN select    LEFT / RIGHT change    ENTER toggle    ESC back", 625.0, 18, Color(1.0, 1.0, 1.0, 0.65))


func _draw_leaderboard() -> void:
	_title("LEADERBOARD", 120.0, 62, Color.WHITE)
	_center("highest score on top", 150.0, 18, Color(1.0, 1.0, 1.0, 0.55))
	var left := W / 2.0 - 300.0
	draw_string(font, Vector2(left + 14.0, 200.0), "RANK", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(1.0, 0.5, 0.9))
	draw_string(font, Vector2(left + 120.0, 200.0), "NAME", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(1.0, 0.5, 0.9))
	draw_string(font, Vector2(left, 200.0), "SCORE", HORIZONTAL_ALIGNMENT_RIGHT, 586.0, 18, Color(1.0, 0.5, 0.9))
	if scores.is_empty():
		_center("No scores yet. Go pop some bots!", 360.0, 28, Color(1.0, 0.9, 0.3))
	else:
		var medal := [Color(1.0, 0.85, 0.2), Color(0.8, 0.85, 0.95), Color(0.9, 0.55, 0.25)]
		for i in MAX_SCORES:
			var y := 240.0 + i * 34.0
			var row := Rect2(left, y - 25.0, 600.0, 32.0)
			draw_rect(row, Color(0.04, 0.02, 0.14, 0.8 if i % 2 == 0 else 0.6))
			if i >= scores.size():
				draw_string(font, Vector2(left + 14.0, y), "#%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color(1.0, 1.0, 1.0, 0.25))
				draw_string(font, Vector2(left + 120.0, y), "---", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color(1.0, 1.0, 1.0, 0.25))
				continue
			var e: Dictionary = scores[i]
			var col := Color(0.85, 0.95, 1.0)
			if i < 3:
				col = medal[i]
			if i == last_rank:
				draw_rect(row, Color(1.0, 0.9, 0.3, 0.18))
				draw_rect(row, Color(1.0, 0.9, 0.3, 0.9), false, 2.0)
				if fmod(t, 0.8) < 0.5:
					col = Color(1.0, 0.95, 0.5)
			draw_string(font, Vector2(left + 14.0, y), "#%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, col)
			draw_string(font, Vector2(left + 120.0, y), str(e["name"]), HORIZONTAL_ALIGNMENT_LEFT, 300.0, 22, col)
			draw_string(font, Vector2(left, y), str(e["score"]), HORIZONTAL_ALIGNMENT_RIGHT, 586.0, 22, col)
	if fmod(t, 1.2) < 0.8:
		_center("Press ENTER or ESC to go back", 625.0, 22, Color(1.0, 0.9, 0.3))


func _draw_name_page() -> void:
	_title("WHO ARE YOU?", 150.0, 70, Color.WHITE)
	_center("ENTER YOUR NAME", 250.0, 34, Color(1.0, 0.5, 0.9))
	var box := Rect2(W / 2.0 - 260.0, 280.0, 520.0, 70.0)
	draw_rect(box.grow(5.0), Color(0.2, 0.95, 1.0, 0.15))
	draw_rect(box, Color(0.04, 0.02, 0.14, 0.92))
	draw_rect(box, Color(0.2, 0.95, 1.0), false, 3.0)
	var shown := name_text
	if fmod(t, 1.0) < 0.6:
		shown += "|"
	draw_string(font, Vector2(box.position.x, box.position.y + 50.0), shown, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 40, Color.WHITE)
	_center("Your name goes on the leaderboard with your score!", 400.0, 20, Color(0.85, 0.95, 1.0))
	_center("Up to %d characters" % MAX_NAME, 428.0, 16, Color(1.0, 1.0, 1.0, 0.55))
	if fmod(t, 1.2) < 0.8:
		_center("Press ENTER to start    |    ESC to go back", 500.0, 24, Color(1.0, 0.9, 0.3))
	# Boomy cheers you on
	var bc := Vector2(W * 0.85, 400.0 - absf(sin(t * 2.4)) * 16.0)
	_draw_character(bc, 0.75)
	_draw_nametag(W * 0.85, 495.0, 0.75)
	var bub := Rect2(W * 0.85 - 105.0, 230.0, 210.0, 38.0)
	draw_rect(bub, Color(1.0, 1.0, 1.0, 0.92))
	draw_string(font, Vector2(bub.position.x, bub.position.y + 27.0), "WHO'S PLAYING?", HORIZONTAL_ALIGNMENT_CENTER, bub.size.x, 20, Color(0.1, 0.0, 0.2))


# ---------------------------------------------------------------- AUDIO
# All sounds and music are generated from code (no sound files needed).
func _play(sound_name: String, pitch: float = 1.0) -> void:
	if not sfx_on or not sfx.has(sound_name) or sfx_players.is_empty():
		return
	var p: AudioStreamPlayer = sfx_players[sfx_next]
	sfx_next = (sfx_next + 1) % sfx_players.size()
	p.stream = sfx[sound_name]
	p.pitch_scale = pitch
	p.play()


func _setup_audio() -> void:
	sfx["bounce"] = _make_wav(_tone(380.0, 760.0, 0.09, "sine", 0.6))
	sfx["pop"] = _make_wav(_mix(_tone(220.0, 40.0, 0.35, "sine", 0.8), _tone(0.0, 0.0, 0.25, "noise", 0.35)))
	sfx["newball"] = _make_wav(_seq([523.3, 659.3, 784.0], 0.07, "square", 0.25))
	sfx["go"] = _make_wav(_tone(660.0, 990.0, 0.15, "square", 0.3))
	sfx["clear"] = _make_wav(_seq([523.3, 659.3, 784.0, 1046.5], 0.13, "square", 0.28))
	sfx["over"] = _make_wav(_tone(520.0, 50.0, 1.0, "saw", 0.45))
	sfx["win"] = _make_wav(_seq([523.3, 659.3, 784.0, 1046.5, 784.0, 1046.5, 1318.5], 0.14, "square", 0.28))
	sfx["drop"] = _make_wav(_tone(330.0, 90.0, 0.3, "saw", 0.35))
	sfx["power"] = _make_wav(_seq([659.3, 880.0, 1174.7], 0.06, "square", 0.25))
	sfx["boom"] = _make_wav(_mix(_tone(160.0, 30.0, 0.6, "sine", 0.9), _tone(0.0, 0.0, 0.5, "noise", 0.5)))
	sfx["virus"] = _make_wav(_tone(220.0, 70.0, 0.4, "square", 0.35))
	sfx["clink"] = _make_wav(_tone(1200.0, 800.0, 0.06, "square", 0.25))
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.volume_db = -4.0
		add_child(p)
		sfx_players.append(p)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -8.0
	add_child(music_player)
	_apply_volumes()


# Applies the music / sound-effect volume sliders from the options page.
func _apply_volumes() -> void:
	var mdb := -8.0 + linear_to_db(maxf(music_vol, 0.0001))
	if music_vol <= 0.0:
		mdb = -80.0
	music_player.volume_db = mdb
	var sdb := -4.0 + linear_to_db(maxf(sfx_vol, 0.0001))
	if sfx_vol <= 0.0:
		sdb = -80.0
	for po in sfx_players:
		var p: AudioStreamPlayer = po
		p.volume_db = sdb


# One looping synth track per level: bass + arpeggio + drums. Later levels are faster.
func _get_track(idx: int) -> AudioStreamWAV:
	if not music_cache.has(idx):
		music_cache[idx] = _make_track(idx)
	return music_cache[idx]


func _set_track(idx: int) -> void:
	if idx == current_track:
		return
	current_track = idx
	music_player.stream = _get_track(idx)
	music_player.play()
	_apply_music_pause()


func _apply_music_pause() -> void:
	music_player.stream_paused = (not music_on) or paused


func _make_track(idx: int) -> AudioStreamWAV:
	var roots := [110.0, 123.5, 98.0, 130.8, 110.0, 146.8, 116.5, 123.5, 138.6, 98.0]
	var root: float = roots[idx]
	var step := maxf(0.2, 0.42 - 0.022 * idx)
	var bass_semis := [0, 0, 7, 0, 3, 3, 10, 5]
	var total := int(step * 8.0 * MIX_RATE)
	var buf := PackedFloat32Array()
	buf.resize(total)
	for i in 8:
		var semi: int = bass_semis[i]
		var off := int(i * step * MIX_RATE)
		var half := int(step * 0.5 * MIX_RATE)
		var f_bass := root * pow(2.0, semi / 12.0)
		var f_a1 := root * pow(2.0, (semi + 12) / 12.0)
		var f_a2 := root * pow(2.0, (semi + (15 if i % 2 == 0 else 19)) / 12.0)
		buf = _add_at(buf, _tone(f_bass, f_bass, step * 0.7, "square", 0.15), off)
		buf = _add_at(buf, _tone(f_a1, f_a1, step * 0.35, "saw", 0.06), off)
		buf = _add_at(buf, _tone(f_a2, f_a2, step * 0.35, "saw", 0.06), off + half)
		buf = _add_at(buf, _tone(130.0, 45.0, 0.12, "sine", 0.45), off)   # kick
		if idx >= 1:
			buf = _add_at(buf, _tone(0.0, 0.0, 0.04, "noise", 0.10), off + half)   # hi-hat
		if idx >= 3 and i % 2 == 1:
			buf = _add_at(buf, _tone(0.0, 0.0, 0.10, "noise", 0.18), off)   # snare
	return _make_wav(buf, true)


func _add_at(buf: PackedFloat32Array, src: PackedFloat32Array, offset: int) -> PackedFloat32Array:
	var n := src.size()
	for i in n:
		var j := offset + i
		if j >= buf.size():
			break
		buf[j] += src[i]
	return buf


func _make_wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = MIX_RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w


func _tone(f0: float, f1: float, dur: float, wave: String, vol: float) -> PackedFloat32Array:
	var n := int(dur * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var inv_n := 1.0 / maxf(1.0, float(n))
	var attack_len := MIX_RATE * 0.004
	for i in n:
		var k := float(i) * inv_n
		phase += lerpf(f0, f1, k) / MIX_RATE
		var s := 0.0
		if wave == "square":
			s = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		elif wave == "saw":
			s = fmod(phase, 1.0) * 2.0 - 1.0
		elif wave == "noise":
			s = randf() * 2.0 - 1.0
		else:
			s = sin(phase * TAU)
		var env := (1.0 - k) * (1.0 - k)
		out[i] = s * minf(1.0, float(i) / attack_len) * env * vol
	return out


func _seq(freqs: Array, step: float, wave: String, vol: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for f in freqs:
		out.append_array(_tone(float(f), float(f), step, wave, vol))
	return out


func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var n := maxi(a.size(), b.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var v := 0.0
		if i < a.size():
			v += a[i]
		if i < b.size():
			v += b[i]
		out[i] = v
	return out


# ---------------------------------------------------------------- MESSAGE PICKER
# Shuffle-bag: every message is shown once before any message repeats.
func _pick(list: Array, key: String) -> String:
	var bag: Array = bags.get(key, [])
	if bag.is_empty():
		bag = list.duplicate()
		bag.shuffle()
		if bag.size() > 1 and bag[bag.size() - 1] == bags.get(key + "_last", ""):
			bag.push_front(bag.pop_back())
	var choice: String = bag.pop_back()
	bags[key] = bag
	bags[key + "_last"] = choice
	return choice


# ---------------------------------------------------------------- VOICE SOUNDS
func _formant_gain(freq: float, f1: float, f2: float) -> float:
	var a := (freq - f1) / 260.0
	var b := (freq - f2) / 380.0
	return exp(-a * a) + 0.6 * exp(-b * b) + 0.04


# A little synthetic "voice": harmonics shaped by two vowel formants (f1, f2).
func _voice(f0a: float, f0b: float, dur: float, f1a: float, f1b: float, f2a: float, f2b: float, vol: float, vib: float) -> PackedFloat32Array:
	var n := int(dur * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var harmonics := 9
	var gains := PackedFloat32Array()
	gains.resize(harmonics)
	var phase := 0.0
	var inv_n := 1.0 / maxf(1.0, float(n))
	for i in n:
		var k := float(i) * inv_n
		var tt := float(i) / MIX_RATE
		var f0 := lerpf(f0a, f0b, k) * (1.0 + vib * sin(tt * TAU * 5.5))
		if i % 64 == 0:
			var f1 := lerpf(f1a, f1b, k)
			var f2 := lerpf(f2a, f2b, k)
			for h in harmonics:
				gains[h] = _formant_gain(f0 * (h + 1), f1, f2)
		phase += f0 / MIX_RATE
		var s := 0.0
		for h in harmonics:
			s += sin(phase * TAU * (h + 1)) * gains[h] / (1.0 + 0.5 * h)
		var env := minf(1.0, tt / 0.06) * minf(1.0, (dur - tt) / 0.25)
		out[i] = s * env * vol * 0.35
	return out


# The sad "FAHHHH": a breathy "f" and a long falling "aaah".
func _make_fah() -> AudioStreamWAV:
	var breath := _tone(0.0, 0.0, 0.1, "noise", 0.22)
	var vowel := _voice(330.0, 140.0, 1.5, 850.0, 600.0, 1250.0, 1000.0, 1.0, 0.03)
	var out := PackedFloat32Array()
	out.resize(vowel.size() + breath.size())
	out = _add_at(out, breath, 0)
	out = _add_at(out, vowel, int(0.08 * MIX_RATE))
	return _make_wav(out)


# The happy "YAYYY": a rising cheer plus a burst of clapping.
func _make_yay() -> AudioStreamWAV:
	var v1 := _voice(260.0, 480.0, 1.3, 320.0, 800.0, 2200.0, 1300.0, 1.0, 0.025)
	var v2 := _voice(330.0, 600.0, 1.3, 320.0, 800.0, 2200.0, 1300.0, 0.7, 0.03)
	var cheer := _mix(v1, v2)
	var claps := PackedFloat32Array()
	claps.resize(int(1.6 * MIX_RATE))
	for i in 24:
		claps = _add_at(claps, _tone(0.0, 0.0, 0.035, "noise", 0.28), int(randf_range(0.1, 1.4) * MIX_RATE))
	return _make_wav(_mix(cheer, claps))
