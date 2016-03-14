// Планы
// -> Поставить лицом к лицу потом повернуть на 180
// -> Резинка между игроками что бы не убегали
// -> Ничья слишком быстро переход к следующему раунду
// -> Способы реализации событи: 1 Договоренность ( 1-меню, 2-стоять с ножем)
//      2-Место телепортации ( 1-респавн, 2-текущие координаты)
//		3-Оповещение          ( 1- текст, 2-звук)
//		4-Награды
//		5-Наказания
//#C:\pro\SourceMod\MySMcompile.exe "$(FULL_CURRENT_PATH)"
#define nDEBUG 1
#define DEBUG_LOG 1
#define DEBUG_PLAYER "Kom64t"

#define PLUGIN_NAME  "KnifeDuel"
#define PLUGIN_VERSION "1.1"
#define USE_WEAPON True
#include "k64t.inc"
#define MSG_1v1 "1v1" 
#define MSG_Compatibility_Conditions	"compatibility_conditions"
#define MSG_Negotiation_Timer			"negotiations_end_in"
#define MSG_Opponent_Agreed				"opponent_agreed"
#define MSG_Opponent_Not_Agreed			"opponent_not_agreed"
#define MSG_Keep_Fighting "keep_fighting"
#define MSG_Ready_to_Duel				"ready_to_duel"
#define MSG_Duel_Timer					"fight_time_remaining"
#define MSG_Duel_Draw					"duel_draw"
#define MSG_Duel_Won					"won_the_fight"


new String:SOUND_TIMER[]={"ambient/tones/floor1.wav"};
new String:SOUND_GONG[]={"gong.wav"};
new String:SOUND_FIGHT[]={"arena_loop10.mp3"};
new String:SOUND_OPPONENT_AGREE[]={"weapons/knife/knife_deploy1.wav"};
//"c:\tmp\vpk from cs\1\sound\ui\achievement_earned.wav" -Ситуация 1vs1
new const String:SOUND_FOLDER[]={"k64t\\KnifeDuel\\"};
new const String:DOWNLOAD_SOUND_FOLDER[]={"sound/k64t/KnifeDuel/"};
 
new String:Plugin_Name[]={PLUGIN_NAME};
new Handle:cvar_KnifeDuel_BeginTimer        = INVALID_HANDLE;
new Float:g_BeginTimer = 3.0;
new Handle:cvar_KnifeDuel_NegotiationTimer  = INVALID_HANDLE;
new g_NegotiationTimer=10;
new Handle:cvar_ForceTimer        = INVALID_HANDLE;
new Float:g_ForceTimer = 30.0;

new Handle:cvar_Fighttimer   				= INVALID_HANDLE;
new g_fighttimer=10;
new Handle:cvar_MinPlayers					= INVALID_HANDLE;
new MinPlayers=4;
new Handle:cvar_sv_alltalk					= INVALID_HANDLE;
new bool:g_alltalkenabled;
new fighttimer;
//
new bool:bombplanted	=false;
new bool:isFighting		=false;
new ct_team_cnt,t_team_cnt,loser,winner,tid,ctid;
//new team;
new Bool:ct_ready,t_ready;
new Handle:g_hMyCookie;
new g_iWeaponParent;
new g_iMyWeapons;
new g_iHealth;
new g_iAccount,g_iSpeed;
new String:ctname[MAX_NAME_LENGTH];
new String:tname[MAX_NAME_LENGTH];
new Float:vClientOrigin[2][3];
new String:ctitems[8][64];
new String:titems[8][64];
new Handle:g_WeaponSlots    = INVALID_HANDLE;



