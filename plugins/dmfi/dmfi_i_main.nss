//::///////////////////////////////////////////////
//:: DMFI - OnPlayerChat functions processor
//:: dmfi_plychat_exe
//:://////////////////////////////////////////////
/*
  Processor for the OnPlayerChat-triggered DMFI functions.
*/
//:://////////////////////////////////////////////
//:: Created By: The DMFI Team
//:: Created On:
//:://////////////////////////////////////////////
//:: 2007.12.12 Merle
//::    - revisions for NWN patch 1.69
//:: 2008.03.24 tsunami282
//::    - renamed from dmfi_voice_exe, updated to work with event hooking system
//:: 2008.06.23 Prince Demetri & Night Journey
//::    - added languages: Sylvan, Mulhorandi, Rashemi
//:: 2008.07.30 morderon
//::    - better emote processing, allow certain dot commands for PC's

#include "x2_inc_switches"
#include "x0_i0_stringlib"
#include "dmfi_string_inc"
#include "dmfi_plchlishk_i"
#include "dmfi_db_inc"

#include "x3_inc_string"
#include "dmfi_i_util"

const int DMFI_LOG_CONVERSATION = TRUE; // turn on or off logging of conversation text

////////////////////////////////////////////////////////////////////////
void dmw_CleanUp(object oMySpeaker)
{
    int nCount;
    int nCache;
    //DeleteLocalObject(oMySpeaker, "dmfi_univ_target");
    DeleteLocalLocation(oMySpeaker, "dmfi_univ_location");
    DeleteLocalObject(oMySpeaker, "dmw_item");
    DeleteLocalString(oMySpeaker, "dmw_repamt");
    DeleteLocalString(oMySpeaker, "dmw_repargs");
    nCache = GetLocalInt(oMySpeaker, "dmw_playercache");
    for (nCount = 1; nCount <= nCache; nCount++)
    {
        DeleteLocalObject(oMySpeaker, "dmw_playercache" + IntToString(nCount));
    }
    DeleteLocalInt(oMySpeaker, "dmw_playercache");
    nCache = GetLocalInt(oMySpeaker, "dmw_itemcache");
    for (nCount = 1; nCount <= nCache; nCount++)
    {
        DeleteLocalObject(oMySpeaker, "dmw_itemcache" + IntToString(nCount));
    }
    DeleteLocalInt(oMySpeaker, "dmw_itemcache");
    for (nCount = 1; nCount <= 10; nCount++)
    {
        DeleteLocalString(oMySpeaker, "dmw_dialog" + IntToString(nCount));
        DeleteLocalString(oMySpeaker, "dmw_function" + IntToString(nCount));
        DeleteLocalString(oMySpeaker, "dmw_params" + IntToString(nCount));
    }
    DeleteLocalString(oMySpeaker, "dmw_playerfunc");
    DeleteLocalInt(oMySpeaker, "dmw_started");
}

////////////////////////////////////////////////////////////////////////
//Smoking Function by Jason Robinson
location GetLocationAboveAndInFrontOf(object oPC, float fDist, float fHeight)
{
    float fDistance = -fDist;
    object oTarget = (oPC);
    object oArea = GetArea(oTarget);
    vector vPosition = GetPosition(oTarget);
    vPosition.z += fHeight;
    float fOrientation = GetFacing(oTarget);
    vector vNewPos = AngleToVector(fOrientation);
    float vZ = vPosition.z;
    float vX = vPosition.x - fDistance * vNewPos.x;
    float vY = vPosition.y - fDistance * vNewPos.y;
    fOrientation = GetFacing(oTarget);
    vX = vPosition.x - fDistance * vNewPos.x;
    vY = vPosition.y - fDistance * vNewPos.y;
    vNewPos = AngleToVector(fOrientation);
    vZ = vPosition.z;
    vNewPos = Vector(vX, vY, vZ);
    return Location(oArea, vNewPos, fOrientation);
}

////////////////////////////////////////////////////////////////////////
//Smoking Function by Jason Robinson
void SmokePipe(object oActivator)
{
    string sEmote1 = "*puffs on a pipe*";
    string sEmote2 = "*inhales from a pipe*";
    string sEmote3 = "*pulls a mouthful of smoke from a pipe*";
    float fHeight = 1.7;
    float fDistance = 0.1;
    // Set height based on race and gender
    if (GetGender(oActivator) == GENDER_MALE)
    {
        switch (GetRacialType(oActivator))
        {
        case RACIAL_TYPE_HUMAN:
        case RACIAL_TYPE_HALFELF: fHeight = 1.7; fDistance = 0.12; break;
        case RACIAL_TYPE_ELF: fHeight = 1.55; fDistance = 0.08; break;
        case RACIAL_TYPE_GNOME:
        case RACIAL_TYPE_HALFLING: fHeight = 1.15; fDistance = 0.12; break;
        case RACIAL_TYPE_DWARF: fHeight = 1.2; fDistance = 0.12; break;
        case RACIAL_TYPE_HALFORC: fHeight = 1.9; fDistance = 0.2; break;
        }
    }
    else
    {
        // FEMALES
        switch (GetRacialType(oActivator))
        {
        case RACIAL_TYPE_HUMAN:
        case RACIAL_TYPE_HALFELF: fHeight = 1.6; fDistance = 0.12; break;
        case RACIAL_TYPE_ELF: fHeight = 1.45; fDistance = 0.12; break;
        case RACIAL_TYPE_GNOME:
        case RACIAL_TYPE_HALFLING: fHeight = 1.1; fDistance = 0.075; break;
        case RACIAL_TYPE_DWARF: fHeight = 1.2; fDistance = 0.1; break;
        case RACIAL_TYPE_HALFORC: fHeight = 1.8; fDistance = 0.13; break;
        }
    }
    location lAboveHead = GetLocationAboveAndInFrontOf(oActivator, fDistance, fHeight);
    // emotes
    switch (d3())
    {
    case 1: AssignCommand(oActivator, ActionSpeakString(sEmote1)); break;
    case 2: AssignCommand(oActivator, ActionSpeakString(sEmote2)); break;
    case 3: AssignCommand(oActivator, ActionSpeakString(sEmote3)); break;
    }
    // glow red
    AssignCommand(oActivator, ActionDoCommand(ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectVisualEffect(VFX_DUR_LIGHT_RED_5), oActivator, 0.15)));
    // wait a moment
    AssignCommand(oActivator, ActionWait(3.0));
    // puff of smoke above and in front of head
    AssignCommand(oActivator, ActionDoCommand(ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_FNF_SMOKE_PUFF), lAboveHead)));
    // if female, turn head to left
    if ((GetGender(oActivator) == GENDER_FEMALE) && (GetRacialType(oActivator) != RACIAL_TYPE_DWARF))
        AssignCommand(oActivator, ActionPlayAnimation(ANIMATION_FIREFORGET_HEAD_TURN_LEFT, 1.0, 5.0));
}

