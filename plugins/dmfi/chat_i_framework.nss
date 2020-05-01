// -----------------------------------------------------------------------------
//    File: x_i_framework.nss
//  System: Core Framework (include script)
//     URL: https://github.com/squattingmonk/nwn-core-framework
// Authors: Michael A. Sinclair (Squatting Monk) <squattingmonk@gmail.com>
// -----------------------------------------------------------------------------
// This is the main include file for the Core Framework. It contains functions
// for managing event hooks and plugins. See the readme for more details.
// -----------------------------------------------------------------------------
// The scripts contains herein are based on those included in Edward Beck's
// HCR2, EPOlson's Common Scripting Framework, and William Bull's Memetic AI.
// -----------------------------------------------------------------------------

#include "chat_i_constants"
#include "util_i_csvlists"
#include "util_i_varlists"
#include "util_i_libraries"
#include "dmfi_i_util"

// -----------------------------------------------------------------------------
//                             Function Prototypes
// -----------------------------------------------------------------------------

// ---< InitializeChatCommands >---
// Calls the system initializer for chat-related items.  These items have
//  specific variables assigned to them to allow them to auto-initialize into
//  the module and provide a system for future expansion without excess
//  scripting.  These items should have tags/resrefs that match the following:
//  <CHAT_INITIALIZER_PREFIX><item name>.  The <item name> portion of the tag/
//  resref must match the entry in CHAT_COMMAND_INVENTORY_CSV.
void InitializeChatCommands();

// ---< GetChatCommandBlacklisted >---
// This system allows DMs and builder to set certain commands to inactive, even
//  if they are loaded into the module.  This purposes of the blacklist is to
//  ensure that players can't use a command that has been inactivated.
// This function returns whether or not a specific command is on the blacklist.
//int GetChatCommandBlacklisted(string sCommand);

// ---< BuildChatCommandBlacklist >---
// Builds the chat command blacklist based on variables set on the chat
//  initializer items.  These variables can be dynamically set through
//  DM conversation or statically set by the builder.
//void BuildChatCommandBlacklist();

// ---< ParsePrefix >---
// Checks to see if the "." is still prefixed to the command.  It should be
//  filters out long before any of these functions are called, but just in case,
//  we'll get rid of it here.
string ParsePrefix (string sCommand);

// ---< RegisterChatCommand >---
// Much like the core framework, chat commands came be registered and
//  routed through the library system to a specific script.  This registration
//  allows the build/scripter to assign multiple options to the same command,
//  allowing flexibility for their players.  For example, to reach the dicebag
//  conversation, the builder/scripter could register .dicebag, .dice, .roll,
//  etc. to the same script and all of the commands would perform the same
//  function.  Subommands can also be created that allows the player to go to
//  a specific sub-fuction, such as .d20 vs .roll d20.  Commands must be unique
//  throughout the system.
void RegisterChatCommand(string sTitle, string sCommands, string sScript);

// ---< RunChatCommand >---
// Once a chat command is recognized by this system and parsed correctly, this
//  function will be called to run the command script, ensuring only appropriate
//  players can do so and that blacklisted functions cannot be called.
int RunChatCommand(string sCommand, object oSpeaker);


// -----------------------------------------------------------------------------
//                             Function Definitions
// -----------------------------------------------------------------------------

void InitializeChatCommands()
{
    //string sCommands, sScript;
    object oChatItem;
    int i, nCount = dmfi_InitializeSystem(CHAT_COMMAND_INVENTORY_CSV,
                                          CHAT_COMMAND_LOADED_CSV,
                                          CHAT_INITIALIZER_PREFIX,
                                          CHAT_OBJECT_LIST,
                                          CHAT_INITIALIZED);

    if (nCount)
    {
        for (i = 0; i < nCount; i++)
        {
            oChatItem = GetListObject(DMFI, CHAT_OBJECT_LIST, i);
            RegisterChatCommandsFromItem(oChatItem);
            //sCommands = GetLocalString(oChatItem, CHAT_COMMAND_CSV);
            //sScript = GetLocalString(oChatItem, CHAT_COMMAND_SCRIPT);

            //RegisterChatCommands(sCommands, sScript);
        }
    }
}

/*int GetChatCommandBlacklisted(string sCommand)
{
    string sBlackList = GetLocalString(DMFI, CHAT_COMMAND_BLACKLIST);
    return HasListString(sBlackList, sCommand);
}*/

/*void BuildChatCommandBlacklist()
{
    int i, j, nCommand, nCount = CountObjectList(DMFI, WAND_OBJECT_LIST);
    string sList, sCommand, sCommands, sBlackList;
    object oItem;

    DeleteLocalString(DMFI, CHAT_COMMAND_BLACKLIST);

    for (i = 0; i < nCount; i++)
    {
        oItem = GetListObject(DMFI, i, CHAT_OBJECT_LIST);
        if (!GetLocalInt(oItem, CHAT_OBJECT_ACTIVE))
        {
            sCommands = GetLocalString(oItem, CHAT_COMMAND_CSV);
            nCommand = CountList(sCommands);

            for (j = 0; j < nCommand; j++)
            {
                sCommand = GetListItem(sCommands, j);
                sCommand = ParsePrefix(sCommand);
                if ()
                {
                    sCommand = StringRemoveParsed(sCommand, ".", ".");
                    sCommands = DeleteListItem(sCommands, j);
                    sCommands = AddListItem(sCommands, sCommand);
                }
            }

            sBlackList = MergeLists(sBlackList, sCommands, TRUE);
        }
    }

    SetLocalString(DMFI, CHAT_COMMAND_BLACKLIST, sBlackList);
}*/