public Plugin:myinfo =
{
    name = PLUGIN_NAME,
    author = "k64t@ya.ru",
    description = "1v1 duel with knives at end of round",
    version = PLUGIN_VERSION,
    url = ""
};
//***********************************************
public OnPluginStart(){
//***********************************************
#if defined DEBUG
DebugPrint("OnPluginStart");
#endif
cvar_sv_alltalk = FindConVar("sv_alltalk");
if (cvar_sv_alltalk == INVALID_HANDLE)
    {
    LogError("FATAL: Cannot find sv_alltalk cvar.");
    SetFailState("[%s] %s",Plugin_Name,"Cannot find sv_alltalk cvar.");
    }
LoadTranslations("KnifeDuel.phrases");
cvar_KnifeDuel_NegotiationTimer	= CreateConVar("KnifeDuel_NegotiationTimer","10",
	"Time (in seconds), which is given to negotiation duel between players",true,0);
cvar_KnifeDuel_BeginTimer	= CreateConVar("KnifeDuel_BeginTimer","3",
	"Number of seconds after which begins a duel, after an agreement between the players",true,0);
cvar_MinPlayers				= CreateConVar("MinPlayers","4",
	"Minimum number of players before knife fights will trigger",true,4);
cvar_Fighttimer    = CreateConVar("KnifeDuel_fighttimer","10", 
        "Number of seconds to allow for knifing. Players get slayed after this time limit expires.");
cvar_ForceTimer	= CreateConVar("ForceTimer","30",
	"Time (in seconds) in duel will force if negotiation failed. 0 - disable force duel◙♪/Секунды по",true,10);
	
//https://wiki.alliedmods.net/Game_Events_(Source
HookEvent("player_death",	EventPlayerDeath);
HookEvent("bomb_planted",	EventBombPlanted,	EventHookMode_PostNoCopy);
HookEvent("round_start",	EventRoundStart,	EventHookMode_PostNoCopy);
HookEvent("round_end",		EventRoundEnd,EventHookMode_PostNoCopy);
HookEvent("bomb_beginplant",EventBombBeginPlant);
HookEvent("bomb_abortplant",EventBombAbortPlant);
HookEvent("hostage_follows",EventHostageFollows);
HookEvent("hostage_stops_following",EventHostageStopsFollowing);
RegConsoleCmd("k_KnifeDuel", cmd_KnifeDuel, "");
g_hMyCookie = RegClientCookie(Plugin_Name, Plugin_Name, CookieAccess_Protected);
    // new f_WeaponSlots[MAX_WEAPONS] =
    // {
         // -1, -1, -1, -1, -1, -1,
        // CS_SLOT_GRENADE,    CS_SLOT_GRENADE,    CS_SLOT_GRENADE,    CS_SLOT_PRIMARY,
        // CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,
        // CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,
        // CS_SLOT_PRIMARY,    CS_SLOT_SECONDARY,  CS_SLOT_SECONDARY,  CS_SLOT_SECONDARY,
        // CS_SLOT_SECONDARY,  CS_SLOT_SECONDARY,  CS_SLOT_SECONDARY,  CS_SLOT_PRIMARY,
        // CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,
        // CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,    CS_SLOT_PRIMARY,    CS_SLOT_C4, 
        // CS_SLOT_KNIFE
    // };

    g_WeaponSlots = CreateTrie( );
    for(new i = 0; i < MAX_WEAPONS; i++)
    {
    SetTrieValue(g_WeaponSlots, g_WeaponNames[i], f_WeaponSlots[i]);
    }

SetupOffsets(); 
}
//***********************************************
public OnConfigsExecuted(){
//***********************************************
g_fighttimer        = GetConVarInt(cvar_Fighttimer);
g_NegotiationTimer  = GetConVarInt(cvar_KnifeDuel_NegotiationTimer);
g_ForceTimer = float(GetConVarInt(cvar_ForceTimer));

PrecacheSound(SOUND_TIMER,true);
PrecacheSound(SOUND_OPPONENT_AGREE,true);
decl String:strBuf[MAX_STRING_LENGHT];
Format(strBuf, MAX_FILENAME_LENGHT,"%s%s\0",DOWNLOAD_SOUND_FOLDER,SOUND_GONG);								
AddFileToDownloadsTable(strBuf);							
Format(strBuf, MAX_FILENAME_LENGHT,"%s%s",SOUND_FOLDER,SOUND_GONG);								
PrecacheSound(strBuf,true);

Format(strBuf, MAX_FILENAME_LENGHT,"%s%s\0",DOWNLOAD_SOUND_FOLDER,SOUND_FIGHT);								
AddFileToDownloadsTable(strBuf);							
Format(strBuf, MAX_FILENAME_LENGHT,"%s%s",SOUND_FOLDER,SOUND_FIGHT);								
PrecacheSound(strBuf,true);

}

