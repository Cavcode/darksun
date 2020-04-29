// -----------------------------------------------------------------------------
//    File: dlg_l_plugin.nss
//  System: Dynamic Dialogs (library script)
//     URL: https://github.com/squattingmonk/nwn-core-framework
// Authors: Michael A. Sinclair (Squatting Monk) <squattingmonk@gmail.com>
// -----------------------------------------------------------------------------
// This library contains hook-in scripts for the Dynamic Dialogs plugin. If the
// Dynamic Dialogs plugin is activated, these scripts will fire on the
// appropriate events.
// -----------------------------------------------------------------------------

#include "core_i_framework"
#include "dlg_i_dialogs"
#include "util_i_color"
#include "util_i_library"

#include "dmfi_i_util"

// -----------------------------------------------------------------------------
//                             Event Hook-In Scripts
// -----------------------------------------------------------------------------

// ----- WrapDialog ------------------------------------------------------------
// Starts a dialog between the calling object and the PC that triggered the
// event being executed. Only valid when being called by an event queue.
// ----- Variables -------------------------------------------------------------
// string "*Dialog":  The name of the dialog script (library or otherwise)
// int    "*Private": Whether the dialog should be hidden from other players.
// int    "*NoHello": Prevent the NPC from saying hello on dialog start
// int    "*NoZoom":  Prevent camera from zooming in on dialog start
// ----- Aliases ---------------------------------------------------------------

void dmfi_StartDialog(int bGhost = FALSE)
{
    // Get the PC that triggered the event. This information is pulled off the
    // event queue since we don't know which event is calling us.
    object oPC = GetEventTriggeredBy();

    if (!_GetIsPC(oPC))
        return;

    string sDialog  = GetLocalString(OBJECT_SELF, DLG_DIALOG);
    int    bPrivate = GetLocalInt   (OBJECT_SELF, DLG_PRIVATE);
    int    bNoHello = GetLocalInt   (OBJECT_SELF, DLG_NO_HELLO);
    int    bNoZoom  = GetLocalInt   (OBJECT_SELF, DLG_NO_ZOOM);

    StartDialog(oPC, OBJECT_SELF, sDialog, bPrivate, bNoHello, bNoZoom);
}

// -----------------------------------------------------------------------------
//                             DMFI System Dialog
// -----------------------------------------------------------------------------
// This dialog allows users to use DMFI wand/widget functions, view DM/player
//  manuals, set custom settings, etc.
// -----------------------------------------------------------------------------

const string DMFI_MASTER_DIALOG      = "DMFIMasterDialog";
const string DMFI_PAGE_MAIN         = "DMFIMAIN";
const string DMFI_PAGE_TOOL        = "DMFITOOL";
const string DMFI_PAGE_FAIL ="DMFIFAIL";
const string DMFI_PAGE_TOOL_MISSING = "DMFITOOLMISSING";

const string DMFI_TOOL_ACTIVATE     = "Activate widget";
const string DMFI_TOOL_DEACTIVATE = "Deactivate widget";

const int DMFI_TOOL_INACTIVE = 0;
const int DMFI_TOOL_ACTIVE = 1;
const int DMFI_TOOL_MISSING = 2;
const int DMFI_TOOL_NEEDS_TARGET = 3;

/*string AddToolFunctionNode(int nIndex)
{

}*/

string AddToolPage(string sTool)
{
    string sPage = DMFI_PAGE_TOOL + sTool;
    if (!HasDialogPage(sPage))
    {
        AddDialogPage(sPage, "Selected Widget:  <DMFITool> <DMFIToolStatus>\n\n" +
                             "What would you like to do with the <DMFITool>?", sTool);
        AddDialogNode(sPage, sPage, "Deactivate Widget", DMFI_TOOL_DEACTIVATE);
        AddDialogNode(sPage, sPage, "Activate Widget", DMFI_TOOL_ACTIVATE);
        //Add all the functions here.
        SetDialogTarget(DMFI_PAGE_MAIN, sPage, DLG_NODE_BACK);
    }

    return sPage;
}

string CommandTokenText(string sCommand)
{
    return HexColorString(sCommand, COLOR_YELLOW_DARK);
}

string ToolStatusText(int nStatus)
{
    switch (nStatus)
    {
        case DMFI_TOOL_INACTIVE:
            return HexColorString("[Inactive]", COLOR_GRAY);
        case DMFI_TOOL_ACTIVE:
            return HexColorString("[Active]", COLOR_GREEN);
        case DMFI_TOOL_MISSING:
            return HexColorString("[Widget Missing]", COLOR_RED);
        case DMFI_TOOL_NEEDS_TARGET:
            return HexColorString("[Target Missing]", COLOR_YELLOW);
    }

    return "";
}

