/* ------------------------------------------- 

    -*- Plugin: [BB] Addon: Ammo-Pack -*- 
    -*- Version: 1.0 -*- 
    -*- Author: crnova -*- 
     
    (c) 2016 - crnova
     
 ---------------------------------------------*/ 

#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <nvault>

enum _:ItemData
{
    ItemName[32],
    ItemCost,
    ItemPlugin,
    ItemFuncID
}

new Array:g_aItems
new g_iTotalItems
new g_Vault
new g_szAuthID[33][35]
new g_pExpireDays
new g_AP[33]

public plugin_init()
{
    register_plugin( "[BB] Addon: Ammo-Pack", "1.0", "crnova")
    
    register_clcmd( "say /shop", "clcmd_shop")
    register_clcmd( "say /ap", "clcmd_checkap")
    
    g_aItems = ArrayCreate(ItemData)
    g_pExpireDays = register_cvar( "cvar_expiredays" , "15")
}

public plugin_cfg()
{
    g_Vault = nvault_open("yourvault")

    if(g_Vault == INVALID_HANDLE)
        set_fail_state("Error opening nVault")

    nvault_prune( g_Vault, 0, get_systime() - (86400 * get_pcvar_num(g_pExpireDays)))
}

public plugin_end()
{
    nvault_close(g_Vault)
}

public plugin_natives()
{
    register_library("bb_ammopacks")
    
    register_native( "bb_get_user_ap", "_get_user_ap")
	register_native( "bb_set_user_ap", "_set_user_ap")
    register_native( "shop_item_add", "_item_add")
}

public clcmd_shop(id)
{
    if(!is_user_alive(id))
        return PLUGIN_HANDLED
        
     ShowShopMenu( id, .iPage = 0 )
     
     return PLUGIN_CONTINUE
}

ShowShopMenu( id, iPage)
{
    if(!g_iTotalItems)
    {
        return
    }
    
    iPage = clamp( iPage, 0, (g_iTotalItems - 1) / 7)
    
    new hMenu = menu_create( "Shop Menu", "MenuShop")
    
    new eItemData[ItemData]
    new szItem[64]
    
    new szNum[3]
    
    for(new i = 0; i < g_iTotalItems; i++)
    {
        ArrayGetArray( g_aItems, i, eItemData)
        
        formatex( szItem, charsmax( szItem ), "%s \y%i AmmoPacks", eItemData[ItemName], eItemData[ItemCost])
        
        num_to_str( i, szNum, charsmax(szNum))
        
        menu_additem( hMenu, szItem, szNum)
    }
    
    menu_display( id, hMenu, iPage)
}

public MenuShop( id, hMenu, iItem)
{
    if( iItem == MENU_EXIT )
    {
        menu_destroy( hMenu)
        return
    }
    
    new iAccess, szNum[ 3 ], hCallback
    menu_item_getinfo( hMenu, iItem, iAccess, szNum, charsmax(szNum), _, _, hCallback)
    menu_destroy(hMenu)
    
    new iItemIndex = str_to_num(szNum)
    
    new eItemData[ItemData]
    ArrayGetArray( g_aItems, iItemIndex, eItemData)
    
    new iAP = bb_get_user_ap(id) - eItemData[ ItemCost ];
    
    if( iAP < 0 )
    {
        client_print( id, print_chat, "* You need $%i more to buy this item!", (iAP * -1))
    }
    else
    {
        bb_set_user_ap( id, iAP)
        
        callfunc_begin_i( eItemData[ItemFuncID], eItemData[ItemPlugin])
        callfunc_push_int(id)
        callfunc_end()
    }
    
    ShowShopMenu( id, .iPage = (iItemIndex / 7))
}

public client_authorized(id)
{
    get_user_authid( id, g_szAuthID[id], charsmax(g_szAuthID[]))
}

public client_putinserver(id)
    load_ap(id)
    
public client_disconnect(id)
    save_ap(id)

public _item_add( iPlugin, iParams )
{
    new eItemData[ItemData]
    
    get_string( 1, eItemData[ItemName], charsmax(eItemData[ItemName]))
    
    eItemData[ItemCost] = get_param(2)
    
    eItemData[ItemPlugin] = iPlugin
    
    new szHandler[32]
    get_string( 3, szHandler, charsmax(szHandler))
    eItemData[ItemFuncID] = get_func_id(szHandler, iPlugin)
    
    ArrayPushArray( g_aItems, eItemData)
    g_iTotalItems++
    
    return (g_iTotalItems - 1)
}

public save_ap(id)
{
    new szAP[7]
    new szKey[40]

    formatex( szKey, charsmax(szKey), "%sAMMOPACK", g_szAuthID[id])
    formatex( szAP, charsmax(szAP), "%d", bb_get_user_ap(id))
    
    nvault_set( g_Vault, szKey, szAP)
}

public load_ap(id)
{
    new szKey[40]
    formatex( szKey, charsmax(szKey), "%sAMMOPACK", g_szAuthID[id])
    new iAP = nvault_get( g_Vault, szKey)
    if(iAP)
    {
        bb_set_user_ap( id, iAP)
        nvault_remove( g_Vault, szKey)
    }
}

public native_get_user_points(id)
{
	return g_AP[id]
}

// Native: surf_set_user_points
public native_set_user_points(id, amount)
{
	g_AP[id] = amount
}
