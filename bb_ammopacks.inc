#if defined _bb_ammopacks_included
    #endinput
#endif

#define _bb_ammopacks_included

#if AMXX_VERSION_NUM >= 175
    #pragma reqlib bb_ammopacks
    #if !defined AMXMODX_NOAUTOLOAD
        #pragma loadlib bb_ammopacks
    #endif
#else
    #pragma library bb_ammopacks
#endif

native shop_item_add( const szName[], const iCost, const szHandler[])

native bb_get_user_ap(index)

native bb_set_user_ap(index, amount)