////////////////////////////////////////////////////////////////////////
void ParseEmote(string sEmote, object oPC)
{
    //Check for muted emotes.
    if (GetLocalInt(MODULE, "DMFI_SUPPRESS_EMOTES") ||
        GetLocalInt(oPC, "hls_emotemute"))
        return;

    DeleteLocalInt(oPC, "dmfi_univ_int");
    
    object oRightHand = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND,oPC);
    object oLeftHand =  GetItemInSlot(INVENTORY_SLOT_LEFTHAND,oPC);

    if (GetStringLeft(sEmote, 1) == "*")
        sEmote = StringParse(sEmote, "*", TRUE);

    //Replace the long-ass list of emotes with a CSV.
    string sLCEmote = GetStringLowerCase(sEmote);

    int i, nCount = CountList(DMFI_PC_CHECKS);
    for (i = 0; i < nCount; i++
    {
        if (FindSubString(sLCEmote, GetListItem(DMFI_PC_CHECKS, i)) != 1)
        {
            SetLocalInt(oPC, "dmfi_univ_int", 60 + i + (i/10));
            break;
        }
        
        if ((FindSubString(sLCEmote, "ride") != -1))
            SetLocalInt(oPC, "dmfi_univ_int", 90);
    }
    
    if (GetLocalInt(oPC, "dmfi_univ_int"))
    {
        SetLocalString(oPC, "dmfi_univ_conv", "pc_dicebag");
        ExecuteScript("dmfi_execute", oPC);
        return;
    }

    //int iSit;
    //object oArea;
    //object oChair;

    //*emote*
    if (FindSubString(GetStringLowerCase(sEmote), "*bows") != -1 ||
        FindSubString(GetStringLowerCase(sEmote), " bows") != -1 ||
        FindSubString(GetStringLowerCase(sEmote), "curtsey") != -1)
        AssignCommand(oPC, PlayAnimation(ANIMATION_FIREFORGET_BOW, 1.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "drink") != -1 ||
             FindSubString(GetStringLowerCase(sEmote), "sips") != -1)
        AssignCommand(oPC, PlayAnimation(ANIMATION_FIREFORGET_DRINK, 1.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "drinks") != -1 &&
             FindSubString(GetStringLowerCase(sEmote), "sits") != -1)
    {
        AssignCommand(oPC, ActionPlayAnimation( ANIMATION_LOOPING_SIT_CROSS, 1.0, 99999.0f));
        DelayCommand(1.0f, AssignCommand(oPC, PlayAnimation( ANIMATION_FIREFORGET_DRINK, 1.0)));
        DelayCommand(3.0f, AssignCommand(oPC, PlayAnimation( ANIMATION_LOOPING_SIT_CROSS, 1.0, 99999.0)));
    }
    else if (FindSubString(GetStringLowerCase(sEmote), "reads") != -1 &&
             FindSubString(GetStringLowerCase(sEmote), "sits") != -1)
    {
        AssignCommand(oPC, ActionPlayAnimation( ANIMATION_LOOPING_SIT_CROSS, 1.0, 99999.0f));
        DelayCommand(1.0f, AssignCommand(oPC, PlayAnimation( ANIMATION_FIREFORGET_READ, 1.0)));
        DelayCommand(3.0f, AssignCommand(oPC, PlayAnimation( ANIMATION_LOOPING_SIT_CROSS, 1.0, 99999.0)));
    }
    else if (FindSubString(GetStringLowerCase(sEmote), "sit")!= -1)
    {
        AssignCommand(oPC, ActionPlayAnimation( ANIMATION_LOOPING_SIT_CROSS, 1.0, 99999.0f));
    }
    else if (FindSubString(GetStringLowerCase(sEmote), "greet")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "wave") != -1)
        AssignCommand(oPC, PlayAnimation(ANIMATION_FIREFORGET_GREETING, 1.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "yawn")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "stretch") != -1 ||
             FindSubString(GetStringLowerCase(sEmote), "bored") != -1)
        AssignCommand(oPC, PlayAnimation(ANIMATION_FIREFORGET_PAUSE_BORED, 1.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "scratch")!= -1)
    {
        AssignCommand(oPC,ActionUnequipItem(oRightHand));
        AssignCommand(oPC,ActionUnequipItem(oLeftHand));
        AssignCommand(oPC, PlayAnimation(ANIMATION_FIREFORGET_PAUSE_SCRATCH_HEAD, 1.0));
    }
    else if (FindSubString(GetStringLowerCase(sEmote), "*reads")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), " reads")!= -1||
             FindSubString(GetStringLowerCase(sEmote), "read")!= -1)
        AssignCommand(oPC, PlayAnimation(ANIMATION_FIREFORGET_READ, 1.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "salute")!= -1)
    {
        AssignCommand(oPC,ActionUnequipItem(oRightHand));
        AssignCommand(oPC,ActionUnequipItem(oLeftHand));
        AssignCommand(oPC, PlayAnimation(ANIMATION_FIREFORGET_SALUTE, 1.0));
    }
    else if (FindSubString(GetStringLowerCase(sEmote), "steal")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "swipe") != -1)
        AssignCommand(oPC, PlayAnimation(ANIMATION_FIREFORGET_STEAL, 1.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "taunt")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "mock") != -1)
    {
        PlayVoiceChat(VOICE_CHAT_TAUNT, oPC);
        AssignCommand(oPC, PlayAnimation(ANIMATION_FIREFORGET_TAUNT, 1.0));
    }
    else if ((FindSubString(GetStringLowerCase(sEmote), "smokes") != -1)||
             (FindSubString(GetStringLowerCase(sEmote), "smoke") != -1))
    {
        SmokePipe(oPC);
    }
    else if (FindSubString(GetStringLowerCase(sEmote), "cheer ")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "cheer*")!= -1)
    {
        PlayVoiceChat(VOICE_CHAT_CHEER, oPC);
        AssignCommand(oPC, PlayAnimation(ANIMATION_FIREFORGET_VICTORY1, 1.0));
    }
    else if (FindSubString(GetStringLowerCase(sEmote), "hooray")!= -1)
    {
        PlayVoiceChat(VOICE_CHAT_CHEER, oPC);
        AssignCommand(oPC, PlayAnimation(ANIMATION_FIREFORGET_VICTORY2, 1.0));
    }
    else if (FindSubString(GetStringLowerCase(sEmote), "celebrate")!= -1)
    {
        PlayVoiceChat(VOICE_CHAT_CHEER, oPC);
        AssignCommand(oPC, PlayAnimation(ANIMATION_FIREFORGET_VICTORY3, 1.0));
    }
    else if (FindSubString(GetStringLowerCase(sEmote), "giggle")!= -1 && GetGender(oPC) == GENDER_FEMALE)
        AssignCommand(oPC, PlaySound("vs_fshaldrf_haha"));
    else if (FindSubString(GetStringLowerCase(sEmote), "flop")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "prone")!= -1)
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_DEAD_FRONT, 1.0, 99999.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "bends")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "stoop")!= -1)
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_GET_LOW, 1.0, 99999.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "fiddle")!= -1)
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_GET_MID, 1.0, 5.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "nod")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "agree")!= -1)
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_LISTEN, 1.0, 4.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "peers")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "scans")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "search")!= -1)
        AssignCommand(oPC,ActionPlayAnimation(ANIMATION_LOOPING_LOOK_FAR, 1.0, 99999.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "*pray")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), " pray")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "meditate")!= -1)
    {
        AssignCommand(oPC,ActionUnequipItem(oRightHand));
        AssignCommand(oPC,ActionUnequipItem(oLeftHand));
        AssignCommand(oPC,ActionPlayAnimation(ANIMATION_LOOPING_MEDITATE, 1.0, 99999.0));
    }
    else if (FindSubString(GetStringLowerCase(sEmote), "drunk")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "woozy")!= -1)
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_PAUSE_DRUNK, 1.0, 99999.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "tired")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "fatigue")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "exhausted")!= -1)
    {
        PlayVoiceChat(VOICE_CHAT_REST, oPC);
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_PAUSE_TIRED, 1.0, 3.0));
    }
    else if (FindSubString(GetStringLowerCase(sEmote), "fidget")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "shifts")!= -1)
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_PAUSE2, 1.0, 99999.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "sits")!= -1 &&
             (FindSubString(GetStringLowerCase(sEmote), "floor")!= -1 ||
              FindSubString(GetStringLowerCase(sEmote), "ground")!= -1))
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_SIT_CROSS, 1.0, 99999.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "demand")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "threaten")!= -1)
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_TALK_FORCEFUL, 1.0, 99999.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "laugh")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "chuckle")!= -1)
    {
        PlayVoiceChat(VOICE_CHAT_LAUGH, oPC);
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_TALK_LAUGHING, 1.0, 2.0));
    }
    else if (FindSubString(GetStringLowerCase(sEmote), "begs")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "plead")!= -1)
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_TALK_PLEADING, 1.0, 99999.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "worship")!= -1)
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_WORSHIP, 1.0, 99999.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "snore")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "*naps")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), " naps")!= -1||
             FindSubString(GetStringLowerCase(sEmote), "nap")!= -1)
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_SLEEP), oPC);
    else if (FindSubString(GetStringLowerCase(sEmote), "*sings")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), " sings")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "hums")!= -1)
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectVisualEffect(VFX_DUR_BARD_SONG), oPC, 6.0f);
    else if (FindSubString(GetStringLowerCase(sEmote), "whistles")!= -1)
        AssignCommand(oPC, PlaySound("as_pl_whistle2"));
    else if (FindSubString(GetStringLowerCase(sEmote), "talks")!= -1 ||
             FindSubString(GetStringLowerCase(sEmote), "chats")!= -1)
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_TALK_NORMAL, 1.0, 99999.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "shakes head")!= -1)
    {
        AssignCommand(oPC, PlayAnimation(ANIMATION_FIREFORGET_HEAD_TURN_LEFT, 1.0, 0.25f));
        DelayCommand(0.15f, AssignCommand(oPC, PlayAnimation(ANIMATION_FIREFORGET_HEAD_TURN_RIGHT, 1.0, 0.25f)));
        DelayCommand(0.40f, AssignCommand(oPC, PlayAnimation(ANIMATION_FIREFORGET_HEAD_TURN_LEFT, 1.0, 0.25f)));
        DelayCommand(0.65f, AssignCommand(oPC, PlayAnimation(ANIMATION_FIREFORGET_HEAD_TURN_RIGHT, 1.0, 0.25f)));
    }
    else if (FindSubString(GetStringLowerCase(sEmote), "ducks")!= -1)
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_FIREFORGET_DODGE_DUCK, 1.0, 99999.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "dodge")!= -1)
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_FIREFORGET_DODGE_SIDE, 1.0, 99999.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "cantrip")!= -1)
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_CONJURE1, 1.0, 99999.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "spellcast")!= -1)
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_CONJURE2, 1.0, 99999.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "fall")!= -1 &&
             FindSubString(GetStringLowerCase(sEmote), "back")!= -1)
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_DEAD_BACK, 1.0, 99999.0));
    else if (FindSubString(GetStringLowerCase(sEmote), "spasm")!= -1)
        AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_SPASM, 1.0, 99999.0));
}

////////////////////////////////////////////////////////////////////////
string ConvertCustom(string sLetter, int iRotate)
{
    if (GetStringLength(sLetter) > 1)
        sLetter = GetStringLeft(sLetter, 1);

    //Functional groups for custom languages
    //Vowel Sounds: a, e, i, o, u
    //Hard Sounds: b, d, k, p, t
    //Sibilant Sounds: c, f, s, q, w
    //Soft Sounds: g, h, l, r, y
    //Hummed Sounds: j, m, n, v, z
    //Oddball out: x, the rarest letter in the alphabet

    string sTranslate = "aeiouAEIOUbdkptBDKPTcfsqwCFSQWghlryGHLRYjmnvzJMNVZxX";
    int iTrans = FindSubString(sTranslate, sLetter);
    if (iTrans == -1) return sLetter; //return any character that isn't on the cipher

    //Now here's the tricky part... recalculating the offsets according functional
    //letter group, to produce an huge variety of "new" languages.

    int iOffset = iRotate % 5;
    int iGroup = iTrans / 5;
    int iBonus = iTrans / 10;
    int iMultiplier = iRotate / 5;
    iOffset = iTrans + iOffset + (iMultiplier * iBonus);

    return GetSubString(sTranslate, iGroup * 5 + iOffset % 5, 1);
}//end ConvertCustom

