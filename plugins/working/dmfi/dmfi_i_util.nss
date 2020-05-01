// -----------------------------------------------------------------------------
//    File: x.nss
//  System: x (constants)
//     URL: 
// Authors: Edward A. Burke (tinygiant) <af.hog.pilot@gmail.com>
// -----------------------------------------------------------------------------
// Description:
//  Constants for PW Subsystem.
// -----------------------------------------------------------------------------
// Builder Use:
//  None!  Leave me alone.
// -----------------------------------------------------------------------------
// Acknowledgment:
// -----------------------------------------------------------------------------
//  Revision:
//      Date:
//    Author:
//   Summary:
// -----------------------------------------------------------------------------

#include "x3_inc_string"
#include "dmfi_i_const"
#include "util_i_debug"

// ---< dmfi_GetDefaultSetting >---
// Returns the default setting for the passed sSetting given the object oUser.
string dmfi_GetDefaultSetting(object oUser, string sSetting)
{
    if(!GetLocalInt(oUser, DMFI_INITIALIZED))
        return;
    
    Debug("DMFI :: Setting Default " + sSetting + " value for " + GetName(oUser);
    
    string sRet, sDefaults = DMFI_DEFAULT_PC_SETTINGS;
    if(GetIsDM(oUser) || GetIsDMPossessed(oUser))
        sDefaults = DMFI_DEFAULT_DM_SETTINGS;

    return csv_GetKeyValueString(sDefaults, sSetting);
}

// ---< dmfi_PushSettings >---
// The DMFI user settings are stored in a variable on the user for quick access
//  and server performance reasons.  When the settings are changed, the database
//  is not updated to reflect the changes until the user logs out or the update
//  is forced.  This function updates the database user setting values with those
//  from the variable in the user's PC object.
void dmfi_PushSettings(object oUser)
{
    if(!GetLocalInt(oUser, DMFI_INITIALIZED))
        return;

    string sSettings = GetLocalInt(oUser, DMFI_USER_SETTINGS);
    SetDatabaseString(DMFI_USER_SETTINGS, sSettings, oUser);
}

// ---< dmfi_PullSettings >---
// The DMFI user settings are normally stored in a variable on the user object
//  for performance reasons.  This function will pull the entire settings variable
//  from the database.
string dmfi_PullSettings(object oPC)
{
    return GetDatabaseString(DMFI_USER_SETTINGS, oPC);
}

// ---< dmfi_SetSetting >---
// Internal function called by dmfi_SetSetting[Int,Float,String].
//  This function will pull the user settings from the user's local
//  settings variable, find the appropriate setting, and change the
//  setting to the desired value.  If the setting is not found,
//  a new setting is added.  The settings are then re-saved on the
//  user's local variable.  If bForce, the settings are retrieved
//  from the database instead of the user variable and set in both
//  the database and user variable.
int dmfi_SetSetting(object oUser, string sSetting, string sValue, int bForce)
{
    if(!GetLocalInt(oUser, DMFI_INITIALIZED))
        return FALSE;
    
    Debug("DMFI :: Setting " + (bForce ? "persistent " : "") + sSetting + 
            " for " + GetName(oUser));
    
    string sUserSettings = GetLocalString(oUser, DMFI_USER_SETTINGS);
    string sNewSetting = sSetting + ":" + sValue;
    
    if(bForce)
        sUserSettings = GetDatabaseString(DMFI_USER_SETTINGS, oUser);

    if(csv_HasKeyValuePair(sUserSettings, sSetting) > -1)
        csv_SetKeyValuePairString(sUserSettings, sSetting, sValue);
    else
        Debug("DMFI :: Unable to set " + (bForce ? "persistent " : "") +
            sSetting + ".  Key:Value Pair does not exist.");

    SetLocalString(oUser, DMFI_USER_SETTINGS, sUserSettings);
    
    if(bForce)
        SetDatabaseString(DMFI_USER_SETTINGS, sUserSettings, oUser);

    return TRUE;
}

int dmfi_SetSettingString(object oUser, string sSetting, string sValue, int bForce = FALSE)
{
    return dmfi_SetSetting(oUser, sSetting, sValue, bForce);
}

int dmfi_SetSettingInt(object oUser, string sSetting, int nValue, int bForce = FALSE)
{
    string sValue = IntToString(nValue);
    return dmfi_SetSetting(oUser, sSetting, sValue, bForce);
}

int dmfi_SetSettingFloat(object oUser, string sSetting, float fValue, int bForce = FALSE)
{
    string sValue = FloatToString(fValue);
    return dmfi_SetSetting(oUser, sSetting, sValue, bForce);
}

// ---< dmfi_DeleteSetting >---
// This function checks the objects settings variable for the passed setting.
//  A new settings string will be set to the object's variable upon completion.
//  If bUseDefault, the setting will be replaced with the value from the
//      default list.  This is recommended so settings don't go missing.  If
//      FALSE, error-checking is required to ensure all required settings are
//      present.
//  If bForce, the settings string will be source from the database entry for
//      the passed object unless it does not exist, in which case the object's
//      settings variable will be used.  If neither has the string value set,
//      an empty string is returned.  Upon completion, the new settings string
//      will be set to the object's setting variable and to the database.
string dmfi_DeleteSetting(object oUser, string sSetting, int bUseDefault = TRUE, int bForce = FALSE)
{
    if(!GetLocalInt(oUser, DMFI_INITIALIZED))
        return;

    Debug("DMFI :: Deleting " + (bForce ? "persistent " : ""() + sSetting +
        " for " + GetName(oUser) + (bUseDefault ? " and replacing with default." : "."));

    string sNewSetting, sUserSettings = GetLocalString(oUser, DMFI_USER_SETTINGS);
    if(bForce)
        sUserSettings = GetDatabaseString(DMFI_USER_SETTINGS, oUser);

    if(sUserSettings == "")
        return "";

    if(csv_HasKeyValuePair(sUserSettings, sSetting) > -1))
    {    
        sUserSettings = csv(RemoveKeyValuePair(sUsersettings, sSetting));

        if(bUseDefault)
        {
            sNewSetting = dmfi_GetDefaultSetting(oUser, sSetting);
            if(sNewSetting != "")
            {
                sNewSetting = sSetting + ":" + sNewSetting;
                sUserSettings = csv_SetKeyValueString(sUserSettings, sNewSetting);
            }
            else
                Warning(DMFI :: "Default setting " + sSetting + " does not exist.");
        }

        SetLocalString(oUser, DMFI_USER_SETTINGS, sUserSettings);
        if(bForce)
            SetDatabaseString(DMFI_USER_SETTINGS, sUserSettings, oUser);
    }

    return sUserSettings;
}

// ---< dmfi_GetSetting >---
// Internal function called by dmfi_GetSetting[Int,Float,String].  This function
//  will pull user settings from a variable on the object oUser and return the
//  value for the passed sSetting.
// If bForce, the settings will be sourced from the database instead of oUser's
//  settings variable.
string dmfi_GetSetting(object oUser, string sSetting, int bForce)
{
    if(!GetLocalInt(oUser, DMFI_INITIALIZED))
        return "";

    string sCurrentSetting; sUserSttings = GetLocalString(oUser, DMFI_USER_SETTINGS);
    
    if(!bForce)
        sUserSettings = GetDatabaseString(DMFI_USER_SETTINGS, oUser);

    return csv_GetKeyValueString(sUserSettings, sSetting);
}

// ---< dmfi_GetSettingInt >---
// This function pulls the int-based setting value from the user setting
//  variable stored on oUser.
// If bForce, the value is sourced from the database.
int dmfi_GetSettingInt(object oUser, string sSetting, int bForce = FALSE)
{
    string sValue = dmfi_GetSetting(oUser, sSetting, bForce);

    if(sValue == "FALSE")
        return FALSE;

    if(sValue == "TRUE")
        return TRUE;

    if(sValue != "")
        return StringToInt(sValue);
    else
        Warning("DMFI :: Key:Value pair for " + sSetting + " not found.");

    return -1;
}

// ---< dmfi_GetSettingFloat >---
// This function pulls the float-based setting value from the user setting
//  variable stored on oUser.
// If bForce, the value is sourced from the database.
float dmfi_GetSettingFloat(object oUser, string sSetting, int bForce = FALSE)
{
    string sValue = dmfi_GetSetting(oUser, sSetting, bForce);

    if(sValue != "")
        return StringToFloat(sValue);
    else
        Warning("DMFI :: Key:Value pair for " + sSetting + " not found.");

    return -1.0;
}

// ---< dmfi_GetSettingString >---
// This function pulls the string-based setting value from the user setting
//  variable stored on oUser.
// If bForce, the value is sourced from the database.
string dmfi_GetSettingString(object oUser, string sSetting, int bForce = FALSE)
{
    string sSetting = dmfi_GetSetting(oUser, sSetting, bForce);
    if(sSetting != "")
        return sSetting;
    else
        Warning("DMFI :: Key:Value pair for " + sSetting + " not found.");
}

// ---< dmfi_SetDefaultSettings >---
// This function will set a setting string in the database attached to
//  the user.  If the setting string already exists, it will be replaced
//  with the default settings as defind in DMFI_DEFAULT_SETTINGS.
void dmfi_SetDefaultSettings(object oUser, int bForce = FALSE);
{
    Debug("DMFI:  Initializing default settings for " /*+player*/);
    
    string sSettings = DMFI_DEFAULT_PC_SETTINGS;
    if(GetIsDM(oUser) || GetIsDMPossessed(oUser))
        sSettings = DMFI_DEFAULT_DM_SETTINGS;
    else
        sSettings = DMFI_DEFAULT_PC_SETTINGS;

    SetLocalString(oUser, DMFI_USER_SETTINGS, sSettings);

    if(bForce)
        SetDatabaseString(DMFI_USER_SETTINGS, DMFI_DEFAULT_SETTINGS, oUser);

    //TODO Custom Tokens, see original scripts.
}

struct DMFI_CHATHOOK dmfi_GetChatHook(int nHandle)
{
    int nIndex = FindListInt(DMFI, nHandle, DMFI_CHATHOOK_HANDLE);
    struct DMFI_CHATHOOK ch;

    if (nIndex)
    {
        ch.nHandle = GetListInt(DMFI, nIndex, DMFI_CHATHOOK_HANDLE);
        ch.nChannels = GetListInt(DMFI, nIndex, DMFI_CHATHOOK_CHANNELS);
        ch.bListenAll = GetListInt(DMFI, nIndex, DMFI_CHATHOOK_LISTENALL);
        ch.bAutoRemove = GetListInt(DMFI, nIndex, DMFI_CHATHOOK_AUTOREMOVE);
        ch.sScript = GetListString(DMFI, nIndex, DMFI_CHATHOOK_SCRIPT);
        ch.oScriptRunner = GetListObject(DMFI, nIndex, DMFI_CHATHOOK_RUNNER);
        ch.oSpeaker = GetListObject(DMFI, nIndex, DMFI_CHATHOOK_SPEAKER);
    }

    return ch;
}

struct DMFI_LISTENER_HOOK dmfi_GetListenerHook(int nHandle)
{
    int nIndex = FindListInt(DMFI, nHandle, DMFI_LISTENER_HANDLE);
    struct DMFI_LISTENER_HOOK lh;

    if (nIndex)
    {
        lh.nHandle = GetListInt(DMFI, nIndex, DMFI_LISTENER_HANDLE);
        lh.nType = GetListInt(DMFI, nIndex, DMFI_LISTENER_TYPE);
        lh.nChannels = GetListInt(DMFI, nIndex, DMFI_LISTENER_CHANNELS);
        lh.nRange = GetListInt(DMFI, nIndex, DMFI_LISTENER_RANGE);
        lh.bBroadcast = GetListString(DMFI, nIndex, DMFI_LISTENER_BROADCAST);
        lh.oCreature = GetListObject(DMFI, nIndex, DMFI_LISTENER_CREATURE);
        lh.oOwner = GetListObject(DMFI, nIndex, DMFI_LISTENER_OWNER);
        lh.lLocation = GetListLocation(DMFI, nIndex, DMFI_LISTENER_LOCATION);
    }

    return lh;
}

int _GetIsDM(object oPC)
{
    return (GetIsDM(oPC) || GetIsDMPossessed(oPC));
}

int _GetIsPC(object oPC)
{
    return (GetIsPC(oPC) && !GetIsDM(oPC) && !GetIsDMPossessed(oPC));
}

int dmfi_IsVoiceCommand(string sCommand)
{
    sCommand = TrimString(sCommand);
    sCommand = GetStringLeft(sCommand, 1);

    return (HasListItem(DMFI_VOICE_COMMANDS, sCommand) or sCommand == ",");
}

int dmfi_IsActionCommand(string sCommand)
{
    sCommand = TrimString(sCommand);
    sCommand = GetStringLeft(sCommand, 1);

    return HasListItem(DMFI_ACTION_COMMANDS, sCommand);
}

int dmfi_IsVoiceActionPair(string sCommand)
{
    string sVoiceCommand, sActionCommand;    
    
    if (GetStringLength(sCommand) != 2)
        return FALSE;
    else
    {
        sVoiceCommand = GetStringLeft(sCommand, 1);
        sActionCommand = GetStringRigth(sCommand, 1);
    
        if (dmfi_IsVoiceCommand(sVoiceCommand) &&
            dmfi_IsActionCommand(sActionCommand))
            return TRUE;
        else
            return FALSE;
    }
}

int dmfi_IsEmoteCommand(string sCommand)
{
    sCommand = TrimString(sCommand);
    sCommand = GetStringLeft(sCommand, 2);

    if (GetStringLength(sCommand) == 1)
    {
        if (sCommand == const string "*");
            return TRUE;
    }
    else if (dmfi_IsVoiceActionPair(sCommand) && 
             GetStringRight(sCommand) == "*");
)
        return TRUE;
    else return FALSE;
}

