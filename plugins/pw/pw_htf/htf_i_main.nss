// -----------------------------------------------------------------------------
//    File: x_i_main.nss
//  System: x Item on Drop (core)
//     URL: 
// Authors: Edward A. Burke (tinygiant) <af.hog.pilot@gmail.com>
// -----------------------------------------------------------------------------
// Description:
//  Core functions for PW Subsystem.
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

#include "pw_i_core"
#include "htf_i_const"
#include "htf_i_config"
#include "htf_i_text"

// -----------------------------------------------------------------------------
//                              Function Prototypes
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
//                             Function Definitions
// -----------------------------------------------------------------------------

float h2_GetHungerDecrement()
{
    return 1.0 / H2_HT_BASE_HUNGER_HOURS;
}

float h2_GetThirstDecrement(object oPC)
{
    int conScore = GetAbilityScore(oPC, ABILITY_CONSTITUTION, TRUE);

    return 1.0 / (H2_HT_BASE_THIRST_HOURS + conScore);
}

void h2_DisplayHTInfoBars(object oPC)
{
    if (!GetIsPC(oPC) || GetIsDM(oPC)) return;

    int thirstCount = FloatToInt(GetLocalFloat(oPC, H2_HT_CURR_THIRST) * 100.0);
    int hungerCount = FloatToInt(GetLocalFloat(oPC, H2_HT_CURR_HUNGER) * 100.0);
    
    string greenBar = StringToRGBString(GetSubString(H2_HT_INFO_BAR, 0, hungerCount), H2_HT_COLOR_GREEN);
    string redBar = StringToRGBString(GetSubString(H2_HT_INFO_BAR, hungerCount, 100 -  hungerCount), H2_HT_COLOR_RED);
    SendMessageToPC(oPC, H2_TEXT_HUNGER + greenBar + redBar);
    
    greenBar = StringToRGBString(GetSubString(H2_HT_INFO_BAR, 0, thirstCount), H2_HT_COLOR_GREEN);
    redBar = StringToRGBString(GetSubString(H2_HT_INFO_BAR, thirstCount, 100 - thirstCount), H2_HT_COLOR_RED);
    SendMessageToPC(oPC, H2_TEXT_THIRST + greenBar + redBar);
}

void h2_InitHungerThirstCheck(object oPC)
{
    if (!GetLocalInt(oPC, H2_HT_IS_DEHYDRATED) && GetLocalFloat(oPC, H2_HT_CURR_THIRST) == 0.0)
        SetLocalFloat(oPC, H2_HT_CURR_THIRST, 1.0);
    if (!GetLocalInt(oPC, H2_HT_IS_STARVING) && GetLocalFloat(oPC, H2_HT_CURR_HUNGER) == 0.0)
        SetLocalFloat(oPC, H2_HT_CURR_HUNGER, 1.0);

    int timerID = CreateTimer(oPC, H2_HT_ON_TIMER_EXPIRE, 120.0, 0, 0);
    //int timerID = h2_CreateTimer(oPC, H2_HT_TIMER_SCRIPT, HoursToSeconds(1), FALSE);
    //int timerID = h2_CreateTimer(oPC, H2_HT_TIMER_SCRIPT, 10.0, FALSE);
    StartTimer(timerID, FALSE);
    //h2_StartTimer(timerID);

    if (GetIsPC(oPC) && H2_HT_DISPLAY_INFO_BARS)
        h2_DisplayHTInfoBars(oPC);
}

void h2_ApplyHTFatigue(object oPC)
{
    effect eStr = EffectAbilityDecrease(ABILITY_STRENGTH, 2);
    effect eDex = EffectAbilityDecrease(ABILITY_DEXTERITY, 2);
    eDex = SupernaturalEffect(EffectLinkEffects(eStr, eDex));
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eDex, oPC);
}

