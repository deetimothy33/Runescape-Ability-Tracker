require 'Win32API'

# number of abilities to display in the tracker
TRACKER_SIZE=14
# html file refresh speed in metadata
AUTO_REFRESH=false
TRACKER_UPDATE_INTERVAL=1
# how frequently the html file is updated 1 second == 100
#0 will update whenever there is a valid input
#otherwise refers to seconds between updates (200 default)
HTML_UPDATE_INTERVAL=0

# get command line arguments to determine what combat styles to output
# true to display bar associated with each combat style
SHOW_MAGIC=false
SHOW_MELEE=false
SHOW_RANGED=false
SHOW_NECROMANCY=false
ARGV.each do |a|
	if a=="magic"
		puts "magic"
		SHOW_MAGIC=true
	elsif a=="melee"
		puts "melee"
		SHOW_MELEE=true
	elsif a=="ranged"
		puts "ranged"
		SHOW_RANGED=true
	elsif a=="necromancy"
		puts "necromancy"
		SHOW_NECROMANCY=true
	end
end

# constants for action bars
ALWAYS_AVAILABLE_BAR=0
MAGIC_2H=1
MAGIC_DW=2
MAGIC_S=3
MELEE_2H=4
MELEE_DW=5
MELEE_S=6
RANGED_2H=7
RANDED_DW=8
RANGED_S=9
NECROMANCY_2H=10
NECROMANCY_DW=11
NECROMANCY_S=12

# modifier key codes
SHIFT=0x10
CTRL=0x11
NONE=0x0

# create a hash of keys to keycodes
# https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
$keys = Hash.new
# add letters
(0x41..0x5A).each { |code| $keys[code.chr.downcase] = code }
# add numbers
(0x30..0x39).each { |code| $keys["#{code-0x30}"] = code }
# add special characters
$keys[';'] = 0xBA; $keys['='] = 0xBB; $keys[','] = 0xBC; $keys['-'] = 0xBD; $keys['.'] = 0xBE 
$keys['/'] = 0xBF; $keys['`'] = 0xC0; $keys['['] = 0xDB; $keys[']'] = 0xDD; $keys["'"] = 0xDE 
$keys['\\'] = 0xDC
# add custom key macros
$keys["\n"] = 0x0D; $keys["\t"] = 0x09; $keys['(backspace)'] = 0x08; $keys['(CAPSLOCK)'] = 0x14
# add f1-f24 keys
$keys["f1"]=0x70; $keys["f2"]=0x71; $keys["f3"]=0x72; $keys["f4"]=0x73; $keys["f5"]=0x74; $keys["f6"]=0x75; 
$keys["f7"]=0x76; $keys["f8"]=0x77; $keys["f9"]=0x78; $keys["f10"]=0x79; $keys["f11"]=0x7A; $keys["f12"]=0x7B; 
$keys["f13"]=0x7C; $keys["f14"]=0x7D; $keys["f15"]=0x7E; $keys["f16"]=0x7F; $keys["f17"]=0x80; $keys["f18"]=0x81; 
$keys["f19"]=0x82; $keys["f20"]=0x83; $keys["f21"]=0x84; $keys["f22"]=0x85; $keys["f23"]=0x86; $keys["f24"]=0x87;
# escape key
$keys["esc"]=0x1B 
# mouse buttons
$keys["mouse_left"]=0x01; $keys["mouse_right"]=0x02

# stores the current action bars as an array
$current_action_bars=[ALWAYS_AVAILABLE_BAR, MAGIC_2H, MAGIC_S]

# provides the currently pressed key
# basically you call the Win32API with a key code
# the Win32API returns whether that key is pressed or not
# this class makes the assumption that only one key is pressed at a time
class Listener
	@@listener=Win32API.new('user32','GetAsyncKeyState',['i'],'i')

	# return the currently pressed key character
	# this is a simplification on the Win32API
	# it assumes only one non-modifier key is a pressed at a time
	def get_key
		key=''
		$keys.each do |char, code|
			n = @@listener.call(code)
			if n and n & 0x01 == 1
				key=char
				break
			end
		end

		return key
	end

	# return SHIFT,CTRL, or NONE representing the currently pressed modifier
	def get_modifier
		value=NONE
		if @@listener.call(SHIFT) != 0
			value=SHIFT
		elsif @@listener.call(CTRL) !=0 
			value=CTRL
		end
		return value
	end