////////////////////////////////////////////////////////////////////////
string ProcessCustom(string sPhrase, int iLanguage)
{
    string sOutput;
    int iToggle;
    while (GetStringLength(sPhrase) > 1)
    {
        if (GetStringLeft(sPhrase,1) == "*")
            iToggle = abs(iToggle - 1);
        if (iToggle)
            sOutput = sOutput + GetStringLeft(sPhrase,1);
        else
            sOutput = sOutput + ConvertCustom(GetStringLeft(sPhrase, 1), iLanguage);
        sPhrase = GetStringRight(sPhrase, GetStringLength(sPhrase)-1);
    }
    return sOutput;
}

string dmfi_SortListString(string sList)
{
    int i, j, nLarger, nCount = CountList(sList);
    string sCurrent, sCompare, sSortList = "DMFI_SORT_LIST";

    DeclareStringList(DMFI, nCount, sSortList);

    for (i = 0; i < nCount; i++)
    {
        nLarger = 0;
        sCurrent = GetListItem(sList, i);

        for (j = 0; j < nCount; j++)
        {
            if (i == j)
                continue;

            sCompare = GetListItem(sList, j);
            if ((sCompare < sCurrent) || (sCompare == sCurrent && i < j))
                nLarger++;
        }

        SetListString(DMFI, nLarger, sCurrent, sSortList);
    }

    sList = JoinList(DMFI, sSortList);
    DeleteStringList(DMFI, sSortList);

    return sList;
}

// ---< dmfi_InitializeLanguages >---
int dmfi_InitializeLanguages()
{
    return dmfi_InitializeSystem(DMFI_LANGUAGE_INSTALLED, DMFI_LANGUAGE_LOADED_CSV,
                                 DMFI_LANGUAGE_ITEM_PREFIX, DMFI_LANGUAGE_OBJECT_LIST,
                                 DMFI_LANGUAGE_INITIALIZED, bForce = FALSE);
}

int dmfi_IntializeDMWands()
{
    return dmfi_InitializeSystem(DMFI_DM_WAND_INVENTORY, DMFI_DM_WAND_LOADED_CSV,
                                 DMFI_WAND_ITEM_PREFIX, DMFI_DM_WAND_OBJECT_LIST,
                                 DMFI_DM_WAND_INITIALIZED, bForce = FALSE);
}

int dmfi_InitializePCWands()
{
    return dmfi_InitializeSystem(DMFI_PC_WAND_INVENTORY, DMFI_PC_WAND_LOADED_CSV,
                                 DMFI_WAND_ITEM_PREFIX, DMFI_PC_WAND_OBJECT_LIST,
                                 DMFI_PC_WAND_INITIALIZED, bForce = FALSE);
}

/*
// ---< dmfi_InitializeLanguages >---
// This function will loop through CSVs in DMFI_LANGUAGE_INSTALLED and load 
//  pointers to their objects on the DMFI data object.  These object will be
//  used when a translation occurs.  To save processing power, language items
//  will not be loaded until the first call for translation occurs.
int dmfi_InitializeLanguages()
{
    int i, nCount = CountList(DMFI_LANGUAGE_INSTALLED);
    object oLanguageItem;
    string sLanguage, sLanguages;

    DeleteLocalString(DMFI, DMFI_LANGUAGE_LOADED_CSV);

    for (i = 0; i < nCount; i++);
    {
        sLanguage = GetListItem(DMFI_LANGUAGE_INSTALLED, i);
        sLanguage = GetStringLeft(sLanguage, 16 - GetStringLength(DMFI_LANGUAGE_ITEM_PREFIX));
        oLanguageItem = GetItemByTag(DMFI_LANGUAGE_ITEM_PREFIX + sLanguage);

        if (GetIsItemValid(oLanguageItem))
        {
            if (AddListObject(DMFI, oLanguageItem, DMFI_LANGUAGE_OBJECT_LIST, TRUE)
                sLanguages = AddListItem(sLanguages, sLanguage);
            else
                Warning("DFMI: Language item '" + GetTag(oLanguageItem) + "' found but not " +
                    "loaded due to language duplication.  Check the language install list.");
        }
        else
            Warning("DMFI: Language '" + sLanguage + "' not found.");
    }

    iLanguageCount = CountObjectList(DMFI, DMFI_LANGUAGE_OBJECT_LIST);

    //TODO create a subsystem to the util_i_debug to manage communications through the pw.
    Debug("DMFI:  Successfully loaded " + iLanguageCount + " languages." +
        (iLanguageCount == nCount ? "\n  All languages on the install list have been loaded." :
        "\n  Unable to find valid language items for " + nCount - iLanguageCount " languages."

    SetLocalString(DMFI, DMFI_LANGUAGE_LOADED_CSV, sLanguages);
    SetLocalInt(DMFI, DMFI_LANGUAGE_INITIALIZED, TRUE);

    return iLanguageCount;
}*/
// TODO add meaningful errors to the debugging systems
// TODO create a subsystem to util_i_debug to handle more custom debugging and messaging to DMs
//  TODO create a custom conversation to allow dms to flip switches in the module.
//  TODO create a DM-only rock/data area with NPCs that have conversations to view specific data
//  on each system.

// ---< dmfi_TranslatePhrase >---
// This function takes an input sPhrase and a request to translate it to sLanguage.
//  Language objects (items dmfi_l_*) are used to define the translations.  If the
//  language item isn't loaded, the translation doesn't occur.  Languages may be
//  translated in three ways:
//      0 - Letter by Letter
//      1 - Word replacement
//      2 - Single repeated character

// The translated phrase, if any, is returned.

string dmfi_TranslatePhrase(string sLanguage, string sPhrase))
{
    if(!GetLocalInt(DMFI, DMFI_LANGUAGE_INITIALIZED))
        dmfi_InitializeLanguages();
    
    int i, nIndex, nCount;
    string sCharacter, sRepeat, sTranslation;

    struct DMFI_LANGUAGE_ITEM liTranslateFrom, liTranslateTo;

    //Load common language.
    if (nIndex = FindListItem(DMFI_LANGUAGE_LOADED_CSV, DMFI_LANGUAGE_COMMON)
        liTranslateFrom = dmfi_GetLanguage(nIndex);
    else
    {
        Debug("DMFI: Unable to find common language.  Translation aborted.");
        return "";
    }

    //Get the language to translate to
    if(nIndex = FindListItem(DMFI_LANGUAGE_LOADED_CSV, sLanguage));
        liTranslateTo = dmfi_GetLanguage(nIndex);
    else
    {
        Debug("DMFI: Unable to find desired translation language.  Translation aborted.");
        return "";
    }

    select (liTranslateTo.nMode)
    {
        case DMFI_LANGUAGE_MODE_LETTER:
            if (nCount = GetStringLength(sPhrase))
            {
                for (i = 0; i < nCount; i++)
                {
                    sCharacter = GetSubString(sPhrase, i, 1);
                    nIndex = FindListItem(liTranslateFrom.sAlphabet, sCharacter);

                    if (nIndex != -1)
                        sTranslation += GetListItem(liTranslateTo.sAlphabet, nIndex);
                    else
                        sTranslation += sCharacter;
                }
            }

            return sTranslation;
        case DMFI_LANGUAGE_MODE_WORD:
            if (GetStringLength(sPhrase) && (nCount = dmfi_CountWords(sPhrase)))
            {
                //TODO add util_i_math include
                nCount = min(nCount, CountList(liTranslateTo.sAlphabet));

                for (i = 0; i < nCount; i++)
                {
                    sTranslation += GetListItem(liTranslateTo.sAlphabet, Random(nCount));)
                }

                return sTranslation;
            }
            else
            {
                Debug("DMFI, Invalid translation phrase length or word count.  Translation aborted.");
                return "";
            }
        case DMFI_LANGUAGE_MODE_REPEAT:
            if (nCount = GetStringLength(sPhrase))
            {
                if(CountList(liTranslateTo.sAlphabet))
                    sRepeat = GetListItem(liTranslateTo.sAlphabet, 0);
                else
                {
                    Debug("DMFI:  Valid character not found for requested translation mode.");
                    return "";
                }

                for (i = 0; i < nCount; i++)
                {
                    sCharacter = GetSubString(sPhrase, i);
                    
                    if (FindListItem(liTranslateFrom.sAlphabet, sCharacter))
                        sTranslation += sRepeat;
                    else
                        sTranslation += sCharacter;
                }
            }

            return sTranslation;
        default:
            Debug("Valid translation mode not found.  Translation aborted.");
            return "";
    }
}