void h2_RemoveHTFatigue(object oPC)
{
    effect eEff = GetFirstEffect(oPC);
    while (GetEffectType(eEff) != EFFECT_TYPE_INVALIDEFFECT)
    {
        if (GetEffectType(eEff) == EFFECT_TYPE_ABILITY_DECREASE &&
            GetEffectDurationType(eEff) == DURATION_TYPE_PERMANENT &&
            GetEffectSubType(eEff) == SUBTYPE_SUPERNATURAL &&
            GetEffectSpellId(eEff) == -1 &&
            GetEffectCreator(eEff) == oPC)
        {
            RemoveEffect(oPC, eEff);
        }
        eEff = GetNextEffect(oPC);
    }
}

void h2_DoThirstFortitudeCheck(object oPC)
{
    SetLocalInt(oPC, H2_HT_IS_DEHYDRATED, TRUE);
    int thirstSaveCount = GetLocalInt(oPC, H2_HT_THIRST_SAVE_COUNT);
    SendMessageToPC(oPC, H2_TEXT_DEHYDRATION_SAVE);
    if (!FortitudeSave(oPC, thirstSaveCount + 10))
    {
        int nonlethaldamage = GetLocalInt(oPC, H2_HT_THIRST_NONLETHAL_DAMAGE);
        if (nonlethaldamage == 0 && GetLocalInt(oPC, H2_HT_HUNGER_NONLETHAL_DAMAGE) == 0)
            h2_ApplyHTFatigue(oPC);
        nonlethaldamage += d6();
        SetLocalInt(oPC, H2_HT_THIRST_NONLETHAL_DAMAGE, nonlethaldamage);
        if (nonlethaldamage > GetMaxHitPoints(oPC))
            ExecuteScript(H2_HT_DAMAGE_SCRIPT, oPC);
    }
    SetLocalInt(oPC, H2_HT_THIRST_SAVE_COUNT, thirstSaveCount + 1);
}

void h2_DoHungerFortitudeCheck(object oPC)
{
    SetLocalInt(oPC, H2_HT_IS_STARVING, TRUE);
    int hourCount = GetLocalInt(oPC, H2_HT_HUNGER_HOUR_COUNT);
    if (hourCount == 24)
        hourCount = 0;
    SetLocalInt(oPC, H2_HT_HUNGER_HOUR_COUNT, hourCount + 1);
    if (hourCount != 0)
        return;
    int hungerSaveCount = GetLocalInt(oPC, H2_HT_HUNGER_SAVE_COUNT);
    SendMessageToPC(oPC, H2_TEXT_STARVATION_SAVE);
    if (!FortitudeSave(oPC, hungerSaveCount + 10))
    {
        int nonlethaldamage = GetLocalInt(oPC, H2_HT_HUNGER_NONLETHAL_DAMAGE);
        if (nonlethaldamage == 0 && GetLocalInt(oPC, H2_HT_THIRST_NONLETHAL_DAMAGE) == 0)
            h2_ApplyHTFatigue(oPC);
        nonlethaldamage +=  d6();
        SetLocalInt(oPC, H2_HT_HUNGER_NONLETHAL_DAMAGE, nonlethaldamage);
        if (nonlethaldamage > GetMaxHitPoints(oPC))
            ExecuteScript(H2_HT_DAMAGE_SCRIPT, oPC);
    }
    SetLocalInt(oPC, H2_HT_HUNGER_SAVE_COUNT, hungerSaveCount + 1);
}