end


# actions are abilities or items used by the player
# each action object represents 1 action that can be taken
class Action
	def initialize(name="",key="",modifier=NONE,icon="blank.png",bar=ALWAYS_AVAILABLE_BAR)
		@name=name
		@key=key
		@modifier=modifier
		@icon=icon
		@bar=bar
	end

	def name; @name; end
	def key; @key; end
	def modifier; @modifier; end
	def icon; @icon; end
	def bar; @bar; end

	# returns true if the key, modifier match 
	# and the bar[] contains bar
	def match(key,modifier,bar)
		@key==key and @modifier==modifier and bar.include? @bar
	end

	def match_action(action)
		#TODO add bar matching
		@key==action.key and @modifier==action.modifier 
		#and action.bar.include? @bar
	end

	def to_s
		return "#{@key} #{@modifier}"
	end	

	def to_str
		return "#{@key} #{@modifier}"
	end
end


# define all actions
# add all actions to an array
$action_array=[]
# ranged primary action bar
$action_array.append(Action.new("binding shot","f1",NONE,"Binding_Shot.png",RANGED_2H))
$action_array.append(Action.new("tight bindings","f2",NONE,"Tight_Bindings.png",RANGED_2H))
$action_array.append(Action.new("incendiary shot","f3",SHIFT,"Incendiary_Shot.png",RANGED_2H))
$action_array.append(Action.new("deaths swiftness","f4",SHIFT,"Greater_Death's_Swiftness.png",RANGED_2H))
$action_array.append(Action.new("snap shot","1",NONE,"Snap_Shot.png",RANGED_2H))
$action_array.append(Action.new("snipe","2",NONE,"Snipe.png",RANGED_2H))
$action_array.append(Action.new("greater dazing shot","3",NONE,"Greater_Dazing_Shot.png",RANGED_2H))
$action_array.append(Action.new("greater ricochet","4",NONE,"Greater_Ricochet.png",RANGED_2H))
$action_array.append(Action.new("piercing shot","5",NONE,"Piercing_Shot.png",RANGED_2H))
$action_array.append(Action.new("rapid fire","6",NONE,"Rapid_Fire.png",RANGED_2H))
$action_array.append(Action.new("fragmentation shot","7",NONE,"Fragmentation_Shot.png",RANGED_2H))
$action_array.append(Action.new("corruption shot","8",NONE,"Corruption_Shot.png",RANGED_2H))
$action_array.append(Action.new("deadshot","9",NONE,"Deadshot.png",RANGED_2H))
$action_array.append(Action.new("essence of finality amulet","0",NONE,"Essence of Finality amulet.png",RANGED_2H))
# ranged secondary action bar
$action_array.append(Action.new("bolg","a",NONE,"Bow of the Last Guardian.png",RANGED_S))
$action_array.append(Action.new("quiver 1","w",NONE,"Quiver_ammo_slot_1.png",RANGED_S))
$action_array.append(Action.new("quiver 2","e",NONE,"Quiver_ammo_slot_2.png",RANGED_S))
$action_array.append(Action.new("essence of finality amulet","u",NONE,"Essence of Finality amulet.png",RANGED_S))
$action_array.append(Action.new("pernix quiver blue","r",NONE,"Pernix's quiver (blue).png",RANGED_S))
$action_array.append(Action.new("pernix quiver red","h",NONE,"Pernix's quiver (red).png",RANGED_S))
$action_array.append(Action.new("shadow tendrils","k",NONE,"Shadow_Tendrils.png",RANGED_S))
$action_array.append(Action.new("arcane spirit shield","x",NONE,"arcane_spirit_shield.png",RANGED_S))
#$action_array.append(Action.new("ode to deceit","f3",NONE,"Ode_to_Deceit.png",RANGED_S))
$action_array.append(Action.new("erethdor's grimoire","f3",NONE,"Erethdor's grimoire.png",RANGED_S))
$action_array.append(Action.new("roar of awakening","f",NONE,"Roar_of_Awakening.png",RANGED_2H))
$action_array.append(Action.new("essence of finality amulet","o",NONE,"Essence of Finality amulet.png",RANGED_S))
$action_array.append(Action.new("desolation","\t",NONE,"Desolation.png",RANGED_S))
#$action_array.append(Action.new("seren godbow","f4",NONE,"Seren godbow.png",RANGED_S))
$action_array.append(Action.new("erethdor's grimoire","f4",NONE,"Erethdor's grimoire.png",RANGED_S))
$action_array.append(Action.new("essence of finality amulet","p",NONE,"Essence of Finality amulet.png",RANGED_S))
# magic primary action bar
$action_array.append(Action.new("impact","f1",NONE,"impact.png",MAGIC_DW))
$action_array.append(Action.new("deep impact","f2",NONE,"Deep Impact.png",MAGIC_DW))
$action_array.append(Action.new("chain","f3",SHIFT,"Greater Chain.png",MAGIC_DW))
$action_array.append(Action.new("sunshine","f4",SHIFT,"Greater Sunshine.png",MAGIC_DW))
$action_array.append(Action.new("metamorphosis","f4",SHIFT,"Metamorphosis.png",MAGIC_2H))
$action_array.append(Action.new("wild magic","1",NONE,"Wild Magic.png",MAGIC_DW))
$action_array.append(Action.new("ice barrage","2",NONE,"Ice Barrage icon.png",MAGIC_DW))
$action_array.append(Action.new("blood burst","3",NONE,"Blood Burst icon.png",MAGIC_DW))
#$action_array.append(Action.new("emerald aurora","3",NONE,"Emerald Aurora icon.png",MAGIC_DW))
$action_array.append(Action.new("wrack","4",NONE,"Wrack.png",MAGIC_DW))
$action_array.append(Action.new("greater concentrated blast","5",NONE,"Greater Concentrated Blast.png",MAGIC_DW))
$action_array.append(Action.new("greater sonic wave","5",NONE,"Greater Sonic Wave.png",MAGIC_2H))
$action_array.append(Action.new("asphyxiate","6",NONE,"Asphyxiate.png",MAGIC_DW))
$action_array.append(Action.new("combust","7",NONE,"Combust.png",MAGIC_DW))
$action_array.append(Action.new("corruption blast","8",NONE,"Corruption Blast.png",MAGIC_DW))
$action_array.append(Action.new("omnipower","9",NONE,"Omnipower.png",MAGIC_DW))
$action_array.append(Action.new("essence of finality amulet","0",NONE,"Essence of Finality amulet.png",MAGIC_DW))
# magic secondary action bar 1
$action_array.append(Action.new("fsoa","a",NONE,"Fractured Staff of Armadyl.png",MAGIC_S))
#$action_array.append(Action.new("praesul wand","w",NONE,"Wand of the praesul.png",MAGIC_S))
$action_array.append(Action.new("roar of awakening","w",NONE,"Roar_of_Awakening.png",MAGIC_S))
#$action_array.append(Action.new("imperium core","e",NONE,"Imperium core.png",MAGIC_S))
$action_array.append(Action.new("ode to deceit","e",NONE,"Ode_to_Deceit.png",MAGIC_S))
$action_array.append(Action.new("dragon breath","f",NONE,"Dragon Breath.png",MAGIC_S))
$action_array.append(Action.new("magma tempest","r",NONE,"Magma Tempest (Targeted).png",MAGIC_S))
$action_array.append(Action.new("tsunami","h",NONE,"Tsunami.png",MAGIC_S))
$action_array.append(Action.new("detonate","u",NONE,"Detonate.png",MAGIC_S))
$action_array.append(Action.new("smoke tendrils","k",NONE,"Smoke Tendrils.png",MAGIC_S))
$action_array.append(Action.new("arcane spirit shield","x",NONE,"arcane_spirit_shield.png",MAGIC_S))
$action_array.append(Action.new("flank orb","f3",NONE,"Imperium core.png",MAGIC_S))
$action_array.append(Action.new("bolg","o",NONE,"Bow of the Last Guardian.png",MAGIC_S))
$action_array.append(Action.new("affliction","\t",NONE,"Affliction.png",MAGIC_S))
$action_array.append(Action.new("fsoa","f4",NONE,"Fractured Staff of Armadyl.png",MAGIC_S))
$action_array.append(Action.new("essence of finality amulet","p",NONE,"Essence of Finality amulet.png",MAGIC_S))
# necromancy primary action bar
$action_array.append(Action.new("soul strike","f1",NONE,"Soul_Strike.png",NECROMANCY_DW))
$action_array.append(Action.new("invoke death","f2",NONE,"Invoke_Death_icon.png",NECROMANCY_DW))
$action_array.append(Action.new("threads of fate","f3",SHIFT,"Threads_of_Fate_icon.png",NECROMANCY_DW))
$action_array.append(Action.new("living death","f4",SHIFT,"Living_Death.png",NECROMANCY_DW))
$action_array.append(Action.new("death skulls","1",NONE,"Death_Skulls.png",NECROMANCY_DW))
$action_array.append(Action.new("finger of death","2",NONE,"Finger_of_Death.png",NECROMANCY_DW))
$action_array.append(Action.new("auto","3",NONE,"Necromancy_(ability).png",NECROMANCY_DW))
$action_array.append(Action.new("touch of death","4",NONE,"Touch_of_Death.png",NECROMANCY_DW))
$action_array.append(Action.new("soul sap","5",NONE,"Soul_Sap.png",NECROMANCY_DW))
$action_array.append(Action.new("volley of souls","6",NONE,"Volley_of_Souls.png",NECROMANCY_DW))
$action_array.append(Action.new("blood siphon","7",NONE,"Blood_Siphon.png",NECROMANCY_DW))
#$action_array.append(Action.new("phantom","8",NONE,"Conjure_Phantom_Guardian.png",NECROMANCY_DW))
$action_array.append(Action.new("phantom","8",NONE,"Command_Phantom_Guardian.png",NECROMANCY_DW))
$action_array.append(Action.new("conjure undead army","9",NONE,"Conjure_Undead_Army.png",NECROMANCY_DW))
$action_array.append(Action.new("split soul","0",NONE,"Split_Soul_icon.png",NECROMANCY_DW))
# necromancy secondary action bar 1
$action_array.append(Action.new("roar of awakening","a",NONE,"Roar_of_Awakening.png",NECROMANCY_S))
$action_array.append(Action.new("omni guard","w",NONE,"Omni_guard.png",NECROMANCY_S))
$action_array.append(Action.new("soulbound lantern","e",NONE,"Soulbound lantern.png",NECROMANCY_S))
$action_array.append(Action.new("bloat","f",NONE,"Bloat.png",NECROMANCY_S))
$action_array.append(Action.new("spectral scythe","r",NONE,"Spectral_Scythe.png",NECROMANCY_S))
#$action_array.append(Action.new("zombie","h",NONE,"Conjure_Putrid_Zombie.png",NECROMANCY_S))
$action_array.append(Action.new("zombie","h",NONE,"Command_Putrid_Zombie.png",NECROMANCY_S))
#$action_array.append(Action.new("skeleton","u",NONE,"Conjure_Skeleton_Warrior.png",NECROMANCY_S))
$action_array.append(Action.new("skeleton","u",NONE,"Command_Skeleton_Warrior.png",NECROMANCY_S))
#$action_array.append(Action.new("ghost","k",NONE,"Conjure_Vengeful_Ghost.png",NECROMANCY_S))
$action_array.append(Action.new("ghost","k",NONE,"Command_Vengeful_Ghost.png",NECROMANCY_S))
$action_array.append(Action.new("spectral spirit shield","x",NONE,"Spectral spirit shield.png",NECROMANCY_S))
#$action_array.append(Action.new("","f3",NONE,"",NECROMANCY_S))
$action_array.append(Action.new("soulbound lantern barrows","f3",NONE,"Soulbound_lantern_(Barrows).png",NECROMANCY_S))
$action_array.append(Action.new("life transfer","o",NONE,"Life_Transfer_icon.png",NECROMANCY_S))
#$action_array.append(Action.new("sorrow","\t",NONE,"Sorrow.png",NECROMANCY_S))
$action_array.append(Action.new("ruination","\t",NONE,"Ruination.png",NECROMANCY_S))
$action_array.append(Action.new("death guard","f4",NONE,"Death guard (tier 90).png",NECROMANCY_S))
$action_array.append(Action.new("essence of finality amulet","p",NONE,"Essence of Finality amulet.png",NECROMANCY_S))