////////////////////////////////////////////////////////////////////////
string TranslateCommonToLanguage(int iLang, string sText)
{
    switch (iLang)
    {
    case 1: //Elven
        return ProcessElven(sText); break;
    case 2: //Gnome
        return ProcessGnome(sText); break;
    case 3: //Halfling
        return ProcessHalfling(sText); break;
    case 4: //Dwarf Note: Race 4 is normally Half Elf and Race 0 is normally Dwarf. This is changed.
        return ProcessDwarf(sText); break;
    case 5: //Orc
        return ProcessOrc(sText); break;
    case 6: //Goblin
        return ProcessGoblin(sText); break;
    case 7: //Draconic
        return ProcessDraconic(sText); break;
    case 8: //Animal
        return ProcessAnimal(sText); break;
    case 9: //Thieves Cant
        return ProcessCant(sText); break;
    case 10: //Celestial
        return ProcessCelestial(sText); break;
    case 11: //Abyssal
        return ProcessAbyssal(sText); break;
    case 12: //Infernal
        return ProcessInfernal(sText); break;
    case 13:
        return ProcessDrow(sText); break;
    case 14: // Sylvan
        return ProcessSylvan(sText); break;
    case 15: // Rashemi
        return ProcessRashemi(sText); break;
    case 16: // Mulhorandi
        return ProcessMulhorandi(sText); break;
    case 99: //1337
        return ProcessLeetspeak(sText); break;
    default: if (iLang > 100) return ProcessCustom(sText, iLang - 100);break;
    }
    return "";
}

////////////////////////////////////////////////////////////////////////
int GetDefaultRacialLanguage(object oPC, int iRename)
{
    switch (GetRacialType(oPC))
    {
    case RACIAL_TYPE_DWARF: if (iRename) SetLocalString(oPC, "hls_MyLanguageName", "Dwarven");return 4; break;
    case RACIAL_TYPE_ELF:
    case RACIAL_TYPE_HALFELF: if (iRename) SetLocalString(oPC, "hls_MyLanguageName", "Elven");return 1; break;
    case RACIAL_TYPE_GNOME: if (iRename) SetLocalString(oPC, "hls_MyLanguageName", "Gnome");return 2; break;
    case RACIAL_TYPE_HALFLING: if (iRename) SetLocalString(oPC, "hls_MyLanguageName", "Halfling");return 3; break;
    case RACIAL_TYPE_HUMANOID_ORC:
    case RACIAL_TYPE_HALFORC: if (iRename) SetLocalString(oPC, "hls_MyLanguageName", "Orc");return 5; break;
    case RACIAL_TYPE_HUMANOID_GOBLINOID: if (iRename) SetLocalString(oPC, "hls_MyLanguageName", "Goblin");return 6; break;
    case RACIAL_TYPE_HUMANOID_REPTILIAN:
    case RACIAL_TYPE_DRAGON: if (iRename) SetLocalString(oPC, "hls_MyLanguageName", "Draconic");return 7; break;
    case RACIAL_TYPE_ANIMAL: if (iRename) SetLocalString(oPC, "hls_MyLanguageName", "Animal");return 8; break;
    default:
        if (GetLevelByClass(CLASS_TYPE_RANGER, oPC) || GetLevelByClass(CLASS_TYPE_DRUID, oPC))
        {
            if (iRename) SetLocalString(oPC, "hls_MyLanguageName", "Animal");
            return 8;
        }
        if (GetLevelByClass(CLASS_TYPE_ROGUE, oPC))
        {
            if (iRename) SetLocalString(oPC, "hls_MyLanguageName", "Thieves' Cant");
            return 9;
        }
        break;
    }
    return 0;
}

////////////////////////////////////////////////////////////////////////
int GetDefaultClassLanguage(object oPC)
{
    if (GetLevelByClass(CLASS_TYPE_RANGER, oPC) || GetLevelByClass(CLASS_TYPE_DRUID, oPC))
        return 8;
    if (GetLevelByClass(CLASS_TYPE_ROGUE, oPC))
        return 9;
    if ((GetSubRace(oPC)=="drow") ||(GetSubRace(oPC)=="DROW")||(GetSubRace(oPC)=="Drow"))
        return 13;
    if ((GetSubRace(oPC)=="fey") ||(GetSubRace(oPC)=="FEY")||(GetSubRace(oPC)=="Fey"))
        return 14;

    return 0;
}

////////////////////////////////////////////////////////////////////////
int GetIsAlphanumeric(string sCharacter)
{
    if (sCharacter == "a" ||
        sCharacter == "b" ||
        sCharacter == "c" ||
        sCharacter == "d" ||
        sCharacter == "e" ||
        sCharacter == "f" ||
        sCharacter == "g" ||
        sCharacter == "h" ||
        sCharacter == "i" ||
        sCharacter == "j" ||
        sCharacter == "k" ||
        sCharacter == "l" ||
        sCharacter == "m" ||
        sCharacter == "n" ||
        sCharacter == "o" ||
        sCharacter == "p" ||
        sCharacter == "q" ||
        sCharacter == "r" ||
        sCharacter == "s" ||
        sCharacter == "t" ||
        sCharacter == "u" ||
        sCharacter == "v" ||
        sCharacter == "w" ||
        sCharacter == "x" ||
        sCharacter == "y" ||
        sCharacter == "z" ||
        sCharacter == "A" ||
        sCharacter == "B" ||
        sCharacter == "C" ||
        sCharacter == "D" ||
        sCharacter == "E" ||
        sCharacter == "F" ||
        sCharacter == "G" ||
        sCharacter == "H" ||
        sCharacter == "I" ||
        sCharacter == "J" ||
        sCharacter == "K" ||
        sCharacter == "L" ||
        sCharacter == "M" ||
        sCharacter == "N" ||
        sCharacter == "O" ||
        sCharacter == "P" ||
        sCharacter == "Q" ||
        sCharacter == "R" ||
        sCharacter == "S" ||
        sCharacter == "T" ||
        sCharacter == "U" ||
        sCharacter == "V" ||
        sCharacter == "W" ||
        sCharacter == "X" ||
        sCharacter == "Y" ||
        sCharacter == "Z" ||
        sCharacter == "1" ||
        sCharacter == "2" ||
        sCharacter == "3" ||
        sCharacter == "4" ||
        sCharacter == "5" ||
        sCharacter == "6" ||
        sCharacter == "7" ||
        sCharacter == "8" ||
        sCharacter == "9" ||
        sCharacter == "0")
        return TRUE;

    return FALSE;
}

////////////////////////////////////////////////////////////////////////
//Marshall the request.