void dmfi_MasterDialog_Init()
{
    AddDialogToken("tool");
    AddDialogToken("widget");
    AddDialogToken("wand");
    AddDialogToken("DMFITool");
    AddDialogToken("DMFIToolStatus");
    
    EnableDialogNode(DLG_NODE_BACK);
    EnableDialogNode(DLG_NODE_END);

    SetDialogPage(DMFI_PAGE_MAIN);
    AddDialogPage(DMFI_PAGE_MAIN, "Which widget would you like to use?\n\nIf the widget " + 
        "you want to use is labeled [Target Missing], that widget requires an Action " +
        "Target designated prior to its use.  In this case, please select a target and " +
        "return this conversation.\n\nYou can return to this page directly by typing " +
        "<tool>, <widget> or <wand> into the chat bar.");
    SetDialogLabel(DLG_NODE_BACK, "[Refresh Widget List]", DMFI_PAGE_MAIN);
    SetDialogTarget(DMFI_PAGE_MAIN, DMFI_PAGE_MAIN, DLG_NODE_BACK);

    string sTool, sPage;
    int i, nCount = CountList(DMFI_DM_WAND_INVENTORY);
    for (i = 0; i < nCount; i++)
    {
        sTool = GetListItem(DMFI_DM_WAND_INVENTORY, i);
        sTool = GetStringLeft(sTool, 16 - GetStringLength(DMFI_WAND_ITEM_PREFIX));
        AddToolPage(sTool);
    }

    AddDialogPage(DMFI_PAGE_FAIL, "Sorry, only player-controlled characters can use this.");
    DisableDialogNode(DLG_NODE_BACK, DMFI_PAGE_FAIL);

    AddDialogPage(DMFI_PAGE_TOOL_MISSING, "The <DMFITool> is currently not loaded on the " +
        "module.  This means it is listed to be added, but the widget item cannot be " +
        "found.  The most likely causes for this are a misnamed item or an item that " +
        "has been removed from the module but not from the inventory list.\n\nCheck " +
        "the documentation for the DMFI widgets to ensure all prerequistes have been met.");
    SetDialogLabel(DLG_NODE_BACK, "[Return to Widget Listing]", DMFI_PAGE_TOOL_MISSING);

    CacheDialogToken("tool", CommandTokenText(".tool"));
    CacheDialogToken("widget", CommandTokenText(".widget"));
    CacheDialogToken("wand", CommandTokenText(".wand"));  
}

void dmfi_MasterDialog_Page()
{
    object oPC = GetPCSpeaker();
    string sPage = GetDialogPage();

    // Build the list of plugins
    object oTool;
    string sTool, sTools, sText, sTarget;
    string INVENTORY, LOADED, OBJECT, FLAG;
    int i, nStatus, nCount, nIndex;

    if (_GetIsDM(oPC))
    {
        INVENTORY = DMFI_DM_WAND_INVENTORY;
        LOADED = GetLocalString(DMFI, DMFI_DM_WAND_LOADED_CSV);
        OBJECT = DMFI_DM_WAND_OBJECT_LIST;
        FLAG = DMFI_DM_WAND_INITIALIZED;
    }
    else if (_GetIsPC(oPC))
    {
        INVENTORY = DMFI_PC_WAND_INVENTORY;
        LOADED = GetLocalString(DMFI, DMFI_PC_WAND_LOADED_CSV);
        OBJECT = DMFI_PC_WAND_OBJECT_LIST;
        FLAG = DMFI_PC_WAND_INITIALIZED;
    }
    else
    {
        SetDialogPage(DMFI_PAGE_FAIL);
    }

    if (sPage == DMFI_PAGE_MAIN)
    {   //This allow refreshing the list
        if (!GetLocalInt(DMFI, FLAG))
            dmfi_InitializeSystem(INVENTORY, LOADED, DMFI_WAND_ITEM_PREFIX, OBJECT, FLAG);

        DeleteDialogNodes(DMFI_PAGE_MAIN);
        nCount = CountList(INVENTORY);

        for (i = 0; i < nCount; i++)
        {
            sTool = GetListItem(INVENTORY, i);
            sTools = GetLocalString(DMFI, LOADED);
            if ((nIndex = FindListItem(sTools, sTool)) != -1)
            {
                oTool = GetListObject(DMFI, nIndex, OBJECT);
                sTarget = AddToolPage(sTool);
                sTool = GetLocalString(oTool, DMFI_WAND_DISPLAY_NAME);
                nStatus = GetLocalInt(oTool, DMFI_WAND_ACTIVE);
                sText = sTool + " " + ToolStatusText(nStatus);
                AddDialogNode(DMFI_PAGE_MAIN, sTarget, sText, IntToString(nIndex));
            }
            else
            {
                sTarget = DMFI_PAGE_TOOL_MISSING;
                nStatus = DMFI_TOOL_MISSING;
                sText = sTool + " " + ToolStatusText(nStatus);
                AddDialogNode(DMFI_PAGE_MAIN, sTarget, sText);
            }
        }

        return;
    }

    if (GetStringLeft(sPage, GetStringLength(DMFI_PAGE_TOOL)) == DMFI_PAGE_TOOL)
    {
        //This is a wand page.
        UnCacheDialogToken("DMFITool");
        UnCacheDialogToken("DMFIToolStatus");

        sTool = GetDialogData(sPage);
        
        if ((nIndex = FindListItem(GetLocalString(DMFI, LOADED), sTool)) != -1)
        {
            oTool = GetListObject(DMFI, nIndex, OBJECT);
            nStatus = GetLocalInt(oTool, DMFI_WAND_ACTIVE);
            
            Debug("Setting Nodes:\n  sTool: " + sTool + "\n  nIndex: " + IntToString(nIndex) +
                "\n  oTool: " + GetName(oTool) + "\n  nStatus: " + IntToString(nStatus));

            switch (nStatus)
            {
                case DMFI_TOOL_INACTIVE:
                case DMFI_TOOL_ACTIVE:
                    FilterDialogNodes(nStatus); 
                    break;
                case DMFI_TOOL_MISSING:
                    //FilterDialogNodes(0,1);
                    break;
                default:
                    //FilterDialogNodes(0, CountDialogNodes(sPage) - 1);
            }

            CacheDialogToken("DMFITool", GetLocalString(oTool, DMFI_WAND_DISPLAY_NAME));
            CacheDialogToken("DMFIToolStatus", ToolStatusText(nStatus));
        }
        else
        {
            if (HasListItem(INVENTORY, sTool))
            {
                Debug("WORKING ON MISSING TOOL");
                nStatus = DMFI_TOOL_MISSING;
                //FilterDialogNodes(0,1);
                CacheDialogToken("DMFITool", sTool);
                CacheDialogToken("DMFIToolStatus", ToolStatusText(nStatus));
            }
        }
    }
}