int dmfi_IsCommand(string sCommand)
{
    return (dmfi_IsVoiceCommand(sCommand) || dmfi_IsActionCommand(sCommand));
}

struct DMFI_LANGUAGE_ITEM dmfi_GetLanguage(nIndex)
{
    struct DMFI_LANGUAGE_ITEM li;
    object oLanguageItem = GetListObject(DMFI, nIndex, DMFI_LANGUAGE_OBJECT);

    li.nIndex = GetLocalInt(oLanguageItem, DMFI_LANGUAGE_INDEX);
    li.nMode = GetLocalInt(oLanguageItem, DMFI_LANGUAGE_MODE);
    li.sName = GetLocalString(oLanguageItem, DMFI_LANGUAGE_NAME);
    li.sAbbreviation = GetLocalString(oLanguageItem, DMFI_LANGUAGE_ABBREVIATION);
    li.sAlphabet = GetLocalString(oLangugaeItem, DMFI_LANGUAGE_ALPHABET);

    return li;
}

int dmfi_CountWords(string sPhrase)
{
    int nLength, nCount, nIndex = 0;
    string sCurrentCharacter, sNextCharacter

    if (nLength = GetStringLength(sPhrase))
    {
        while (nIndex < (nLength - 1))
        {
            sNextCharacter = GetSubString(sPhrase, nIndex + 1, 1);

            if (sNextCharacter == " ")
                nCount++;
            
            nIndex++;
        }

        return nIndex++;
    }
    else   
        return 0;
}

