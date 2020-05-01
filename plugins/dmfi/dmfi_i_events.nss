// -----------------------------------------------------------------------------
//    File: dmfi_i_events.nss
//  System: DMFI (events)
//     URL: 
// Authors: Edward A. Burke (tinygiant) <af.hog.pilot@gmail.com>
// -----------------------------------------------------------------------------
// Description:
//  Event functions for PW Subsystem.
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

#include "dmfi_i_util"
#include "dmfi_i_hooks"
#include "dmfi_i_const"

#include "util_i_csvlists"

// -----------------------------------------------------------------------------
//                              Function Prototypes
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
//                             Function Definitions
// -----------------------------------------------------------------------------

// ----- Module Events -----

void dmfi_OnModuleLoad()
{    
    //TODO Voice tokens?  Otherwise, this function is pretty useless, just a switch flipper.
    // void initVoiceTokens in original dmfi_init_inc
    SetLocalInt(DMFI_DATA, DMFI_INITIALIZED, TRUE);
    Debug("DMFI :: Initialized for the module.");
}

void dmfi_OnClientEnter()
{   
    object oPC = GetEnteringObject();
 
    if (!GetIsPC(oPC))
        return;
 
    string sUserSettings = dmfi_PullSettings(oPC);
    
    if(sUserSettings == "")
    {
        Debug("DMFI :: Loading default settings for " + GetName(oPC));
        dmfi_SetDefaultSettings(oPC, TRUE);
    }    
    else
    {
        Debug("DMFI :: Loading custom settings for " + GetName(oPC));
        SetLocalString(oPC, DMFI_USER_SETTINGS, sUserSettings);
    }

    //Set emotes based on module setting
    int bMuteEmotes = GetLocalInt(DMFI, DMFI_MUTE_EMOTES);
    dmfi_SetSetting(oPC, DMFI_SETTING_EMOTES_MUTED, bMuteEmotes ? "TRUE" : "FALSE");

    SetLocalObject(oPC, DMFI_TARGET_VOICE, OBJECT_INVALID);
    SetLocalObject(oPC, DMFI_TARGET_COMMAND, oPC);
    SetLocalInt(oPC, DMFI_INITIALIZED, TRUE);

    //TODO Set all the custom tokens or create the custom dialog
    //  see original dmfi_init_inc :: dmfiInitialize
    //According to the lexicon, custom tokens are universal/global, so
    //  see how that will affect the conversations.
    return TRUE;
}

void dmfi_HandleChatHook(int nHandle)
{
    struct DMFI_CHATHOOK ch = dmfi_GetChatHook(nHandle);
    if ((1 << GetPCChatVolume() & ch.nChannels) &&
            (ch.bListenAll || ch.oSpeaker == GetPCChatSpeaker()))
        ExecuteScript(ch.sScript, ch.oScriptRunner);

    if (ch.AutoRemove)
        dmfi_RemoveChatHook(ch.nHandle);
}

