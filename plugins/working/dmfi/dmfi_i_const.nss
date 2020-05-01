// -----------------------------------------------------------------------------
//    File: dmfi_i_const.nss
//  System: DMFI (constants)
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

// -----------------------------------------------------------------------------
//                                   Constants
// -----------------------------------------------------------------------------

const string DMFI = "DMFI Data";
const string DMFI_USER_SETTINGS = "DMFI_USER_SETTINGS";
const string DMFI_INITIALIZED = "DMFI_INITIALIZED";
const string DMFI_TARGET_VOICE = "DMFI_TARGET_VOICE";
const string DMFI_TARGET_COMMAND = "DMFI_TARGET_COMMAND";

const string DMFI_VOICE_COMMANDS = ":,;";  //Plus ,
const string DMFI_ACTION_COMMANDS = "[,*,.";
const string DMFI_TARGET_VOICE = "DMFI_TARGET_VOICE";
const string DMFI_TARGET_UNIVERSAL = "DMFI_TARGET_UNIVERSAL";

const string DMFI_COMMAND_ARGUMENTS = "DMFI_COMMAND_ARGUMENTS";
const string DMFI_DEFAULT_DM_SETTINGS = "ALIGNMENT_SHIFT:5," +
                                        "BEAM_DURATION:5.0," +
                                        "BUFF_LEVEL:LOW," +
                                        "BUFF_PARTY:FALSE," +
                                        "DICEBAG:PRIVATE," +
                                        "EFFECT_DELAY:1.0,";
                                        "EFFECT_DURATION:60.0," +
                                        "EMOTES_MUTED:FALSE," +
                                        "REPUTATION:5.0," +
                                        "SAFE_FACTIONS:0," +
                                        "SAVE_AMOUNT:5.0," +
                                        "SOUND_DELAY:0.2," +
                                        "STUN_DURATION:1000.0,";
                                        "DICEBAG_ANIMATION:TRUE"
const string DMFI_DEFAULT_PC_SETTINGS = "EMOTES_MUTED:FALSE," +
                                        "DICEBAG_ANIMATION:TRUE," +
                                        "DICEBAG:PRIVATE";
const string DMFI_TARGET_VOICE = "DMFI_TARGET_VOICE";
const string DMFI_TARGET_COMMAND = "DMFI_TARGET_COMMAND";

// ----- Settings Constants -----
const string DMFI_SETTING_ALIGNMENT_SHIFT = "ALIGNMENT_SHIFT";
const string DMFI_SETTING_BEAM_DURATION =   "BEAM_DURATION";
const string DMFI_SETTING_BUFF_LEVEL =      "BUFF_LEVEL";
const string DMFI_SETTING_BUFF_PARTY =      "BUFF_PARTY";
const string DMFI_SETTING_DICEBAG =         "DICEBAG";
const string DMFI_SETTING_EFFECT_DELAY =    "EFFECT_DELAY";
const string DMFI_SETTING_EFFECT_DURATION = "EFFECT_DURATION";
const string DMFI_SETTING_EMOTES_MUTED =    "EMOTES_MUTED";
const string DMFI_SETTING_REPUTATION =      "REPUTATION";
const string DMFI_SETTING_SAFE_FACTIONS =   "SAFE_FACTIONS";
const string DMFI_SETTING_SAVE_AMOUNT =     "SAVE_AMOUNT";
const string DMFI_SETTING_SOUND_DELAY =     "SOUND_DELAY";
const string DMFI_SETTING_STUN_DURATION =   "STUN_DURATION";
const string DMFI_SETTING_DICEBAG_ANIMATION =       "DICEBAG_ANIMATION";

// ----- Variable Names -----
const string DMFI_HOOK = "DMFI_HOOK";
const int DMFI_HOOK_HANDLE_SPLIT = 10000;

const string DMFI_CHATHOOK_PREVIOUS_HANDLE = "DMFI_CHATHOOK_PREVIOUS_HANDLE";
const string DMFI_CHATHOOK_HANDLE = "DMFI_CHATHOOK_HANDLE";
const string DMFI_CHATHOOK_SCRIPT = "DMFI_CHATHOOK_SCRIPT";
const string DMFI_CHATHOOK_RUNNER = "DMFI_CHATHOOK_RUNNER";
const string DMFI_CHATHOOK_CHANNELS = "DMFI_CHATHOOK_CHANNELS";
const string DMFI_CHATHOOK_LISTENALL = "DMFI_CHATHOOK_LISTENALL";
const string DMFI_CHATHOOK_SPEAKER = "DMFI_CHATHOOK_SPEAKER";
const string DMFI_CHATHOOK_AUTOREMOVE = "DMFI_CHATHOOK_AUTOREMOVE";

const string DMFI_LISTENER_HANDLE = "DMFI_LISTENER_HANDLE";
const string DMFI_LISTENER_TYPE = "DMFI_LISTENER_TYPE";
const string DMFI_LISTENER_CREATURE = "DMFI_LISTENER_CREATURE";
const string DMFI_LISTENER_LOCATION = "DMFI_LISTENER_LOCATION";
const string DMFI_LISTENER_CHANNELS = "DMFI_LISTENER_CHANNELS";
const string DMFI_LISTENER_OWNER = "DMFI_LISTENER_OWNER";
const string DMFI_LISTENER_RANGE = "DMFI_LISTENER_RANGE";
const string DMFI_LISTENER_BROADCAST = "DMFI_LISTENER_BROADCAST";

