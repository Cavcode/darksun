
#include "util_i_varlists"

int DMFI_CHANNELMASK_TALK = (1 << TALKVOLUME_TALK);
int DMFI_CHANNELMASK_WHISPER = (1 << TALKVOLUME_WHISPER);
int DMFI_CHANNELMASK_SHOUT = (1 << TALKVOLUME_SHOUT);
// * this channel not hookable ** int DMFI_CHANNELMASK_SILENT_TALK = (1 << TALKVOLUME_SILENT_TALK);
int DMFI_CHANNELMASK_DM = (1 << TALKVOLUME_SILENT_SHOUT);
int DMFI_CHANNELMASK_PARTY = (1 << TALKVOLUME_PARTY);
// * this channel not hookable ** int DMFI_CHANNELMASK_TELL = (1 << TALKVOLUME_TELL);

const int DMFI_LISTEN_ON_CHANNEL_TALK = 1;
const int DMFI_LISTEN_ON_CHANNEL_WHISPER = 1;
const int DMFI_LISTEN_ON_CHANNEL_SHOUT = 1;
const int DMFI_LISTEN_ON_CHANNEL_DM = 1;
const int DMFI_LISTEN_ON_CHANNEL_PARTY = 1;

const string DMFI_EAVESDROP_HOOK_VARNAME = "dmfi_Eavesdrop";

const float WHISPER_DISTANCE = 1.0;
const float TALK_DISTANCE = 30.0;

// ---< dmfi_AddChatHook >---
// Adds a ChatHook to the DMFI datapoint in order to receive chat data from a
//  specified source.  The chat hook specifies the Chat Receiver (oScriptRunner),
//  the speaker (oSpeaker), the script to be run when the chat is received
//  (sChatHandlerScript), the channels to listen on (maskChannels), whether to
//  listen to all channels (bListenAll) and whether to remove the hook the first
//  time it's called (bAutoRemove).
// Returns a unique handle to the hook so it can later be removed.
int dmfi_AddChatHook(string sChatHandlerScript, object oScriptRunner = OBJECT_SELF,
        int maskChannels = -1, int bListenAll = TRUE, object oSpeaker = OBJECT_INVALID,
        int bAutoRemove = FALSE)
{
    int nHandle;

    do
    {
        nHandle = Random(DMFI_HOOK_HANDLE_SPLIT) + 1;
    } while (FindListInt(DMFI, nHandle, DMFI_CHATHOOK_HANDLE))

    AddListInt(DMFI, hdlHook, DMFI_CHATHOOK_HANDLE);
    AddListString(DMFI, sChatHandlerScript, DMFI_CHATHOOK_SCRIPT);
    AddListObject(DMFI, oScriptRunner, DMFI_CHATHOOK_RUNNER);
    AddListInt(DMFI, maskChannels, DMFI_CHATHOOK_CHANNELS);
    AddListInt(DMFI, bListenAll, DMFI_CHATHOOK_LISTENALL);
    AddListObject(DMFI, oSpeaker, DMFI_CHATHOOK_SPEAKER);
    AddListInt(DMFI, bAutoRemove, DMFI_CHATHOOK_AUTOREMOVE);

    AddLocalListItem(oSpeaker, DMFI_HOOKS, IntToString(nHandle), TRUE);
    return hdlHook;
}

// ---< dmfi_RemoveChatHook >---
// Receives a unique chat hook handle (generated in dmfi_AddChatHook) and deletes
//  all values associated with the chat hook.  Returns TRUE if the hook was found
//  and deleted, FALSE otherwise.
int dmfi_RemoveChatHook(int nHandle)
{
    int nIndex = FindListInt(DMFI, nHandle, DMFI_CHATHOOK_HANDLE);

    if (nIndex)
    {
        object oSpeaker = GetListObject(DMFI, nIndex, DMFI_CHATHOOK_SPEAKER);
        RemoveLocalListItem(oSpeaker, DMFI_HOOKS, IntToString(nHandle));
        
        DeleteListInt(DMFI, nIndex, DMFI_CHATHOOK_HANDLE);
        DeleteListString(DMFI, nIndex, DMFI_CHATHOOK_SCRIPT);
        DeleteListObject(DMFI, nIndex, DMFI_CHATHOOK_RUNNER);
        DeleteListInt(DMFI, nIndex, DMFI_CHATHOOK_CHANNELS);
        DeleteListInt(DMFI, nIndex, DMFI_CHATHOOK_LISTENALL);
        DeleteListObject(DMFI, nIndex, DMFI_CHATHOOK_SPEAKER);
        DeleteListInt(DMFI, nIndex, DMFI_CHATHOOK_AUTOREMOVE);
        return TRUE;
    }

    return FALSE;
}

// ---< dmfi_RemoveListenerHook >---
// Receives a unique listener hook handle (generated in dmfi_AddListenerHook) and 
//  deletes all values associated with the listener hook.  Returns TRUE if the
//  hook was found and deleted, FALSE otherwise.
int dmfi_RemoveListenerHook(int nHandle)
{
    int nIndex = FindListInt(DMFI, nHandle, DMFI_LISTENER_HANDLE);
 
    if (nIndex)
    {
        object oCreature = GetListObject(DMFI, nIndex, DMFI_LISTENER_CREATURE);
        RemoveLocalListItem (oSpeaker, DMFI_HOOKS, IntToString(nHandle));
        
        DeleteListInt(DMFI, nIndex, DMFI_LISTENER_HANDLE);
        DeleteListInt(DMFI, nIndex, DMFI_LISTENER_TYPE);
        DeleteListObject(DMFI, nIndex, DMFI_LISTENER_CREATURE);
        DeleteListLocation(DMFI, nIndex, DMFI_LISTENER_LOCATION);
        DeleteListInt(DMFI, nIndex, DMFI_LISTENER_CHANNELS);
        DeleteListObject(DMFI, nIndex, DMFI_LISTENER_OWNER);
        DeleteListInt(DMFI, nIndex, DMFI_LISTENER_RANGE);
        DeleteListInt(DMFI, nIndex, DMFI_LISTENER_BROADCAST);
        return TRUE;
    }

    return FALSE;
}

// ---< dmfi_AddListenerHook >---
// Adds a ListenerHook to the DMFI datapoint in order to either eavesdrop on a
//  specified PC or receive all chatter heard by either an NPC or at a specified
//  location.
// Returns a unique handle to the hook so it can later be removed.
int dmfi_AddListenerHook(int nType, object oCreature, location lLocation,
        int nChannels, int nRange, int bBroadcast, object oOwner)
{
    int nHandle;

    do 
    {
        nHandle = Random(DMFI_HOOK_HANDLE_SPLIT) + DMFI_HOOK_HANDLE_SPLIT + 1;
    } while (FindListInt(DMFI, nHandle, DMFI_LISTENER_HANDLE));

    AddLIstInt(DMFI, nHandle, DMFI_LISTENER_HANDLE))
    AddListInt(DMFI, nType, DMFI_LISTENER_TYPE);
    AddListObject(DMFI, oCreature, DMFI_LISTENER_CREATURE);
    AddListLocation(DMFI, lLocation, DMFI_LISTENER_LOCATION);
    AddListInt(DMFI, nChannels, DMFI_LISTENER_CHANNELS);
    AddListObject(DMFI, oOwner, DMFI_LISTENER_OWNER);
    AddListInt(DMFI, nRange, DMFI_LISTENER_RANGE);
    AddListInt(DMFI, bBroadcast, DMFI_LISTENER_BROADCAST);

    AddLocalListItem(oCreature, DMFI_HOOKS, IntToString(nHandle), TRUE);

    return nHandle;
}