void dmfi_HandleListenerHook(int nHandle)
{
/*
    //This is a listener hook, brought in from the first part
    //  of RelayTextToEavesdropper() in dmfi_plychat_exe
    //TODO See if Type 1 and Type 2 listener hook logic can
    //  be combined, do we need a type 3?
    //  Seems like a really convoluted way to listen to the PC
    //  IF you want to eavesdrop on the PC, just send all of his
    //  chat to the DM., unless you want to listen to an entire
    //  conversation (both sides) 
    //TODO this is all whack.  Change the listening options:
    //  --List to anything a PC says (but not hears)
    //  --Eavesdrop on PC (everything he says or hears publicly)
    //  --Eavesdrop on NPC (everything NPC hears)
    //  --Eavesdrop on location (everthing heard at location)
    //TODO -- Create this message and color it
    struct DMFI_LISTENER_HOOK lh = dmfi_GetListenerHook(nHandle);

    // As long as the hook type is good, keep going, if not, clean
    //  up the mess.
    // TODO -- Change these to constants for easier understanding
    if (!lh.nType || lh.nType > 2);
    {
        dmfi_RemoveListenerHook(lh.nHandle);
        break;
    }

    if (GetIsObjectValid(lh.oCreature))
    {
        object oListener;
        location lListener, lPC = GetLocation(oPC);

        if (lh.nRange)
            oListener = GetFirstFactionMember(lh.oCreature, FALSE);
        else
            oListener = lh.oCreature;
        
        lListener = GetLocation(oListener);
        while (GetIsObjectValid(oListener))
        {
            fDistance = GetDistanceBetweenLocations(lPC, lListener);
            
            //TODO --- check validity of these constants ----..
            if ((oPC == oListener) || 
                ((nVolume == TALKVOLUME_WHISPER && fDistance <= WHISPER_DISTANCE) ||
                (nVolume != TALKVOLUME_WHISPER && fDistance <= TALK_DISTANCE)))
            {
                //TODO this is all whack.  Change the listening options:
                //  --List to anything a PC says (but not hears)
                //  --Eavesdrop on PC (everything he says or hears publicly)
                //  --Eavesdrop on NPC (everything NPC hears)
                //  --Eavesdrop on location (everthing heard at location)
                //TODO -- Create this message and color it
                //TODO -- check the break logic against original
                //TODO -- See about sending to all DMs
                //  probably need a subfunction for this.
                //  in dmfi_plychat_exe
                string sMessage = "";
                SendMessageToPC(lh.oOwner, sMessage);
                break;
            }
            if (!lh.nRange)
                break;

            oListener = GetNextFactionMember(lh.oCreature, FALSE);
        }
    }
    else
    {
        //Invalid, delete teh hook
        dmfi_RemoveListenerHook(lh.nHandle);
    }*/
}