# melee primary action bar
$action_array.append(Action.new("","f1",NONE,"Backhand.png",MELEE_DW))
$action_array.append(Action.new("","f2",NONE,"Forceful_Backhand.png",MELEE_DW))
$action_array.append(Action.new("","f3",SHIFT,"Meteor_Strike.png",MELEE_DW))
$action_array.append(Action.new("","f4",SHIFT,"Berserk.png",MELEE_DW))
$action_array.append(Action.new("","1",NONE,"Hurricane.png",MELEE_DW))
$action_array.append(Action.new("","2",NONE,"Greater_Fury.png",MELEE_DW))
$action_array.append(Action.new("","3",NONE,"Smash.png",MELEE_DW))
$action_array.append(Action.new("","4",NONE,"Cleave.png",MELEE_DW))
$action_array.append(Action.new("","5",NONE,"Sever.png",MELEE_DW))
$action_array.append(Action.new("","6",NONE,"Quake.png",MELEE_DW))
$action_array.append(Action.new("","7",NONE,"Slaughter.png",MELEE_DW))
$action_array.append(Action.new("","8",NONE,"Dismember.png",MELEE_DW))
$action_array.append(Action.new("","9",NONE,"Overpower.png",MELEE_DW))
$action_array.append(Action.new("","0",NONE,"Assault.png",MELEE_DW))
# melee secondary action bar 1
$action_array.append(Action.new("","a",NONE,"Ek-ZekKil.webp",MELEE_S))
$action_array.append(Action.new("","w",NONE,"Dark_Shard_of_Leng.webp",MELEE_S))
$action_array.append(Action.new("","e",NONE,"Dark_Sliver_of_Leng.webp",MELEE_S))
#$action_array.append(Action.new("","f",NONE,".png",MELEE_S))
$action_array.append(Action.new("","r",NONE,"Greater_Barge.png",MELEE_S))
$action_array.append(Action.new("","h",NONE,"Chaos_Roar.png",MELEE_S))
$action_array.append(Action.new("essence of finality amulet","u",NONE,"Essence of Finality amulet.png",MELEE_S))
$action_array.append(Action.new("","k",NONE,"Blood_Tendrils.png",MELEE_S))
$action_array.append(Action.new("","x",NONE,"Divine_spirit_shield.png",MELEE_S))
$action_array.append(Action.new("","f3",NONE,"Dark_Sliver_of_Leng_(Barrows).webp",MELEE_S))
$action_array.append(Action.new("essence of finality amulet","o",NONE,"Essence of Finality amulet.png",MELEE_S))
$action_array.append(Action.new("","\t",NONE,"Malevolence.webp",MELEE_S))
$action_array.append(Action.new("","f4",NONE,"Masterwork_Spear_of_Annihilation.webp",MELEE_S))
$action_array.append(Action.new("","p",NONE,"Punish.png",MELEE_S))
# secondary action bar 2
$action_array.append(Action.new("preparation","c",SHIFT,"Preparation.png"))
$action_array.append(Action.new("divert","v",SHIFT,"Divert.png"))
$action_array.append(Action.new("escape","z",SHIFT,"Escape.png"))
$action_array.append(Action.new("ingenuity of the humans","f6",NONE,"Ingenuity of the Humans.png"))
$action_array.append(Action.new("darkness","1",CTRL,"Darkness icon.png"))
#$action_array.append(Action.new("achto primeval robe legs","2",CTRL,"Augmented Achto Primeval robe legs.png"))
#$action_array.append(Action.new("elite dracolich chaps","2",CTRL,"Elite Dracolich chaps.png"))
$action_array.append(Action.new("invoke_lord_of_bones","2",CTRL,"Invoke_Lord_of_Bones.png"))
$action_array.append(Action.new("demon slayer","3",CTRL,"Demon Slayer (ability).png"))
$action_array.append(Action.new("smoke cloud","3",SHIFT,"Smoke Cloud icon.png"))
#$action_array.append(Action.new("vulnerability","3",SHIFT,"Vulnerability icon.png"))
$action_array.append(Action.new("shield dome","x",SHIFT,"Shield Dome icon.png"))
$action_array.append(Action.new("provoke","f",CTRL,"Provoke.png"))
$action_array.append(Action.new("essence of finality","f5",NONE,"Essence of Finality.png"))
$action_array.append(Action.new("shatter","h",SHIFT,"Shatter.png"))
$action_array.append(Action.new("storm shards","u",SHIFT,"Storm Shards.png"))
$action_array.append(Action.new("erethdor's grimoire","k",SHIFT,"Erethdor's grimoire.png"))
# secondary action bar 3
#$action_array.append(Action.new("blessed flask","g",NONE,"Blessed flask.png"))
$action_array.append(Action.new("super restore","g",NONE,"Super_restore_(4).png"))
$action_array.append(Action.new("adrenaline renewal","n",NONE,"Adrenaline renewal potion (4).png"))
#$action_array.append(Action.new("sailfish soup","t",NONE,"Sailfish soup.png"))
$action_array.append(Action.new("blue blubber jellyfish","t",NONE,"Blue_blubber_jellyfish.png"))
#$action_array.append(Action.new("super saradomin brew","y",NONE,"Super Saradomin brew flask (6).png"))
$action_array.append(Action.new("super guthix brew","y",NONE,"Super_Guthix_brew_flask_(6).png"))
$action_array.append(Action.new("vulnerability bomb","r",SHIFT,"Vulnerability bomb.png"))
$action_array.append(Action.new("spellbook swap lunar","l",SHIFT,"Spellbook Swap (Lunar) icon.png"))
$action_array.append(Action.new("spellbook swap standard","s",SHIFT,"Spellbook Swap (Standard) icon.png"))
#$action_array.append(Action.new("entangle","d",SHIFT,"Entangle.png"))
$action_array.append(Action.new("temporal anomaly","d",SHIFT,"Temporal_Anomaly_icon.webp"))
$action_array.append(Action.new("enfeeble","f",SHIFT,"Enfeeble icon.png"))
$action_array.append(Action.new("fortitude","\t",SHIFT,"Fortitude.png"))
$action_array.append(Action.new("deflect ranged","q",NONE,"Deflect Ranged.png"))
$action_array.append(Action.new("deflect magic","s",NONE,"Deflect Magic.png"))
$action_array.append(Action.new("deflect melee","d",NONE,"Deflect Melee.png"))
$action_array.append(Action.new("soul split","z",NONE,"Soul Split.png"))
# secondary action bar 4
$action_array.append(Action.new("disruption shield","w",SHIFT,"Disruption Shield icon.png"))
$action_array.append(Action.new("vengeance","e",SHIFT,"Vengeance Group icon.png"))
$action_array.append(Action.new("resonance","c",NONE,"Resonance.png"))
$action_array.append(Action.new("reflect","v",NONE,"Reflect.png"))
$action_array.append(Action.new("natural instinct","1",SHIFT,"Natural Instinct.png"))
$action_array.append(Action.new("barricade","4",CTRL,"Barricade.png"))
$action_array.append(Action.new("dive","a",SHIFT,"Dive.png"))
$action_array.append(Action.new("devotion","4",SHIFT,"Devotion.png"))
$action_array.append(Action.new("freedom","5",SHIFT,"Freedom.png"))
$action_array.append(Action.new("anticipation","6",SHIFT,"Anticipation.png"))
$action_array.append(Action.new("limitless","i",NONE,"Limitless.png"))
$action_array.append(Action.new("debilitate","2",SHIFT,"Debilitate.png"))
$action_array.append(Action.new("immortality","r",CTRL,"Immortality.png"))
$action_array.append(Action.new("surge","q",SHIFT,"Surge.png"))
# key binds not on bar
$action_array.append(Action.new("target cycle","m",NONE,"target_cycle.png"))
$action_array.append(Action.new("target cycle","m",SHIFT,"target_cycle.png"))
$action_array.append(Action.new("familiar action","b",NONE,"Summoning detail.png"))
$action_array.append(Action.new("weapon special attack","l",NONE,"Weapon Special Attack.png"))
$action_array.append(Action.new("extra action button","m",CTRL,"Realm Movement extra action button.png"))
$action_array.append(Action.new("quick prayer","p",SHIFT,"Prayer.png"))