//***********************************************
public Action:cmd_KnifeDuel(client, args){
//***********************************************
}

//***********************************************
public OnMapStart(){
//***********************************************
#if defined DEBUG
DebugPrint("OnMapStart");
#endif
AutoExecConfig(true, "KnifeDuel");
g_BeginTimer= GetConVarFloat(cvar_KnifeDuel_BeginTimer);
MinPlayers= GetConVarInt(cvar_MinPlayers);
					
}
//***********************************************
public EventBombBeginPlant			(Handle:event, const String:name[],bool:dontBroadcast){bombplanted = true;}
public EventBombAbortPlant			(Handle:event, const String:name[],bool:dontBroadcast){bombplanted = false;}
public EventHostageFollows			(Handle:event, const String:name[],bool:dontBroadcast){bombplanted = true;}
public EventHostageStopsFollowing	(Handle:event, const String:name[],bool:dontBroadcast){bombplanted = false;}
public EventBombPlanted				(Handle:event, const String:name[],bool:dontBroadcast){bombplanted = true;}
//***********************************************
public EventRoundEnd(Handle:event, const String:name[],bool:dontBroadcast){
//***********************************************
#if defined DEBUG
DebugPrint("EventRoundEnd");
#endif
//-> Проверить что событие EventRoundEnd возникает всегда, даже если ничья
//<- Проверил. При ничья событие возникает.
isFighting=false;
fighttimer=-1;

}
//***********************************************
public EventRoundStart(Handle:event, const String:name[],bool:dontBroadcast){
//***********************************************
#if defined DEBUG
DebugPrint("EventRoundStart");
#endif
bombplanted=false;
//isFighting=false;
//fighttimer=-1;
ct_ready=false;
t_ready=false;

//->остановить таймеры
//-> Проверить что есть Не менее двух игроков
//
// Запомнить координаты места рождения для последующей телепортации
//-> Оптимизировать расстояние между местами 
new p=0;
for (new i = 1; i <= MaxClients; i++)
        {      
		if (IsClientInGame(i) && IsPlayerAlive(i))
			if (GetClientTeam(i)==CS_TEAM_CT)
				{
				GetClientAbsOrigin(i,vClientOrigin[p]);
				p++;
				if (p==2) break;
				}
		}
}
//***********************************************
public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast){
//***********************************************
#if defined DEBUG
DebugPrint("EventPlayerDeath");
#endif
if (isFighting)
	{
	loser = GetClientOfUserId(GetEventInt(event, "userid"));	
	if (loser == ctid || loser == tid)
		{	
		#if defined DEBUG
		DebugPrint("loser=%d",loser);
		#endif				
		//winner = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (loser == ctid)winner=tid;else winner=ctid;
		#if defined DEBUG
		DebugPrint("winner=%d",winner);
		#endif
		if ( (winner != loser) && (winner != 0) )
			{
			decl String:winnername[MAX_NAME_LENGTH];		
			GetClientName(winner, winnername, sizeof(winnername));
			CPrintToChatAll("{lightgreen}%s %t",winnername,MSG_Duel_Won);
			//->Set bonus for winner			
			}
		CancelFight();	
		}
		
	}
else
	{
	//->Если тид или цтид не равно нулю-> конец согласованаия.
	//->Если нет координат телепортации -> выход
	if(bombplanted)return;
	#if defined DEBUG
	#else
	if (GetClientCount() < MinPlayers)return;
	#endif
	ct_team_cnt	=0;t_team_cnt=0;
	ctid =0;tid =0;
	new tmpteam;	
	for (new i = 1; i <= MaxClients; i++)
        {      
		if (IsClientInGame(i) && IsPlayerAlive(i))
			{
			tmpteam = GetClientTeam(i);
			//-> Попробовать обойтись логикой без счетчика.	
			//if (tmpteam == CS_TEAM_CT) {  ct_team_cnt++;if (ct_team_cnt>1){return;} ctid = i; }
			if (tmpteam == CS_TEAM_CT)	if(ctid ==0)ctid = i;else return;
			else //if (tmpteam == CS_TEAM_T) {  t_team_cnt++;if (t_team_cnt>1){return;} tid = i; }
				    if (tmpteam == CS_TEAM_T) if(tid ==0)tid = i;else return;
			}
        }		
	if (/*ct_team_cnt == 1 && t_team_cnt == 1 && */ctid !=0 && tid !=0 && !bombplanted)
		{		
		//->Проиграть бетховен та да да да
		CPrintToChatAll("{green}%t",MSG_1v1);				
		//CPrintToChat( tid,"{green}%t",MSG_1v1);				
		//CPrintToChat(ctid,"{green}%t",MSG_1v1);		
		//Достань нож - сразимся как мужчины. 
		CPrintToChat( tid,"{green}%t",MSG_Compatibility_Conditions);				
		CPrintToChat(ctid,"{green}%t",MSG_Compatibility_Conditions);				
		//->Добавить голосовую инструкцию	
		fighttimer=g_NegotiationTimer;	
        GetClientName(ctid, ctname, sizeof(ctname));
        GetClientName(tid, tname, sizeof(tname));
		CreateTimer(1.0, TimerNegotiation, _, TIMER_REPEAT);
		// Если в момент 1vs1 один из игроков с ножем, то счиать что он согласен на ножевую
		decl String:tmpGetClientWeapon[MAX_WEAPON_STRING];
		GetClientWeapon(ctid, tmpGetClientWeapon, sizeof(tmpGetClientWeapon));
		if (strcmp(tmpGetClientWeapon,"weapon_knife")==0)ct_ready=true;	
		GetClientWeapon(tid, tmpGetClientWeapon, sizeof(tmpGetClientWeapon));
		if (strcmp(tmpGetClientWeapon,"weapon_knife")==0)t_ready=true;	

		//SDKHookEx(ctid,SDKHook_WeaponSwitch, OnChangeActiveWeapon);				
		}
	}
}
//***********************************************
public Action:TimerNegotiation(Handle:timer){
//***********************************************
#if defined DEBUG
DebugPrint("TimerNegotiation %i",fighttimer);
#endif
fighttimer--;
if (fighttimer<0)return Plugin_Stop;
if (fighttimer==0)
	{	
	// - > Menu to force player to duel
	PrintHintText(tid,"%t",MSG_Keep_Fighting);
	PrintHintText(ctid,"%t",MSG_Keep_Fighting);
	CPrintToChatAll("{green}%t",MSG_Opponent_Not_Agreed);
    if (g_ForceTimer!=0)
		{
		PrintHintText(tid,"%s %2.0f %s","У вас есть ",g_ForceTimer," секунд покончить с этим");
		PrintHintText(ctid,"%s %2.0f %s","У вас есть ",g_ForceTimer,"секунд покончить с этим");		
		CreateTimer(g_ForceTimer,StartFight);
		}
	return Plugin_Stop;
	}
EmitSoundToAll(SOUND_TIMER);	
PrintHintText(tid,"%t %i %t", MSG_Negotiation_Timer,fighttimer,"second");
PrintHintText(ctid,"%t %i %t", MSG_Negotiation_Timer,fighttimer,"second");
decl String:tmpGetClientWeapon[MAX_WEAPON_STRING];
decl Float:tmpspeed[3];
if (!ct_ready)
	{
	if (IsFakeClient(ctid)) ct_ready=true;
	else	
		{
		GetClientWeapon(ctid, tmpGetClientWeapon, sizeof(tmpGetClientWeapon));
		if (strcmp(tmpGetClientWeapon,"weapon_knife")==0)
			{
			GetEntityVelocity(ctid,tmpspeed);
			#if defined DEBUG
			DebugPrint("TimerNegotiation CT spd=%f",GetVectorLength(tmpspeed));
			#endif		
			if (tmpspeed[0]==0 && tmpspeed[1]==0)
				{
				ct_ready=true;				
				}
			}
		}
	if (ct_ready) 
		{
		CPrintToChatAll("{blue}%t %s %t","counter-terrorist",ctname,"agree");			
		CPrintToChat(tid,"{green}%t",MSG_Opponent_Agreed);					
		//"c:\tmp\vpk from cs\1\sound\weapons\knife\knife_deploy1.wav" 
		EmitSoundToClient(tid,SOUND_OPPONENT_AGREE);	
		//->Голосовое сообщение
		}
	}	
	
if (!t_ready)
	{
	if (IsFakeClient(tid)) t_ready=true;
	else
		{
		GetClientWeapon(tid, tmpGetClientWeapon, sizeof(tmpGetClientWeapon));
		if (strcmp(tmpGetClientWeapon,"weapon_knife")==0)
			{
			GetEntityVelocity(tid,tmpspeed);
			#if defined DEBUG
			DebugPrint("TimerNegotiation T spd=%f",GetVectorLength(tmpspeed));
			#endif		
			if (tmpspeed[0]==0 && tmpspeed[1]==0)
				{
				t_ready=true;				
				}
			}
		}
	if (t_ready) 
		{
		CPrintToChatAll("{red}%t %s %t","terrorist",tname,"agree");			
		CPrintToChat(ctid,"{green}%t",MSG_Opponent_Agreed);			
		EmitSoundToClient(ctid,SOUND_OPPONENT_AGREE);	
		//->Голосовое сообщение
		}	
	}	
if (ct_ready && t_ready)
	{	
	PrintHintText(tid,"%t", MSG_Ready_to_Duel);
	PrintHintText(ctid,"%t", MSG_Ready_to_Duel);
	CPrintToChatAll("{green}%t", MSG_Ready_to_Duel);
	//CreateTimer(g_BeginTimer,VerifyConditions);
	CreateTimer(0.1,StartFight);
	return Plugin_Stop;
	}
return Plugin_Continue;
}

