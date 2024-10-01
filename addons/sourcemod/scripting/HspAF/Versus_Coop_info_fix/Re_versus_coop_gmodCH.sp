#pragma semicolon 1
#pragma newdecls required

// 头文件
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

public Plugin myinfo = 
{
	name 			= "Basic Server Function",
	author 			= "Caibiii, 夜羽真白,kita",
	description 	= "提供服务器基本功能",
	version 		= "2022.03.07",
	url 			= "https://github.com/GlowingTree880/L4D2_LittlePlugins"
}

public void OnPluginStart()
{
	HookEvent("player_team", evt_ChangeTeam, EventHookMode_Post);   //玩家转换队伍检测事件
}

// 对抗计分面板出现前，切换游戏模式为写实，realism based on coop，实际为战役，不会出现计分板
public Action L4D2_OnEndVersusModeRound(bool countSurvivors)
{
	SetConVarString(FindConVar("mp_gamemode"), "realism");
	return Plugin_Handled;
}

// 开局，切换游戏模式为战役，coop based on versus，实际为对抗
public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	SetConVarString(FindConVar("mp_gamemode"), "coop");
	return Plugin_Stop;
}

public Action Command_ChooseTeam(int client, const char[] command, int args)
{
	return Plugin_Handled;   //阻止使用m切换队伍
}

public void OnClientPutInServer(int client)
{
	if (client && IsClientConnected(client) && !IsFakeClient(client))
	{
		CreateTimer(3.0, Timer_FirstMoveToSpec, client, TIMER_FLAG_NO_MAPCHANGE);   //玩家回合加入游戏之后3秒检测是否属于特感方，是则移至旁观
	}
}

public Action Timer_FirstMoveToSpec(Handle timer, int client)
{
	if (IsValidPlayerInTeam(client, TEAM_INFECTED))
	{
		ChangeClientTeam(client, TEAM_SPECTATOR);
	}
	return Plugin_Continue;
}

public Action evt_ChangeTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int newteam = event.GetInt("team");
	bool disconnect = event.GetBool("disconnect");
	if (IsValidPlayer(client, true, true) && !disconnect && newteam == TEAM_INFECTED)
	{
		if (!IsFakeClient(client))
		{
			CreateTimer(1.0, MoveClientToSpec, client, TIMER_FLAG_NO_MAPCHANGE);   //玩家更换队伍后检测一次是否属于特感方，是则移至旁观
		}
	}
	return Plugin_Continue;
}

public Action MoveClientToSpec(Handle timer, int client)
{
	ChangeClientTeam(client, TEAM_SPECTATOR);
	return Plugin_Continue;
}

bool IsValidPlayerInTeam(int client, int team)
{
	if (IsValidPlayer(client, true, true))
	{
		if (team == GetClientTeam(client))
		{
			return true;
		}
	}
	return false;
}

bool IsValidPlayer(int client, bool allowbot, bool allowdeath)
{
	if (client && client <= MaxClients)
	{
		if (IsClientConnected(client) && IsClientInGame(client))
		{
			if (!allowbot)
			{
				if (IsFakeClient(client))
				{
					return false;
				}
			}
			if (!allowdeath)
			{
				if (!IsPlayerAlive(client))
				{
					return false;
				}
			}
			return true;
		}
		else
		{
			return false;
		}
	}
	else
	{
		return false;
	}
}