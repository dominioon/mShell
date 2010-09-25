UI2 - mShell NMI module to add Symbian UI functionality the mShell ui module 
doesn't provide.
-------------------------------------------------------------------------------
Currently ui2 provides only 4 methods to display timed informative messages 
(ie, they will disappear after some seconds):

* ui2.msg('some message') - displays a message
* ui2.info('some informative message') - displays an informative message 
* ui2.warning('some warning message') - displays a warning message 
* ui2.error('some error message') - displays an error message

All these functions accept optional 2nd parameter timeout - it must be one 
of those following constants:

* ui2.shortesttimeout - delay of 0.5 sec
* ui2.shorttimeout    - delay of 1.5 sec
* ui2.longtimeout     - delay of 3 sec
* ui2.forever         - the message is displayed as long as the user clicks 
                        it away.

PS, depending on the theme, the warning and error message may look similar.

-------------------------------------------------------------------------------
The module wraps aknnotewrappers.h to mShell.

-------------------------------------------------------------------------------
Author: Meelis Saluvee
