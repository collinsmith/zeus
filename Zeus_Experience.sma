#include <amxmodx>
#include <hamsandwich>

#pragma dynamic 64

#define PLUGIN_NAME		"Zeus XP"
#define PLUGIN_VERSION	"0.0.1"
#define PLUGIN_AUTHOR	"Tirant"

#define MAXPLAYERS	32

#define flag_get(%1,%2)		(g_playerInfo[%1] &   (1 << (%2 & 31)))
#define flag_set(%1,%2)		(g_playerInfo[%1] |=  (1 << (%2 & 31)))
#define flag_unset(%1,%2)	(g_playerInfo[%1] &= ~(1 << (%2 & 31)))

enum _:ePlayerInfo {
	info_isConnected,
	info_isAlive
}

static g_playerInfo[ePlayerInfo];

enum _:eRankInfo {
	rank_Exp,
	rank_Rank
};

static g_iRankInfo[MAXPLAYERS+1][eRankInfo];

enum _:eForwardedEvents {
	fwDummy,
	fwRankUp,
	fwChangeXP
};

static g_forwardedEvents[eForwardedEvents];

static const g_szRankName[][] = { 
	"Rank 1",
	"Rank 2",
	"Rank 3",
	"Rank 4",
	"Rank 5",
	"Rank 6",
	"Rank 7",
	"Rank 8",
	"Rank 9",
	"Rank 10"
};

static const g_iRankXP[sizeof g_szRankName-1] = {
	//...
	250,
	500,
	750,
	1000,
	1250,
	1500,
	1750,
	2000,
	2500
};

static const g_iRankMax = sizeof g_szRankName;
static const g_iHighestRank = sizeof g_szRankName-1;
static const g_iRankXPLast = sizeof g_iRankXP-1;
static g_iMaxXP;

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	g_iMaxXP = g_iRankXP[g_iRankXPLast];
	
	RegisterHam(Ham_Spawn,	"player", "ham_PlayerSpawn_Post", 1);
	RegisterHam(Ham_Killed,	"player", "ham_PlayerDeath_Post", 1);
	
	g_forwardedEvents[fwRankUp  ] = CreateMultiForward("zeus_fw_xp_rankUp", ET_IGNORE, FP_CELL, FP_CELL);
	g_forwardedEvents[fwChangeXP] = CreateMultiForward("zeus_fw_xp_gainExp", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
}

public plugin_natives() {
	register_library("Zeus_Experience");
	
	register_native("zeus_xp_changeUserExp",	"_changeUserExperience",1);
	register_native("zeus_xp_getUserExp",		"_getUserExperience",	1);
	register_native("zeus_xp_setUserExp",		"_setUserExperience",	1);
	
	register_native("zeus_xp_setUserRank",		"_setUserRank",			1);
	register_native("zeus_xp_getUserRank",		"_getUserRank",			1);
	
	register_native("zeus_xp_getRankName",		"_getRankName",			0);
	register_native("zeus_xp_getRankExp",		"_getRankExperience",	1);
	
	register_native("zeus_xp_getMaxRank",		"_getMaxRank",			1);
	register_native("zeus_xp_queryRank",		"_queryRank",			1);
}

public client_connect(id) {
	flag_set(info_isConnected,id);
	arrayset(g_iRankInfo[id], 0, eRankInfo);
}

public client_disconnect(id) {
	resetPlayerInfo(id);
}

resetPlayerInfo(id) {
	for (new i; i < ePlayerInfo; i++) {
		flag_unset(i,id);
	}
}

public ham_PlayerDeath_Post(victim, killer, shouldgib) {
	if (!flag_get(info_isConnected,victim)) {
		return HAM_IGNORED;
	}
	
	flag_unset(info_isAlive,victim);
	return HAM_IGNORED;
}

public ham_PlayerSpawn_Post(id) {
	if (!is_user_alive(id)) {
		return HAM_IGNORED;
	}
	
	flag_set(info_isAlive,id);
	return HAM_IGNORED;
}

/**
 * @see Zeus_Experience.inc
 */
public _changeUserExperience(id, exp, bool:notifyLevelChange) {
	if (exp != 0) {
		g_iRankInfo[id][rank_Exp] = clamp(g_iRankInfo[id][rank_Exp]+exp, 0, g_iMaxXP);
		while (checkPlayerRank(id, notifyLevelChange)) {}
		ExecuteForward(g_forwardedEvents[fwChangeXP], g_forwardedEvents[fwDummy], id, exp, g_iRankInfo[id][rank_Exp]);
	}
	
	return g_iRankInfo[id][rank_Exp];
}

