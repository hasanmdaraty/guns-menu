/*
    Spawn Guns HUD Menu - INI Version
    Author: Hasan

    Config file:
    addons/amxmodx/configs/alarab_guns.ini

    Reload command:
    reguns
*/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>

#define PLUGIN  "Spawn Guns HUD Menu"
#define VERSION "1.2"
#define AUTHOR  "Hasan"

#define TASK_MENU 5000
#define TASK_CLOSE 6000

#define MAX_LINES 6

new g_iChoice[33]
new bool:g_bAutoSave[33]
new bool:g_bMenuOpen[33]
new bool:g_bBlockedMap
new g_pCsdmActive

new g_szConfigFile[128]

new g_szTitle[64]
new g_szAkName[32]
new g_szM4Name[32]
new g_szAwpName[32]
new g_szSaveText[64]
new g_szExitText[32]
new g_szChatPrefix[32]
new g_szBlockedMsg[96]
new g_szAutoOnMsg[96]
new g_szAutoOffMsg[96]

new Float:g_fHudX
new Float:g_fHudY[MAX_LINES]
new Float:g_fMenuTime
new Float:g_fSpawnDelay
new Float:g_fRefreshTime

new g_iColor[MAX_LINES][3]

new bool:g_bDefaultAutoSave
new bool:g_bEnableSpawnMenu
new bool:g_bDisableOnCsdm
new bool:g_bEnableHE
new bool:g_bEnableDefuse
new bool:g_bEnableFlash
new bool:g_bEnableSmoke
new g_iArmor
new g_iAkAmmo
new g_iM4Ammo
new g_iAwpAmmo
new g_iDeagleAmmo

new g_szBlockedPrefixes[128]

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)

    register_clcmd("say /guns", "cmd_guns")
    register_clcmd("say_team /guns", "cmd_guns")
    register_clcmd("guns", "cmd_guns")

    register_concmd("reguns", "cmd_reload_guns", ADMIN_RCON, "- reload Spawn Guns HUD Menu settings")

    register_menucmd(register_menuid("Primary Weapon Menu"), 1023, "menu_handler")

    g_pCsdmActive = get_cvar_pointer("csdm_active")

    build_config_path()
    load_guns_config()
    check_blocked_map()
}

public client_putinserver(id)
{
    g_iChoice[id] = 0
    g_bAutoSave[id] = g_bDefaultAutoSave
    g_bMenuOpen[id] = false
}

public client_disconnected(id)
{
    remove_task(id)
    remove_task(id + TASK_MENU)
    remove_task(id + TASK_CLOSE)
}

