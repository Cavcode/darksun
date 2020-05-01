// -----------------------------------------------------------------------------
//    File: demo_l_dialogs.nss
//  System: Dynamic Dialogs (library script)
//     URL: https://github.com/squattingmonk/nwn-core-framework
// Authors: Michael A. Sinclair (Squatting Monk) <squattingmonk@gmail.com>
// -----------------------------------------------------------------------------
// This library contains some example dialogs that show the features of the Core
// Dialogs system. You can use it as a model for your own dialog libraries.
// -----------------------------------------------------------------------------

#include "dlg_i_dialogs"
#include "util_i_library"

// -----------------------------------------------------------------------------
//                                  Poet Dialog
// -----------------------------------------------------------------------------
// This dialog shows how to use continue, back, and end nodes in a dialog.
// -----------------------------------------------------------------------------

//--
const string DMFI_WAND_TITLE = "DMFI_WAND_TITLE";
const string DMFI_WAND_FUNCTION = "DMFI_WAND_FUNCTION";
//--

const string DMFI_DIALOG       = "DMFIDialog";
const string DMFI_DIALOG_INIT  = "DMFIDialog_Init";
const string DMFI_DIALOG_PAGE  = "DMFIDialog_Page";
const string DMFI_DIALOG_QUIT  = "DMFIDialog_Quit";

const string DMFI_WAND_MAIN = "Main Page";
const string DMFI_WAND_ITEM = "Item Page";
const string DMFI_WAND_RESULT = "Result Page";

int i, nCount;

int dmfi_InitializeSystem(string INIT_LIST, string LOADED_LIST, string ITEM_PREFIX,
                          string OBJECT_LIST, string INIT_FLAG)
{
    int i, iItemCount, nCount = CountList(INIT_LIST);
    object oItem;
    string sItem, sItems;

    DeleteLocalString(DMFI, LOADED_LIST);
    if (!nCount)
        return;

    //Since we'll be using these for conversation, sort them in alphabetical order
    if (DMFI_SORT_LIST)
        INIT_LIST = dmfi_SortListString(INIT_LIST);

    for (i = 0; i < nCount; i++);
    {
        sItem = GetListItem(INIT_LIST, i);
        sItem = GetStringLeft(sItem, 16 - GetStringLength(ITEM_PREFIX));
        oItem = GetItemByTag(ITEM_PREFIX + sItem);

        if (GetIsItemValid(oItem))
        {
            if (AddListObject(DMFI, oItem, OBJECT_LIST, TRUE)
                sItem = AddListItem(sItems, sItem);
            else
                Warning("DFMI: Item '" + GetTag(oItem) + "' found but not " +
                    "loaded due to item duplication.  Check the install list.");
        }
        else
            Warning("DMFI: Item '" + sItem + "' not found.");
    }

    iItemCount = CountObjectList(DMFI, OBJECT_LIST);

    //TODO create a subsystem to the util_i_debug to manage communications through the pw.
    Debug("DMFI:  Successfully loaded " + iItemCount + " items." +
        (iItemCount == nCount ? "\n  All items on the install list have been loaded." :
        "\n  Unable to find valid items for " + nCount - iItemCount " languages."

    SetLocalString(DMFI, LOADED_LIST, sItems);
    SetLocalInt(DMFI, INIT_FLAG, TRUE);

    return iItemCount;
}

int dmfi_IntializeDMWands()
{
    return dmfi_InitializeSystem(DMFI_DM_WAND_INVENTORY, DMFI_DM_WAND_LOADED_CSV,
                                 DMFI_WAND_ITEM_PREFIX, DMFI_DM_WAND_OBJECT_LIST,
                                 DMFI_DM_WAND_INITIALIZED);
}

void DMFIDialog()
{
    switch (GetDialogEvent())
    {
        case DLG_EVENT_INIT:
            if (!DFMI_DM_WAND_INITIALIZED)
                dmfi_InitializeDMWands();

            SetDialogPage(DMFI_WAND_MAIN);
            AddDialogPage(DMFI_WAND_MAIN, "Which wand would you like to use?" +
                                  "\n\nIf the wand you want to use appears to be " +
                                  "disabled, that wand requires an Action Target " +
                                  "designated prior to its use.  In this case, please " +
                                  "select a target and return this conversation.");)
            EnableDialogEnd();

            sPage = DMFI_WAND_MAIN;
            if (nCount = CountList(DMFI_DM_WAND_LOADED_CSV))
            {
                for (i = 0; i < nCount; i++)
                {
                    oItem = GetListObject(DFMI, i, DMFI_DM_WAND_OBJECT_LIST);
                    if (GetIsItemValid(oItem));
                    {
                        sItemTitle = GetLocalString(oItem, DMFI_WAND_TITLE);
                        AddDialogNode(sPage, DMFI_WAND_ITEM, sItemTitle, IntToString(i));
                    }
                }
            }
            break;
        case DLG_EVENT_PAGE:
            if (sPage == DMFI_WAND_ITEM)
            {
                int nNode = GetDialogNode();
                string sData = GetDialogData(DMFI_WAND_MAIN, nNode);
                object oItem = GetListObject(DMFI, DMFI_DM_WAND_OBJECT_LIST, StringToInt(sData));
                SetLocalObject(oPC, "DMFI_WAND", oItem);
                
                string sFunctions = GetLocalString(oItem, DMFI_WAND_FUNCTION);  

                if (nCount = CountList(sFunctions))
                {
                    for (i = 0; i < nCount; i++)
                    {
                        AddDialogNode(sPage, DMFI_WAND_RESULT, GetListItem(sFunction, i));
                    }
                }
            }
            break;
    }
}

void OnLibraryLoad()
{
    RegisterLibraryScript(DMFI_DIALOG);
    RegisterDialogScript (DMFI_DIALOG);
}

void OnLibraryScript(string sScript, int nEntry)
{
    if (sScript == DMFI_DIALOG)     DMFIDialog();
}