void h2_PerformHungerThirstCheck(object oPC, float fCustomThirstDecrement = -1.0, float fCustomHungerDecrement = -1.0)
{
    if (h2_GetPlayerPersistentInt(oPC, H2_PLAYER_STATE) == H2_PLAYER_STATE_DEAD)
    {
        DeleteLocalFloat(oPC, H2_HT_CURR_ALCOHOL);
        int timerID = GetLocalInt(oPC, H2_HT_DRUNK_TIMERID);
        KillTimer(timerID);
        //h2_KillTimer(timerID);
        DeleteLocalInt(oPC, H2_HT_DRUNK_TIMERID);
        return;
    }
    int conScore = GetAbilityScore(oPC, ABILITY_CONSTITUTION, TRUE);

    //tinygiant - 20200125
    //Used to implement the new argument added for custom fatigue decrements.
    float thirstDrop = (fCustomThirstDecrement >= 0.0) ? fCustomThirstDecrement : h2_GetThirstDecrement(oPC);
    float hungerDrop = (fCustomHungerDecrement >= 0.0) ? fCustomHungerDecrement : h2_GetHungerDecrement();

    int ad = 26 - conScore;
    ad = (ad <= 0 ? 1 : ad);
    float alcoholDrop = 2.0 / ad;

    float currThirst = GetLocalFloat(oPC, H2_HT_CURR_THIRST);
    if (currThirst > 0.0)
        currThirst = currThirst - thirstDrop;
    if (currThirst < 0.0)
        currThirst = 0.0;
    float currHunger = GetLocalFloat(oPC, H2_HT_CURR_HUNGER);
    if (currHunger > 0.0)
        currHunger = currHunger - hungerDrop;
    if (currHunger < 0.0)
        currHunger = 0.0;
    float currAlcohol = GetLocalFloat(oPC, H2_HT_CURR_ALCOHOL);
    if (currAlcohol > 0.0)
        currAlcohol = currAlcohol - alcoholDrop;
    if (currAlcohol < 0.0)
        currAlcohol = 0.0;
    if (currAlcohol < 0.4)
    {
        int timerID = GetLocalInt(oPC, H2_HT_DRUNK_TIMERID);
        KillTimer(timerID);
        //h2_KillTimer(timerID);
        DeleteLocalInt(oPC, H2_HT_DRUNK_TIMERID);
    }
    SetLocalFloat(oPC, H2_HT_CURR_THIRST, currThirst);
    SetLocalFloat(oPC, H2_HT_CURR_HUNGER, currHunger);
    SetLocalFloat(oPC, H2_HT_CURR_ALCOHOL, currAlcohol);

    if (H2_HT_DISPLAY_INFO_BARS)
        h2_DisplayHTInfoBars(oPC);

    if (currThirst == 0.0)
        h2_DoThirstFortitudeCheck(oPC);
    else
        DeleteLocalInt(oPC, H2_HT_THIRST_SAVE_COUNT);
    if (currHunger == 0.0)
        h2_DoHungerFortitudeCheck(oPC);
    else
    {
        DeleteLocalInt(oPC, H2_HT_HUNGER_HOUR_COUNT);
        DeleteLocalInt(oPC, H2_HT_HUNGER_SAVE_COUNT);
    }
}