string ParsePrefix(string sCommand)
{
    if (GetStringLeft(sCommand, 1) == ".")
        return StringRemoveParsed(sCommand, ".", ".");
}

//void RegisterChatCommands(string sCommands, string sScript)
int RegisterChatCommandsFromItem(object oChatItem)
{
    if (!GetLocalInt(DMFI, CHAT_INITIALIZED))
        InitializeChatCommands();
    
    if (!GetIsObjectValid(oChatItem))
        return;

    string sAdded, sCommands = GetLocalString(oChatItem, CHAT_COMMAND_CSV);
    string sScript = GetLocalString(oChatItem, CHAT_COMMAND_SCRIPT);
    int i, nIndex, nCount = CountList(sCommands);
    int nActive = GetLocalInt(oChatItem, CHAT_OBJECT_ACTIVE);
    int nCommandCount = CountStringList(CHAT_COMMAND_LIST);

    if (nActive)
    {
        for (i = 0; i < nCount; i++)
        {
            sCommand = GetListItem(sCommands, i);
            sCommand = ParsePrefix(sCommand);
            sCommand = GetStringLowerCase(sCommand);
            if (AddListString(DMFI, sCommand, CHAT_COMMAND_LIST, TRUE))
                AddListString(DMFI, sScript, CHAT_SCRIPT_LIST);
            else
            {
                if (nCount = i)
                {
                    for (i = 0; i < nCount; i++)
                    {
                        sCommand = GetListItem(sCommands, i);
                        nIndex = FindListString(DMFI, sCommand, CHAT_COMMAND_LIST);
                        DeleteListString(DMFI, nIndex, CHAT_COMMAND_LIST);
                        DeleteListString(DMFI, nIndex, CHAT_SCRIPT_LIST);
                    }
                }

                return FALSE;
            }

        return TRUE;
        }
    }

    return FALSE;
}

int RegisterChatCommands(string sCommands, string sScript);
{
    if (sCommands = "" || sScript == "")
        return;

    int i, nCount = CountList(sCommands);
    int nChatItems = CountObjectList(DMFI, CHAT_OBJECT_LIST);

    oChatItem = CreateItemOnObject(CHAT_INITIALIZER_TEMPLATE, DMFI, 1, 
        CHAT_INITIALIZER_AUTO_PREFIX + IntToString(nChatItems + 1));

    SetLocalString(oChatItem, CHAT_COMMAND_CSV, sCommands);
    SetLocalString(oChatItem, CHAT_COMMAND_SCRIPT, sScript);
    SetLocalInt(oChatItem, CHAT_OBJECT_ACTIVE, TRUE);

    return RegisterChatCommandsByObject(oChatItem);
}

int ActivateChatCommands(object oChatItem)
{
    if (!GetIsObjectValid(oChatItem))
        return FALSE;
    
    string sCommands = GetLocalString(oItem, CHAT_COMMAND_CSV);
    string sScript = GetLocalString(oItem, CHAT_COMMAND_SCRIPT);
    int nActive = GetLocalInt(oItem, CHAT_OBJECT_ACTIVE);

    if (nActive)
        RegisterChatCommand(sCommands, sScript);

    return TRUE;
}

int DeactiveateChatCommands(object oChatItem)
{
    if (!GetIsObjectValid(oChatItem))
        return FALSE;
    
    string sCommand, sCommands = GetLocalString(oItem, CHAT_COMMAND_CSV);
    int i, nIndex, nCount = CountList(sCommands);

    for (i = 0; i < nCount; i++)
    {
        sCommand = GetListItem(sCommands, i);
        if((nIndex = FindListString(DMFI, sCommand, CHAT_COMAND_LIST)) != -1)
        {
            DeleteListString(DMFI, i, CHAT_COMMAND_LIST);
            DeleteListString(DMFI, i, CHAT_SCRIPT_LIST);
        }
    }

    return TRUE;
}

int RunChatCommand(string sCommand, object oSpeaker)
{
    int nIndex = FindListString(DMFI, sCommand, CHAT_COMMAND_LIST);
    //string sBlackList;
    
    if (sCommand == "" || !GetIsObjectValid(oSpeaker))
        return FALSE;
    
    if (!GetLocalInt(DMFI, CHAT_INITIALIZED))
        InitializeChatCommands();

    //BuildChatCommandBlacklist();
    sBlackList = GetLocalString(DMFI, CHAT_COMMAND_BLACKLIST);

    sCommand = ParsePrefix(sCommand);
    sCommand = GetStringLowerCase(sCommand);

    /*if (_GetIsPC(oSpeaker))
    {
        if (GetChatCommandBlacklisted(oCommand))
        {
            Debug(GetName(oSpeaker) + " attempted to use the command ." + 
                sCommand + ".  This command is currently blacklisted.");
            return FALSE;
            //TODO Send message to pc
        }   
    }*/

    if (nIndex != -1)
    {
        sScript = GetListString(DMFI, nIndex, CHAT_SCRIPT_LIST);
        RunLibraryScript(sScript);
    }

    //TODO end state bitwise
    return TRUE;
}