public cmd_reload_guns(id, level, cid)
{
    if (!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED

    load_guns_config()
    check_blocked_map()

    console_print(id, "[Spawn Guns] Settings reloaded from spawn_guns_hud.ini")
    client_print_color(0, print_team_default, "^4%s^1 Guns menu settings reloaded.", g_szChatPrefix)

    return PLUGIN_HANDLED
}

public fw_PlayerSpawn_Post(id)
{
    if (!g_bEnableSpawnMenu || !is_user_alive(id) || is_blocked())
        return

    set_task(g_fSpawnDelay, "task_spawn_menu", id)
}

public task_spawn_menu(id)
{
    if (!is_user_alive(id) || is_blocked())
        return

    if (g_bAutoSave[id])
    {
        if (g_iChoice[id] > 0)
            give_loadout(id, g_iChoice[id])

        return
    }

    show_guns_menu(id)
}

public cmd_guns(id)
{
    if (!is_user_alive(id))
        return PLUGIN_HANDLED

    if (is_blocked())
    {
        client_print_color(id, print_team_default, "^4%s^1 %s", g_szChatPrefix, g_szBlockedMsg)
        return PLUGIN_HANDLED
    }

    show_guns_menu(id)
    return PLUGIN_HANDLED
}

show_guns_menu(id)
{
    g_bMenuOpen[id] = true

    show_menu(id, MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_0, "^n", floatround(g_fMenuTime), "Primary Weapon Menu")

    remove_task(id + TASK_MENU)
    remove_task(id + TASK_CLOSE)

    set_task(g_fRefreshTime, "task_draw_hud_menu", id + TASK_MENU, _, _, "b")
    set_task(g_fMenuTime, "task_close_hud_menu", id + TASK_CLOSE)
}

public task_close_hud_menu(taskid)
{
    new id = taskid - TASK_CLOSE

    g_bMenuOpen[id] = false
    remove_task(id + TASK_MENU)
}

public task_draw_hud_menu(taskid)
{
    new id = taskid - TASK_MENU

    if (!is_user_alive(id) || !g_bMenuOpen[id])
    {
        remove_task(taskid)
        return
    }

    set_dhudmessage(g_iColor[0][0], g_iColor[0][1], g_iColor[0][2], g_fHudX, g_fHudY[0], 0, 0.0, 1.0, 0.0, 0.0)
    show_dhudmessage(id, g_szTitle)

    set_dhudmessage(g_iColor[1][0], g_iColor[1][1], g_iColor[1][2], g_fHudX, g_fHudY[1], 0, 0.0, 1.0, 0.0, 0.0)
    show_dhudmessage(id, "[1] %s", g_szAkName)

    set_dhudmessage(g_iColor[2][0], g_iColor[2][1], g_iColor[2][2], g_fHudX, g_fHudY[2], 0, 0.0, 1.0, 0.0, 0.0)
    show_dhudmessage(id, "[2] %s", g_szM4Name)

    set_dhudmessage(g_iColor[3][0], g_iColor[3][1], g_iColor[3][2], g_fHudX, g_fHudY[3], 0, 0.0, 1.0, 0.0, 0.0)
    show_dhudmessage(id, "[3] %s", g_szAwpName)

    set_dhudmessage(g_iColor[4][0], g_iColor[4][1], g_iColor[4][2], g_fHudX, g_fHudY[4], 0, 0.0, 1.0, 0.0, 0.0)
    show_dhudmessage(id, "[4] %s: %s", g_szSaveText, g_bAutoSave[id] ? "ON" : "OFF")

    set_dhudmessage(g_iColor[5][0], g_iColor[5][1], g_iColor[5][2], g_fHudX, g_fHudY[5], 0, 0.0, 1.0, 0.0, 0.0)
    show_dhudmessage(id, "[0] %s", g_szExitText)
}

public menu_handler(id, key)
{
    if (!is_user_alive(id) || is_blocked())
        return PLUGIN_HANDLED

    switch (key)
    {
        case 0:
        {
            close_menu(id)
            g_iChoice[id] = 1
            give_loadout(id, 1)
        }
        case 1:
        {
            close_menu(id)
            g_iChoice[id] = 2
            give_loadout(id, 2)
        }
        case 2:
        {
            close_menu(id)
            g_iChoice[id] = 3
            give_loadout(id, 3)
        }
        
        case 3:
{
    g_bAutoSave[id] = !g_bAutoSave[id]

    if (g_bAutoSave[id])
        client_print_color(id, print_team_default, "^4%s^1 Menu disabled. Use /guns if you want to open it again.")
    else
        client_print_color(id, print_team_default, "^4%s^1 Menu enabled again.")

    show_guns_menu(id)
}

        case 9:
        {
            close_menu(id)
        }
    }

    return PLUGIN_HANDLED
}

close_menu(id)
{
    g_bMenuOpen[id] = false
    remove_task(id + TASK_MENU)
    remove_task(id + TASK_CLOSE)
}

give_loadout(id, choice)
{
    new CsTeams:team = cs_get_user_team(id)

    strip_loadout_keep_c4(id)

    if (!user_has_weapon(id, CSW_KNIFE))
        give_item(id, "weapon_knife")

    switch (choice)
    {
        case 1:
        {
            give_item(id, "weapon_ak47")
            cs_set_user_bpammo(id, CSW_AK47, g_iAkAmmo)
        }
        case 2:
        {
            give_item(id, "weapon_m4a1")
            cs_set_user_bpammo(id, CSW_M4A1, g_iM4Ammo)
        }
        case 3:
        {
            give_item(id, "weapon_awp")
            cs_set_user_bpammo(id, CSW_AWP, g_iAwpAmmo)
        }
    }

    give_item(id, "weapon_deagle")
    cs_set_user_bpammo(id, CSW_DEAGLE, g_iDeagleAmmo)

    if (g_bEnableHE)
        give_item(id, "weapon_hegrenade")

    if (g_bEnableFlash)
    {
        give_item(id, "weapon_flashbang")
        give_item(id, "weapon_flashbang")
    }

    if (g_bEnableSmoke)
        give_item(id, "weapon_smokegrenade")

    if (g_iArmor > 0)
        cs_set_user_armor(id, g_iArmor, CS_ARMOR_VESTHELM)

    if (g_bEnableDefuse && team == CS_TEAM_CT)
        cs_set_user_defuse(id, 1)
}

stock strip_loadout_keep_c4(id)
{
    static const weapons[][] = {
        "weapon_ak47","weapon_m4a1","weapon_awp","weapon_deagle",
        "weapon_hegrenade","weapon_flashbang","weapon_smokegrenade",
        "weapon_glock18","weapon_usp","weapon_p228","weapon_elite",
        "weapon_fiveseven","weapon_mp5navy","weapon_tmp","weapon_p90",
        "weapon_mac10","weapon_ump45","weapon_galil","weapon_famas",
        "weapon_aug","weapon_sg552","weapon_scout","weapon_sg550",
        "weapon_g3sg1","weapon_m249","weapon_m3","weapon_xm1014"
    }

    for (new i = 0; i < sizeof weapons; i++)
        ham_strip_weapon(id, weapons[i])
}

stock ham_strip_weapon(id, weapon[])
{
    new weaponid = get_weaponid(weapon)
    if (!weaponid)
        return 0

    new ent = -1

    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", weapon)))
    {
        if (pev(ent, pev_owner) == id)
            break
    }

    if (!ent)
        return 0

    if (get_user_weapon(id) == weaponid)
        ExecuteHamB(Ham_Weapon_RetireWeapon, ent)

    if (!ExecuteHamB(Ham_RemovePlayerItem, id, ent))
        return 0

    ExecuteHamB(Ham_Item_Kill, ent)

    set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1 << weaponid))

    return 1
}