//***********************************************
public Action:CancelFight(){
//***********************************************
#if defined DEBUG
DebugPrint("CancelFight");
#endif
isFighting = false;
// Победный звук
//EmitSound(clients, total, song,_, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL);
//->Вернуть оружие победителю
if (winner != 0)
    {
        if (IsPlayerAlive(winner))
        {
            PlayerWeaponHandler(winner, GetClientTeam(winner));
			//очистить список оружия
            for (new i = 0; i <= 7; i++)
            {
                ctitems[i] = "";
                titems[i] = "";
            }
        }
    }
else
		{
		SetEntData(ctid, g_iAccount, 0);
		SetEntData(tid, g_iAccount, 0);
		}
SetConVarInt(cvar_sv_alltalk,g_alltalkenabled);	
}
//***********************************************
public Action:StartFight(Handle:timer){ 
//***********************************************
#if defined DEBUG
DebugPrint("StartFight");
#endif   
// check if one player left server
if (ctid == 0 || tid == 0)return;  

// check if there are only two players
ct_team_cnt = 0, t_team_cnt = 0;
for (new i = 1; i <= MaxClients; i++)
{
	new tmpteam;
	if (IsClientInGame(i) && IsPlayerAlive(i))
	{
		tmpteam = GetClientTeam(i);
		if (tmpteam == CS_TEAM_CT) { ct_team_cnt++;}
		else if (tmpteam == CS_TEAM_T) { t_team_cnt++;}
	}
}
// check if there are only two players and round has 
// not ended or bomb is not planted
if (ct_team_cnt != 1 || t_team_cnt != 1 || bombplanted)return;
// start fight
isFighting = true;
// Remove all weapons from the map
RemoveAllWeapons();
// Play fight song
//
	/*    // play fight song
    if (songsfound > 0)
    {
        new randomsong = 0;
        if (songsfound > 1)
        {
            randomsong = GetRandomInt(0, songsfound - 1);
        }
        strcopy(song, sizeof(song), fightsong[randomsong]);
        
        new clients[MaxClients];
        new total = 0;
        for (new i=1; i<=MaxClients; i++)
        {
            if (IsClientInGame(i) && g_soundPrefs[i])
            {
                clients[total++] = i;
            }
        }

        if (total)
        {
            Trace("Starting fight song.");
            EmitSound(clients, total, song, 
                _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
        }
    }
*/	
    
//    Start beacons
//    CreateTimer(2.0, StartBeacon, ctid, TIMER_REPEAT);
//    /CreateTimer(1.0, StartBeaconT, tid);


// Remove weapons from players
PlayerWeaponHandler(ctid, CS_TEAM_CT);
PlayerWeaponHandler(tid, CS_TEAM_T);   
// switch alltalk
//if (g_alltalk) 
//{
     g_alltalkenabled = GetConVarBool(cvar_sv_alltalk);
//    if ( !g_alltalkenabled )
//    {
SetConVarInt(cvar_sv_alltalk, 1);
//    }
//    g_alltalkenabled = !g_alltalkenabled;
//}
    
// switch blocking
	/*
    if ( g_block )
    {
        if ( sm_noblock == INVALID_HANDLE )
        {
            sm_noblock = FindConVar("sm_noblock");
        }
        if ( sm_noblock != INVALID_HANDLE )
        {
            g_blockenabled = !GetConVarBool(sm_noblock);
            if ( !g_blockenabled )
            {
                SetConVarInt(sm_noblock, 0);
            }
            g_blockenabled = !g_blockenabled;
        }
    }
	*/
// Save health
new ct_health=GetClientHealth(ctid);
SetEntData(ctid, g_iHealth, 400);
new t_health=GetClientHealth(tid);
SetEntData(tid, g_iHealth, 400);    
// Give players knifes
EquipKnife(ctid);
EquipKnife(tid);
// Teleport players https://wiki.alliedmods.net/Vectors_Explained_(Scripting)
new Float:Angs[3]; // {pitch, yaw, roll}
new Float:FaceToFaceVector[3];
MakeVectorFromPoints(vClientOrigin[1],vClientOrigin[0],FaceToFaceVector);
GetVectorAngles(FaceToFaceVector,Angs);
TeleportEntity(tid, vClientOrigin[0], Angs, NULL_VECTOR);
MakeVectorFromPoints(vClientOrigin[0],vClientOrigin[1],FaceToFaceVector);
GetVectorAngles(FaceToFaceVector,Angs);
TeleportEntity(ctid, vClientOrigin[1], Angs, NULL_VECTOR);
// Restore players health
//OldVersion
//SetEntData(ctid, g_iHealth, 100)
//SetEntData(tid, g_iHealth, 100)
if(ct_ready)SetEntityHealth(ctid, 100);else SetEntityHealth(ctid, ct_health);
if(t_ready)SetEntityHealth(tid, 100);else SetEntityHealth(tid, t_health);
//if (t_ready) SetEntityHealth(tid, 100); 
//	else SetEntityHealth(tid, ct_health);
//-> Display prepare to fight
//->Start sound
//Start FightTimer
fighttimer=g_fighttimer;
decl String:strBuf[MAX_STRING_LENGHT];
Format(strBuf, MAX_FILENAME_LENGHT,"%s%s",SOUND_FOLDER,SOUND_GONG);	
EmitSoundToAll(strBuf);
CreateTimer(1.0, FightTimer, _, TIMER_REPEAT);
Format(strBuf, MAX_FILENAME_LENGHT,"%s%s",SOUND_FOLDER,SOUND_FIGHT);	
EmitSoundToAll(strBuf);
}
//***********************************************
public EquipKnife(client)
//***********************************************
{
    GivePlayerItem(client, "weapon_knife");
    FakeClientCommand(client, "use weapon_knife");
}
//***********************************************
PlayerWeaponHandler(client, teamid){
//***********************************************

    if ( isFighting )
    {
        new count = 0;
        for (new i = 0; i <= 128; i += 4)
        {
            new weaponentity = -1;
            new String:weaponname[MAX_WEAPON_NAME];
            weaponentity = GetEntDataEnt2(client, (g_iMyWeapons + i));
            if ( IsValidEdict(weaponentity) )
            {
                GetEdictClassname(weaponentity, weaponname, MAX_WEAPON_NAME);
                if ( (weaponentity != -1) && !StrEqual(weaponname, "worldspawn", false) )
                {
                    if ( teamid == CS_TEAM_CT || teamid == CS_TEAM_T)
                    {
                        RemovePlayerItem(client, weaponentity);
                        RemoveEdict(weaponentity);
                        if ( teamid == CS_TEAM_CT )
                        {
                            ctitems[count++] = weaponname;
                        }
                        else if ( teamid == CS_TEAM_T )
                        {
                            titems[count++] = weaponname;
                        }
                    }
                }
            }
        }
    }
    else
    {
        // we have a winner, so give all its weapons we removed before
        RemoveWeapon(client, "knife");
        for ( new i = 0; i <= 7 ; i++ )
        {
            if ( IsClientInGame(client) )
            {   
                if (teamid == 3)
                {
                    if ( !StrEqual(ctitems[i], "", false) )
                    {
                        GivePlayerItem(client, ctitems[i]);
                    }
                }
                else if (teamid == 2)
                {
                    if ( !StrEqual(titems[i], "", false) )
                    {
                        GivePlayerItem(client, titems[i]);
                    }
                }
            }
        }
    }

}
//***********************************************
RemoveAllWeapons(){
//***********************************************
#if defined DEBUG
DebugPrint("RemoveAllWeapons");
#endif
new maxent = GetMaxEntities(), String:weapon[64];
for (new i=MaxClients;i<maxent;i++)
	{
	if ( IsValidEdict(i) && IsValidEntity(i) && GetEntDataEnt2(i, g_iWeaponParent) == -1 )
		{
		GetEdictClassname(i, weapon, sizeof(weapon));
		if (    StrContains(weapon, "weapon_") != -1                // remove weapons
				|| StrEqual(weapon, "hostage_entity", true)         // remove hostages
				|| StrContains(weapon, "item_") != -1           )   // remove bombs
			{	
				RemoveEdict(i);
			}
		}
	}
}    
//***********************************************
RemoveWeapon(client, String:weapon[]){
//***********************************************
new slot, curr_weapon;
GetTrieValue(g_WeaponSlots, weapon, slot);
curr_weapon = GetPlayerWeaponSlot(client, slot);

if(client == 0 || !IsValidEntity(curr_weapon))
	{
	return;
	}
RemovePlayerItem(client, curr_weapon);
}

