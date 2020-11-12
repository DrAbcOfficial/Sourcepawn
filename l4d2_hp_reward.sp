#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_NAME "[L4D2]HP弹药恢复"
#define PLUGIN_DESCRIPTION "击杀特感恢复血量与子弹"
#define PLUGIN_AUTHOR "Dr.Abc"
#define PLUGIN_VERSION "0.001"
#define PLUGIN_URL "https://www.bilibili.com"
#define PLUGIN_DEBUG 1

Handle hHRBoomer;
Handle hHRSpitter;
Handle hHRSmoker;
Handle hHRJockey;
Handle hHRHunter;
Handle hHRCharger;
Handle hHRWitch;
Handle hHRTank;
Handle hHRMax;
Handle hHRMinReward;
Handle hAREnable;
Handle hHRNotifications;

float flBoomer;
float flSpitter;
float flSmoker;
float flJockey;
float flHunter;
float flCharger;
float flWitch;
float flTank;
int iMax;
int iMinReward;

bool bAmmoReward;
bool bNotifications;

public Plugin myinfo = {
	name = PLUGIN_NAME,
	description = PLUGIN_DESCRIPTION,
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart(){
	CreateConVar("sm_hpr_version", PLUGIN_VERSION, "版本号", FCVAR_SPONLY|FCVAR_DONTRECORD);
	//血量
	hHRBoomer = CreateConVar("sm_hpr_multi_bommer", "1", "boomer的HP回复倍率", FCVAR_NONE, true, 0.01);
	hHRSpitter = CreateConVar("sm_hpr_multi_spitter", "1", "spitter的HP回复倍率", FCVAR_NONE, true, 0.01);
	hHRSmoker = CreateConVar("sm_hpr_multi_smoker", "1", "smoker的HP回复倍率", FCVAR_NONE, true, 0.01);
	hHRJockey = CreateConVar("sm_hpr_multi_jockey", "1", "jockey的HP回复倍率", FCVAR_NONE, true, 0.01);
	hHRHunter = CreateConVar("sm_hpr_multi_hunter", "1", "hunter的HP回复倍率", FCVAR_NONE, true, 0.01);
	hHRCharger = CreateConVar("sm_hpr_multi_charger", "1", "charger的HP回复倍率", FCVAR_NONE, true, 0.01);
	hHRWitch = CreateConVar("sm_hpr_multi_witch", "1", "witch的HP回复倍率", FCVAR_NONE, true, 0.01);
	hHRTank = CreateConVar("sm_hpr_multi_tank", "1", "tank的HP回复倍率", FCVAR_NONE, true, 0.01);
	hHRNotifications = CreateConVar("sm_hpr_notify", "1", "提示模式: 0=中心文字, 1=提示框", FCVAR_NONE, true, 0.0, true, 1.0);
	hHRMax = CreateConVar("sm_hpr_max", "200", "最大血量", FCVAR_NONE, true, 100.0);
	hHRMinReward = CreateConVar("sm_hpr_min_reward", "5", "最低回复", FCVAR_NONE, true, 0.0);
	//子弹
	hAREnable = CreateConVar("sm_amr_allow_reward", "1", "允许子弹回复", FCVAR_NONE, true, 0.0, true, 1.0);

	HookEvent("player_death", OnPlayerDeath);
	HookEvent("witch_killed", OnWitchKilled);

	flBoomer = GetConVarFloat(hHRBoomer);
	flSpitter = GetConVarFloat(hHRSpitter);
	flSmoker = GetConVarFloat(hHRSmoker);
	flJockey = GetConVarFloat(hHRJockey);
	flHunter = GetConVarFloat(hHRHunter);
	flCharger = GetConVarFloat(hHRCharger);
	flWitch = GetConVarFloat(hHRWitch);
	flTank = GetConVarFloat(hHRTank);
	iMax = GetConVarInt(hHRMax);
	iMinReward = GetConVarInt(hHRMinReward);
	bNotifications = GetConVarBool(hHRNotifications);
	bAmmoReward = GetConVarBool(hAREnable);

	HookConVarChange(hHRBoomer, HRConfigsChanged);
	HookConVarChange(hHRSpitter, HRConfigsChanged);
	HookConVarChange(hHRSmoker, HRConfigsChanged);
	HookConVarChange(hHRJockey, HRConfigsChanged);
	HookConVarChange(hHRHunter, HRConfigsChanged);
	HookConVarChange(hHRCharger, HRConfigsChanged);
	HookConVarChange(hHRWitch, HRConfigsChanged);
	HookConVarChange(hHRTank, HRConfigsChanged);
	HookConVarChange(hHRMax, HRConfigsChanged);
	HookConVarChange(hHRMinReward, HRConfigsChanged);
	HookConVarChange(hHRNotifications, HRConfigsChanged);
	HookConVarChange(hAREnable, HRConfigsChanged);

	AutoExecConfig(true, "l4d_hp_rewards");
}

public void HRConfigsChanged(Handle convar, const char[] oValue, const char[] nValue){
	flBoomer = GetConVarFloat(hHRBoomer);
	flSpitter = GetConVarFloat(hHRSpitter);
	flSmoker = GetConVarFloat(hHRSmoker);
	flJockey = GetConVarFloat(hHRJockey);
	flHunter = GetConVarFloat(hHRHunter);
	flCharger = GetConVarFloat(hHRCharger);
	flWitch = GetConVarFloat(hHRWitch);
	flTank = GetConVarFloat(hHRTank);
	iMax = GetConVarInt(hHRMax);
	iMinReward = GetConVarInt(hHRMinReward);
	bNotifications = GetConVarBool(hHRNotifications);
	bAmmoReward = GetConVarBool(hAREnable);
}

/**
		            1
		--------------------------    +  iMinReward
		   /        iMax     \
		   |  x + --------   |
		tan|        100      |
		   | --------------- |
		   \       iMax      /

**/
int GetRewardHealth(int iHp){
	return iHp > 0 ? RoundToFloor( 1 / (Tangent(( float(iHp) + iMax / 100 ) / iMax))) + iMinReward : 0;
}

void GiveHealth(int client, float flHealth){
	if(IsPlayerAvaliable(client) || flHealth <= 0.0)
		return;	
	int sHealth = GetClientHealth(client);
	int aHealth = RoundToFloor(flHealth);
	if((sHealth + aHealth) < iMax){
		SetEntProp(client, Prop_Send, "m_iHealth", sHealth + aHealth, 1);
	}
	else{
		SetEntProp(client, Prop_Send, "m_iHealth", iMax, 1);
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
	}
	SendNotify(client, aHealth);
}

void GiveAmmo(int client){
	int flCheat = GetCommandFlags("give");
	SetCommandFlags("give", flCheat & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give ammo");
	SetCommandFlags("give", flCheat);
}

void SendNotify(int client, int iHp){
	if(bNotifications)
		PrintHintText(client, "+%i HP", iHp);
	else
		PrintCenterText(client, "+%i HP", iHp);
}

bool IsPlayerAvaliable(int client){
	return client <= 0 || client > MaxClients || !IsClientInGame(client);
}

bool IsPlayerIncapped(int client){
	return GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) ? true : false;
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast){
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsPlayerAvaliable(client) || GetClientTeam(client) != 3)
		return;
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(IsPlayerAvaliable(attacker) || GetClientTeam(attacker) != 2 || !IsPlayerAlive(attacker) || IsPlayerIncapped(attacker))
		return;

	float flHealth = float(GetRewardHealth(GetClientHealth(attacker)));
	int iClass = GetEntProp(client, Prop_Send, "m_zombieClass");
	switch(iClass){
		//smoker
		case 1:{flHealth = flHealth * flSmoker;}
		//boomer
		case 2:{flHealth = flHealth * flBoomer;}
		//hunter
		case 3:{flHealth = flHealth * flHunter;}
		//spitter
		case 4:{flHealth = flHealth * flSpitter;}
		//jockey
		case 5:{flHealth = flHealth * flJockey;}
		//charger
		case 6:{flHealth = flHealth * flCharger;}
		//tank
		case 8:{flHealth = flHealth * flTank;}
		//default
		default:{}
	}
	GiveHealth(attacker, flHealth);
	if(bAmmoReward)
		GiveAmmo(attacker);
}

public Action OnWitchKilled(Handle event, const char[] name, bool dontBroadcast){
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsPlayerAvaliable(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || IsPlayerIncapped(client))
		return;
	GiveHealth(client, GetRewardHealth(GetClientHealth(client)) * flWitch);
	if(bAmmoReward)
		GiveAmmo(client);
}
