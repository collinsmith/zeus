#include <amxmodx>
#include <sqlvault>
#include <Zeus_Experience>

#pragma dynamic 1024

#define PLUGIN_NAME		"Zeus - Save"
#define PLUGIN_VERSION	"0.0.1"
#define PLUGIN_AUTHOR	"Tirant"

//#define USES_MySql
#define MAXPLAYERS	32
#define VAULT_NAME	"Zeus_Experience"
#define TASK_GetKey 64483

static SQLVault:g_SqlVault;
static g_szAuthID[MAXPLAYERS+1][35];
static g_iMaxPlayers;

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	g_iMaxPlayers = get_maxplayers();
	
	#if defined USES_MySql
		new szHost[64], szUser[64], szPass[64], szDb[64];
		get_cvar_string("zeus_sql_host", szHost, 63);
		get_cvar_string("zeus_sql_user", szUser, 63);
		get_cvar_string("zeus_sql_pass", szPass, 63);
		get_cvar_string("zeus_sql_db",   szDb, 	63);
		g_SqlVault = sqlv_open(szHost, szUser, szPass, szDb, VAULT_NAME, false);
	#else
		g_SqlVault = sqlv_open_local(VAULT_NAME, false);
	#endif
	
	if (g_SqlVault == Invalid_SQLVault) {
		set_fail_state("SqlVault: Could not connect to database");
	} else {
		sqlv_init(g_SqlVault);
	}
}

public plugin_end() {
	if (g_SqlVault == Invalid_SQLVault) {
		return;
	}
	
	new iPruneDays = get_cvar_num("zeus_xp_prune");
	if (iPruneDays) {
		iPruneDays *= -86400;
		sqlv_prune(g_SqlVault, 0, get_systime(iPruneDays));
	}
	
	sqlv_close(g_SqlVault);
}

public client_putinserver(id) {
	if (!is_user_bot(id)) {
		getSteamID(id);
	} else {
		zeus_xp_setUserRank(id, random_num(1, zeus_xp_getMaxRank()), false);
	}
}

public client_disconnect(id) {
	if (!is_user_bot(id)) {
		remove_task(id+TASK_GetKey);
		saveLevel(id);
	}
	
	g_szAuthID[id][0] = '^0';
}

/**
 * Loads a player's authid. If the authid is not valid, then this
 * function will loop until a valid authid is found.
 * 
 * @param taskid	Player index (with out without TASK_GetKey offset)
 */
public getSteamID(taskid) {
	if (taskid > g_iMaxPlayers) {
		taskid -= TASK_GetKey;
	}
	
	new szTempAuthID[35];
	get_user_authid(taskid, szTempAuthID, 34);
	if (szTempAuthID[0] == '^0' || equali(szTempAuthID, "STEAM_ID_PENDING")) {
		set_task(1.0, "getSteamID", taskid+TASK_GetKey);
	} else {
		copy(g_szAuthID[taskid], 34, szTempAuthID);
		loadLevel(taskid);
	}
}

/**
 * Loads a players experience from the SqlVault.
 * 
 * @param id		Player index.
 */
loadLevel(id) {
	sqlv_connect(g_SqlVault);
	new exp = sqlv_get_num(g_SqlVault, g_szAuthID[id]);
	sqlv_disconnect(g_SqlVault);
	zeus_xp_setUserExp(id, exp, false);
}

/**
 * Saves a players experience to the SqlVault.
 * 
 * @param id		Player index.
 */
saveLevel(id) {
	if (g_szAuthID[id][0] == '^0' || equali(g_szAuthID[id], "STEAM_ID_PENDING")) {
		return;
	}
	
	sqlv_connect(g_SqlVault); {
	sqlv_set_num(g_SqlVault, g_szAuthID[id], zeus_xp_getUserExp(id));
	} sqlv_disconnect(g_SqlVault);
}