void h2_ApplyAlchoholEffects(object oPC, object oItem)
{
    float alcoholValue = GetLocalFloat(oItem, H2_HT_ALCOHOL_VALUE) / 200.0;
    if (alcoholValue > 0.0)
    {
        float currAlcohol = GetLocalFloat(oPC, H2_HT_CURR_ALCOHOL) + alcoholValue;
        if (currAlcohol > 1.0)
            currAlcohol = 1.0;
        SetLocalFloat(oPC, H2_HT_CURR_ALCOHOL, currAlcohol);
        if (GetLocalInt(oPC, H2_HT_DRUNK_TIMERID) == 0 && currAlcohol >= 0.4)
        {
            int timerID = CreateTimer(oPC, H2_HT_DRUNK_ON_TIMER_EXPIRE, 150.0, 0, 30);
            //int timerID = h2_CreateTimer(oPC, H2_HT_DRUNK_TIMER_SCRIPT, 150.0);
            SetLocalInt(oPC, H2_HT_DRUNK_TIMERID, timerID);
            StartTimer(timerID, TRUE);
            //h2_StartTimer(timerID);
        }

        int dropRate = 26 - GetAbilityScore(oPC, ABILITY_CONSTITUTION, TRUE);
        if (dropRate <= 0)
            dropRate = 1;
        float duration = (HoursToSeconds(1) * ((currAlcohol * dropRate))) / 2;
        if (currAlcohol == 1.0)
        {
            if (!FortitudeSave(oPC, 15))
            {
                if (GetRacialType(oPC) == RACIAL_TYPE_ELF || GetRacialType(oPC) == RACIAL_TYPE_HALFELF)
                    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectKnockdown(), oPC, 120.0);
                else
                    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectSleep(), oPC, 120.0);
                AssignCommand(oPC, SpeakString(H2_TEXT_ALCOHOL_PASSED_OUT));
                ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectBlindness(), oPC, 120.0);
            }
        }
        int DC = FloatToInt(currAlcohol * 17);
        int fortSave = GetFortitudeSavingThrow(oPC);
        if (currAlcohol >= 0.95 && fortSave + d20() < DC)
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectSpellFailure(25), oPC, duration);
        if (currAlcohol >= 0.85 && fortSave + d20() < DC)
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectMovementSpeedDecrease(20), oPC, duration);
        if (currAlcohol >= 0.75 && fortSave + d20() < DC)
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectAbilityDecrease(ABILITY_STRENGTH, 1), oPC, duration);
        if (currAlcohol >= 0.65 && fortSave + d20() < DC)
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectAbilityDecrease(ABILITY_CHARISMA, 1), oPC, duration);
        if (currAlcohol >= 0.55 && fortSave + d20() < DC)
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectAbilityDecrease(ABILITY_DEXTERITY, 1), oPC, duration);
        if (currAlcohol >= 0.45 && fortSave + d20() < DC)
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectAbilityDecrease(ABILITY_INTELLIGENCE, 1), oPC, duration);
        if (currAlcohol >= 0.35 && fortSave + d20() < DC)
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectAbilityDecrease(ABILITY_WISDOM, 1), oPC, duration);
        if (currAlcohol >= 0.25 && fortSave + d20() < DC)
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectAttackDecrease(1), oPC, duration);

        if (DC >= 5 && currAlcohol < 1.0 && fortSave + d20() < DC)
        {
            switch (d6())
            {
                case 1: AssignCommand(oPC, SpeakString(H2_TEXT_ALCOHOL_BELCHES)); break;
                case 2: AssignCommand(oPC, SpeakString(H2_TEXT_ALCOHOL_HICCUPS)); break;
                case 3: AssignCommand(oPC, SpeakString(H2_TEXT_ALCOHOL_STUMBLES));
                        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectStunned(), oPC, 10.0);
                        break;
                case 4: AssignCommand(oPC, SpeakString(H2_TEXT_ALCOHOL_FALLS_DOWN));
                        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectKnockdown(), oPC, 3.0);
                        break;
                case 5:
                case 6: AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_PAUSE_DRUNK, 1.0, 3.0)); break;
            }
        }
    }
}

void h2_ApplyHungerBonus(object oPC, object oItem)
{
    float hungerValue = GetLocalFloat(oItem, H2_HT_HUNGER_VALUE) / 300.0;
    if (hungerValue > 0.0)
    {
        float currHunger = GetLocalFloat(oPC, H2_HT_CURR_HUNGER) + hungerValue;
        if (currHunger > 1.0)
        {
            currHunger = 1.0;
            SendMessageToPC(oPC, H2_TEXT_NOT_HUNGRY);
        }
        SetLocalFloat(oPC, H2_HT_CURR_HUNGER, currHunger);
        if (GetLocalInt(oPC, H2_HT_HUNGER_NONLETHAL_DAMAGE) && !GetLocalInt(oPC, H2_HT_THIRST_NONLETHAL_DAMAGE))
            h2_RemoveHTFatigue(oPC);
        DeleteLocalInt(oPC, H2_HT_HUNGER_NONLETHAL_DAMAGE);
        DeleteLocalInt(oPC, H2_HT_IS_STARVING);
    }
}