//***********************************************
SetupOffsets(){
//***********************************************
g_iMyWeapons = FindSendPropOffs("CBaseCombatCharacter", "m_hMyWeapons");
if (g_iMyWeapons == -1)SetFailState("[%s] %s",Plugin_Name,"Error - Unable to get offset for CBaseCombatCharacter::m_hMyWeapons");
g_iHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");
if (g_iHealth == -1)SetFailState("[%s] %s",Plugin_Name,"Error - Unable to get offset for CSSPlayer::m_iHealth");
g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
if (g_iAccount == -1)SetFailState("[%s] %s",Plugin_Name,"Error - Unable to get offset for CSSPlayer::m_iAccount");
g_iSpeed = FindSendPropOffs("CCSPlayer", "m_flLaggedMovementValue");
if (g_iSpeed == -1)SetFailState("[%s] %s",Plugin_Name,"Error - Unable to get offset for CSSPlayer::m_flLaggedMovementValue");
g_iWeaponParent = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");	
if (g_iWeaponParent == -1)SetFailState("[%s] %s",Plugin_Name,"Error - Unable to get offset for CBaseCombatWeapon::m_hOwnerEntity");
}

//***********************************************
public Action:FightTimer(Handle:timer){
//***********************************************
#if defined DEBUG
DebugPrint("FightTimer");
#endif
if ( !isFighting )
{
	#if defined DEBUG
	DebugPrint("FightTimer.No fight");
	#endif

	return Plugin_Stop;
}

if ( fighttimer >= 0 )
{
	#if defined DEBUG
	DebugPrint("FightTimer.countdown %i ",fighttimer);
	#endif	
	PrintHintTextToAll("%t %i %t",MSG_Duel_Timer, fighttimer,"second");
	fighttimer--;
	if ( fighttimer < 6 ) 
	{
		EmitSoundToAll(SOUND_TIMER);
	}	
	return Plugin_Continue;
}
#if defined DEBUG
DebugPrint("FightTimer.fight drow");
#endif
//
// fight draw, fight timer is up
//
CS_TerminateRound(0.1,CSRoundEnd_Draw);
CancelFight();
//CPrintToChatAll("{green}%t",MSG_Duel_Draw);	
//PrintHintTextToAll("%t",MSG_Duel_Draw);
return Plugin_Stop;
}