void ParseCommand(object oActionTarget, object oPC, string sArguments)
{
// :: 2008.07.31 morderon / tsunami282 - allow certain . commands for
// ::     PCs as well as DM's; allow shortcut targeting of henchies/pets

    string sValue, sCommandList, sCommand, sArgument, sLanguage;
    int i, nCount, iOffset = 0

    //TODO exactly how do these offsets work and why.  document.
    //int iOffset=0;

    //Check case if PC is trying to target a DM
    if (_GetIsDM(oActionTarget) && oActionTarget != oPC)
        return;

    // break into command and args
    sCommandList = dmfi_GetArgumentList(sArguments, " ");
    sCommand = GetListItem(sCommandList, 0);
    sArgument = GetListItem(sCommandList, 1);
    
    //TODO more tokens!
    // ** commands usable by everyone
    //Dicebag stuff
    if (HasListItem("loc,local,glo,global,pri,private,dm", sCommand)
    {
        if (HasListItem("loc,local", sCommand)
            sValue = "LOCAL";
        else if (HasListItem("glo,global", sCommand))
            sValue = "GLOBAL";
        else if (HasListItem("pri,private"), sCommand))
            sValue = "PRIVATE";
        else if sCommand = "dm"
            sValue = "DM";

        dmfi_SetSettingString(oPC, DMFI_SETTING_DICEBAG, sValue);
        return;
    }

    if (HasListItem("aniy,anin", sCommand))
    {
        dmfi_SetSettingString(oPC, DMFI_SETTING_DICEBAG_ANIMATION, 
            GetStringRight(sCommand, 1) == "y" ? "TRUE" : "FALSE")
        return;
    }

    if (HasListItem("emoy,emon"), sCommand)
    {
        dmfi_SetSettingString(oPC, DMFI_SETTING_DMFI_SETTING_EMOTES_MUTED,
            GetStringRight(sCommand, 1) == "y", "FALSE" : "TRUE");
        return;
    }

    if (HasListItem("lan,language"), sCommand)
    {
        //TODO set language variable on pc during login and when new langauges are learned
        //Was a language provided?
        if (sArgument == "")
            //Error, no language provided
            return;
        
        //Is the target valid for the player type?
        if (!(_GetIsDM(oPC) || oActionTarget == oPC || GetMaster(oActionTarget) == oPC))
            //Error, can't do that!
            return;

        //Ok, let's figure out which language they want to translate to
        sArgument = GetStringLeft(sArgument, 16 - GetStringLength(DMFI_LANGUAGE_ITEM_PREFIX));

        //See if the language is on our list of loaded languages (which might different
        //  form our list of installed languages)
        //The fastest way to do this is to use the full language name and compare
        //  it to the installed language list.
        //Should be using _LOADED here because we're assigning a language to speak,
        //  not just awarding a language.
        if(!GetLocalInt(DMFI, DMFI_LANGUAGE_INITIALIZED))
            dmfi_InitializeLanguages();

        if (HasListItem(DMFI_LANGUAGE_LOADED_CSV, sArgument))
            sLanguage = sArgument;
        else
        {
            if (nCount = CountObjectList(DMFI_LANGUAGE_OBJECT))
            {
                for (i = 0; i < nCount; i++)
                {
                    int nLanguageIndex;
                    oLanguageItem = GetListObject(DMFI, i, DMFI_LANGUAGE_OBJECT)
                    sLanguageAbbreviation = GetLocalString(oLanguageItem, DMFI_LANGUAGE_ABBREVIATION);
                    if (sArgument == sLanguageAbbreviation)
                    {
                        sLanguage = GetLocalString(oLanguageItem, DMFI_LANGUAGE_NAME);
                        break;
                    }
                    else if (nLanguageIndex = GetLocalString(oLanguageItem, DMFI_LANGUAGE_INDEX))
                    {
                        if (nLanguageIndex == GetLocalInt(oLanguageItem, DMFI_LANGUAGE_INDEX))
                        {
                            sLanguage = GetLocalString(oLanguageItem, DMFI_LANGUAGE_NAME);
                            break;
                        }    
                        
                    }
                }
            }
        }

        if (sLanguage != "")
        {
            if (dmfi_AssignCurrentLanguage(oActionTarget, oPC, sLanguage))
                //TODO Send Message to PC saying they're speaking a different language.
                return;
            else
                //TDOO send failur message
                return;
        }
    }

    //Ok that's the end of PC commands, now to DM only commdns.  iOffset hasn't been used yet.
    // that's all the PC commands, bail out if not DM
    if (!_GetIsDM(oPC))
        return;

    if (HasListItem("app,appear"), sCommand)
    {
        int nAppearance;
        string sAppearance;
        
        if (TestStringAgainstPattern("*n", sArgument))
        {
            nAppearance = StringToInt(sArgument);
        }
        else
        {
            //Unlike previous behavior, let's just use the appearance.2da.  This will allow
            // custom worlds to use whatever hak they feel like using without being limited to
            //  the standard NWN list.  This is the hard way, but it works.  
            i = 0;
            //TODO need some serious work for custom worlds, cannot be limited to standard nwn stuff.
            //  will probably need 2da stuff.  how to loop a 2da even when "" is returned for *****
            
            while (1)
            {
                if (Get2DAString("appearance", "NAME", i) == "")
                {
                    nAppearance = -1;
                    break;
                }
                else if (GetStringUpperCase(sArgument) == Get2DAString("appearance", "LABEL", i))
                {
                    nAppearance = i;
                    break;
                }
            }
        }

        if (nAppearance != -1)
            SetCreatureAppearanceType(oActionTarget, i);
        else
            //Raise error
            //return;

        dmw_CleanUp(oCommander);
        return;
    }

    //Ok, now checking for pc checks.  Easy way is if it's all spelled out, but we'll see
    //  Special cases like .use magic device won't work because of the way the string is parsed.
    //  We'll treat those with special cases after checking for the rest.  Since we're going to load
    //  all the skills from the 2da, there can't be any spaces.  This is going to be a limitation
    //  for entry, but will greatly expand the cpaiblity of the system.  TODO how will these offsets
    //  work when the list isn't predefined?  What exactly are the offsets?
    if (nCount = CountList(DMFI_SKILLS))
        dmfi_LoadSkills();
    
    if (nIndex = FindListItem(DMFI_SKILLS, sArgument) != -1)
        iOffset = nIndex + 10 + (nIndex/10);
    

    if(!iOffset)
    {
        //We didn't find anything the easy way.  let's try reducing the 
    }

    {
        sAbbreviatedList = dmfi_AbbreviateList(DMFI_PC_CHECKS, 4);



    }


    if (iOffset)
    {
        if (FindSubString(sCom, "all") != -1 || FindSubString(sArgs, "all") != -1)
            SetLocalInt(oCommander, "dmfi_univ_int", iOffset+40);
        else
            SetLocalInt(oCommander, "dmfi_univ_int", iOffset);

        SetLocalString(oCommander, "dmfi_univ_conv", "dicebag");
        if (GetIsObjectValid(oTarget))
        {
            if (oTarget != GetLocalObject(oCommander, "dmfi_univ_target"))
            {
                SetLocalObject(oCommander, "dmfi_univ_target", oTarget);
                FloatingTextStringOnCreature("DMFI Target set to "+GetName(oTarget), oCommander);
            }
            ExecuteScript("dmfi_execute", oCommander);
        }
        else
        {
            DMFISendMessageToPC(oCommander, "No valid DMFI target!", FALSE, DMFI_MESSAGE_COLOR_ALERT);
        }

        dmw_CleanUp(oCommander);
        return;
    }


    if (GetStringLeft(sCom, 4) == ".set")
    {
        // sCom = GetStringRight(sCom, GetStringLength(sCom) - 4);
        while (sArgs != "")
        {
            if (GetStringLeft(sArgs, 1) == " " ||
                GetStringLeft(sArgs, 1) == "[" ||
                GetStringLeft(sArgs, 1) == "." ||
                GetStringLeft(sArgs, 1) == ":" ||
                GetStringLeft(sArgs, 1) == ";" ||
                GetStringLeft(sArgs, 1) == "*" ||
                GetIsAlphanumeric(GetStringLeft(sArgs, 1)))
                sArgs = GetStringRight(sArgs, GetStringLength(sArgs) - 1);
            else
            {
                SetLocalObject(GetModule(), "hls_NPCControl" + GetStringLeft(sArgs, 1), oTarget);
                FloatingTextStringOnCreature("The Control character for " + GetName(oTarget) + " is " + GetStringLeft(sArgs, 1), oCommander, FALSE);
                return;
            }
        }
        FloatingTextStringOnCreature("Your Control Character is not valid. Perhaps you are using a reserved character.", oCommander, FALSE);
        return;
    }
    else if (GetStringLeft(sCom, 4) == ".ani")
    {
        int iArg = StringToInt(sArgs);
        AssignCommand(oTarget, ClearAllActions(TRUE));
        AssignCommand(oTarget, ActionPlayAnimation(iArg, 1.0, 99999.0f));
        return;
    }
    else if (GetStringLowerCase(GetStringLeft(sCom, 4)) == ".buf")
    {
        string sArgsLC = GetStringLowerCase(sArgs);
        if (FindSubString(sArgsLC, "low") !=-1)
        {
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectACIncrease(3, AC_NATURAL_BONUS), oTarget, 3600.0f);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectVisualEffect(VFX_DUR_PROT_BARKSKIN), oTarget, 3600.0f);
            AssignCommand(oTarget, ActionCastSpellAtObject(SPELL_RESISTANCE, oTarget, METAMAGIC_ANY, TRUE, 5, PROJECTILE_PATH_TYPE_DEFAULT, TRUE));
            AssignCommand(oTarget, ActionCastSpellAtObject(SPELL_GHOSTLY_VISAGE, oTarget, METAMAGIC_ANY, TRUE, 5, PROJECTILE_PATH_TYPE_DEFAULT, TRUE));
            AssignCommand(oTarget, ActionCastSpellAtObject(SPELL_CLARITY,  oTarget,METAMAGIC_ANY, TRUE, 5, PROJECTILE_PATH_TYPE_DEFAULT, TRUE));
            FloatingTextStringOnCreature("Low Buff applied: " + GetName(oTarget), oCommander);   return;
        }
        else if (FindSubString(sArgsLC, "mid") !=-1)
        {
            AssignCommand(oTarget, ActionCastSpellAtObject(SPELL_LESSER_SPELL_MANTLE, oTarget, METAMAGIC_ANY, TRUE, 10, PROJECTILE_PATH_TYPE_DEFAULT, TRUE));
            AssignCommand(oTarget, ActionCastSpellAtObject(SPELL_STONESKIN, oTarget, METAMAGIC_ANY, TRUE, 10, PROJECTILE_PATH_TYPE_DEFAULT, TRUE));
            AssignCommand(oTarget, ActionCastSpellAtObject(SPELL_ELEMENTAL_SHIELD,  oTarget,METAMAGIC_ANY, TRUE, 10, PROJECTILE_PATH_TYPE_DEFAULT, TRUE));
            FloatingTextStringOnCreature("Mid Buff applied: " + GetName(oTarget), oCommander);  return;
        }
        else if (FindSubString(sArgsLC, "high") !=-1)
        {
            AssignCommand(oTarget, ActionCastSpellAtObject(SPELL_SPELL_MANTLE, oTarget, METAMAGIC_ANY, TRUE, 15, PROJECTILE_PATH_TYPE_DEFAULT, TRUE));
            AssignCommand(oTarget, ActionCastSpellAtObject(SPELL_STONESKIN, oTarget, METAMAGIC_ANY, TRUE,15, PROJECTILE_PATH_TYPE_DEFAULT, TRUE));
            AssignCommand(oTarget, ActionCastSpellAtObject(SPELL_SHADOW_SHIELD,  oTarget,METAMAGIC_ANY, TRUE, 15, PROJECTILE_PATH_TYPE_DEFAULT, TRUE));
            FloatingTextStringOnCreature("High Buff applied: " + GetName(oTarget), oCommander);  return;
        }
        else if (FindSubString(sArgsLC, "epic") !=-1)
        {
            AssignCommand(oTarget, ActionCastSpellAtObject(SPELL_GREATER_SPELL_MANTLE, oTarget, METAMAGIC_ANY, TRUE, 20, PROJECTILE_PATH_TYPE_DEFAULT, TRUE));
            AssignCommand(oTarget, ActionCastSpellAtObject(SPELL_SPELL_RESISTANCE, oTarget, METAMAGIC_ANY, TRUE, 20, PROJECTILE_PATH_TYPE_DEFAULT, TRUE));
            AssignCommand(oTarget, ActionCastSpellAtObject(SPELL_SHADOW_SHIELD,  oTarget,METAMAGIC_ANY, TRUE, 20, PROJECTILE_PATH_TYPE_DEFAULT, TRUE));
            AssignCommand(oTarget, ActionCastSpellAtObject(SPELL_CLARITY,  oTarget,METAMAGIC_ANY, TRUE, 20, PROJECTILE_PATH_TYPE_DEFAULT, TRUE));
            FloatingTextStringOnCreature("Epic Buff applied: " + GetName(oTarget), oCommander);  return;
        }
        else if (FindSubString(sArgsLC, "barkskin") != -1)
        {
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectACIncrease(3, AC_NATURAL_BONUS), oTarget, 3600.0f);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectVisualEffect(VFX_DUR_PROT_BARKSKIN), oTarget, 3600.0f);  return;
        }
        else if (FindSubString(sArgsLC, "elements") != -1)
        {
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectDamageResistance(DAMAGE_TYPE_COLD, 20, 40), oTarget, 3600.0f);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectDamageResistance(DAMAGE_TYPE_FIRE, 20, 40), oTarget, 3600.0f);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectDamageResistance(DAMAGE_TYPE_ACID, 20, 40), oTarget, 3600.0f);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectDamageResistance(DAMAGE_TYPE_SONIC, 20, 40), oTarget, 3600.0f);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectDamageResistance(DAMAGE_TYPE_ELECTRICAL, 20, 40), oTarget, 3600.0f);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectVisualEffect(VFX_DUR_PROTECTION_ELEMENTS), oTarget, 3600.0f);  return;
        }
        else if (FindSubString(sArgsLC, "haste") != -1)
        {
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectHaste(), oTarget, 3600.0f);  return;
        }
        else if (FindSubString(sArgsLC, "immortal") != -1) // tsunami282 added
        {
            SetImmortal(oTarget, TRUE);
            FloatingTextStringOnCreature("The target is set to Immortal (cannot die).", oCommander, FALSE);  return;
        }
        else if (FindSubString(sArgsLC, "mortal") != -1) // tsunami282 added
        {
            SetImmortal(oTarget, TRUE);
            FloatingTextStringOnCreature("The target is set to Mortal (can die).", oCommander, FALSE);  return;
        }
        else if (FindSubString(sArgsLC, "invis") != -1)
        {
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectInvisibility(INVISIBILITY_TYPE_NORMAL), oTarget, 3600.0f);   return;
        }
        else if (FindSubString(sArgsLC, "unplot") != -1)
        {
            SetPlotFlag(oTarget, FALSE);
            FloatingTextStringOnCreature("The target is set to non-Plot.", oCommander, FALSE); return;
        }
        else if (FindSubString(sArgsLC, "plot") != -1)
        {
            SetPlotFlag(oTarget, TRUE);
            FloatingTextStringOnCreature("The target is set to Plot.", oCommander, FALSE);  return;
        }
        else if (FindSubString(sArgsLC, "stoneskin") != -1)
        {
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectDamageReduction(10, DAMAGE_POWER_PLUS_THREE, 100), oTarget, 3600.0f);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectVisualEffect(VFX_DUR_PROT_GREATER_STONESKIN), oTarget, 3600.0f); return;
        }
        else if (FindSubString(sArgsLC, "trues") != -1)
        {
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectTrueSeeing(), oTarget, 3600.0f); return;
        }
    }
    else if (GetStringLeft(sCom, 4) == ".dam")
    {
        int iArg = StringToInt(sArgs);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDamage(iArg, DAMAGE_TYPE_MAGICAL, DAMAGE_POWER_NORMAL), oTarget);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_COM_BLOOD_LRG_RED), oTarget);
        FloatingTextStringOnCreature(GetName(oTarget) + " has taken " + IntToString(iArg) + " damage.", oCommander, FALSE);
        return;
    }
    // 2008.05.29 tsunami282 - set description
    else if (GetStringLeft(sCom, 5) == ".desc")
    {
        // object oTgt = GetLocalObject(oCommander, "dmfi_univ_target");
        if (GetIsObjectValid(oTarget))
        {
            if (sArgs == ".") // single dot means reset to base description
            {
                SetDescription(oTarget);
            }
            else // assign new description
            {
                SetDescription(oTarget, sArgs);
            }
            FloatingTextStringOnCreature("Target's description set to " + GetDescription(oTarget), oCommander, FALSE);
        }
        else
        {
            FloatingTextStringOnCreature("Invalid target - command not processed.", oCommander, FALSE);
        }
    }
    else if (GetStringLeft(sCom, 5) == ".dism")
    {
        DestroyObject(oTarget);
        FloatingTextStringOnCreature(GetName(oTarget) + " dismissed", oCommander, FALSE); return;
    }
    else if (GetStringLeft(sCom, 4) == ".inv")
    {
        OpenInventory(oTarget, oCommander);
        return;
    }
    else if (GetStringLeft(sCom, 4) == ".dmt")
    {
        SetLocalInt(GetModule(), "dmfi_DMToolLock", abs(GetLocalInt(GetModule(), "dmfi_DMToolLock") -1)); return;
    }
    // else if (GetStringLowerCase(GetStringLeft(sCom, 4)) == ".dms")
    // {
    //     SetDMFIPersistentInt("dmfi", "dmfi_DMSpy", abs(GetDMFIPersistentInt("dmfi", "dmfi_DMSpy", oCommander) -1), oCommander); return;
    // }
    else if (GetStringLeft(sCom, 4) == ".fac")
    {
        string sArgsLC = GetStringLowerCase(sArgs);
        if (FindSubString(sArgsLC, "hostile") != -1)
        {
            ChangeToStandardFaction(oTarget, STANDARD_FACTION_HOSTILE);
            FloatingTextStringOnCreature("Faction set to hostile", oCommander, FALSE);
        }
        else if (FindSubString(sArgsLC, "commoner") != -1)
        {
            ChangeToStandardFaction(oTarget, STANDARD_FACTION_COMMONER);
            FloatingTextStringOnCreature("Faction set to commoner", oCommander, FALSE);
        }
        else if (FindSubString(sArgsLC, "defender") != -1)
        {
            ChangeToStandardFaction(oTarget, STANDARD_FACTION_DEFENDER);
            FloatingTextStringOnCreature("Faction set to defender", oCommander, FALSE);
        }
        else if (FindSubString(sArgsLC, "merchant") != -1)
        {
            ChangeToStandardFaction(oTarget, STANDARD_FACTION_MERCHANT);
            FloatingTextStringOnCreature("Faction set to merchant", oCommander, FALSE);
        }
        else
        {
            DMFISendMessageToPC(oCommander, "Invalid faction name - command aborted.", FALSE, DMFI_MESSAGE_COLOR_ALERT);
            return;
        }

        // toggle blindness on the target, to cause a re-perception
        if (GetIsImmune(oTarget, IMMUNITY_TYPE_BLINDNESS))
        {
            DMFISendMessageToPC(oCommander, "Targeted creature is blind immune - no attack will occur until new perception event is fired", FALSE, DMFI_MESSAGE_COLOR_ALERT);
        }
        else
        {
            effect eInvis =EffectBlindness();
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eInvis, oTarget, 6.1);
            DMFISendMessageToPC(oCommander, "Faction Adjusted - will take effect in 6 seconds", FALSE, DMFI_MESSAGE_COLOR_STATUS);
        }
        return;
    }
    else if (GetStringLeft(sCom, 4) == ".fle")
    {
        AssignCommand(oTarget, ClearAllActions(TRUE));
        AssignCommand(oTarget, ActionMoveAwayFromObject(oCommander, TRUE));
        return;
    }
    else if (GetStringLeft(sCom, 4) == ".fly")
    {
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDisappear(), oTarget);
        return;
    }
    else if (GetStringLeft(sCom, 4) == ".fol")
    {
        int iArg = StringToInt(sArgs);
        FloatingTextStringOnCreature(GetName(oTarget) + " will follow you for "+IntToString(iArg)+" seconds.", oCommander, FALSE);
        AssignCommand(oTarget, ClearAllActions(TRUE));
        AssignCommand(oTarget, ActionForceMoveToObject(oCommander, TRUE, 2.0f, IntToFloat(iArg)));
        DelayCommand(IntToFloat(iArg), FloatingTextStringOnCreature(GetName(oTarget) + " has stopped following you.", oCommander, FALSE));
        return;
    }
    else if (GetStringLeft(sCom, 4) == ".fre")
    {
        FloatingTextStringOnCreature(GetName(oTarget) + " frozen", oCommander, FALSE);
        SetCommandable(TRUE, oTarget);
        AssignCommand(oTarget, ClearAllActions(TRUE));
        DelayCommand(0.5f, SetCommandable(FALSE, oTarget));
        return;
    }
    else if (GetStringLeft(sCom, 4) == ".get")
    {
        while (sArgs != "")
        {
            if (GetStringLeft(sArgs, 1) == " " ||
                GetStringLeft(sArgs, 1) == "[" ||
                GetStringLeft(sArgs, 1) == "." ||
                GetStringLeft(sArgs, 1) == ":" ||
                GetStringLeft(sArgs, 1) == ";" ||
                GetStringLeft(sArgs, 1) == "*" ||
                GetIsAlphanumeric(GetStringLeft(sArgs, 1)))
                sArgs = GetStringRight(sArgs, GetStringLength(sArgs) - 1);
            else
            {
                object oJump = GetLocalObject(GetModule(), "hls_NPCControl" + GetStringLeft(sArgs, 1));
                if (GetIsObjectValid(oJump))
                {
                    AssignCommand(oJump, ClearAllActions());
                    AssignCommand(oJump, ActionJumpToLocation(GetLocation(oCommander)));
                }
                else
                {
                    FloatingTextStringOnCreature("Your Control Character is not valid. Perhaps you are using a reserved character.", oCommander, FALSE);
                }
                return;
            }
        }
        FloatingTextStringOnCreature("Your Control Character is not valid. Perhaps you are using a reserved character.", oCommander, FALSE);
        return;

    }
    else if (GetStringLeft(sCom, 4) == ".got")
    {
        while (sArgs != "")
        {
            if (GetStringLeft(sArgs, 1) == " " ||
                GetStringLeft(sArgs, 1) == "[" ||
                GetStringLeft(sArgs, 1) == "." ||
                GetStringLeft(sArgs, 1) == ":" ||
                GetStringLeft(sArgs, 1) == ";" ||
                GetStringLeft(sArgs, 1) == "*" ||
                GetIsAlphanumeric(GetStringLeft(sArgs, 1)))
                sArgs = GetStringRight(sArgs, GetStringLength(sArgs) - 1);
            else
            {
                object oJump = GetLocalObject(GetModule(), "hls_NPCControl" + GetStringLeft(sArgs, 1));
                if (GetIsObjectValid(oJump))
                {
                    AssignCommand(oCommander, ClearAllActions());
                    AssignCommand(oCommander, ActionJumpToLocation(GetLocation(oJump)));
                }
                else
                {
                    FloatingTextStringOnCreature("Your Control Character is not valid. Perhaps you are using a reserved character.", oCommander, FALSE);
                }
                return;
            }
        }
        FloatingTextStringOnCreature("Your Control Character is not valid. Perhaps you are using a reserved character.", oCommander, FALSE);
        return;
    }
    else if (GetStringLeft(sCom, 4) == ".hea")
    {
        int iArg = StringToInt(sArgs);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(iArg), oTarget);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_HEALING_M), oTarget);
        FloatingTextStringOnCreature(GetName(oTarget) + " has healed " + IntToString(iArg) + " HP.", oCommander, FALSE);
        return;
    }
    else if (GetStringLeft(sCom, 4) == ".ite")
    {
        object oCreate = CreateItemOnObject(sArgs, oTarget, 1);
        if (GetIsObjectValid(oCreate)) FloatingTextStringOnCreature("Item " + GetName(oCreate) + " created.", oCommander, FALSE);
        return;
    }
    // 2008.05.29 tsunami282 - set name
    else if (GetStringLeft(sCom, 5) == ".name")
    {
        // object oTgt = GetLocalObject(oCommander, "dmfi_univ_target");
        if (GetIsObjectValid(oTarget))
        {
            if (sArgs == ".") // single dot means reset to base name
            {
                SetName(oTarget);
            }
            else // assign new name
            {
                SetName(oTarget, sArgs);
            }
            FloatingTextStringOnCreature("Target's name set to " + GetName(oTarget), oCommander, FALSE);
        }
        else
        {
            FloatingTextStringOnCreature("Invalid target - command not processed.", oCommander, FALSE);
        }
    }
    else if (GetStringLeft(sCom, 4) == ".mut")
    {
        FloatingTextStringOnCreature(GetName(oTarget) + " muted", oCommander, FALSE);
        SetLocalInt(oTarget, "dmfi_Mute", 1);
        return;
    }
    else if (GetStringLeft(sCom, 4) == ".npc")
    {
        object oCreate = CreateObject(OBJECT_TYPE_CREATURE, sArgs, GetLocation(oTarget));
        if (GetIsObjectValid(oCreate))
            FloatingTextStringOnCreature("NPC " + GetName(oCreate) + " created.", oCommander, FALSE);
        return;
    }
    else if (GetStringLeft(sCom, 4) == ".pla")
    {
        object oCreate = CreateObject(OBJECT_TYPE_PLACEABLE, sArgs, GetLocation(oTarget));
        if (GetIsObjectValid(oCreate))
            FloatingTextStringOnCreature("Placeable " + GetName(oCreate) + " created.", oCommander, FALSE);
        return;
    }
    else if (GetStringLeft(sCom, 4) == ".rem")
    {
        effect eRemove = GetFirstEffect(oTarget);
        while (GetIsEffectValid(eRemove))
        {
            RemoveEffect(oTarget, eRemove);
            eRemove = GetNextEffect(oTarget);
        }
        return;
    }
    else if (GetStringLeft(sCom, 4) == ".say")
    {
        int iArg = StringToInt(sArgs);
        if (GetDMFIPersistentString("dmfi", "hls206" + IntToString(iArg)) != "")
        {
            AssignCommand(oTarget, SpeakString(GetDMFIPersistentString("dmfi", "hls206" + IntToString(iArg))));
        }
        return;
    }
    else if (GetStringLeft(sCom, 4) == ".tar")
    {
        object oGet = GetFirstObjectInArea(GetArea(oCommander));
        while (GetIsObjectValid(oGet))
        {
            if (FindSubString(GetName(oGet), sArgs) != -1)
            {
                // SetLocalObject(oCommander, "dmfi_VoiceTarget", oGet);
                SetLocalObject(oCommander, "dmfi_univ_target", oGet);
                FloatingTextStringOnCreature("You have targeted " + GetName(oGet) + " with the DMFI Targeting Widget", oCommander, FALSE);
                return;
            }
            oGet = GetNextObjectInArea(GetArea(oCommander));
        }
        FloatingTextStringOnCreature("Target not found.", oCommander, FALSE);
        return;
    }
    else if (GetStringLeft(sCom, 4) == ".unf")
    {
        FloatingTextStringOnCreature(GetName(oTarget) + " unfrozen", oCommander, FALSE);
        SetCommandable(TRUE, oTarget); return;
    }
    else if (GetStringLeft(sCom, 4) == ".unm")
    {
        FloatingTextStringOnCreature(GetName(oTarget) + " un-muted", oCommander, FALSE);
        DeleteLocalInt(oTarget, "dmfi_Mute"); return;
    }
    else if (GetStringLeft(sCom, 4) == ".vfx")
    {
        int iArg = StringToInt(sArgs);
        if (GetTag(oTarget) == "dmfi_voice")
            ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(iArg), GetLocation(oTarget), 10.0f);
        else
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(iArg), oTarget, 10.0f);
        return;
    }
    else if (GetStringLeft(sCom, 5) == ".vtar")
    {
        object oGet = GetFirstObjectInArea(GetArea(oCommander));
        while (GetIsObjectValid(oGet))
        {
            if (FindSubString(GetName(oGet), sArgs) != -1)
            {
                SetLocalObject(oCommander, "dmfi_VoiceTarget", oGet);
                FloatingTextStringOnCreature("You have targeted " + GetName(oGet) + " with the Voice Widget", oCommander, FALSE);
                return;
            }
            oGet = GetNextObjectInArea(GetArea(oCommander));
        }
        FloatingTextStringOnCreature("Target not found.", oCommander, FALSE);
        return;
    }
}