bool:is_blocked()
{
    if (g_bBlockedMap)
        return true

    if (g_bDisableOnCsdm && g_pCsdmActive && get_pcvar_num(g_pCsdmActive) == 1)
        return true

    return false
}

build_config_path()
{
    new configsDir[64]
    get_configsdir(configsDir, charsmax(configsDir))
    formatex(g_szConfigFile, charsmax(g_szConfigFile), "%s/alarab_guns.ini", configsDir)
}

set_default_config()
{
    copy(g_szTitle, charsmax(g_szTitle), "★ Server Alarab ★")
    copy(g_szAkName, charsmax(g_szAkName), "A.K.47")
    copy(g_szM4Name, charsmax(g_szM4Name), "M.4.A.1")
    copy(g_szAwpName, charsmax(g_szAwpName), "A.W.P")
    copy(g_szSaveText, charsmax(g_szSaveText), "Save Last Choice")
    copy(g_szExitText, charsmax(g_szExitText), "Exit")
    copy(g_szChatPrefix, charsmax(g_szChatPrefix), "[Server Alarab]")
    copy(g_szBlockedMsg, charsmax(g_szBlockedMsg), "Menu is disabled on this map.")
    copy(g_szAutoOnMsg, charsmax(g_szAutoOnMsg), "Auto equip enabled.")
    copy(g_szAutoOffMsg, charsmax(g_szAutoOffMsg), "Auto equip disabled.")

    g_fHudX = 0.03
    g_fHudY[0] = 0.38
    g_fHudY[1] = 0.43
    g_fHudY[2] = 0.47
    g_fHudY[3] = 0.51
    g_fHudY[4] = 0.55
    g_fHudY[5] = 0.60

    g_fMenuTime = 15.0
    g_fSpawnDelay = 0.3
    g_fRefreshTime = 0.1

    g_iColor[0][0] = 0
    g_iColor[0][1] = 255
    g_iColor[0][2] = 0

    g_iColor[1][0] = 255
    g_iColor[1][1] = 0
    g_iColor[1][2] = 0

    g_iColor[2][0] = 0
    g_iColor[2][1] = 60
    g_iColor[2][2] = 180

    g_iColor[3][0] = 160
    g_iColor[3][1] = 0
    g_iColor[3][2] = 200

    g_iColor[4][0] = 0
    g_iColor[4][1] = 255
    g_iColor[4][2] = 0

    g_iColor[5][0] = 150
    g_iColor[5][1] = 0
    g_iColor[5][2] = 0

    g_bDefaultAutoSave = false
    g_bEnableSpawnMenu = true
    g_bDisableOnCsdm = true
    g_bEnableHE = true
    g_bEnableDefuse = true
    g_bEnableFlash = true
    g_bEnableSmoke = true

    g_iArmor = 100
    g_iAkAmmo = 90
    g_iM4Ammo = 90
    g_iAwpAmmo = 30
    g_iDeagleAmmo = 35

    copy(g_szBlockedPrefixes, charsmax(g_szBlockedPrefixes), "awp_,aim_")
}

