Replay Tools is a small collection of tools to integrate assetto Corsa with ACSM by Emperor Servers.

Made and tested on CSP 3.0.0preview-140, but should be fine for 2.11? (untested)
It uses [ACSM'S API endpoints](https://wiki.emperorservers.com/assetto-corsa-server-manager/web-api) so ACSM 2.0.0+ is required for postrace and 2.4.2+ required for live. Endpoints Must be open as public from the accounts section, authentication planned for a future update.

Download the repo and manually place into assettocorsa/apps/Lua/replayTools

It collects incidents by connecting to ACSM via the ACSM Link tab, and can display them in one of two modes.

## Postrace
By searching for a results file, the app can load the incidents and display them in the replay data tab.

## Live
By ticking the "Connect to penalties log" button, penalties in the current session are displayed in the PenaltyLink tab, and can be opened with the instant replay function.

This project was made by myself, without use of any AI. It is unaffiliated with ACSM, if you require support with ACSM go to their discord :)
