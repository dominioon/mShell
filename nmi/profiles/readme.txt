Profiles - mShell NMI module to manipulate phone profiles.
-------------------------------------------------------------------------------
The module provides the following functionality:

* profiles.active() -> Number 
      Permissions: ReadApp
    Returns active profile ID.

* profiles.active(newProfileId) -> Number 
      Permissions: ReadApp, WriteApp
    Sets active profile to newProfileId and returns the old profile ID.

* profiles.get() -> Array
      Permissions: ReadApp
    Returns information about the currently selected profile. The returned 
    array has the following keys:
    
    id          - the ID of the profile (Number).
    name        - the display name of the profile (String).
    ringtype    - ringing type (Number). See "constants".
    ringvolume  - ringing volume (Number, 1..10).
    keyvolume   - keypad volume (Number, 0..3).
    vibra       - vibrating alert setting (Boolean).
    silent      - is this profile silent (Boolean).
    ringtone    - line 1 ringing tone file name (String).
    ringtone2   - line 2 ringing tone file name (String).
    msgtone     - message alert tone file name (String).
    emailtone   - email alert tone file name (String).
    videotone   - video call ringing tone file name (String).
    warntones   - the state of warning and game tones (Boolean).
    tts         - the state of text-to-speech setting (Boolean).
    groupids    - the alert for item array (Array of Numbers). Only the calls 
                   coming from people who belong to one or more "Alert for" 
                   groups returned here trigger an audible alert. If the length 
                   of this array is 0, it is interpreted: "alert for all calls".

* profiles.get(profileId) -> Array
      Permissions: ReadApp
    Returns information about the profile with ID profileId. The returned array 
    has the same keys as in profiles.get() method.

* profiles.list() -> Array
      Permissions: ReadApp
    Returns array of all the profiles on the device. The key of the array is 
    profile name (String) and the value is profile ID (Number).

* profiles.set(newData) -> null
      Permissions: ReadApp, WriteApp
    Updates the currently selected profile data. Only these properties specified
    in newData (Array, key: property name, value: new value) are updated, others
    remain unchanged. You cannot update profile ID nor 'silent' setting.

* profiles.set(newData, profileId) -> null
      Permissions: ReadApp, WriteApp
    Updates the profile specified with profileId data. See profiles.set(newData).


Constants:
- Profile ID constants:
* profiles.default  - the ID of the Default profile.
* profiles.silent   - the ID of the Silent profile.
* profiles.meeting  - the ID of the Meeting profile.
* profiles.outdoor  - the ID of the Outdoor profile.
* profiles.pager    - the ID of the Pager profile.
* profiles.offline  - the ID of the Offline profile.
* profiles.drive    - the ID of the Drive profile.

- Ringing type constants:
* profiles.ringNormal    - The tone is played in a loop.
* profiles.ringAscending - The tone is played in a loop. On the 1st round, 
                           the volume is gradually increment from the lowest 
                           level to the set level.
* profiles.ringOnce      - The tone is played only once.
* profiles.ringBeep      - The phone only beeps once instead of playing the tone.
* profiles.ringSilent    - The phone is silent.

-------------------------------------------------------------------------------
The module wraps profileengine.lib to mShell, therefore it requires FP1!

-------------------------------------------------------------------------------
Author: Meelis Saluvee