void h2_ApplyThirstBonus(object oPC, object oItem)
{
    float thirstValue = GetLocalFloat(oItem, H2_HT_THIRST_VALUE) / 100.0;
    if (thirstValue > 0.0)
    {
        float currThirst = GetLocalFloat(oPC, H2_HT_CURR_THIRST) + thirstValue;
        if (currThirst > 1.0)
        {
            currThirst = 1.0;
            SendMessageToPC(oPC, H2_TEXT_NOT_THIRSTY);
        }
        SetLocalFloat(oPC, H2_HT_CURR_THIRST, currThirst);
        if (GetLocalInt(oPC, H2_HT_THIRST_NONLETHAL_DAMAGE) && !GetLocalInt(oPC, H2_HT_HUNGER_NONLETHAL_DAMAGE))
            h2_RemoveHTFatigue(oPC);
        DeleteLocalInt(oPC, H2_HT_THIRST_NONLETHAL_DAMAGE);
        DeleteLocalInt(oPC, H2_HT_IS_DEHYDRATED);
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_FIREFORGET_DRINK));
    }
}

void h2_ApplyOtherFoodEffects(object oPC, object oItem)
{
    float delay = GetLocalFloat(oItem, H2_HT_DELAY);
    string feedback = GetLocalString(oItem, H2_HT_FEEDBACK);
    if (feedback != "")
        DelayCommand(delay, SendMessageToPC(oPC, feedback));

    int poison = GetLocalInt(oItem, H2_HT_POISON);
    if (poison)
        DelayCommand(delay, ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectPoison(poison), oPC));

    int disease = GetLocalInt(oItem, H2_HT_DISEASE);
    if (disease)
        DelayCommand(delay, ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectDisease(disease), oPC));

    if (GetLocalInt(oItem, H2_HT_SLEEP))
        DelayCommand(delay, ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectSleep(), oPC,  HoursToSeconds(1) / 4));

    int HPbonus = GetLocalInt(oItem, H2_HT_HPBONUS);
    if (HPbonus && GetCurrentHitPoints(oPC) == GetMaxHitPoints(oPC))
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectTemporaryHitpoints(HPbonus), oPC, HoursToSeconds(1) / 2);
    else if (HPbonus)
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(HPbonus), oPC);
}

void h2_ConsumeFoodItem(object oPC, object oItem)
{
    h2_ApplyHungerBonus(oPC, oItem);
    h2_ApplyThirstBonus(oPC, oItem);
    h2_ApplyOtherFoodEffects(oPC, oItem);
    h2_ApplyAlchoholEffects(oPC, oItem);
}

void h2_DoDrunkenAntics(object oPC)
{
    if (GetCurrentAction(oPC) == ACTION_REST)
        return;

    effect eEff = GetFirstEffect(oPC);
    while (GetEffectType(eEff) != EFFECT_TYPE_INVALIDEFFECT)
    {
        if (GetEffectType(eEff) == EFFECT_TYPE_BLINDNESS)
            return;
        eEff = GetNextEffect(oPC);
    }

    switch (d6())
    {
        case 1: AssignCommand(oPC, SpeakString(H2_TEXT_ALCOHOL_BELCHES)); break;
        case 2: AssignCommand(oPC, SpeakString(H2_TEXT_ALCOHOL_HICCUPS)); break;
        case 3:
        case 4: AssignCommand(oPC, SpeakString(H2_TEXT_ALCOHOL_STUMBLES));
                AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_PAUSE_DRUNK, 1.0, 3.0));
                break;
        case 5: AssignCommand(oPC, SpeakString(H2_TEXT_ALCOHOL_FALLS_DOWN));
                AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_DEAD_FRONT, 1.0, 3.0));
                break;
        case 6: AssignCommand(oPC, SpeakString(H2_TEXT_ALCOHOL_DRY_HEAVES));
                AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_SPASM, 1.0, 1.5));
                break;
    }
}

void h2_FillCanteen(object oPC, object oCanteen, object oSource)
{
    if (GetLocalFloat(oSource, H2_HT_THIRST_VALUE) == 0.0)
    {
        SendMessageToPC(oPC, H2_TEXT_CANNOT_USE_ON_TARGET);
        return;
    }
    SetLocalObject(oCanteen, H2_HT_CANTEEN_SOURCE, oSource);
    SetLocalInt(oCanteen, H2_HT_CURR_CHARGES, GetLocalInt(oCanteen, H2_HT_MAX_CHARGES));
    SendMessageToPC(oPC, H2_TEXT_FILL_CANTEEN + GetName(oCanteen));
}