//***********************************************
//public OnSettingChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
//***********************************************
/*    if      (convar == g_Cvarenabled)               g_enabled           = (newValue[0] == '1');
    else if (convar == g_Cvaralltalk)               g_alltalk           = (newValue[0] == '1');
    else if (convar == g_Cvarblock)                 g_block             = (newValue[0] == '1');
    else if (convar == g_Cvarrandomkill)            g_randomkill        = (newValue[0] == '1');
    else if (convar == g_Cvaruseteleport)           g_useteleport       = (newValue[0] == '1');
    else if (convar == g_Cvarrestorehealth)         g_restorehealth     = (newValue[0] == '1');
    else if (convar == g_Cvarwinnereffects)         g_winnereffects     = (newValue[0] == '1');
    else if (convar == g_Cvarlosereffects)          g_losereffects      = (newValue[0] == '1');
    else if (convar == g_Cvarlocatorbeam)           g_locatorbeam       = (newValue[0] == '1');
    else if (convar == g_Cvarstopmusic)             g_stopmusic         = (newValue[0] == '1');
    else if (convar == g_Cvarforcefight)            g_forcefight        = (newValue[0] == '1');
    else if (convar == g_Cvarwinnerhealth)          g_winnerhealth      = StringToInt(newValue);
    else if (convar == g_Cvarwinnerspeed)           g_winnerspeed       = StringToFloat(newValue);
    else if (convar == g_Cvarwinnermoney)           g_winnermoney       = StringToInt(newValue);
    else if (convar == g_Cvarcountdowntimer)        g_countdowntimer    = StringToInt(newValue);tag mismatch
    else if (convar == g_Cvarfighttimer)            g_fighttimer        = StringToInt(newValue);
    else if (convar == g_Cvarbeaconradius)          g_beaconragius      = StringToFloat(newValue);
    else if (convar == g_Cvarminplayers)            g_minplayers        = StringToInt(newValue);
    else if (convar == g_Cvar_Debug)                g_debug             = (newValue[0] == '1');
    else if (convar == g_Cvar_IsBotFightAllowed)    g_isBotFightAllowed = (newValue[0] == '1');
    else if (convar == g_Cvar_ShowWinner)           g_showWinner        = GetConVarInt(g_Cvar_ShowWinner);
    else if (convar == g_Cvar_RemoveNewPlayer)      g_removeNewPlayer   = GetConVarInt(g_Cvar_RemoveNewPlayer);*/