////////////////////////////////////////////////////////////////////////
void subTranslateToLanguage(string sSaid, object oShouter, int nVolume,
                            object oMaster, int iTranslate, string sLanguageName,
                            object oEavesdrop)
{
    string sVolume = "said";
    if (nVolume == TALKVOLUME_WHISPER) sVolume = "whispered";
    else if (nVolume == TALKVOLUME_SHOUT) sVolume = "shouted";
    else if (nVolume == TALKVOLUME_PARTY) sVolume = "said to the party";
    else if (nVolume == TALKVOLUME_SILENT_SHOUT) sVolume = "said to the DM's";

    //Translate and Send or do Lore check
    if (oEavesdrop == oMaster ||
        GetIsObjectValid(GetItemPossessedBy(oEavesdrop, "hlslang_" + IntToString(iTranslate))) ||
        GetIsObjectValid(GetItemPossessedBy(oEavesdrop, "babelfish")) ||
        iTranslate == GetDefaultRacialLanguage(oEavesdrop, 0) ||
        iTranslate == GetDefaultClassLanguage(oEavesdrop) ||
        GetIsDM(oEavesdrop) ||
        GetIsDMPossessed(oEavesdrop))
    {
        DelayCommand(0.1, DMFISendMessageToPC(oEavesdrop, GetName(oShouter) + " " + sVolume + " in " + sLanguageName + ": " + sSaid, FALSE, DMFI_MESSAGE_COLOR_TRANSLATION));
    }
    else
    {
        if (iTranslate != 9)
        {
            string sKnownLanguage;
            if (d20() + GetSkillRank(SKILL_LORE, oEavesdrop) > 20) sKnownLanguage = sLanguageName;
            else sKnownLanguage = "a language you do not recognize";
            DelayCommand(0.1, DMFISendMessageToPC(oEavesdrop, GetName(oShouter)+" "+sVolume+" something in "+sKnownLanguage+".", FALSE, DMFI_MESSAGE_COLOR_TRANSLATION));
        }
    }
}