void dmfi_MasterDialog_Node()
{/*
    string sPage = GetDialogPage();
    string sPrefix = GetStringLeft(sPage, GetStringLength(PLUGIN_PAGE));

    if (sPrefix == PLUGIN_PAGE)
    {
        int nNode = GetDialogNode();
        string sData = GetDialogData(sPage, nNode);
        string sPlugin = GetDialogData(sPage);
        object oPlugin = GetPlugin(sPlugin);

        if (sData == PLUGIN_ACTIVATE)
            ActivatePlugin(oPlugin);
        else if (sData == PLUGIN_DEACTIVATE)
            DeactivatePlugin(oPlugin);
    }*/
}

// -----------------------------------------------------------------------------
//                               Library Dispatch
// -----------------------------------------------------------------------------

void OnLibraryLoad()
{
    // Plugin setup
    if (!GetIfPluginExists("dlg_dmfi"))
    {
        object oPlugin = GetPlugin("dlg_dmfi", TRUE);
        SetName(oPlugin, "[Plugin] Master DMFI Dialog");
        SetDescription(oPlugin,
            "This dialog allows control over every aspect of the tools, settings, " +
            "and systems provided by the DMFI plugin.");
    }

    // Event scripts
    RegisterLibraryScript(DMFI_MASTER_DIALOG,        0x0100+0x01);
    RegisterLibraryScript("DMFIMasterDialogGhost",   0x0100+0x02);

    // Plugin Control Dialog
    RegisterLibraryScript("dmfi_MasterDialog_Init", 0x0200+0x01);
    RegisterLibraryScript("dmfi_MasterDialog_Page", 0x0200+0x02);
    RegisterLibraryScript("dmfi_MasterDialog_Node", 0x0200+0x03);

    RegisterDialogScript(DMFI_MASTER_DIALOG, "dmfi_MasterDialog_Init", DLG_EVENT_INIT, DLG_PRIORITY_FIRST);
    RegisterDialogScript(DMFI_MASTER_DIALOG, "dmfi_MasterDialog_Page", DLG_EVENT_PAGE);
    RegisterDialogScript(DMFI_MASTER_DIALOG, "dmfi_MasterDialog_Node", DLG_EVENT_NODE);
}

void OnLibraryScript(string sScript, int nEntry)
{
    switch (nEntry & 0xff00)
    {
        case 0x0100:
            switch (nEntry & 0x00ff)
            {
                case 0x01: dmfi_StartDialog();          break;
                case 0x02: dmfi_StartDialog(TRUE);      break;
            }  break;

        case 0x0200:
            switch (nEntry & 0x00ff)
            {
                 case 0x01: dmfi_MasterDialog_Init(); break;
                 case 0x02: dmfi_MasterDialog_Page(); break;
                 case 0x03: dmfi_MasterDialog_Node(); break;
             }   break;
    }
}