# determine if the action should update current action bars
# and update the stored value
def update_action_bars(action)
	# staff
	if action.match("f4",NONE,[MAGIC_S]) or action.match("a",NONE,[MAGIC_S])
		$current_action_bars=[ALWAYS_AVAILABLE_BAR, MAGIC_2H, MAGIC_S]
	end
	# wand
	if action.match("w",NONE,[MAGIC_S])
		$current_action_bars=[ALWAYS_AVAILABLE_BAR, MAGIC_DW, MAGIC_S]
	end
end

# retrieves the current action bars as an array
def get_current_bars
	bar=$current_action_bars
	
	# consider doing the below only on mouse key press

	# take a screenshot of the action bar number location
	#TODO win32screenshot
	# extract numbers from the screenshot
	#TODO rtessaract
	#OR
	# assess the rgb values of the pixels and 
	# determine what action bar the color belongs to

	return bar
end

# given an key and modifier
# return the corresponding action from the action_array
# return false if there is no corresponding action in the array
def get_action (key,modifier,bar=get_current_bars())
	action=false
	$action_array.each do |element|
		#if element.key==key and element.modifier==modifier and bar.include? element.bar
		if element.match(key, modifier, bar)
			action=element
			break
		end
	end
	return action
end

# return a string of html corresponding to the bars in the array actions
def html_show (actions, bars)
	html_text="<div>"
	actions.each do |action|
		a=get_action(action.key, action.modifier, bars)
		# if a does not exist make it a default action (blank)
		if !a
			a=Action.new()
		end
		html_text+="<img src=\"icon\\#{a.icon}\">"
	end
	html_text+="</div><p style=\"clear: both;\"></p>"

	return html_text