load_guns_config()
{
    set_default_config()

    if (!file_exists(g_szConfigFile))
    {
        create_default_config_file()
        return
    }

    new fp = fopen(g_szConfigFile, "rt")
    if (!fp)
        return

    new line[192], key[64], value[128], pos

    while (!feof(fp))
    {
        fgets(fp, line, charsmax(line))
        trim(line)

        if (!line[0] || line[0] == ';' || line[0] == '#')
            continue

        pos = contain(line, "=")
        if (pos == -1)
            continue

        line[pos] = 0
        copy(key, charsmax(key), line)
        copy(value, charsmax(value), line[pos + 1])
        trim(key)
        trim(value)

        apply_config_value(key, value)
    }

    fclose(fp)
}

apply_config_value(const key[], const value[])
{
    if (equali(key, "TITLE")) copy(g_szTitle, charsmax(g_szTitle), value)
    else if (equali(key, "AK47_NAME")) copy(g_szAkName, charsmax(g_szAkName), value)
    else if (equali(key, "M4A1_NAME")) copy(g_szM4Name, charsmax(g_szM4Name), value)
    else if (equali(key, "AWP_NAME")) copy(g_szAwpName, charsmax(g_szAwpName), value)
    else if (equali(key, "SAVE_TEXT")) copy(g_szSaveText, charsmax(g_szSaveText), value)
    else if (equali(key, "EXIT_TEXT")) copy(g_szExitText, charsmax(g_szExitText), value)
    else if (equali(key, "CHAT_PREFIX")) copy(g_szChatPrefix, charsmax(g_szChatPrefix), value)
    else if (equali(key, "BLOCKED_MESSAGE")) copy(g_szBlockedMsg, charsmax(g_szBlockedMsg), value)
    else if (equali(key, "AUTO_ON_MESSAGE")) copy(g_szAutoOnMsg, charsmax(g_szAutoOnMsg), value)
    else if (equali(key, "AUTO_OFF_MESSAGE")) copy(g_szAutoOffMsg, charsmax(g_szAutoOffMsg), value)

    else if (equali(key, "HUD_X")) g_fHudX = str_to_float(value)
    else if (equali(key, "TITLE_Y")) g_fHudY[0] = str_to_float(value)
    else if (equali(key, "AK47_Y")) g_fHudY[1] = str_to_float(value)
    else if (equali(key, "M4A1_Y")) g_fHudY[2] = str_to_float(value)
    else if (equali(key, "AWP_Y")) g_fHudY[3] = str_to_float(value)
    else if (equali(key, "SAVE_Y")) g_fHudY[4] = str_to_float(value)
    else if (equali(key, "EXIT_Y")) g_fHudY[5] = str_to_float(value)

    else if (equali(key, "MENU_TIME")) g_fMenuTime = str_to_float(value)
    else if (equali(key, "SPAWN_DELAY")) g_fSpawnDelay = str_to_float(value)
    else if (equali(key, "REFRESH_TIME")) g_fRefreshTime = str_to_float(value)

    else if (equali(key, "TITLE_COLOR")) parse_color(value, 0)
    else if (equali(key, "AK47_COLOR")) parse_color(value, 1)
    else if (equali(key, "M4A1_COLOR")) parse_color(value, 2)
    else if (equali(key, "AWP_COLOR")) parse_color(value, 3)
    else if (equali(key, "SAVE_COLOR")) parse_color(value, 4)
    else if (equali(key, "EXIT_COLOR")) parse_color(value, 5)

    else if (equali(key, "DEFAULT_AUTOSAVE")) g_bDefaultAutoSave = bool:clamp(str_to_num(value), 0, 1)
    else if (equali(key, "ENABLE_SPAWN_MENU")) g_bEnableSpawnMenu = bool:clamp(str_to_num(value), 0, 1)
    else if (equali(key, "DISABLE_ON_CSDM")) g_bDisableOnCsdm = bool:clamp(str_to_num(value), 0, 1)
    else if (equali(key, "ENABLE_HE")) g_bEnableHE = bool:clamp(str_to_num(value), 0, 1)
    else if (equali(key, "ENABLE_DEFUSE")) g_bEnableDefuse = bool:clamp(str_to_num(value), 0, 1)
    else if (equali(key, "ENABLE_FLASH")) g_bEnableFlash = bool:clamp(str_to_num(value), 0, 1)
    else if (equali(key, "ENABLE_SMOKE")) g_bEnableSmoke = bool:clamp(str_to_num(value), 0, 1)

    else if (equali(key, "ARMOR")) g_iArmor = str_to_num(value)
    else if (equali(key, "AK47_AMMO")) g_iAkAmmo = str_to_num(value)
    else if (equali(key, "M4A1_AMMO")) g_iM4Ammo = str_to_num(value)
    else if (equali(key, "AWP_AMMO")) g_iAwpAmmo = str_to_num(value)
    else if (equali(key, "DEAGLE_AMMO")) g_iDeagleAmmo = str_to_num(value)

    else if (equali(key, "BLOCKED_MAP_PREFIXES")) copy(g_szBlockedPrefixes, charsmax(g_szBlockedPrefixes), value)
}