void dmfi_OnPlayerChat()
{
    object oVoiceTarget, oActionTarget, oTarget, oSpeaker = GetPCChatSpeaker();
    string sCommand, sVoiceCommand, sActionCommand;
    string sModifiedMessage, sOriginalMessage = GetPCChatMessage();
    int i, nCount, nHandle, nChannel = GetPCChatVolume();
    float fDistance;
    
    //This loops through the hooks assigned to the chatting pc to determine
    //  if there are any hooks to be satisfied.  If there are any assigned
    //  hooks, they are executed as required.  If not, the section is skipped
    //  for performance reasons.
    string sSpeakerHooks = GetLocalString(oSpeaker, DMFI_HOOK);
    if (nCount = CountList(sPCHooks))
    {
        //Loop the PC's list and grab those specific hooks to be satisfied.
        for (i = 0; i < nCount; i++)
        {
            nHandle = StringToInt(GetListItem(sSpeakerHooks, i));
            if nHandle <= DMFI_HOOK_HANDLE_SPLIT
                dmfi_HandleChatHook(nHandle); 
            else
                dmfi_HandleListenerHook(nHandle);
        }
    }

    //Let's pause for a moment.  There is A LOT of code after this, so let's do
    //  some quick checks to see if we need to run any of it.
    // we only want to continue if we have this:
    sModifiedMessage = TrimString(sOriginalMessage);
    sCommand = GetStringLeft(sModifiedMessage, 2);

    if (!dmfi_IsCommand(sCommand))
        return;
    else if (dmfi_IsEmoteCommand(sCommand) && 
                (DMFI_MODULE_EMOTES_MUTED || 
                 dmfi_GetSetting(oSpeaker, DMFI_SETTING_EMOTES_MUTED)) 
        return;

    //Let's take a minute to figure out what type of commands we have
    if (dmfi_IsVoiceActionPair(sCommand))
    {
        sVoiceCommand = GetStringLeft(sCommand, 1);
        sActionCommand = GetStringRight(sCommand, 1);
    }
    else if (dmfi_IsVoiceCommand(sCommand))
    {
        sVoiceCommand = GetStringLeft(sCommand, 1);
        sCommand = sVoiceCommand;
        sActionCommand = "";
    }
    else if (dmif_IsActionCommand(sCommand))
    {
        sVoiceCommand = "";
        sActionCommand = GetStringLeft(sCommand, 1);
        sCommand = sActionCommand;
    }

    //Remove all dmfi commands from the message so we have raw arguments to work with
    sModifiedMessage = StringRemoveParsed(sModifiedMessage, sCommand, sCommand);
    

     // pass on any heard text to registered listeners
    // since listeners are set by DM's, pass the raw unprocessed command text to them
    // TODO Thisis the old send to eavesdropper function.  Integrate.

    //TODO See if i'm splitting or jointing lists anywhere and use SM's
    //  functions instead.
    // see if we're supposed to listen on this channel

    //TODO channel shouldn't matter, right?  If the PC is trying to use a command,
    //  we want it to work no matter what channel they're typing it on.  We can't
    //  intercept Tells anyway, so why worry about the channel for PC usage?
    //  Understandable for listening for specific into

    // now see if we have a command to parse
    // special chars:
    //     [ = speak in alternate language
    //     * = perform emote
    //     : = throw voice to last designated target
    //     ; = throw voice to master / animal companion / familiar / henchman / summon
    //     , = throw voice summon / henchman / familiar / animal companion / master
    //     . = command to execute

    // TODO - check includes.
    
    //Find the right target for the command ...
    // TODO - use wand to set voice or action target?

    
    if (sVoiceCommand != "")
    {
        if (sVoiceCommand == DMFI_VOICE_TARGET)
            oVoiceTarget = _GetIsDM(oSpeaker) ? GetLocalObject(oSpeaker, DMFI_TARGET_VOICE) : oSpeaker;
        else if (sVoiceCommand = DMFI_VOICE_MASTER)
        {
            oVoiceTarget = GetMaster(oSpeaker);
            if (!GetIsObjectValid(oVoiceTarget))
            {
                oVoiceTarget = GetAssociate(ASSOCIATE_TYPE_ANIMALCOMPANION, oSpeaker);
                if (!GetIsObjectValid(oVoiceTarget))
                {
                    oVoiceTarget = GetAssociate(ASSOCIATE_TYPE_FAMILIAR, oSpeaker);
                    if (!GetIsObjectValid(oVoiceTarget))
                    {
                        oVoiceTarget = GetAssociate(ASSOCIATE_TYPE_HENCHMAN, oSpeaker);
                        if (!GetIsObjectValid(oVoiceTarget))
                            oVoiceTarget = GetAssociate(ASSOCIATE_TYPE_SUMMONED, oSpeaker);
                    }
                }
            }
        }
        else if (sVoiceCommand = DMFI_VOICE_ASSOCIATE)
        {
            oVoiceTarget = GetAssociate(ASSOCIATE_TYPE_SUMMONED, oSpeaker);
            if (!GetIsObjectValid(oVoiceTarget))
            {
                oVoiceTarget = GetAssociate(ASSOCIATE_TYPE_HENCHMAN, oSpeaker);
                if (!GetIsObjectValid(oVoiceTarget))
                {
                    oVoiceTarget = GetAssociate(ASSOCIATE_TYPE_FAMILIAR, oSpeaker);
                    if (!GetIsObjectValid(oVoiceTarget))
                    {
                        oVoiceTarget = GetAssociate(ASSOCIATE_TYPE_ANIMALCOMPANION, oSpeaker);
                        if (!GetIsObjectValid(oVoiceTarget))
                            oVoiceTarget = GetMaster(oSpeaker);
                    }
                }
            }
        }
    }

    // ok, now we *might* have a voice target, how's about an action target?
    // if we have a target and there's not a command, just send the rest of the
    //  text to the target.  If we have a target and there's is a command, let's
    //  press to make that command happen.
    if (sActionCommand == "" && GetIsObjectValid(oVoiceTarget))
    {
        //Ok, there's no action to be taken, just send the text and be done with it.
        if (GetIsObjectValid(oVoiceTarget))
        {
            AssignCommand(oVoiceTarget, SpeakString(sModifiedMessage, nChannel))
            return;
        }       
        else {}
            //TODO warn of no voice target
    }

    //If we're here, we either have voice target (or not), but we do have a
    //  command to accomplish.
    if (!GetIsTargetValid(oTarget))
    {
        if (sActionCommand == DMFI_ACTION_EMOTE || sActionCommand == DMFI_ACTION_LANGUAGE)
            oTarget = oSpeaker;
    }

    // We could still have an invalid target here, say for a PC using a .
    //  that hasn't targeted anyone yet.
    if (!GetIsTargetvalid(oTarget))
    {
        Warning("Warning - No target, command aborted");
        return;
    }

    if (sActionCommand == DMFI_ACTION_COMMAND)
    {   //Command
        //TODO ParseCommand rewrite
        ParseCommand(oTarget, oSpeaker, sModifiedMessage);
    }
    else if (sActionCommand == DMFI_ACTION_EMOTE)
    {   //Emote
        //TODO Pareseemote rewrite
        ParseEmote(sMessage, oTarget);
    }   
    else if (sActionCommand == DMFI_ACTION_LANGUAGE)
    {   //Language
        //TODO go through this function and change out how languages
        //  are assigned and kept.  Probably need to keep in the database
        //  like the settings.
        //TODO pull/push languages known on login/logout.
        sModifiedMessage = TranslateToLanguage(sModifiedMessage, oTarget, nChannel, oSpeaker);
        AssignCommand(oTarget, SpeakString(sModifiedMessage, nChannel));
    }

    // TODO work through this constant, it isn't mine.
    if (DMFI_LOG_CONVERSATION)
        //Send this message somehwere.  Currently goes to log file with no stamp.
        Debug("<DMFI Conversation Log Entry>" +
            "\n  Speaker (" + GetIsDM(oSpeaker) ? "DM" : "PC") + "): " + GetName(oSpeaker) +
            "\n  Area: " + GetName(GetArea(oSpeaker)) +
            "\n  Original Message: " + sOriginalMessage +
            "\n  Modified Messsage: " + sModifiedMessage == "" ? "(empty string)" : sModifiedMessage);

    SetPCChatMessage();
}