void h2_EmptyCanteen(object oCanteen)
{
    DeleteLocalObject(oCanteen, H2_HT_CANTEEN_SOURCE);
    DeleteLocalInt(oCanteen, H2_HT_CURR_CHARGES);
}

void h2_UseCanteen(object oPC, object oCanteen)
{
    object oTarget = GetItemActivatedTarget();
    location lTarget = GetItemActivatedTargetLocation();
    if (oPC == oTarget)
    {
        int currCharges = GetLocalInt(oCanteen, H2_HT_CURR_CHARGES);
        object oSource = GetLocalObject(oCanteen, H2_HT_CANTEEN_SOURCE);
        if (currCharges == 0 || !GetIsObjectValid(oSource))
        {   //self-fix the canteen if its contents source is invalid.
            SendMessageToPC(oPC, H2_TEXT_CANTEEN_EMPTY);
            h2_EmptyCanteen(oCanteen);
        }
        else
        {
            currCharges--;
            SetLocalInt(oCanteen, H2_HT_CURR_CHARGES, currCharges);
            SendMessageToPC(oPC, H2_TEXT_TAKE_A_DRINK);
            AssignCommand(oPC, ActionPlayAnimation(ANIMATION_FIREFORGET_DRINK));
            h2_ConsumeFoodItem(oPC, oSource);
        }
        return;
    }

    if (oCanteen == oTarget)
    {
        SendMessageToPC(oPC, H2_TEXT_EMPTY_CANTEEN + GetName(oCanteen));
        h2_EmptyCanteen(oCanteen);
        return;
    }

    if (GetIsObjectValid(oTarget))
    {
        if (GetObjectType(oTarget) == OBJECT_TYPE_PLACEABLE)
        {
            AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_GET_MID));
            h2_FillCanteen(oPC, oCanteen, oTarget);
        }
        else
            SendMessageToPC(oPC, H2_TEXT_CANNOT_USE_ON_TARGET);
        return;
    }

    oTarget = GetLocalObject(oPC, H2_HT_TRIGGER);
    if (!GetIsObjectValid(oTarget))
        SendMessageToPC(oPC, H2_TEXT_NO_PLACE_TO_FILL);
    else
    {
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_GET_LOW));
        h2_FillCanteen(oPC, oCanteen, oTarget);
    }
}

float h2_GetFatigueDecrement()
{
    return 1.0 / (H2_FATIGUE_HOURS_WITHOUT_REST);
}

void h2_DisplayFatigueInfoBar(object oPC)
{
    if(GetIsDM(oPC)) return;

    int fatigueCount = FloatToInt(GetLocalFloat(oPC, H2_CURR_FATIGUE) * 100.0);
    string greenBar = h2_ColorText(GetSubString(H2_FATIGUE_INFO_BAR, 0, fatigueCount), H2_COLOR_GREEN);
    string redBar = h2_ColorText(GetSubString(H2_FATIGUE_INFO_BAR, fatigueCount, 100 - fatigueCount), H2_COLOR_RED);
    SendMessageToPC(oPC, H2_TEXT_FATIGUE + greenBar + redBar);
}

void h2_InitFatigueCheck(object oPC)
{
    if (!GetLocalInt(oPC, H2_IS_FATIGUED) && GetLocalFloat(oPC, H2_CURR_FATIGUE) == 0.0)
        SetLocalFloat(oPC, H2_CURR_FATIGUE, 1.0);

    int timerID = CreateTimer(oPC, H2_FATIGUE_ON_TIMER_EXPIRE, 120.0, 0, 0);
    //int timerID = h2_CreateTimer(oPC, H2_FATIGUE_TIMER_SCRIPT, HoursToSeconds(1), FALSE);
    //int timerID = h2_CreateTimer(oPC, H2_FATIGUE_TIMER_SCRIPT, 10.0, FALSE);
    StartTimer(timerID, FALSE);
    //h2_StartTimer(timerID);

    if (GetIsPC(oPC) && H2_FATIGUE_DISPLAY_INFO_BAR)
        h2_DisplayFatigueInfoBar(oPC);
}