parse_color(const value[], line)
{
    new r[8], g[8], b[8]
    parse(value, r, charsmax(r), g, charsmax(g), b, charsmax(b))

    g_iColor[line][0] = clamp(str_to_num(r), 0, 255)
    g_iColor[line][1] = clamp(str_to_num(g), 0, 255)
    g_iColor[line][2] = clamp(str_to_num(b), 0, 255)
}

check_blocked_map()
{
    g_bBlockedMap = false

    new map[32]
    get_mapname(map, charsmax(map))
    strtolower(map)

    new prefixes[128], prefix[32]
    copy(prefixes, charsmax(prefixes), g_szBlockedPrefixes)

    while (prefixes[0])
    {
        strtok(prefixes, prefix, charsmax(prefix), prefixes, charsmax(prefixes), ',')
        trim(prefix)
        trim(prefixes)
        strtolower(prefix)

        if (prefix[0] && equal(map, prefix, strlen(prefix)))
        {
            g_bBlockedMap = true
            return
        }
    }
}

create_default_config_file()
{
    new fp = fopen(g_szConfigFile, "wt")
    if (!fp)
        return

    fprintf(fp, "; Spawn Guns HUD Menu Settings^n")
    fprintf(fp, "; Command to reload without map change: reguns^n^n")

    fprintf(fp, "[HUD]^n")
    fprintf(fp, "TITLE = ★ Server Alarab ★^n")
    fprintf(fp, "HUD_X = 0.03^n")
    fprintf(fp, "TITLE_Y = 0.38^n")
    fprintf(fp, "AK47_Y = 0.43^n")
    fprintf(fp, "M4A1_Y = 0.47^n")
    fprintf(fp, "AWP_Y = 0.51^n")
    fprintf(fp, "SAVE_Y = 0.55^n")
    fprintf(fp, "EXIT_Y = 0.60^n^n")

    fprintf(fp, "[COLORS]^n")
    fprintf(fp, "TITLE_COLOR = 0 255 0^n")
    fprintf(fp, "AK47_COLOR = 255 0 0^n")
    fprintf(fp, "M4A1_COLOR = 0 60 180^n")
    fprintf(fp, "AWP_COLOR = 160 0 200^n")
    fprintf(fp, "SAVE_COLOR = 0 255 0^n")
    fprintf(fp, "EXIT_COLOR = 150 0 0^n^n")

    fprintf(fp, "[TEXT]^n")
    fprintf(fp, "AK47_NAME = A.K.47^n")
    fprintf(fp, "M4A1_NAME = M.4.A.1^n")
    fprintf(fp, "AWP_NAME = A.W.P^n")
    fprintf(fp, "SAVE_TEXT = Save Last Choice^n")
    fprintf(fp, "EXIT_TEXT = Exit^n")
    fprintf(fp, "CHAT_PREFIX = [Server Alarab]^n")
    fprintf(fp, "BLOCKED_MESSAGE = Menu is disabled on this map.^n")
    fprintf(fp, "AUTO_ON_MESSAGE = Auto equip enabled.^n")
    fprintf(fp, "AUTO_OFF_MESSAGE = Auto equip disabled.^n^n")

    fprintf(fp, "[GENERAL]^n")
    fprintf(fp, "MENU_TIME = 15.0^n")
    fprintf(fp, "SPAWN_DELAY = 0.3^n")
    fprintf(fp, "REFRESH_TIME = 0.1^n")
    fprintf(fp, "DEFAULT_AUTOSAVE = 0^n")
    fprintf(fp, "ENABLE_SPAWN_MENU = 1^n")
    fprintf(fp, "DISABLE_ON_CSDM = 1^n")
    fprintf(fp, "BLOCKED_MAP_PREFIXES = awp_,aim_^n^n")

    fprintf(fp, "[LOADOUT]^n")
    fprintf(fp, "AK47_AMMO = 90^n")
    fprintf(fp, "M4A1_AMMO = 90^n")
    fprintf(fp, "AWP_AMMO = 30^n")
    fprintf(fp, "DEAGLE_AMMO = 35^n")
    fprintf(fp, "ARMOR = 100^n")
    fprintf(fp, "ENABLE_HE = 1^n")
    fprintf(fp, "ENABLE_DEFUSE = 1^n")
    fprintf(fp, "ENABLE_FLASH = 1^n")
    fprintf(fp, "ENABLE_SMOKE = 1^n")

    fclose(fp)
}

