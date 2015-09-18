#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <Zeus_Experience>

#pragma dynamic 1024

#define PLUGIN_NAME		"Zeus - HUD"
#define PLUGIN_VERSION	"0.0.1"
#define PLUGIN_AUTHOR	"Tirant"

#define FLAG_EXP	ADMIN_RCON

#define HUD_RED		120
#define HUD_GREEN	0
#define HUD_BLUE	120
#define HUD_LOC_X	-1.00
#define HUD_LOC_Y	0.35
#define HUD_CHANNEL	1

static const HUD_HEADER[] = "[Zeus]";
static const SOUND_LEVEL[] = "buttons\bell1.wav";
static g_msgStatusText;

public plugin_precache() {
	precache_sound(SOUND_LEVEL);
}

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	register_concmd("zeus_setrank",	"cmdSetRank",		FLAG_EXP, " <name> <rank>");
	register_concmd("zeus_addxp",	"cmdAddExperience",	FLAG_EXP, " <name> <experience>");
	
	RegisterHam(Ham_Spawn,	"player", "ham_PlayerSpawn_Post", 1);
	
	g_msgStatusText = get_user_msgid("StatusText");
}

public ham_PlayerSpawn_Post(id) {
	if (!is_user_alive(id)) {
		return HAM_IGNORED;
	}
	
	displayHUD(id);
	return HAM_IGNORED;
}

public zeus_fw_xp_rankUp(id, rank) {
	new szPlayerName[32], szRankName[32];
	zeus_xp_getRankName(rank, szRankName, 31);
	
	set_hudmessage(HUD_RED, HUD_GREEN, HUD_BLUE, HUD_LOC_X, HUD_LOC_Y, 3, 4.0, 4.0, 0.1, 0.1, HUD_CHANNEL);
	show_hudmessage(id, "You've been promoted!^n%s", szRankName);
	client_cmd(id, "spk %s", SOUND_LEVEL);

	get_user_name(id, szPlayerName, 31);
	client_print(0, print_chat, "%s has ranked up and is now a %s", szPlayerName, szRankName);
	
	displayHUD(id);
}

public zeus_fw_xp_gainExp(id, xp_gained, xp_before) {
	displayHUD(id);
}

displayHUD(id) {
	static szHUD[192], iRank, iXPCur, iXPNext, szRankName[32];
	iRank	 = zeus_xp_getUserRank(id);
	iXPCur	 = zeus_xp_getUserExp(id);
	iXPNext	 = zeus_xp_getRankExp(iRank);
	zeus_xp_getRankName(iRank, szRankName, 31);
	formatex(szHUD, 191, "%s %d/%d (%d) %s (%d)", HUD_HEADER, iXPCur, iXPNext, clamp(iXPNext-iXPCur, 0), szRankName, iRank);
	
	message_begin(MSG_ONE_UNRELIABLE, g_msgStatusText, _, id); {
	write_byte(0);
	write_string(szHUD);
	} message_end();
}

public cmdSetRank(id, level, cid) {
	if(!cmd_access(id, level, cid, 3)) {
		return PLUGIN_HANDLED;
	}
		
	new szTarget[32];
	read_argv(1, szTarget, 31);
	new player = cmd_target(id, szTarget, 8);
   	if(!player) {
		client_print(id, print_console, "%s Invalid player index (%d)", HUD_HEADER, player);
		return PLUGIN_CONTINUE;
	}
	
	read_argv(2, szTarget, 31);
	if (!is_str_num(szTarget)) {
		client_print(id, print_console, "%s Invalid rank entered (%s)", HUD_HEADER, szTarget);
		return PLUGIN_CONTINUE;
	}
	
	
	new iRank = str_to_num(szTarget);
	iRank = zeus_xp_setUserRank(id, iRank);
	if (iRank) {
		get_user_name(player, szTarget, 31);
		client_print(id, print_console, "%s You have set %s's to rank %d", HUD_HEADER, szTarget, iRank);
		
		new szRankName[32];
		zeus_xp_getRankName(player, szRankName, 31);
		client_print(player, print_chat, "An admin has set your rank to %d (%s)", iRank, szRankName);
	}
	
	return PLUGIN_CONTINUE;
}

public cmdAddExperience(id, level, cid) {
	if(!cmd_access(id, level, cid, 3)) {
		return PLUGIN_HANDLED;
	}
		
	new szTarget[32];
	read_argv(1, szTarget, 31);
	new player = cmd_target(id, szTarget, 8);
   	if(!player) {
		client_print(id, print_console, "%s Invalid player index (%d)", HUD_HEADER, player);
		return PLUGIN_CONTINUE;
	}
	
	read_argv(2, szTarget, 31);
	if (!is_str_num(szTarget)) {
		client_print(id, print_console, "%s Invalid experience amount entered (%s)", HUD_HEADER, szTarget);
		return PLUGIN_CONTINUE;
	}
	
	new iExp = str_to_num(szTarget);
	iExp = zeus_xp_changeUserExp(id, iExp);
	if (iExp > -1) {
		get_user_name(player, szTarget, 31);
		client_print(id, print_console, "%s You have awarded %s with %d XP", HUD_HEADER, szTarget, iExp);
		client_print(player, print_chat, "An admin has awarded you with %d XP", iExp);
	}
	
	return PLUGIN_CONTINUE;
}