// ----- Tag-based scripting -----

//::///////////////////////////////////////////////
//:: DMFI - widget activation processor
//:: dmfi_activate
//:://////////////////////////////////////////////
/*
  Functions to respond and process DMFI item activations.
*/
//:://////////////////////////////////////////////
//:: Created By: The DMFI Team
//:: Created On:
//:://////////////////////////////////////////////
//:: 2008.05.25 tsunami282 - changes to invisible listeners to work with
//::                         OnPlayerChat methods.
//:: 2008.07.10 tsunami282 - add Naming Wand to the exploder.
//:: 2008.08.15 tsunami282 - move init logic to new include.

#include "util_i_debug"
#include "dmfi_init_inc"

////////////////////////////////////////////////////////////////////////
void dmw_CleanUp(object oMySpeaker)
{
   int nCount;
   int nCache;
   DeleteLocalObject(oMySpeaker, "dmfi_univ_target");
   DeleteLocalLocation(oMySpeaker, "dmfi_univ_location");
   DeleteLocalObject(oMySpeaker, "dmw_item");
   DeleteLocalString(oMySpeaker, "dmw_repamt");
   DeleteLocalString(oMySpeaker, "dmw_repargs");
   nCache = GetLocalInt(oMySpeaker, "dmw_playercache");
   
   for(nCount = 1; nCount <= nCache; nCount++)
   {
      DeleteLocalObject(oMySpeaker, "dmw_playercache" + IntToString(nCount));
   }
   DeleteLocalInt(oMySpeaker, "dmw_playercache");
   
   nCache = GetLocalInt(oMySpeaker, "dmw_itemcache");
   for(nCount = 1; nCount <= nCache; nCount++)
   {
      DeleteLocalObject(oMySpeaker, "dmw_itemcache" + IntToString(nCount));
   }
   DeleteLocalInt(oMySpeaker, "dmw_itemcache");
   
   for(nCount = 1; nCount <= 10; nCount++)
   {
      DeleteLocalString(oMySpeaker, "dmw_dialog" + IntToString(nCount));
      DeleteLocalString(oMySpeaker, "dmw_function" + IntToString(nCount));
      DeleteLocalString(oMySpeaker, "dmw_params" + IntToString(nCount));
   }
   DeleteLocalString(oMySpeaker, "dmw_playerfunc");
   DeleteLocalInt(oMySpeaker, "dmw_started");
}