/*
    Put this file in:
    addons/amxmodx/configs/alarab_guns.ini

; Spawn Guns HUD Menu Settings
; Command to reload without map change: reguns

[HUD]
TITLE = ★ Server Alarab ★
HUD_X = 0.03
TITLE_Y = 0.38
AK47_Y = 0.43
M4A1_Y = 0.47
AWP_Y = 0.51
SAVE_Y = 0.55
EXIT_Y = 0.60

[COLORS]
TITLE_COLOR = 0 255 0
AK47_COLOR = 255 0 0
M4A1_COLOR = 0 60 180
AWP_COLOR = 160 0 200
SAVE_COLOR = 0 255 0
EXIT_COLOR = 150 0 0

[TEXT]
AK47_NAME = A.K.47
M4A1_NAME = M.4.A.1
AWP_NAME = A.W.P
SAVE_TEXT = Save Last Choice
EXIT_TEXT = Exit
CHAT_PREFIX = [Server Alarab]
BLOCKED_MESSAGE = Menu is disabled on this map.
AUTO_ON_MESSAGE = Auto equip enabled.
AUTO_OFF_MESSAGE = Auto equip disabled.

[GENERAL]
MENU_TIME = 15.0
SPAWN_DELAY = 0.3
REFRESH_TIME = 0.1
DEFAULT_AUTOSAVE = 0
ENABLE_SPAWN_MENU = 1
DISABLE_ON_CSDM = 1
BLOCKED_MAP_PREFIXES = awp_,aim_

[LOADOUT]
AK47_AMMO = 90
M4A1_AMMO = 90
AWP_AMMO = 30
DEAGLE_AMMO = 35
ARMOR = 100
ENABLE_HE = 1
ENABLE_FLASH = 1
ENABLE_SMOKE = 1
ENABLE_DEFUSE = 1
*/
