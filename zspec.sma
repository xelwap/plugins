/* READ PLEASE, i've removed the rendering (fun) function and replaced it with addtofullpack, 
so the ct team can't see the zspectators i didn't want to resend you a PM, so i thought i'd notify you here instead*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <basebuilder>
#include <fun>
#include <cstrike>
#include <hamsandwich>

new bool:Blocked[32], bool:ZSpecBanned[32], bool:ZSpectator[32]
new MaxPlayers, MsgSayText

public plugin_init() 
{
	register_plugin( "ZSpec", "1.0", "Nova")
	
	register_clcmd( "say /zspec", "ZSpec")
	register_clcmd( "say /zspecban", "ZSpec_BanMenu")
	
	register_concmd( "amx_zspec_ban", "ZSpec_Ban", ADMIN_KICK, "<name> - Bans a player from ZSpectating.")
	register_concmd( "amx_zspec_unban", "ZSpec_Unban", ADMIN_KICK, "<name> - Unbans a player from ZSpectating.")
	
	register_forward( FM_PlayerPreThink, "PlayerPreThink")
	register_forward( FM_AddToFullPack, "AddToFullPack", 1)
	register_logevent( "RoundStart", 2, "1=Round_Start")
	
	MsgSayText = get_user_msgid("SayText")
	MaxPlayers = get_maxplayers()
}

public RoundStart() 
{
	static Players[32], Num, Player, i
	get_players( Players, Num)
	for( i = 0; i < Num; i++)
	{
		Player = Players[i]
		Remove_ZSpec(Player)
	}
}

public bb_prepphase_started()
{
	static Players[32], Num, Player, i
	get_players( Players, Num) 
	for( i = 0; i < Num; i++)
	{
		Player = Players[i]
		Remove_ZSpec(Player)
	}
}

public bb_round_started()
{
	static Players[32], Num, Player, i
	get_players( Players, Num) 
	for( i = 0; i < Num; i++)
	{
		Player = Players[i]
		Remove_ZSpec(Player)
	}
}

public client_disconnect(id)
	Remove_ZSpec(id)

public bb_zombie_class_picked( id, class)
{
	new szName[32]
	get_user_name( id, szName, charsmax(szName))
	
	if(ZSpectator[id])
	{
		Remove_ZSpec(id)
		
		client_print_color( 0, "^3%s ^1is no longer ZSpectating.", szName)
	}
}

public PlayerPreThink(id)
{
	new Button = pev( id, pev_button)
    
	if(Blocked[id] && (Button & IN_ATTACK || Button & IN_ATTACK2))
		set_pev( id, pev_button, (Button & ~(IN_ATTACK | IN_ATTACK2)))
}

public AddToFullPack( es, e, Entity, Host, HostFlags, Player, pSet)
{
	if(Player)
	{
		if(ZSpectator[Entity] && is_user_alive(Entity) && is_user_alive(Host) && cs_get_user_team(Entity) == CS_TEAM_T && cs_get_user_team(Host) == CS_TEAM_CT)
		{
			set_es( es, ES_RenderMode, kRenderTransAdd );	
			set_es( es, ES_RenderAmt, 0 )
		}
	}
}

public ZSpec(id)
{
	new szName[32]
	get_user_name( id, szName, charsmax(szName))
	
	new CountAdmins = Count_Admins()
	
	if(ZSpecBanned[id])
	{
		client_print_color( id, "You cannot use this command due to being ^3Banned ^1from ZSpectating.")
		
		return PLUGIN_HANDLED
	}
	
	if(!bb_is_build_phase())
	{
		client_print_color( id, "You can only use this command in ^3Build Phase^1.")
		
		return PLUGIN_HANDLED
	}
	
	if(!is_user_alive(id))
	{
		client_print_color( id, "You have to be ^3Alive ^1in order to use this command.")
		
		return PLUGIN_HANDLED
	}
	
	if(!bb_is_user_zombie(id))
	{
		client_print_color( id, "You have to be a ^3Zombie ^1in order to use this command.")

		return PLUGIN_HANDLED
	}
	
	if(!CountAdmins)
	{
		client_print_color( id, "There has to be atleast^3 1 Admin Online ^1in order to use this command.")
		
		return PLUGIN_HANDLED
	}
			
	if(ZSpectator[id])
	{
		Remove_ZSpec(id)
		
		client_print_color( 0, "^3%s ^1is no longer ZSpectating.", szName)
	}
	
	else
	{
		ZSpectator[id] = true
		Blocked[id] = true
			
		set_user_noclip( id, 1)
		
		client_print_color( id, "^3%s ^1is now ZSpectating.", szName)
		client_print_color( id, "If you want to stop ZSpectating type ^3/zspec ^1again.")
	}

	return PLUGIN_HANDLED
}

public ZSpec_BanMenu(id)
{
	if(!is_user_admin(id))
	{
		client_print_color( id," You have to be ^3Admin ^1in order to use this command.")
		
		return PLUGIN_HANDLED
	}
	
	new Menu = menu_create( "\rZSpec By Nova^n\yBan/Unban Menu", "ZSpec_BanMenu_Handler")

	new szName[32], szFormatex[32], szID[6]
	static Players[32], Num, Player, i
	
	get_players( Players, Num)
	
	for( i = 0; i < Num; i++)
	{
		Player = Players[i]

		get_user_name( Player, szName, charsmax(szName))
		num_to_str( get_user_userid(Player), szID, charsmax(szID))
		
		if(ZSpecBanned[Player]) 
		{
			formatex( szFormatex, charsmax(szFormatex), "\yUnBan\w: %s", szName)
		} 
		
		else 
		{
			formatex( szFormatex, charsmax(szFormatex), "\rBan\w: %s", szName)
		}

		menu_additem( Menu, szFormatex, szID)
	}
			
	menu_display( id, Menu, 0)
	return PLUGIN_CONTINUE
}

public ZSpec_BanMenu_Handler( id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}

	new szData[6], szAdminName[32], szTargetName[32]
	new _access, item_callback
	menu_item_getinfo( Menu, Item, _access, szData, charsmax(szData), _, _, item_callback)

	new TargetID = str_to_num(szData)
	new Target = find_player( "k", TargetID)
	get_user_name( id, szAdminName, charsmax(szAdminName))
	get_user_name( Target, szTargetName, charsmax(szTargetName))
	
	if(ZSpecBanned[Target]) 
	{
		ZSpecBanned[Target] = false
		
		log_amx( "%s Unbanned %s from ZSpectating.", szAdminName, szTargetName)
	
		client_print_color( 0, "Admin ^3%s ^1Unbanned ^3%s ^1from ZSpectating.", szAdminName, szTargetName)
	
		client_print_color( id, "^3%s ^1is now Unbanned from ZSpectating", szTargetName)
		
	}
		
	else 
	{	
		ZSpecBanned[Target] = true
		
		log_amx( "%s Banned %s from ZSpectating.", szAdminName, szTargetName)
		
		client_print_color( 0, "Admin ^3%s ^1Banned ^3%s ^1from ZSpectating.", szAdminName, szTargetName)
		
		client_print_color( id, "^3%s ^1is now banned from ZSpectating", szTargetName)
		
		if(ZSpectator[Target])
			Remove_ZSpec(Target)
	}
	
	menu_destroy(Menu)
	return PLUGIN_HANDLED
}

public ZSpec_Ban( id, level, cid) 
{
	if (!cmd_access( id, level, cid, 2))
		return PLUGIN_HANDLED
		
	new Arg[32]
	read_argv( 1, Arg, charsmax(Arg))
	
	new Target = cmd_target( id, Arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF)
	
	new szAdminName[32],szTargetName[32]
	
	get_user_name( id, szAdminName, charsmax(szAdminName))
	get_user_name( Target, szTargetName, charsmax(szTargetName))
	
	if(!Target)
		return PLUGIN_HANDLED
	
	if(ZSpecBanned[Target])
	{
		console_print( id, "%s is already banned from ZSpectating", szTargetName)
		
		return PLUGIN_HANDLED
	}
	
	ZSpecBanned[Target] = true
	
	if(ZSpectator[Target])
	{
		Remove_ZSpec(Target)
	}
	
	log_amx( "%s Banned %s from ZSpectating.", szAdminName, szTargetName)
	
	client_print_color( 0, "Admin ^3%s ^1Banned ^3%s ^1from ZSpectating.", szAdminName, szTargetName)
	
	console_print( id, "%s is now banned from ZSpectating", szTargetName)
	
	return PLUGIN_HANDLED
	
}

public ZSpec_Unban( id, level, cid) 
{
	if (!cmd_access( id, level, cid, 2))
		return PLUGIN_HANDLED
		
	new Arg[32]
	
	read_argv( 1, Arg, charsmax(Arg))	
	
	new Target = cmd_target( id, Arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF)
	
	new szAdminName[32],szTargetName[32]
	get_user_name( id, szAdminName, charsmax(szAdminName))
	get_user_name( Target, szTargetName, charsmax(szTargetName))
	
	if(!Target)
		return PLUGIN_HANDLED
	
	if(!ZSpecBanned[Target])
	{
		console_print( id, "%s is not banned from ZSpectating", szTargetName)
		
		return PLUGIN_HANDLED
	}
	
	ZSpecBanned[Target] = false
	
	log_amx( "%s Unbanned %s from ZSpectating.", szAdminName, szTargetName)
	
	client_print_color( 0, "Admin ^3%s ^1Unbanned ^3%s ^1from ZSpectating.", szAdminName, szTargetName)
	
	console_print( id, "%s is now Unbanned from ZSpectating", szTargetName)
	
	return PLUGIN_HANDLED
}

public Remove_ZSpec(id)
{
	if(!ZSpectator[id])
		return PLUGIN_HANDLED
		
	if(bb_is_user_zombie(id))
	{
		ExecuteHamB( Ham_CS_RoundRespawn, id)
	}
		
	ZSpectator[id] = false
	Blocked[id] = false

	set_user_noclip(id)
	
	return PLUGIN_HANDLED
}

public Count_Admins()
{
	static id, count
	for(id = 1; id <= MaxPlayers; id++ )
	{
		if(is_user_connected(id) && is_user_admin(id))
		count++
	}
	
	return count
}

client_print_color( index, const Msg[], any:...) 
{
	new Buffer[190], Buffer2[192]
	formatex( Buffer2, charsmax(Buffer2), "^x03[ZSpec] ^x01%s", Msg)
	vformat( Buffer, charsmax(Buffer), Buffer2, 3)
	
	if(!index) 
	{
		for( new i = 1; i <= MaxPlayers; i++) 
		{
			if (!is_user_connected(i))
				continue
			
			message_begin( MSG_ONE_UNRELIABLE, MsgSayText, _, i)
			write_byte(i)
			write_string(Buffer)
			message_end()
		}
	}
	
	else 
	{
		if(!is_user_connected(index))
			return
		
		message_begin( MSG_ONE, MsgSayText, _, index)
		write_byte(index)
		write_string(Buffer)
		message_end()
	}
}