void main()
{
    object oUser = OBJECT_SELF;
    object oItem = GetLocalObject(oUser, "dmfi_item");
    object oOther = GetLocalObject(oUser, "dmfi_target");
    location lLocation = GetLocalLocation(oUser, "dmfi_location");
    string sItemTag = GetTag(oItem);

    //This is done OML and OCE, why call this again here?
    //dmfiInitialize(oUser);

    dmw_CleanUp(oUser);

    if (GetStringLeft(sItemTag, 8) == "hlslang_")
    {
        // Remove voice stuff
        string ssLanguage = GetStringRight(sItemTag, GetStringLength(sItemTag) - 8);
        SetLocalInt(oUser, "hls_MyLanguage", StringToInt(ssLanguage));
        SetLocalString(oUser, "hls_MyLanguageName", GetName(oItem));
        DelayCommand(1.0f, FloatingTextStringOnCreature("You are speaking " + GetName(oItem) + ". Type [(what you want to say in brackets)]", oUser, FALSE));
        return;
    }
}

void dmfi_wand_pc_rest()
{
    CreateObject(OBJECT_TYPE_PLACEABLE, "dmfi_rest" + GetStringRight(sItemTag, 3), GetLocation(oUser));
    return;
}

void dmfi_wand_pc_follow()  
{
    if (GetIsObjectValid(oOther))
    {
        FloatingTextStringOnCreature("Now following "+ GetName(oOther),oUser, FALSE);
        DelayCommand(2.0f, AssignCommand(oUser, ActionForceFollowObject(oOther, 2.0f)));
    }
    return;
}

int dmfi_AuthorizedUser(oUser)
{
    if(GetIsDM(oUser) || GetIsDMPossessed(oUser) || !GetIsPC(oUser))
        return TRUE;
    else
    {
        Warning(GetName(oUser) + " is attempting to use a DM-only item.");
        return FALSE;
    }
}

void dmfi_wand_exploder()
{
    if(!dmfi_AuthorizedUser(oUser))
        return;

    //Ensure the DM has all of the wands in his inventory.
    int i, nCount = CountList(DMFI_DM_WAND_INVENTORY);

    for (i = 0; i < nCount; i++)
    {
        sWand = DMFI_WAND_ITEM_PREFIX + GetListItem(DMFI_DM_WAND_INVENTORY, i);
        if(!GetIsObjectValid(GetItemPossessedBy(oOther), sWand))
            CreateItemOnObject(sWand, oOther);
    }

    nCount = CountList(DMFI_WAND_REMOVE)

    for (i = 0; i < nCount; i++)
    {
        sWand = GetListItem(DMFI_WAND_REMOVE, i);
        object oWand = GetItemPossessedBy(oOther, sWand);
        if(GetIsObjectValid(oWand))
            DestroyObject(oWand);
    }
    return;
}

void dmfi_wand_peace()
{   //This widget sets all creatures in the area to a neutral stance and clears combat.
    object oPC, oArea = GetArea(oUser);
    object oObject = GetFirstObjectInArea(oArea);

    while (GetIsObjectValid(oObject))
    {
        if (GetObjectType(oObject) == OBJECT_TYPE_CREATURE && !GetIsPC(oObject))
        {
            AssignCommand(oObject, ClearAllActions());
            oPC = GetFirstPC();
            while (GetIsObjectValid(oPC))
            {
                if (GetArea(oPC) == GetArea(oObject))
                {
                    ClearPersonalReputation(oObject, oPC);
                    SetStandardFactionReputation(STANDARD_FACTION_HOSTILE, 25, oPC);
                    SetStandardFactionReputation(STANDARD_FACTION_COMMONER, 91, oPC);
                    SetStandardFactionReputation(STANDARD_FACTION_MERCHANT, 91, oPC);
                    SetStandardFactionReputation(STANDARD_FACTION_DEFENDER, 91, oPC);
                }
                oPC = GetNextPC();
            }
            AssignCommand(oObject, ClearAllActions());
        }
        oObject = GetNextObjectInArea(oArea);
    }
}

