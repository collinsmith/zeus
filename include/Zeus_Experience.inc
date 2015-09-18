#if defined _Zeus_Experience
	#endinput
#endif
#define _Zeus_Experience

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib Zeus_Experience
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib Zeus_Experience
	#endif
#else
	#pragma library Zeus_Experience
#endif

/**
 * Called when a player ranks up. This may not always be called,
 * depending on whether or not this rank up is from ranking up
 * or from loading experience.
 * 
 * @param id		Player index.
 * @param ranking	New rank of the player.
 */
forward zeus_fw_xp_rankUp(id, rank);

/**
 * Called when a player gain experience.
 * 
 * @param id		Player index.
 * @param xp_gained	The amount of experience gained.
 * @param xp_before	The amount of experience before gain.
 */
forward zeus_fw_xp_gainExp(id, xp_gained, xp_before);

/**
 * Changes a users experience (+ or -).
 * 
 * @param id				Player index.
 * @param exp				Experience change (+ or -).
 * @param notifyLevelChange	True to send zeus_fw_xp_rankUp
 * 							forwards, false otherwise.
 * @return					Experience after change.
 */
native zeus_xp_changeUserExp(id, exp, bool:notifyLevelChange = true);

/**
 * Retrieves a users experience.
 * 
 * @param id		Player index.
 * @return			The users experience.
 */
native zeus_xp_getUserExp(id);

/**
 * Explicitly sets a users experience.
 * 
 * @param id				Player index.
 * @param exp				The experience to set this user to.
 * @param notifyLevelChange	True to send zeus_fw_xp_rankUp
 * 							forwards, false otherwise.
 * @return					The users rank after XP set.
 */
native zeus_xp_setUserExp(id, exp, bool:notifyLevelChange = true);

/**
 * Explicitly sets a users rank and performs all experience
 * changes.
 * 
 * @param id				Player index.
 * @param rank				The rank to set this user to.
 * @param notifyLevelChange	True to send zeus_fw_xp_rankUp
 * 							forwards, false otherwise.
 * @return					The users rank after XP set.
 */
native zeus_xp_setUserRank(id, rank, bool:notifyLevelChange = true);

/**
 * Retrieves a users rank.
 * 
 * @param id		Player index.
 * @return			The rank of this user. 0 -> No rank
 */
native zeus_xp_getUserRank(id);

/**
 * Retrieves the name of a rank.
 * 
 * @param rank		The rank to retrieve.
 * @param string	Array to place string into.
 * @param length	Length of the string to return.
 */
native zeus_xp_getRankName(rank, string[], length);

/**
 * Retrieves the amount of experience required for a
 * given rank.
 * 
 * @param rank		The rank of which whos experience requirement
 * 					to retrieve.
 * @return			The amount of experience required for this rank.
 */
native zeus_xp_getRankExp(rank);

/**
 * Retrieves the maximum rank possible.
 * 
 * @return			The max rank.
 */
native zeus_xp_getMaxRank();

/**
 * Retrieves the rank which would match up with the
 * specified amount of experience.
 * 
 * @param exp		The experience to query.
 * @return			The rank which matches the experience.
 */
native zeus_xp_queryRank(exp);