//}

//***********************************************
public Action:CS_OnBuyCommand(client, const String:weapon[]){
//***********************************************
if ( isFighting ) return Plugin_Handled;
return Plugin_Continue;
}

#endinput

//***********************************************
public Action:VerifyConditions(Handle:timer){
//***********************************************
#if defined DEBUG
DebugPrint("VerifyConditions");
#endif
if (ctid == 0 || tid == 0)return;

if ( IsClientInGame(ctid) && IsPlayerAlive(ctid) && IsClientInGame(tid) &&  IsPlayerAlive(tid) )
    {
        //-> Добавить проверку с ботами разрешено сражение
		//-> Добавить проверку между ботами разрешено сражение
		/*if ( IsFakeClient(ctid) &&  IsFakeClient(tid) )
        {
        //    //if ( !g_isBotFightAllowed )
        //    //{
		#if defined DEBUG
		DebugPrint("VerifyConditions FAILD");
		#endif
            return;
        //    //}
        }*/        
        PrintHintTextToAll("%s %t %s",ctname,"vs",tname);
		CreateTimer(0.1, DelayFight);
    }
}
//***********************************************
public Action:DelayFight(Handle:timer){
#if defined DEBUG
DebugPrint("DelayFight");
#endif
CreateTimer(0.1, StartFight);
}





/*//***********************************************
public Action:ReturnPlayerTeam(Handle:timer){
//***********************************************
//CS_SwitchTeam(ctid, CS_TEAM_CT);
//CS_SwitchTeam(tid, CS_TEAM_T);
}*/


//***********************************************
public OnChangeActiveWeapon(client,Weapon)
//***********************************************
{
#if defined DEBUG
DebugPrint("OnChangeActiveWeapon");
#endif
/*decl String:oldWeaponName[50];
GetEdictClassname(oldWeapon, oldWeaponName, sizeof(oldWeaponName));
if(oldWeapon && !newWeapon && !strcmp(oldWeaponName, "weapon_hegrenade"))
{
// oldWeapon is the ent index of an hegrenade
// do what you need to do here
}*/
}