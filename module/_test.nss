#include "util_i_color"
#include "pqj_i_main"

object oPC = GetLastUsedBy();
string sText = "The quick brown fox jumps over the lazy dog";

void PrintColor(string sColor, int nColor)
{
    SendMessageToPC(oPC, HexColorString(sColor + ": " + IntToHexString(nColor), nColor));
}

void PrintHexColor(int nColor)
{
    string sMessage = IntToHexString(nColor) + ": " + sText;
    SendMessageToPC(oPC, HexColorString(sMessage, nColor));
}

void other()
{
    PrintColor("Black", COLOR_BLACK);
    PrintColor("Blue", COLOR_BLUE);
    PrintColor("Dark Blue", COLOR_BLUE_DARK);
    PrintColor("Light Blue", COLOR_BLUE_LIGHT);
    PrintColor("Brown", COLOR_BROWN);
    PrintColor("Light Brown", COLOR_BROWN_LIGHT);
    PrintColor("Divine", COLOR_DIVINE);
    PrintColor("Gold", COLOR_GOLD);
    PrintColor("Gray", COLOR_GRAY);
    PrintColor("Dark Gray", COLOR_GRAY_DARK);
    PrintColor("Light Gray", COLOR_GRAY_LIGHT);
    PrintColor("Green", COLOR_GREEN);
    PrintColor("Dark Green", COLOR_GREEN_DARK);
    PrintColor("Light Green", COLOR_GREEN_LIGHT);
    PrintColor("Orange", COLOR_ORANGE);
    PrintColor("Dark Orange", COLOR_ORANGE_DARK);
    PrintColor("Light Orange", COLOR_ORANGE_LIGHT);
    PrintColor("Red", COLOR_RED);
    PrintColor("Dark Red", COLOR_RED_DARK);
    PrintColor("Light Red", COLOR_RED_LIGHT);
    PrintColor("Pink", COLOR_PINK);
    PrintColor("Purple", COLOR_PURPLE);
    PrintColor("Turquoise", COLOR_TURQUOISE);
    PrintColor("Violet", COLOR_VIOLET);
    PrintColor("Light Violet", COLOR_VIOLET_LIGHT);
    PrintColor("Dark Violet", COLOR_VIOLET_DARK);
    PrintColor("White", COLOR_WHITE);
    PrintColor("Yellow", COLOR_YELLOW);
    PrintColor("Dark Yellow", COLOR_YELLOW_DARK);
    PrintColor("Light Yellow", COLOR_YELLOW_LIGHT);

    PrintHexColor(0x0099fe);
    PrintHexColor(0x3dc93d);

    struct HSV hsv = HexToHSV(0xff0000);
    PrintHexColor(HSVToHex(hsv));
    SpeakString("H: " + FloatToString(hsv.h) +
               " S: " + FloatToString(hsv.s) +
               " V: " + FloatToString(hsv.v));
    hsv.v /= 2.0;
    hsv.s = 0.0;
    PrintHexColor(HSVToHex(hsv));

    object oPC = GetLastUsedBy();
    int nState = pqj_GetQuestState("test", oPC);
    pqj_AddJournalQuestEntry("test", nState + 1, oPC);

    effect eDeath = EffectDamage(6, DAMAGE_TYPE_FIRE);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, eDeath, oPC);
}

// Put this script OnExit. 
void other2() 
{ 
    object oPartyMember, oArea, oTarget = GetWaypointByTag("DS_DESCENC_1"); 
    object oPC = GetExitingObject(); 
    int bGoing;

    // Only fire for (real) PCs. 
    if (GetIsDM(oPC) || GetIsDMPossessed(oPC)) 
        return; 
    
    if (GetIsDawn() || GetIsDay())
        bGoing = (Random(100) <= 10);
    else
        bGoing = (Random(100) <= 20);
    
    if (bGoing)
    { 
        SetLocalLocation(oPC, "ls_stored_loc", GetLocation(oPC));
        oArea = GetArea(oPC);
        oPartyMember = GetFirstFactionMember(oPC, FALSE);

        while (GetIsObjectValid(oPartyMember))
        {
            if (GetArea(oPartyMember) == oArea)
            {
                AssignCommand(oPartyMember, ClearAllActions());
                AssignCommand(oPartyMember, JumpToObject(oTarget));
            }

            oPartyMember = GetNextFactionMember(oPC, FALSE);
        }
    }
}

void main() 
{ 
    object oParty;
    object oArea;
    object oTarget;

    // Get the creature who triggered this event.
    object oPC = GetExitingObject();

    // Only fire for (real) PCs.
    if ( !GetIsPC(oPC)  ||  GetIsDMPossessed(oPC) )
        return;

    // If it is dawn or day.
    if ( GetIsDawn()  ||  GetIsDay() )
    {
        // If success on a 10% chance.
        if ( Random(100) < 10 )
        {
            // Find the location to which to teleport.
            oTarget = GetWaypointByTag("DS_DESENC_1");

            // Save the PC's current location for the return trip.
            SetLocalLocation(oPC, "ls_stored_loc", GetLocation(oPC));

            // Teleport the PC's party (only those in the same area, though).
            oArea = GetArea(oPC);
            // Loop through the PC's party.
            oParty = GetFirstFactionMember(oPC, FALSE);
            while ( oParty != OBJECT_INVALID )
            {
                // Only teleport those in the same area.
                if ( GetArea(oParty) == oArea )
                {
                    AssignCommand(oParty, ClearAllActions());
                    AssignCommand(oParty, JumpToObject(oTarget));
                }

                // Update the loop.
                oParty = GetNextFactionMember(oPC, FALSE);
            }

            // If it is dusk or night.
            if ( GetIsDusk()  ||  GetIsNight() )
            {
                // If success on a 20% chance.
                if ( Random(100) < 20 )
                {
                    // Find the location to which to teleport.

                    // Save the PC's current location for the return trip.
                    SetLocalLocation(oPC, "ls_stored_loc", GetLocation(oPC));

                    // Teleport the PC's party (only those in the same area, though).
                    // Loop through the PC's party.
                    oParty = GetFirstFactionMember(oPC, FALSE);
                    while ( oParty != OBJECT_INVALID )
                    {
                        // Only teleport those in the same area.
                        if ( GetArea(oParty) == oArea )
                        {
                            AssignCommand(oParty, ClearAllActions());
                            AssignCommand(oParty, JumpToObject(oTarget));
                        }

                        // Update the loop.
                        oParty = GetNextFactionMember(oPC, FALSE);
                    }
                }
            }
        }
    }
}