// -----------------------------------------------------------------------------
//    File: dmfi_l_plugin.nss
//  System: DMFI (library)
//     URL: 
// Authors: Edward A. Burke (tinygiant) <af.hog.pilot@gmail.com>
// -----------------------------------------------------------------------------
// Description:
//  Library functions for PW Subsystem
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

#include "dmfi_i_events"

// -----------------------------------------------------------------------------
//                               Library Dispatch
// -----------------------------------------------------------------------------

void OnLibraryLoad()
{
    //Need to check for pw plugin and this is a sub-plugin
    if (!GetIfPluginExists("dmfi"))
    {
        object oPlugin = GetPlugin("dmfi", TRUE);
        SetName(oPlugin, "[Plugin] DM Friendly Initiative :: Wands & Widgets 1.09");
        SetDescription(oPlugin,
            "This plugin implements the DMFI W&W 1.09 System.");

        // ----- Module Events -----
        //RegisterEventScripts(oPlugin, MODULE_EVENT_ON_CLIENT_ENTER, "dmfi_OnClientEnter");
    }

    // ----- Module Events -----
    //RegisterLibraryScript("dmfi_OnClientEnter", 1);
}

void OnLibraryScript(string sScript, int nEntry)
{
    switch (nEntry)
    {
        // ----- Module Events -----
        //case 1:   dmfi_OnClientEnter(); break;
        default: CriticalError("Library function " + sScript + " not found");
    }
}