const int DMFI_LISTENER_RANGE_EARSHOT = 0;
const int DMFI_LISTENER_RANGE_AREA = 1;
const int DMFI_LISTENER_RANGE_REGION = 2;
const int DMFI_LISTENER_RANGE_MODULE = 3;

const string DMFI_LANGUAGE_ITEM_PREFIX = "dmfi_l_";
const string DMFI_WAND_ITEM_PREFIX = "dmfi_";
const int DMFI_SORT_LIST = TRUE;
const string DMFI_DM_WAND_INITIALIZED = "DMFI_DM_WAND_INITIALIZED";
const string DMFI_DM_WAND_OBJECT_LIST = "DMFI_DM_WAND_OBJECT_LIST";
const string DMFI_PC_WAND_OBJECT_LIST = "DMFI_PC_WAND_OBJECT_LIST";
const string DMFI_DM_WAND_LOADED_CSV = "DMFI_DM_WAND_LOADED_CSV";
const string DMFI_PC_WAND_LOADED_CSV = "DMFI_PC_WAND_LOADED_CSV";
const string DMFI_PC_WAND_INITIALIZED = "DMFI_PC_WAND_INITIALIZED";

const string DMFI_WAND_TITLE = "DMFI_WAND_TITLE";
const string DMFI_WAND_FUNCTION = "DMFI_WAND_FUNCTION";

const string DMFI_LANGUAGE_OBJECT_LIST = "DMFI_LANGUAGE_OBJECT_LIST";
const string DMFI_LANGUAGE_LOADED_CSV = "DMFI_LANGUAGE_LOADED_CSV";
const string DMFI_LANGUAGE_INITIALIZED = "DMFI_LANGUAGE_INITIALIZED";
const string DMFI_LANGUAGE_INDEX = "DMFI_LANGUAGE_INDEX";
const string DMFI_LANGUAGE_NAME = "DMFI_LANGUAGE_NAME";
const string DMFI_LANGUAGE_ABBREVIATION = "DMFI_LANGUAGE_ABBREVIATION";
const string DMFI_LANGUAGE_ALPHABET = "DMFI_LANGUAGE_ALPHABET";
const string DMFI_LANGUAGE_TRANSLATION_MODE = "DMFI_LANGUAGE_TRANSLATION_MODE";
const string DMFI_LANGUAGE_COMMON = "common";

const string DMFI_LANGUAGE_KNOWN = "DMFI_LANGUAGE_KNOWN";
const string DMFI_LANGUAGE_CURRENT = "DMFI_LANGUAGE_CURRENT";

const int DMFI_LANGUAGE_MODE_LETTER = 0;
const int DMFI_LANGUAGE_MODE_WORD = 1;
const int DMFI_LANGUAGE_MODE_REPEAT = 2;

// TODO move these to config file?

//CSV to determine which languages are available in the module.  Language
//  variables are set on the language items dmfi_l_*.  The values in this
//  list must match the * portion of the item tag in order to load
//  correctly.  Language names must be <=9 characters.
const string DMFI_LANGUAGE_INSTALLED = "common," +
                                       "drow," +
                                       "abyssal," +
                                       "celestial," +
                                       "cant," +
                                       "infernal," +
                                       "draconic," +
                                       "goblin," +
                                       "dwarf," +
                                       "elven," +
                                       "gnome," +
                                       "halfling," +
                                       "orc," +
                                       "animal," +
                                       "sylvan," +
                                       "rashemi," +
                                       "mulhorandi," +
                                       "leetspeak";                                

//This is a CSV to determine which wands a DM should have in his inventory.
const string DMFI_DM_WAND_INVENTORY = "afflict," +
                                      "dicebag," +
                                      "pc_dicebag," +
                                      "pc_follow," +
                                      "pc_emote," +
                                      "server," +
                                      "emote," +
                                      "encounter," +
                                      "faction," +
                                      "fx," +
                                      "music," +
                                      "sound," +
                                      "voice," +
                                      "xp," +
                                      "500xp," +
                                      "en_ditto," +
                                      "mute," +
                                      "peace," +
                                      "voiceWidget," +
                                      "remove," +
                                      "dmw," +
                                      "target," +
                                      "buff," +
                                      "dmbook," +
                                      "playerbook," +
                                      "jail_widget," +
                                      "naming";
const string DMFI_PC_WAND_INVENTORY = "playerbook," +
                                      "emote";
const string DMFI_WAND_REMOVE =       "exploder";

const string DMFI_EMOTES_MUTED = DMFI_EMOTES_MUTED;
int DMFI_MODULE_EMOTES_MUTED = GetLocalInt(DMFI, DMFI_EMOTES_MUTED);

string DMFI_SKILLS;

object DMFI_DATA = GetDatapoint(DMFI);

struct DMFI_CHATHOOK
{
    int nHandle;
    int nChannels;
    int nListenAll;
    int nAutoRemove;
    string sScript;
    object oScriptRunner;
    object oSpeaker;
}

struct DMFI_LISTENER_HOOK
{
    int nHandle;
    int nType;
    int nChannels;
    int bParty;
    int bBroadcast;
    object oCreature;
    object oOwner;
    location lLocation;
}

struct DMFI_LANGUAGE_ITEM
{
    int nIndex;
    int nMode;
    int nActive;
    string sName;
    string sAbbreviation;
    string sAlphabet;
}
