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

#include "nw_i0_generic"

// -----------------------------------------------------------------------------
//                              Function Prototypes
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
//                             Function Definitions
// -----------------------------------------------------------------------------

//:://////////////////////////////////////////////////
//:: NW_C2_DEFAULT4
/*
  Default OnConversation event handler for NPCs.

 */
//:://////////////////////////////////////////////////
//:: Copyright (c) 2002 Floodgate Entertainment
//:: Created By: Naomi Novik
//:: Created On: 12/22/2002
//:://////////////////////////////////////////////////

void NPC_OnConversation()
{
    //DMFI Override for NPC Devault Conversation Handler
    //overrides nw_c2_default4
    
    // * if petrified, jump out
    if (GetHasEffect(EFFECT_TYPE_PETRIFY, OBJECT_SELF) == TRUE)
    {
        return;
    }

    // * If dead, exit directly.
    if (GetIsDead(OBJECT_SELF) == TRUE)
    {
        return;
    }


    // See if what we just 'heard' matches any of our
    // predefined patterns
    int nMatch = GetListenPatternNumber();
    object oShouter = GetLastSpeaker();


    // 2008.05.25 tsunami282 - removed for NWN 1.69 (no longer needed)
    //DMFI CODE ADDITIONS BEGIN HERE
    // if (GetIsPC(oShouter) || GetIsDM(oShouter) || GetIsDMPossessed(oShouter))
    //     {
    //     ExecuteScript("dmfi_voice_exe", OBJECT_SELF);
    //     }

    if (nMatch == -1 && GetIsPC(oShouter) &&(GetLocalInt(GetModule(), "dmfi_AllMute") || GetLocalInt(OBJECT_SELF, "dmfi_Mute")))
    {
        SendMessageToAllDMs(GetName(oShouter) + " is trying to speak to a muted NPC, " + GetName(OBJECT_SELF) + ", in area " + GetName(GetArea(OBJECT_SELF)));
        SendMessageToPC(oShouter, "This NPC is muted. A DM will be here shortly.");
        return;
    }
    //DMFI CODE ADDITIONS END HERE



    if (nMatch == -1)
    {
        // Not a match -- start an ordinary conversation
        if (GetCommandable(OBJECT_SELF))
        {
            ClearActions(CLEAR_NW_C2_DEFAULT4_29);
            BeginConversation();
        }
        else
        // * July 31 2004
        // * If only charmed then allow conversation
        // * so you can have a better chance of convincing
        // * people of lowering prices
        if (GetHasEffect(EFFECT_TYPE_CHARMED) == TRUE)
        {
            ClearActions(CLEAR_NW_C2_DEFAULT4_29);
            BeginConversation();
        }
    }
    // Respond to shouts from friendly non-PCs only
    else if (GetIsObjectValid(oShouter)
               && !GetIsPC(oShouter)
               && GetIsFriend(oShouter))
    {
        object oIntruder = OBJECT_INVALID;
        // Determine the intruder if any
        if(nMatch == 4)
        {
            oIntruder = GetLocalObject(oShouter, "NW_BLOCKER_INTRUDER");
        }
        else if (nMatch == 5)
        {
            oIntruder = GetLastHostileActor(oShouter);
            if(!GetIsObjectValid(oIntruder))
            {
                oIntruder = GetAttemptedAttackTarget();
                if(!GetIsObjectValid(oIntruder))
                {
                    oIntruder = GetAttemptedSpellTarget();
                    if(!GetIsObjectValid(oIntruder))
                    {
                        oIntruder = OBJECT_INVALID;
                    }
                }
            }
        }

        // Actually respond to the shout
        RespondToShout(oShouter, nMatch, oIntruder);
    }

    // Send the user-defined event if appropriate
    if(GetSpawnInCondition(NW_FLAG_ON_DIALOGUE_EVENT))
    {
        SignalEvent(OBJECT_SELF, EventUserDefined(EVENT_DIALOGUE));
    }
}

//::///////////////////////////////////////////////
//:: Default On Attacked
//:: NW_C2_DEFAULT5
//:: Copyright (c) 2001 Bioware Corp.
//:://////////////////////////////////////////////
/*
    If already fighting then ignore, else determine
    combat round
*/
//:://////////////////////////////////////////////
//:: Created By: Preston Watamaniuk
//:: Created On: Oct 16, 2001
//:://////////////////////////////////////////////
//:://////////////////////////////////////////////
//:: Modified By: Deva Winblood
//:: Modified On: Jan 4th, 2008
//:: Added Support for Mounted Combat Feat Support
//:://////////////////////////////////////////////

#include "nw_i0_generic"