/**
 * @see Zeus_Experience.inc
 */
public _setUserExperience(id, exp, bool:notifyLevelChange) {
	g_iRankInfo[id][rank_Exp ] = clamp(exp, 0, g_iMaxXP);
	g_iRankInfo[id][rank_Rank] = _queryRank(g_iRankInfo[id][rank_Exp])-1;
	if (notifyLevelChange) {
		ExecuteForward(g_forwardedEvents[fwRankUp], g_forwardedEvents[fwDummy], id, g_iRankInfo[id][rank_Rank]+1);
	}
	
	return g_iRankInfo[id][rank_Rank]+1;
}

/**
 * @see Zeus_Experience.inc
 */
public _queryRank(exp) {
	new rank;
	if (g_iRankXP[0] <= exp < _:g_iRankXP[g_iRankXPLast]) {
		new low;
		new high = g_iRankXPLast;
		while (!(g_iRankXP[rank] <= exp < g_iRankXP[rank+1]) && low <= high) {
			rank = (low+high)>>>1;
			if (g_iRankXP[rank] < exp) {
				low = rank+1;
			} else {
				high = rank-1;
			}
		}
		
		rank++;
	} else if (exp == _:g_iRankXP[g_iRankXPLast]) {
		rank = g_iRankXPLast+1;
	}
	
	return rank+1;
}

/**
 * Checks if a player should level up or not and then handles all leveling
 * issues.  Due to possible issues with gaining multiple levels gained at
 * once, this will only update their level by one.  If you would like to
 * continutally update their level until they have reached the max, you'll
 * need to use a while() loop.
 * 
 * @param id					Player index.
 * @param notifyLevelChange		True to forward the event, false otherwise.
 */
bool:checkPlayerRank(id, bool:notifyLevelChange) {
	if (!flag_get(info_isConnected,id)) {
		return false;
	}
	
	if (g_iRankInfo[id][rank_Rank] < g_iHighestRank) {
		if (g_iRankInfo[id][rank_Exp] < g_iRankXP[g_iRankInfo[id][rank_Rank]]) {
			return false;
		}

		g_iRankInfo[id][rank_Rank]++;
		if (notifyLevelChange) {
			ExecuteForward(g_forwardedEvents[fwRankUp], g_forwardedEvents[fwDummy], id, g_iRankInfo[id][rank_Rank]+1);
		}
		
		return true;
	}
	
	return false;
}

/**
 * @see Zeus_Experience.inc
 */
public _getUserExperience(id) {
	return g_iRankInfo[id][rank_Exp];
}

/**
 * @see Zeus_Experience.inc
 */
public _getUserRank(id) {
	return g_iRankInfo[id][rank_Rank]+1;
}

/**
 * @see Zeus_Experience.inc
 */
public _setUserRank(id, rank, bool:notifyLevelChange) {
	rank = clamp(rank-1, 0, g_iHighestRank);
	if (g_iRankInfo[id][rank_Rank] != rank) {
		g_iRankInfo[id][rank_Rank] = rank;
		g_iRankInfo[id][rank_Exp ] = (rank ? g_iRankXP[clamp(rank-1, 0, g_iRankXPLast)] : 0);
		if (notifyLevelChange) {
			ExecuteForward(g_forwardedEvents[fwRankUp], g_forwardedEvents[fwDummy], id, g_iRankInfo[id][rank_Rank]+1);
		}
	}
	
	return g_iRankInfo[id][rank_Rank]+1;
}

/**
 * @see Zeus_Experience.inc
 */
public _getRankName(iPlugin, iParams) {
	if (iParams != 3) {
		return PLUGIN_HANDLED;
	}
	
	new rank = clamp(get_param(1)-1, 0, g_iHighestRank);
	set_string(2, g_szRankName[rank], get_param(3));
	return PLUGIN_CONTINUE;
}

/**
 * @see Zeus_Experience.inc
 */
public _getRankExperience(rank) {
	if (rank != 1) {
		rank = clamp(rank-1, 0, g_iRankXPLast);
		return g_iRankXP[rank];
	}
	
	return 0;
}

/**
 * @see Zeus_Experience.inc
 */
public _getMaxRank() {
	return g_iRankMax;
}