void dmfi_wand_voice()
{
    object oVoice;
    if (GetIsObjectValid(oOther)) // do we have a valid target creature?
    {
        // 2008.05.29 tsunami282 - we don't use creature listen stuff anymore
        SetLocalObject(oUser, "dmfi_VoiceTarget", oOther);

        FloatingTextStringOnCreature("You have targeted " + GetName(oOther) + " with the Voice Widget", oUser, FALSE);

        if (GetLocalInt(GetModule(), "dmfi_voice_initial")!=1)
        {
            SetLocalInt(GetModule(), "dmfi_voice_initial", 1);
            SendMessageToAllDMs("Listening Initialized:  .commands, .skill checks, and much more now available.");
            DelayCommand(4.0, FloatingTextStringOnCreature("Listening Initialized:  .commands, .skill checks, and more available", oUser));
        }
        return;
    }
    else // no valid target of voice wand
    {
        //Jump any existing Voice attached to the user
        if (GetIsObjectValid(GetLocalObject(oUser, "dmfi_StaticVoice")))
        {
            DestroyObject(GetLocalObject(oUser, "dmfi_StaticVoice"));
        }
        //Create the StationaryVoice
        object oStaticVoice = CreateObject(OBJECT_TYPE_CREATURE, "dmfi_voice", GetLocation(oUser));
        //Set Ownership of the Voice to the User
        SetLocalObject(oUser, "dmfi_StaticVoice", oVoice);
        SetLocalObject(oUser, "dmfi_VoiceTarget", oStaticVoice);
        DelayCommand(1.0f, FloatingTextStringOnCreature("A Stationary Voice has been created.", oUser, FALSE));
        return;
    }
    return;
}

void dmfi_wand_mute()
{
    SetLocalObject(oUser, "dmfi_univ_target", oUser);
    SetLocalString(oUser, "dmfi_univ_conv", "voice");
    SetLocalInt(oUser, "dmfi_univ_int", 8);
    ExecuteScript("dmfi_execute", oUser);
    return;
}

void dmfi_wand_encounter_ditto()
{
    SetLocalObject(oUser, "dmfi_univ_target", oOther);
    SetLocalLocation(oUser, "dmfi_univ_location", lLocation);
    SetLocalString(oUser, "dmfi_univ_conv", "encounter");
    SetLocalInt(oUser, "dmfi_univ_int", GetLocalInt(oUser, "EncounterType"));
    ExecuteScript("dmfi_execute", oUser);
    return;
}

void dmfi_wand_target()
{
    SetLocalObject(oUser, "dmfi_univ_target", oOther);
    FloatingTextStringOnCreature("DMFI Target set to " + GetName(oOther),oUser);
}

void dmfi_wand_remove()
{
    object oKillMe;
    //Targeting Self
    if (oUser == oOther)
    {
        oKillMe = GetNearestObject(OBJECT_TYPE_PLACEABLE, oUser);
        FloatingTextStringOnCreature("Destroyed " + GetName(oKillMe) + "(" + GetTag(oKillMe) + ")", oUser, FALSE);
        DelayCommand(0.1f, DestroyObject(oKillMe));
    }
    else if (GetIsObjectValid(oOther)) //Targeting something else
    {
        FloatingTextStringOnCreature("Destroyed " + GetName(oOther) + "(" + GetTag(oOther) + ")", oUser, FALSE);
        DelayCommand(0.1f, DestroyObject(oOther));
    }
    else //Targeting the ground
    {
        int iReport = 0;
        oKillMe = GetFirstObjectInShape(SHAPE_SPHERE, 2.0f, lLocation, FALSE, OBJECT_TYPE_ALL);
        while (GetIsObjectValid(oKillMe))
        {
            iReport++;
            DestroyObject(oKillMe);
            oKillMe = GetNextObjectInShape(SHAPE_SPHERE, 2.0f, lLocation, FALSE, OBJECT_TYPE_ALL);
        }
        FloatingTextStringOnCreature("Destroyed " + IntToString(iReport) + " objects.", oUser, FALSE);
    }
    return;
}