////////////////////////////////////////////////////////////////////////
string TranslateToLanguage(string sSaid, object oShouter, int nVolume, object oMaster)
{
// arguments
//  (return) = translated text
//  sSaid = string to translate
//  oShouter = object that spoke sSaid
//  iVolume = TALKVOLUME setting of speaker
//  oMaster = master of oShouter (if oShouter has no master, oMaster should equal oShouter)

    //Gets the current language that the character is speaking
    int iTranslate = GetLocalInt(oShouter, "hls_MyLanguage");
    if (!iTranslate) iTranslate = GetDefaultRacialLanguage(oShouter, 1);
    if (!iTranslate)
    {
        DMFISendMessageToPC(oMaster, "Translator Error: your message was dropped.", FALSE, DMFI_MESSAGE_COLOR_ALERT);
        return "";
    }

    //Defines language name
    string sLanguageName = GetLocalString(oShouter, "hls_MyLanguageName");

    sSaid = GetStringRight(sSaid, GetStringLength(sSaid)-1); // toss the leading translate flag '['
    string sSpeak = TranslateCommonToLanguage(iTranslate, sSaid);
    // lop off trailing ']'
    if (GetStringRight(sSaid, 1) == "]")
        sSaid = GetStringLeft(sSaid, GetStringLength(sSaid)-1);
    // AssignCommand(oShouter, SpeakString(sSpeak)); // no need reissue translated speech, handled in player chat hook

    // send speech to everyone who should be able to hear
    float fDistance = 20.0f;
    if (nVolume == TALKVOLUME_WHISPER)
    {
        fDistance = 1.0f;
    }
    string sVolume = "said";
    if (nVolume == TALKVOLUME_WHISPER) sVolume = "whispered";
    else if (nVolume == TALKVOLUME_SHOUT) sVolume = "shouted";
    else if (nVolume == TALKVOLUME_PARTY) sVolume = "said to the party";
    else if (nVolume == TALKVOLUME_SILENT_SHOUT) sVolume = "said to the DM's";
    string sKnownLanguage;

    // send translated message to PC's in range who understand it
    object oEavesdrop = GetFirstObjectInShape(SHAPE_SPHERE, fDistance, GetLocation(oShouter), FALSE, OBJECT_TYPE_CREATURE);
    while (GetIsObjectValid(oEavesdrop))
    {
        if (GetIsPC(oEavesdrop) || GetIsDM(oEavesdrop) || GetIsDMPossessed(oEavesdrop) || GetIsPossessedFamiliar(oEavesdrop))
        {
            subTranslateToLanguage(sSaid, oShouter, nVolume, oMaster, iTranslate, sLanguageName, oEavesdrop);
        }
        oEavesdrop = GetNextObjectInShape(SHAPE_SPHERE, fDistance, GetLocation(oShouter), FALSE, OBJECT_TYPE_CREATURE);
    }

    // send translated message to DM's in range
    oEavesdrop = GetFirstPC();
    while (GetIsObjectValid(oEavesdrop))
    {
        if (GetIsDM(oEavesdrop))
        {
            if (GetArea(oShouter) == GetArea(oEavesdrop) &&
                GetDistanceBetweenLocations(GetLocation(oShouter), GetLocation(oEavesdrop)) <= fDistance)
            {
                subTranslateToLanguage(sSaid, oShouter, nVolume, oMaster, iTranslate, sLanguageName, oEavesdrop);
            }
        }
        oEavesdrop = GetNextPC();
    }
    return sSpeak;
}

