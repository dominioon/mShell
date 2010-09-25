UI2 - mShell NMI module to add Symbian UI functionality the mShell ui module 
doesn't provide.
-------------------------------------------------------------------------------
UI2 provides the following methods:

* Methods to display timed informative messages (ie, they will disappear 
after some seconds):
** ui2.msg('some message')              - displays a message
** ui2.info('some informative message') - displays an informative message 
** ui2.warning('some warning message')  - displays a warning message 
** ui2.error('some error message')      - displays an error message

All these functions accept optional 2nd parameter timeout - it must be one 
of those following constants:
- ui2.tiny    - delay of 0.5 sec
- ui2.short   - delay of 1.5 sec
- ui2.long    - delay of 3 sec
- ui2.forever - the message is displayed as long as the user clicks it away.

Depending on the theme, the warning and error message may look similar.

* Methods to query value in specific format:
** ui2.phone(message, defaultValue='') -> string - query for phone number. 
Only symbols allowed in phone number (0-9, +, w, p, *, #) can be entered.
** ui2.time(message, defaultValue=systime) -> number - query for time.
** ui2.date(message, defaultValue=sysdate) -> number - query for date.
** ui2.duration(message, defaultValue=0)   -> number - query for duration. 
The duration cannot be equal or longer than 1 hour.

Date parameters and return values are in milliseconds, but the actual query 
dialog operates in days (date dialog) or in seconds (time & duration dialogs).
The dialogs return null if the user cancels editing it.


-------------------------------------------------------------------------------
The module wraps aknnotewrappers.h to mShell.

-------------------------------------------------------------------------------
Author: Meelis Saluvee