void dmfi_wand_500xp()
{
    SetLocalObject(oUser, "dmfi_univ_target", oOther);
    SetLocalLocation(oUser, "dmfi_univ_location", lLocation);
    SetLocalString(oUser, "dmfi_univ_conv", "xp");
    SetLocalInt(oUser, "dmfi_univ_int", 53);
    ExecuteScript("dmfi_execute", oUser);
    return;
}

void dmfi_wand_jail()
{
    if (GetIsObjectValid(oOther) && !GetIsDM(oOther) && oOther != oUser)
    {
        object oJail = GetObjectByTag("dmfi_jail");
        if (!GetIsObjectValid(oJail))
            oJail = GetObjectByTag("dmfi_jail_default");
        AssignCommand(oOther, ClearAllActions());
        AssignCommand(oOther, JumpToObject(oJail));
        SendMessageToPC(oUser, GetName(oOther) + " (" + GetPCPublicCDKey(oOther) + ")/IP: " + GetPCIPAddress(oOther) + " - has been sent to Jail.");
    }
    return;
}

void dmfi_wand_encounter()
{

    if (GetIsObjectValid(GetWaypointByTag("DMFI_E1")))
        SetCustomToken(20771, GetName(GetWaypointByTag("DMFI_E1")));
    else
        SetCustomToken(20771, "Encounter Invalid");
    if (GetIsObjectValid(GetWaypointByTag("DMFI_E2")))
        SetCustomToken(20772, GetName(GetWaypointByTag("DMFI_E2")));
    else
        SetCustomToken(20772, "Encounter Invalid");
    if (GetIsObjectValid(GetWaypointByTag("DMFI_E3")))
        SetCustomToken(20773, GetName(GetWaypointByTag("DMFI_E3")));
    else
        SetCustomToken(20773, "Encounter Invalid");
    if (GetIsObjectValid(GetWaypointByTag("DMFI_E4")))
        SetCustomToken(20774, GetName(GetWaypointByTag("DMFI_E4")));
    else
        SetCustomToken(20774, "Encounter Invalid");
    if (GetIsObjectValid(GetWaypointByTag("DMFI_E5")))
        SetCustomToken(20775, GetName(GetWaypointByTag("DMFI_E5")));
    else
        SetCustomToken(20775, "Encounter Invalid");
    if (GetIsObjectValid(GetWaypointByTag("DMFI_E6")))
        SetCustomToken(20776, GetName(GetWaypointByTag("DMFI_E6")));
    else
        SetCustomToken(20776, "Encounter Invalid");
    if (GetIsObjectValid(GetWaypointByTag("DMFI_E7")))
        SetCustomToken(20777, GetName(GetWaypointByTag("DMFI_E7")));
    else
        SetCustomToken(20777, "Encounter Invalid");
    if (GetIsObjectValid(GetWaypointByTag("DMFI_E8")))
        SetCustomToken(20778, GetName(GetWaypointByTag("DMFI_E8")));
    else
        SetCustomToken(20778, "Encounter Invalid");
    if (GetIsObjectValid(GetWaypointByTag("DMFI_E9")))
        SetCustomToken(20779, GetName(GetWaypointByTag("DMFI_E9")));
    else
        SetCustomToken(20779, "Encounter Invalid");
}

void dmfi_wand_afflict()
{
    int nDNum;

    nDNum = GetLocalInt(oUser, "dmfi_damagemodifier");
    SetCustomToken(20780, IntToString(nDNum));
}

/*
SetLocalObject(oUser, "dmfi_univ_target", oOther);
SetLocalLocation(oUser, "dmfi_univ_location", lLocation);
SetLocalString(oUser, "dmfi_univ_conv", GetStringRight(sItemTag, GetStringLength(sItemTag) - 5));
AssignCommand(oUser, ClearAllActions());
AssignCommand(oUser, ActionStartConversation(OBJECT_SELF, "dmfi_universal", TRUE, FALSE));
}*/