end

# output an array of actions to tracker.html
def html_output (actions)
	html_text=""
	# make the page automatically refresh
	if AUTO_REFRESH
		html_text+="<meta http-equiv=\"refresh\" content=\"#{TRACKER_UPDATE_INTERVAL}\">\n"
	end

	# page style
	html_text+="<style>\n"
	html_text+="img { float: left; width: 64px; height: 64px; object-fit: cover; }\n"
	html_text+=".clear { clear: both; }\n"
	html_text+="</style>\n"

	#TODO revert to this from TEMPORARY below
	# display an icon for each action
	#actions.each do |action|
	#	html_text+="<img src=\"icon\\#{action.icon}\">"
	#end

	#TEMPORARY 
	# display combat style equivalent actions
	if SHOW_MAGIC 
		html_text+=html_show(actions, [ALWAYS_AVAILABLE_BAR, MAGIC_DW, MAGIC_S])
	end	

	if SHOW_MELEE
		html_text+=html_show(actions, [ALWAYS_AVAILABLE_BAR, MELEE_DW, MELEE_S])
	end

	if SHOW_RANGED
		html_text+=html_show(actions, [ALWAYS_AVAILABLE_BAR, RANGED_2H, RANGED_S])
	end

	if SHOW_NECROMANCY
		html_text+=html_show(actions, [ALWAYS_AVAILABLE_BAR, NECROMANCY_DW, NECROMANCY_S])
	end
	
	# overwrite tracker.html
	html_file=File.open("tracker.html", "w")
	html_file.write(html_text)
	html_file.close

	# test ouput
	#text=""
	#actions.each do |action|
	#	text+="#{action}, "
	#end
	#puts text
