/* ---------------------------------------------------

	-*- Include: [AP] Extra item: Bazooka -*-
	-*- Version: 1.0 -*-
	-*- Author: Vechta -*-
	
	-*- Website: https://forums.alliedmods.net/showthread.php?t=142539 -*-
	
-----------------------------------------------------*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <xs>
#include <bb_ammopacks>
#include <basebuilder>

#define SWITCH_TIME	0.5
#define TASK_SEEK_CATCH 9000
#define fm_is_valid_ent(%1) pev_valid(%1)

static const mrocket[] = "models/rpgrocket.mdl"
static const mrpg_w[] = "models/w_rpg.mdl"
static const mrpg_v[] = "models/v_rpg.mdl"
static const mrpg_p[] = "models/p_rpg.mdl"

static const sfire[] = "weapons/rocketfire1.wav"
static const sfly[] = "weapons/nuke_fly.wav"
static const shit[] = "weapons/mortarhit.wav"
static const spickup[] = "items/gunpickup2.wav"
static const reload[] = "items/9mmclip2.wav"

new pcvar_delay, pcvar_maxdmg, pcvar_radius, pcvar_speed,
	pcvar_dmgforpacks, pcvar_award, pcvar_speed_homing,
	pcvar_speed_camera, pcvar_cost

new rocketsmoke, white, explosion, bazsmoke

new dmgcount[33], user_controll[33], mode[33]

new bool:g_hasbazooka[33], Float:LastShoot[33]

new Float:lastSwitchTime[33]

new gmsg_screenshake, gmsg_death, gmsg_damage, gmsgBarTime

new Saytxt

public plugin_init() 
{
	register_plugin( "[AP] Extra item: Bazooka", "1.0", "Vechta")
	bb_shop_item_add( "Bazooka \r(Humans Only)", get_pcvar_num(pcvar_cost), "Bazooka_Handler")
	
	pcvar_cost = register_cvar( "ap_bazooka_cost", "200")
	pcvar_delay = register_cvar( "ap_bazooka_delay", "20")
	pcvar_maxdmg = register_cvar( "ap_bazooka_damage", "500")
	pcvar_radius = register_cvar( "ap_bazooka_radius", "250")
	pcvar_award = register_cvar( "ap_bazooka_awardpacks", "1")
	pcvar_speed = register_cvar( "ap_bazooka_speed", "800")
	pcvar_speed_homing = register_cvar( "ap_bazooka_homing_speed", "350")
	pcvar_speed_camera = register_cvar( "ap_bazooka_camera_speed", "300")
	
	register_logevent( "RoundStart", 2, "1=Round_Start")
	
	register_event( "CurWeapon","switch_to_knife","be")
	register_event( "HLTV", "event_HLTV", "a", "1=0", "2=0")
	register_event( "DeathMsg", "player_die", "a")
	
	register_clcmd( "drop", "drop_call")
	
	register_forward( FM_PlayerPreThink, "client_PreThink");
	register_forward( FM_Touch, "fw_touch");
	register_forward( FM_CmdStart, "fw_CmdStart")
	
	gmsg_screenshake = get_user_msgid("ScreenShake")
	gmsg_death = get_user_msgid("DeathMsg")
	gmsg_damage = get_user_msgid("Damage")
	Saytxt = get_user_msgid("SayText")
	gmsgBarTime = get_user_msgid( "BarTime" )
}

public plugin_cfg()
{
	new cfgdirecction[32]
	get_configsdir(cfgdirecction, sizeof cfgdirecction - 1);

	server_cmd("exec %s/ap_bazooka_modes.cfg", cfgdirecction)
}

public plugin_precache()
{
	precache_model(mrocket);        
 
	precache_model(mrpg_w);
	precache_model(mrpg_v);
	precache_model(mrpg_p);
 
	precache_sound(sfire);
	precache_sound(sfly);
	precache_sound(shit);
	precache_sound(spickup);
	precache_sound(reload);
        
	rocketsmoke = precache_model("sprites/smoke.spr");
	white = precache_model("sprites/white.spr");
	explosion = precache_model("sprites/fexplo.spr");
	bazsmoke  = precache_model("sprites/steam1.spr");
}

public RoundStart() 
{
	static Players[32], Num, Player, i
	get_players( Players, Num)
	for( i = 0; i < Num; i++)
	{
		Player = Players[i]
		g_hasbazooka[Player] = false
	}
}

public Bazooka_Handler(id)
{
	if(!bb_is_user_zombie(id))
	{
		bb_set_user_ap( id, bb_get_user_ap(id) + get_pcvar_num(pcvar_cost))
		
		bazooka_message(id, "^x04[AP] ^x01You need to be ^x04Human ^x01 in order to use this command.")
		
		return PLUGIN_HANDLED
	}
	
	if(g_hasbazooka[id])
	{
		bb_set_user_ap( id, get_pcvar_num(pcvar_cost))
		
		bazooka_message(id, "^x04[AP] ^x01You already bought this item.")
		
		return PLUGIN_HANDLED
	}
	
	g_hasbazooka[id] = true
	LastShoot[id] = 0.0
	emit_sound(id, CHAN_WEAPON, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	bazooka_message(id, "^x04[AP]^x01 You got a Bazooka! [Attack2: Change modes] [Reload:^x04 %2.1f^x01 seconds]", get_pcvar_float(pcvar_delay))
	
	return PLUGIN_HANDLED
}

public client_putinserver(id)
{
	mode[id] = 1
	g_hasbazooka[id] = false
	LastShoot[id] = 0.0
}

public switch_to_knife(id)
{
	if(!is_user_alive(id)) 
	return;
 
	if(g_hasbazooka[id])
	{
		if(get_user_weapon(id) == CSW_KNIFE)
		{
			set_pev( id, pev_viewmodel2, mrpg_v)
			set_pev( id, pev_weaponmodel2, mrpg_p)
		}
	}
}

fire_rocket(id) 
{
	if (!CanShoot(id) ) return;

	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	
	if (!pev_valid(ent) || !is_user_alive(id) )
		return;
 
	new data[1]
	data[0] = id
	LastShoot[id] = get_gametime();
	set_task(0.0 + get_pcvar_num(pcvar_delay), "rpg_reload", id);
	engclient_cmd(id, "weapon_knife");
 
	new Float:StartOrigin[3], Float:Angle[3];
	pev(id, pev_origin, StartOrigin);
	pev(id, pev_angles, Angle);
	
	set_pev(ent, pev_classname, "rpgrocket");
	engfunc(EngFunc_SetModel, ent, mrocket);
	set_pev(ent, pev_mins, {-1.0, -1.0, -1.0});
	set_pev(ent, pev_maxs, {1.0, 1.0, 1.0});
	engfunc(EngFunc_SetOrigin, ent, StartOrigin);
	set_pev(ent, pev_angles, Angle);

 
	set_pev(ent, pev_solid, 2);
	set_pev(ent, pev_movetype, 5);
	set_pev(ent, pev_owner, id);
 
	new Float:fAim[3],Float:fAngles[3],Float:fOrigin[3]
	velocity_by_aim(id,64,fAim)
	vector_to_angle(fAim,fAngles)
	pev(id,pev_origin,fOrigin)
        
	fOrigin[0] += fAim[0]
	fOrigin[1] += fAim[1]
	fOrigin[2] += fAim[2]
 
	new Float:nVelocity[3];
	if (mode[id] == 1)
		velocity_by_aim(id, get_pcvar_num(pcvar_speed), nVelocity);
	else if (mode[id] == 2)
		velocity_by_aim(id, get_pcvar_num(pcvar_speed_homing), nVelocity);
	else if (mode[id] == 3)
		velocity_by_aim(id, get_pcvar_num(pcvar_speed_camera), nVelocity);
		
	set_pev(ent, pev_velocity, nVelocity);
	entity_set_int(ent, EV_INT_effects, entity_get_int(ent, EV_INT_effects) | EF_BRIGHTLIGHT)

 
	emit_sound(ent, CHAN_WEAPON, sfire, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	emit_sound(ent, CHAN_VOICE, sfly, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
        
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(22);
	write_short(ent);
	write_short(rocketsmoke);
	write_byte(50);
	write_byte(3);
	write_byte(255);
	write_byte(255);
	write_byte(255);
	write_byte(255);
	message_end();

	if (mode[id] == 2) 
		set_task(0.5, "rpg_seek_follow", ent + TASK_SEEK_CATCH, _, _, "b");
	else if (mode[id] == 3) 
	{
		if (is_user_alive(id))
		{
			entity_set_int(ent, EV_INT_rendermode, 1)
			attach_view(id, ent)
			user_controll[id] = ent
		}
	} 
	launch_push(id, 130)
	Progress_status(id, get_pcvar_num(pcvar_delay))
}
 
public rpg_reload(id)
{
	if (!g_hasbazooka[id]) return;
	
	if ( get_user_weapon(id) == CSW_KNIFE ) switch_to_knife(id);
	{
		// CanShoot[id] = true
		client_print(id, print_center, "Bazooka reloaded!")
		emit_sound(id, CHAN_WEAPON, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
}
 
public fw_touch(ent, touched)
{
	if ( !pev_valid(ent) ) return FMRES_IGNORED;
	
	static entclass[32];
	pev(ent, pev_classname, entclass, 31);
	
	if ( equali(entclass, "rpg_temp") )
	{
		static touchclass[32];
		pev(touched, pev_classname, touchclass, 31);
		if ( !equali(touchclass, "player") ) return FMRES_IGNORED;
                
		if( !is_user_alive(touched) || bb_is_user_zombie(touched) ) return FMRES_IGNORED;
                        
		emit_sound(touched, CHAN_VOICE, spickup, 1.0, ATTN_NORM, 0, PITCH_NORM);
		g_hasbazooka[touched] = true;
		
		engfunc(EngFunc_RemoveEntity, ent);
        
		return FMRES_HANDLED;
	}
	else if ( equali(entclass, "rpgrocket") )
	{
		new Float:EndOrigin[3];
		pev(ent, pev_origin, EndOrigin);
		new NonFloatEndOrigin[3];
		NonFloatEndOrigin[0] = floatround(EndOrigin[0]);
		NonFloatEndOrigin[1] = floatround(EndOrigin[1]);
		NonFloatEndOrigin[2] = floatround(EndOrigin[2]);
	
		emit_sound(ent, CHAN_WEAPON, shit, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		emit_sound(ent, CHAN_VOICE, shit, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(17);
		write_coord(NonFloatEndOrigin[0]);
		write_coord(NonFloatEndOrigin[1]);
		write_coord(NonFloatEndOrigin[2] + 128);
		write_short(explosion);
		write_byte(60);
		write_byte(255);
		message_end();
	
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(5);
		write_coord(NonFloatEndOrigin[0]);
		write_coord(NonFloatEndOrigin[1]);
		write_coord(NonFloatEndOrigin[2] + 256);
		write_short(bazsmoke);
		write_byte(125);
		write_byte(5);
		message_end();
        
		new maxdamage = get_pcvar_num(pcvar_maxdmg);
		new damageradius = get_pcvar_num(pcvar_radius);
        
		new PlayerPos[3], distance, damage;
		for (new i = 1; i <= 32; i++) 
		{
			if ( is_user_alive(i)) 
			{       
				new id = pev(ent, pev_owner)
				
				if  ((bb_is_user_zombie(id)))
				if ((bb_is_user_zombie(i))) continue;
                                                
				if  ((!bb_is_user_zombie(id))) 
				if ((!bb_is_user_zombie(i))) continue;
                                                
				get_user_origin(i, PlayerPos);
                
				distance = get_distance(PlayerPos, NonFloatEndOrigin);
				
				if (distance <= damageradius)
				{ 
					message_begin(MSG_ONE, gmsg_screenshake, {0,0,0}, i);
					write_short(1<<14);
					write_short(1<<14);
					write_short(1<<14);
					message_end();
					
					damage = maxdamage - floatround(floatmul(float(maxdamage), floatdiv(float(distance), float(damageradius))));
					new attacker = pev(ent, pev_owner);
                
					baz_damage(i, attacker, damage, "bazooka");
				}
			}
		}
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(21);
		write_coord(NonFloatEndOrigin[0]);
		write_coord(NonFloatEndOrigin[1]);
		write_coord(NonFloatEndOrigin[2]);
		write_coord(NonFloatEndOrigin[0]);
		write_coord(NonFloatEndOrigin[1]);
		write_coord(NonFloatEndOrigin[2] + 320);
		write_short(white);
		write_byte(0);
		write_byte(0);
		write_byte(16);
		write_byte(128);
		write_byte(0);
		write_byte(255);
		write_byte(255);
		write_byte(192);
		write_byte(128);
		write_byte(0);
		message_end();
		
		attach_view(entity_get_edict(ent, EV_ENT_owner), entity_get_edict(ent, EV_ENT_owner))
		user_controll[entity_get_edict(ent, EV_ENT_owner)] = 0
		remove_entity(ent)
                
		return FMRES_HANDLED;
	}
	return FMRES_IGNORED;
}
 
public drop_call(id)
{
	if ( g_hasbazooka[id] && get_user_weapon(id) == CSW_KNIFE )
	{
		drop_rpg_temp(id);
		return PLUGIN_HANDLED; 
	}
	return PLUGIN_CONTINUE;
}
 
drop_rpg_temp(id) 
{
	new Float:fAim[3] , Float:fOrigin[3];
	velocity_by_aim(id , 64 , fAim);
	pev(id , pev_origin , fOrigin);
 
	fOrigin[0] += fAim[0];
	fOrigin[1] += fAim[1];
 
	new rpg = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
 
	set_pev(rpg, pev_classname, "rpg_temp");
	engfunc(EngFunc_SetModel, rpg, mrpg_w);
 
	set_pev(rpg, pev_mins, { -16.0, -16.0, -16.0 } );
	set_pev(rpg, pev_maxs, { 16.0, 16.0, 16.0 } );
 
	set_pev(rpg , pev_solid , 1);
	set_pev(rpg , pev_movetype , 6);
 
	engfunc(EngFunc_SetOrigin, rpg, fOrigin);
 
	g_hasbazooka[id] = false;
}
 
baz_damage(id, attacker, damage, weaponDescription[])
{
	if ( pev(id, pev_takedamage) == DAMAGE_NO ) return;
	if ( damage <= 0 ) return;
 
	new userHealth = get_user_health(id);
	
	if (userHealth - damage <= 0 ) 
	{
		dmgcount[attacker] += userHealth - damage;
		set_msg_block(gmsg_death, BLOCK_SET);
		ExecuteHamB(Ham_Killed, id, attacker, 2);
		set_msg_block(gmsg_death, BLOCK_NOT);
        
                
		message_begin(MSG_BROADCAST, gmsg_death);
		write_byte(attacker);
		write_byte(id);
		write_byte(0);
		write_string(weaponDescription);
		message_end();
                
		set_pev(attacker, pev_frags, float(get_user_frags(attacker) + 1));
                        
		new kname[32], vname[32], kauthid[32], vauthid[32], kteam[10], vteam[10];
        
		get_user_name(attacker, kname, 31);
		get_user_team(attacker, kteam, 9);
		get_user_authid(attacker, kauthid, 31);
         
		get_user_name(id, vname, 31);
		get_user_team(id, vteam, 9);
		get_user_authid(id, vauthid, 31);
                        
		log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"", 
		kname, get_user_userid(attacker), kauthid, kteam, 
		vname, get_user_userid(id), vauthid, vteam, weaponDescription);
	}
	else 
	{
		dmgcount[attacker] += damage;
		new origin[3];
		get_user_origin(id, origin);
                
		message_begin(MSG_ONE,gmsg_damage,{0,0,0},id);
		write_byte(21);
		write_byte(20);
		write_long(DMG_BLAST);
		write_coord(origin[0]);
		write_coord(origin[1]);
		write_coord(origin[2]);
		message_end();
                
		set_pev(id, pev_health, pev(id, pev_health) - float(damage));
	}
	if ( !get_pcvar_num(pcvar_award) ) return;
        
	new breaker = get_pcvar_num(pcvar_dmgforpacks);
	
	if ( dmgcount[attacker] > breaker )
	{
		new temp = dmgcount[attacker] / breaker
		if ( temp * breaker > dmgcount[attacker] ) return; //should never be possible
		dmgcount[attacker] -= temp * breaker;
		bb_set_user_ap( attacker, bb_get_user_ap(attacker) + temp )
	}
}
 
public rpg_seek_follow(ent) 
{
	ent -= TASK_SEEK_CATCH
        
	new Float: shortest_distance = 500.0;
	new NearestPlayer = 0;
 
	if (pev_valid(ent)) 
	{
		static entclass[32];
		pev(ent, pev_classname, entclass, 31); 

		if ( equali(entclass, "rpgrocket") )
		{
			new id_owner = pev(ent, pev_owner)
			new iClient[32], livePlayers, iNum;
			get_players(iClient, livePlayers, "a"); 
	 
			for(iNum = 0; iNum < livePlayers; iNum++) 
			{ 
				if ( is_user_alive(iClient[iNum]) && pev_valid(ent) ) 
				{
					if ( id_owner != iClient[iNum] && bb_is_user_zombie(iClient[iNum]) )
					{
						new Float:PlayerOrigin[3], Float:RocketOrigin[3]
						pev(ent, pev_origin, RocketOrigin)
						pev(iClient[iNum], pev_origin, PlayerOrigin)
					
						new Float: distance = get_distance_f(PlayerOrigin, RocketOrigin)
						
						if ( distance <= shortest_distance )
						{
							shortest_distance = distance;
							NearestPlayer = iClient[iNum];
						}
					}
				}
			}
			if (NearestPlayer > 0) 
			{
				entity_set_follow(ent, NearestPlayer, 250.0)
			}
		}
	}
}
 
stock entity_set_follow(entity, target, Float:speed) 
{
	if(!fm_is_valid_ent(entity) || !fm_is_valid_ent(target)) 
		return 0

	new Float:entity_origin[3], Float:target_origin[3]
	pev(entity, pev_origin, entity_origin)
	pev(target, pev_origin, target_origin)

	new Float:diff[3]
	diff[0] = target_origin[0] - entity_origin[0]
	diff[1] = target_origin[1] - entity_origin[1]
	diff[2] = target_origin[2] - entity_origin[2]
 
	new Float:length = floatsqroot(floatpower(diff[0], 2.0) + floatpower(diff[1], 2.0) + floatpower(diff[2], 2.0))
 
       	new Float:velocity[3]
	velocity[0] = diff[0] * (speed / length)
	velocity[1] = diff[1] * (speed / length)
	velocity[2] = diff[2] * (speed / length)
 
	set_pev(entity, pev_velocity, velocity)

	return 1
}

public fw_CmdStart(id, UC_Handle, Seed)
{
	if(!is_user_alive(id) || !g_hasbazooka[id]) return 
                
	static Button, OldButton
	OldButton = get_user_oldbutton(id)
                
	Button = get_uc(UC_Handle, UC_Buttons)
        
	if (Button & IN_ATTACK)
	{
		if (!CanShoot(id) || (OldButton & IN_ATTACK2)) return;
        
		if ( get_user_weapon(id) == CSW_KNIFE ) 
			fire_rocket(id); 
	}
	else if (Button & IN_ATTACK2 && get_user_weapon(id) == CSW_KNIFE) 
	{
		if ( get_gametime ( ) - lastSwitchTime [ id ] < SWITCH_TIME || (OldButton & IN_ATTACK2)) return
		
		if (is_user_alive(id))
		{
			switch(mode[id]) 
			{
				case 1:
				{
					mode[id] = 2
					emit_sound(id, CHAN_ITEM, "common/wpn_select.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
					client_print(id, print_center, "Homing fire mode")
				}
				case 2:
				{
					mode[id] = 3
					emit_sound(id, CHAN_ITEM, "common/wpn_select.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
					client_print(id, print_center, "Camera fire mode")
				}
				case 3:
				{
					mode[id] = 1
					emit_sound(id, CHAN_ITEM, "common/wpn_select.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
					client_print(id, print_center, "Normal fire mode")
				}		
			}	
			lastSwitchTime [ id ] = get_gametime ( )
		}
	}
	else if (user_controll[id]) 
	{
		new RocketEnt = user_controll[id]
			
		if (is_valid_ent(RocketEnt)) 
		{
			new Float:Velocity[3]
			VelocityByAim(id, 500, Velocity)
			entity_set_vector(RocketEnt, EV_VEC_velocity, Velocity)
				
			new Float:NewAngle[3]
			entity_get_vector(id, EV_VEC_v_angle, NewAngle)
			entity_set_vector(RocketEnt, EV_VEC_angles, NewAngle)
		}
		else 
		{
			attach_view(id, id)
		}
	}
}

public client_connect(id)
	g_hasbazooka[id] = false

stock launch_push(id, velamount)
{
	static Float:flNewVelocity[3], Float:flCurrentVelocity[3]
	
	velocity_by_aim(id, -velamount, flNewVelocity)
	
	get_user_velocity(id, flCurrentVelocity)
	xs_vec_add(flNewVelocity, flCurrentVelocity, flNewVelocity)
	
	set_user_velocity(id, flNewVelocity)
}

stock bazooka_message(const id, const input[], any:...)
{
	new count = 1, players[32]
	
	static msg[191]
	vformat(msg,190,input,3)
	
	replace_all(msg,190,"/g","^4")
	replace_all(msg,190,"/y","^1")
	replace_all(msg,190,"/ctr","^3")
	
	if (id) players[0] = id; else get_players(players,count,"ch")
	
	for (new i = 0; i < count; i++)
		if (is_user_connected(players[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, Saytxt, _, players[i])
			write_byte(players[i])
			write_string(msg)
			message_end()
		}
}

public Progress_status( const id, const duration )
{
	message_begin( MSG_ONE, gmsgBarTime, _, id )
	write_short( duration )
	message_end()
}

public player_die() {

	new id = read_data(2)
	
	if ( g_hasbazooka[id] )
		drop_rpg_temp(id)

	return PLUGIN_CONTINUE
}

public CanShoot(id)
{
	return get_gametime() - LastShoot[id] >= get_pcvar_float(pcvar_delay)
}