void h2_DoFatigueFortitudeCheck(object oPC)
{
    SetLocalInt(oPC, H2_IS_FATIGUED, TRUE);
    int saveCount = GetLocalInt(oPC, H2_FATIGUE_SAVE_COUNT);
    if(GetIsPC(oPC)) 
    {
        SendMessageToPC(oPC, H2_TEXT_NEAR_COLLAPSE);
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_PAUSE_TIRED, 1.0, 2.0));
        PlayVoiceChat(VOICE_CHAT_REST, oPC);
    }

    int fortCheck = FortitudeSave(oPC, saveCount + 10);
    if (!fortCheck || saveCount >= 10)
    {
        effect eStrLoss = ExtraordinaryEffect(EffectAbilityDecrease(ABILITY_STRENGTH, 1));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eStrLoss, oPC);
        effect eDexLoss = ExtraordinaryEffect(EffectAbilityDecrease(ABILITY_DEXTERITY, 1));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eDexLoss, oPC);
        effect eMovement = ExtraordinaryEffect(EffectMovementSpeedDecrease(10));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eMovement, oPC);
        if (saveCount >= 10 && !fortCheck)
        {
            if (GetRacialType(oPC) == RACIAL_TYPE_ELF || GetRacialType(oPC) == RACIAL_TYPE_HALFELF)
                ApplyEffectToObject(DURATION_TYPE_TEMPORARY, ExtraordinaryEffect(EffectKnockdown()), oPC, 180.0);
            else
            {
                ApplyEffectToObject(DURATION_TYPE_TEMPORARY, ExtraordinaryEffect(EffectSleep()), oPC, 180.0);
                ApplyEffectToObject(DURATION_TYPE_TEMPORARY, ExtraordinaryEffect(EffectVisualEffect(VFX_IMP_SLEEP)), oPC, 180.0);
            }
            if(GetIsPC(oPC)) AssignCommand(oPC, SpeakString(H2_TEXT_COLLAPSE));
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, ExtraordinaryEffect(EffectBlindness()), oPC, 180.0);
            SetLocalFloat(oPC, H2_CURR_FATIGUE, 0.33);
        }
    }
    SetLocalInt(oPC, H2_FATIGUE_SAVE_COUNT, saveCount + 1);
}

void h2_PerformFatigueCheck(object oPC, float fCustomFatigueDecrement = -1.0)
{
    if(GetIsDM(oPC)) return;

    if(GetIsPC(oPC))
        if (h2_GetPlayerPersistentInt(oPC, H2_PLAYER_STATE) == H2_PLAYER_STATE_DEAD)
            return;

    float fatigueDrop = (fCustomFatigueDecrement >= 0.0) ? fCustomFatigueDecrement : h2_GetFatigueDecrement();

    float currFatigue = GetLocalFloat(oPC, H2_CURR_FATIGUE);
    if (currFatigue > 0.0)
        currFatigue = currFatigue - fatigueDrop;
    if (currFatigue < 0.0)
        currFatigue = 0.0;
    SetLocalFloat(oPC, H2_CURR_FATIGUE, currFatigue);
    
    if(GetIsPC(oPC))
    {
        if (H2_FATIGUE_DISPLAY_INFO_BAR)
            h2_DisplayFatigueInfoBar(oPC);

        if (currFatigue < 0.33 && currFatigue > 0.0)
        {
            SendMessageToPC(oPC, H2_TEXT_TIRED1);
            AssignCommand(oPC, SpeakString(H2_TEXT_YAWNS));
            AssignCommand(oPC, ActionPlayAnimation(ANIMATION_FIREFORGET_PAUSE_BORED));
        }
    }

    if (currFatigue == 0.0)
        h2_DoFatigueFortitudeCheck(oPC);
    else
        DeleteLocalInt(oPC, H2_FATIGUE_SAVE_COUNT);
}