//DMFI CODE ADDITIONS*****************************
void SafeFaction(object oCurrent, object oAttacker)
{
        AssignCommand(oAttacker, ClearAllActions());
        AssignCommand(oCurrent, ClearAllActions());
        // * Note: waiting for Sophia to make SetStandardFactionReptuation to clear all personal reputation
        if (GetStandardFactionReputation(STANDARD_FACTION_COMMONER, oAttacker) <= 10)
        {   SetLocalInt(oAttacker, "NW_G_Playerhasbeenbad", 10); // * Player bad
            SetStandardFactionReputation(STANDARD_FACTION_COMMONER, 80, oAttacker);
        }
        if (GetStandardFactionReputation(STANDARD_FACTION_MERCHANT, oAttacker) <= 10)
        {   SetLocalInt(oAttacker, "NW_G_Playerhasbeenbad", 10); // * Player bad
            SetStandardFactionReputation(STANDARD_FACTION_MERCHANT, 80, oAttacker);
        }
        if (GetStandardFactionReputation(STANDARD_FACTION_DEFENDER, oAttacker) <= 10)
        {   SetLocalInt(oAttacker, "NW_G_Playerhasbeenbad", 10); // * Player bad
            SetStandardFactionReputation(STANDARD_FACTION_DEFENDER, 80, oAttacker);
        }


}
//END DMFI CODE ADDITIONS*************************

void NPC_OnAttacked()
{
//DMFI CODE ADDITIONS*****************************
    if ((GetIsPC(GetLastAttacker()) && (GetLocalInt(GetModule(), "dmfi_safe_factions")==1)))
        {
        SafeFaction(OBJECT_SELF, GetLastAttacker());
        SpeakString("DM ALERT:  Default non-hostile faction member attacked.  Player: "+GetName(GetLastAttacker()), TALKVOLUME_SILENT_SHOUT);
        SendMessageToAllDMs("DMFI Safe Faction setting is currently set to ignore.");
        SendMessageToPC(GetLastAttacker(), "Script Fired.");
        return;
        }
//END DMFI CODE ADDITIONS****************************

    if (!GetLocalInt(GetModule(),"X3_NO_MOUNTED_COMBAT_FEAT"))
        { // set variables on target for mounted combat
            SetLocalInt(OBJECT_SELF,"bX3_LAST_ATTACK_PHYSICAL",TRUE);
            SetLocalInt(OBJECT_SELF,"nX3_HP_BEFORE",GetCurrentHitPoints(OBJECT_SELF));
        } // set variables on target for mounted combat

    if(GetFleeToExit()) {
        // Run away!
        ActivateFleeToExit();
    } else if (GetSpawnInCondition(NW_FLAG_SET_WARNINGS)) {
        // We give an attacker one warning before we attack
        // This is not fully implemented yet
        SetSpawnInCondition(NW_FLAG_SET_WARNINGS, FALSE);

        //Put a check in to see if this attacker was the last attacker
        //Possibly change the GetNPCWarning function to make the check
    } else {
        object oAttacker = GetLastAttacker();
        if (!GetIsObjectValid(oAttacker)) {
            // Don't do anything, invalid attacker

        } else if (!GetIsFighting(OBJECT_SELF)) {
            // We're not fighting anyone else, so
            // start fighting the attacker
            if(GetBehaviorState(NW_FLAG_BEHAVIOR_SPECIAL)) {
                SetSummonHelpIfAttacked();
                DetermineSpecialBehavior(oAttacker);
            } else if (GetArea(oAttacker) == GetArea(OBJECT_SELF)) {
                SetSummonHelpIfAttacked();
                DetermineCombatRound(oAttacker);
            }

            //Shout Attack my target, only works with the On Spawn In setup
            SpeakString("NW_ATTACK_MY_TARGET", TALKVOLUME_SILENT_TALK);

            //Shout that I was attacked
            SpeakString("NW_I_WAS_ATTACKED", TALKVOLUME_SILENT_TALK);
        }
    }


    if(GetSpawnInCondition(NW_FLAG_ATTACK_EVENT))
    {
        SignalEvent(OBJECT_SELF, EventUserDefined(EVENT_ATTACKED));
    }
}

//::///////////////////////////////////////////////
//:: Actuvate Item Script
//:: NW_S3_ActItem01
//:: Copyright (c) 2001 Bioware Corp.
//:://////////////////////////////////////////////
/*
    This fires the event on the module that allows
    for items to have special powers.
*/
//:://////////////////////////////////////////////
//:: Created By: Preston Watamaniuk
//:: Created On: Dec 19, 2001
//:://////////////////////////////////////////////
//:: Modified by The DMFI Team to handle activation of DMFI Wands & Widgets

void main()
{
    object oItem = GetSpellCastItem();
    object oTarget = GetSpellTargetObject();
    location lLocal = GetSpellTargetLocation();

    if (GetStringLeft(GetTag(oItem), 5) == "dmfi_" ||
    GetStringLeft(GetTag(oItem), 8) == "hlslang_")
    {
        SetLocalObject(OBJECT_SELF, "dmfi_item", oItem);
        SetLocalObject(OBJECT_SELF, "dmfi_target", oTarget);
        SetLocalLocation(OBJECT_SELF, "dmfi_location", lLocal);
        ExecuteScript("dmfi_activate", OBJECT_SELF);
        return;
    }
    SignalEvent(GetModule(), EventActivateItem(oItem, lLocal, oTarget));
}

//::///////////////////////////////////////////////
//:: x2_sig_state
//:: Copyright (c) 2001 Bioware Corp.
//:://////////////////////////////////////////////
/*
    Sends an event to every party member
    saying I've been put into a disabling state
*/
//:://////////////////////////////////////////////
//:: Created By: Brent
//:: Created On:
//:://////////////////////////////////////////////
#include "x0_inc_henai"

void main()
{
    //SendForHelp();
}