////////////////////////////////////////////////////////////////////////
int RelayTextToEavesdropper(object oShouter, int nVolume, string sSaid)
{
// arguments
//  (return) - flag to continue processing text: X2_EXECUTE_SCRIPT_CONTINUE or
//             X2_EXECUTE_SCRIPT_END
//  oShouter - object that spoke
//  nVolume - channel (TALKVOLUME) text was spoken on
//  sSaid - text that was spoken

    int bScriptEnd = X2_EXECUTE_SCRIPT_CONTINUE;

    // sanity checks
    if (GetIsObjectValid(oShouter))
    {
        int iHookToDelete = 0;
        int iHookType = 0;
        int channels = 0;
        int rangemode = 0;
        string siHook = "";
        object oMod = MODULE;
        int iHook = 1;
        while (1)
        {
            siHook = IntToString(iHook);
            iHookType = GetLocalInt(oMod, sHookTypeVarname+siHook);
            if (iHookType == 0) break; // end of list

            // check channel
            channels = GetLocalInt(oMod, sHookChannelsVarname+siHook);
            if (((1 << nVolume) & channels) != 0)
            {
                string sVol = (nVolume == TALKVOLUME_WHISPER ? "whispers" : "says");
                object oOwner = GetLocalObject(oMod, sHookOwnerVarname+siHook);
                if (GetIsObjectValid(oOwner))
                {
                    // it's a channel for us to listen on, process
                    int bcast = GetLocalInt(oMod, sHookBcastDMsVarname+siHook);
                    // for type 1, see if speaker is the one we want (pc or party)
                    // for type 2, see if speaker says his stuff within ("earshot" / area / module) of listener's location
                    if (iHookType == 1) // listen to what a PC hears
                    {
                        object oListener;
                        location locShouter, locListener;
                        object oTargeted = GetLocalObject(oMod, sHookCreatureVarname+siHook);
                        if (GetIsObjectValid(oTargeted))
                        {
                            rangemode = GetLocalInt(oMod, sHookRangeModeVarname+siHook);
                            if (rangemode) oListener = GetFirstFactionMember(oTargeted, FALSE); // everyone in party are our listeners
                            else oListener = oTargeted; // only selected PC is our listener
                            while (GetIsObjectValid(oListener))
                            {
                                // check speaker:
                                // check within earshot
                                int bInRange = FALSE;
                                locShouter = GetLocation(oShouter);
                                locListener = GetLocation(oListener);
                                if (oShouter == oListener)
                                {
                                    bInRange = TRUE; // the target can always hear himself
                                }
                                else if (GetAreaFromLocation(locShouter) == GetAreaFromLocation(locListener))
                                {
                                    float dist = GetDistanceBetweenLocations(locListener, locShouter);
                                    if ((nVolume == TALKVOLUME_WHISPER && dist <= WHISPER_DISTANCE) ||
                                        (nVolume != TALKVOLUME_WHISPER && dist <= TALK_DISTANCE))
                                    {
                                        bInRange = TRUE;
                                    }
                                }
                                if (bInRange)
                                {
                                    // relay what's said to the hook owner
                                    string sMesg = "("+GetName(GetArea(oShouter))+") "+GetName(oShouter)+" "+sVol+": "+sSaid;
                                    // if (bcast) SendMessageToAllDMs(sMesg);
                                    // else SendMessageToPC(oOwner, sMesg);
                                    DMFISendMessageToPC(oOwner, sMesg, bcast, DMFI_MESSAGE_COLOR_EAVESDROP);
                                }
                                if (rangemode == 0) break; // only check the target creature for rangemode 0
                                if (bInRange) break; // once any party member hears shouter, we're done
                                oListener = GetNextFactionMember(oTargeted, FALSE);
                            }
                        }
                        else
                        {
                            // bad desired speaker, remove hook
                            iHookToDelete = iHook;
                        }
                    }
                    else if (iHookType == 2) // listen at location
                    {
                        location locShouter, locListener;
                        object oListener = GetLocalObject(oMod, sHookCreatureVarname+siHook);
                        if (oListener != OBJECT_INVALID)
                        {
                            locListener = GetLocation(oListener);
                        }
                        else
                        {
                            locListener = GetLocalLocation(oMod, sHookLocationVarname+siHook);
                        }
                        locShouter = GetLocation(oShouter);
                        rangemode = GetLocalInt(oMod, sHookRangeModeVarname+siHook);
                        int bInRange = FALSE;
                        if (rangemode == 0)
                        {
                            // check within earshot
                            if (GetAreaFromLocation(locShouter) == GetAreaFromLocation(locListener))
                            {
                                float dist = GetDistanceBetweenLocations(locListener, locShouter);
                                if ((nVolume == TALKVOLUME_WHISPER && dist <= WHISPER_DISTANCE) ||
                                    (nVolume != TALKVOLUME_WHISPER && dist <= TALK_DISTANCE))
                                {
                                    bInRange = TRUE;
                                }
                            }
                        }
                        else if (rangemode == 1)
                        {
                            // check within area
                            if (GetAreaFromLocation(locShouter) == GetAreaFromLocation(locListener)) bInRange = TRUE;
                        }
                        else
                        {
                            // module-wide
                            bInRange = TRUE;
                        }
                        if (bInRange)
                        {
                            // relay what's said to the hook owner
                            string sMesg = "("+GetName(GetArea(oShouter))+") "+GetName(oShouter)+" "+sVol+": "+sSaid;
                            // if (bcast) SendMessageToAllDMs(sMesg);
                            // else SendMessageToPC(oOwner, sMesg);
                            DMFISendMessageToPC(oOwner, sMesg, bcast, DMFI_MESSAGE_COLOR_EAVESDROP);
                        }
                    }
                    else
                    {
                        WriteTimestampedLogEntry("ERROR: DMFI OnPlayerChat handler: invalid iHookType; removing hook.");
                        iHookToDelete = iHook;
                    }
                }
                else
                {
                    // bad owner, delete hook
                    iHookToDelete = iHook;
                }
            }

            iHook++;
        }

        // remove a bad hook: note we can only remove one bad hook this way, have to rely on subsequent calls to remove any others
        if (iHookToDelete > 0)
        {
            RemoveListenerHook(iHookToDelete);
        }
    }

    return bScriptEnd;
}