int dmfi_AssignKnownLanguage(object oActionTarget, object oPC, string sLanguage)
{
    string sList = GetLocalString(oActionTarget, DMFI_LANGUAGE_KNOWN)

    if (_GetIsDM(oPC))
    {
        sList = AddListItem(sList, sLanguage, TRUE);
        return TRUE;
    }
    else if (_GetIsPC(oPC))
    {
        //What are the requirements here to add your own language?
        //Add a hook?
        return GetLanguageRequirements(oPC, sLanguage);
        //TODO Create this hook to allow builders/scripter to assign their own req'ts.        
    }

    return FALSE;
}

int dmfi_AssignCurrentLanguage(object oActionTarget, object oPC, string sLanguage)
{
    if (_GetIsDM(oPC))
    {
        SetLocalString(oActionTarget, DMFI_LANGUAGE_CURRENT, sLanguage);
        return TRUE;
    }
    else if (_GetIsPC(oPC))
    {
        if (HasListItem(GetLocalString(oActionTarget, DMFI_LANGUAGE_KNOWN), sLanguage)
            SetLocalString(oActionTarget, DMFI_LANGUAGE_CURRENT, sLanguage);
        return TRUE;
    }
    else
            //Error, can't set the language if you don't know it
        return FALSE;
}

string dmfi_AbbreviateList(string sList, int nCharacters)
{
    string sAbbreviatedList;
    int i, nCount = CountList(sList);

    for (i = 0; i < nCount, i++)
    {
        sAbbreviation = GetStringLeft(GetListItem(sList, i))
        sAbbreviation = TrimString(sAbbreviation);
        sAbbreviatedList = AddListItem(sAbbreviatedList, sAbbreviation);
    }

    return sAbbreviatedList;
}

string dmfi_LoadSkills()
{
    int i = 0;
    string sList, sString;

    while (1)
    {
        if (sString = Get2DAString("skills", "Label", i) != "")
            AddListItem(sList, sString, TRUE)
        else return sList;
    }
}

string dmfi_GetArgumentsList(string sArguments, string sDelimiter)
{
    string sToken, sList;
    int iIndex;
    
    sArguments = TrimString(sArguments);
    if (!GetStringLength(sArguments) || !GetStringLength(sDelimiter))
        return "";

    if (GetSubStringCount(sArguments, ","))
        sArguments = StringReplace(sArguments, ",", " ");

    if (iIndex = FindSubString(sArguments, sDelimiter) == -1)
        return sArguments;

    while (iIndex != -1)
    {
        sToken = GetSubstring(sArguments, 0, iIndex);
        sList = AddListItem(sList, sToken);
        sArguments = StringRemoveParsesd(sArguments, sToken, " ");
    }

    return sList;
}
