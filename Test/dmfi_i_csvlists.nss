
#include "x3_inc_string"
#include "util_i_csvlists"

// ---< csv_SetKeyValuePair >---
// Internal function called by csv_SetKeyValue[Int,Float,String].
//  This function will find the key:value pair that matches the
//  passed key, if it exists, and replace the value with the passed
//  value.  If the passed key does not exist, the key:value pair
//  is added to the list.  The new list is returned.
string csv_SetKeyValuePair(string sList, string sKey, string sValue)
{
    string sCurrentPair;

    int i, nCount = CountList(sList);
    for (i = 0; i < nCount; i++)
    {
        sCurrentPair = GetListItem(sList, i);
        if(StringParse(sCurrentPair, ":") == sKey)
        {
            sList = RemoveListItem(sList, sCurrentPair);
            break;
        }
    }

    sList = AddListItem(sList, sKey + ":" + sValue);
    return sList;
}

// ---< csv_SetKeyValueInt >---
// This function searches the passed list for the passed key.  If
//  found, the value associated with the key is updated to the passed
//  value.  TRUE and FALSE can be set as either an integer 1/0 
//  through this function or as a string "TRUE"/"FALSE" through
//  csv_SetKeyValueString.
void csv_SetKeyValueInt(string sList, string sKey, int nValue)
{
    string sValue = IntToString(nValue);
    csv_SetKeyValuePair(sList, sKey, sValue);
}

// ---< csv_SetKeyValueFloat >---
// This function searches the passed list for the passed key.  If
//  found, the value associated with the key is updated to the passed
//  value.
void csv_SetKeyValueFloat(string sList, string sKey, float fValue)
{
    string sValue = FloatToString(fValue);
    csv_SetKeyValuePair(sList, sKey, sValue);
}

// ---< csv_SetKeyValueString >---
// This function searches the passed list for the passed key.  If
//  found, the value associated with the key is updated to the passed
//  value.  TRUE and FALSE can be set as either a string "TRUE"/"FALSE"
//  through this function or as an integer 1/0 through csv_SetKeyValueInt.
string csv_SetKeyValueString(string sList, string sKey, string sValue)
{
    return csv_SetKeyValuePair(sList, sKey, sValue);
}

// ---< csv_RemoveKeyValuePair >---
// This function removes a key:value pair that matches the passed key from
//  the passed list.  The modified list is returned.  If no key:value pair
//  is found, the original list is returned with no indication of failure.
// Errors can be determined by checking if the returned list is equal to
//  the passed list.
string csv_RemoveKeyValuePair(string sList, string sKey)
{
    string sCurrentPair;

    int i, nCount = CountList(sList);
    for (i = 0; i < nCount; i++)
    {
        sCurrentPair = GetListItem(sList, i);
        if(StringParse(sCurrentPair, ":") == sKey)
        {
            sList = RemoveListItem(sList, sCurrentPair);
            break;
        }    
    }

    return sList;
}

// ---< csv_HasKeyValuePair >---
// This function will determine whether a partial match exists in
//  the list based solely on the presence of sKey within sList.
int csv_HasKeyValuePair(string sList, string sKey)
{
    if (sList == "" || sKey == "")
        return -1;

    int nOffset = FindSubString(sList, sKey);
    if (nOffset == -1)
        return -1;
    else 
        return TRUE;
}

// ---< csv_GetKeyValuePair >---
// Internal function called by csv_GetKeyValue[Int,Float,String].
//  This function will find the key:value pair that matches the
//  passed key, if it exists, return the associated value.  If the
//  passed key does not exist, an empty string is returned.
string csv_GetKeyValuePair(string sList, string sKey)
{
    string sCurrentPair; 
    
    int i, nCount = CountList(sList);
    for (i = 0; i < nCount; i++)
    {
        sCurrentPair = GetListItem(sList, i);
        if(StringParse(sCurrentPair, ":") == sKey)
            return StringParse(sCurrentPair, ":", TRUE);
    }

    return "";
}

// ---< csv_GetKeyValueInt >---
// This function searches the passed list for the passed key.  If
//  found, the value associated with the key is returned as an
//  integer.  This function can handle string "TRUE" and string
//  "FALSE" and returns them as appropriate integer values.  If the
//  key is not found, -1 is returned.
int csv_GetKeyValueInt(string sList, string sKey)
{
    string sValue = csv_GetKeyValuePair(sList, sKey);

    if(sValue == "FALSE")
        return FALSE;

    if(sValue == "TRUE")
        return TRUE;

    if(sValue != "")
        return StringToInt(sValue);

    return -1;
}

// ---< csv_GetKeyValueFloat >---
// This function searches the passed list for the passed key.  If
//  found, the value associated with the key is returned as a float.
//  If the key is not found, -1.0 is returned.
float csv_GetKeyValueFloat(string sList, string sKey)
{
    string sValue = csv_GetKeyValuePair(sList, sKey);

    if(sValue != "")
        return StringToFloat(sValue);
    else
        return -1.0;
}

// ---< csv_GetKeyValueString >---
// This function searches the passed list for the passed key.  If
//  found, the value associated with the key is returned as a string.
//  If the key is not found, and empty string is returned.
string csv_GetKeyValueString(string sList, string sKey)
{
    return csv_GetKeyValuePair(sList, sKey);
}