end


# define the main code loop and call it
# listen for key board input
# update tracker.html whenever a relevent key is pressed
def main
	listener=Listener.new
	input=Array.new(TRACKER_SIZE,Action.new())
	last_key=""
	last_modifier=NONE
	loop_count=0

	while true
		key=listener.get_key
		modifier=listener.get_modifier
		break if key == "f12"

		# do not accept duplicate inputs
		if key != '' and !(key == last_key and modifier == last_modifier)

			#TODO remove getting action for only magic and ranged bars
			action=get_action(key,modifier,[ALWAYS_AVAILABLE_BAR, MAGIC_DW, MAGIC_S, RANGED_S])
			if action and !action.match_action(input.last)
				# remove the first element from the array
				input.shift()
				# place the most recent input at the end of the array
				input.push(action)
				# update the current action bars if necessary
				update_action_bars(action)
				# update the output file
				if (HTML_UPDATE_INTERVAL == 0)
					html_output(input)
				end
				#puts "#{key} #{modifier}"
			end
			last_key=key
			last_modifier=modifier
		end

		# update the html file 
		if (HTML_UPDATE_INTERVAL > 0) and (loop_count % HTML_UPDATE_INTERVAL == 0)
			html_output(input)
		end
		loop_count+=1

		sleep(0.001)
	end
end

main

#TODO
#coordinate-based actions for bar switching
#create actions with arrays of bars [MAGIC_S,MAGIC_2H] instead of integers MAGIC_S
