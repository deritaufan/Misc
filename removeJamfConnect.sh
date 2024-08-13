#!/bin/bash

# Created in 2020 by Deri Taufan
# Updated 2024.08.13
# Last updated by Deri Taufan

# Logging variables
logDir="/private/var/log"
logFile="${logDir}/remove-JamfConnect.log"

if [ ! -d "${logDir}" ]; then
	mkdir /private/var/log
fi


addLog(){
	DATE=`date +%Y-%m-%d\ %H:%M:%S`
	/bin/echo "$DATE:" " $1" >> ${logFile}
	/bin/echo "$DATE:" " $1"
}

user=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
uid=$(/usr/bin/id -u "${user}")
addLog "Logged in user is ${user}, UID: ${uid}"

# Variables
jcUnlockPair="/Library/Caches/com.jamf.connect.unlock"
jcConnectApp="/Applications/Jamf Connect.app/"
jcSyncApp="/Applications/Jamf Connect Sync.app/"
jcVerifyApp="Applications/Jamf Connect Verify.app/"
jcDaemon="/Library/Application Support/JamfConnect"
jcEvaluationAsset="/Users/Shared/JamfConnectEvaluationAssets/"
jcChromeExtension="/Library/Google/Chrome/NativeMessagingHosts/"

SyncLA="/Library/LaunchAgents/com.jamf.connect.sync.plist"
VerifyLA='/Library/LaunchAgents/com.jamf.connect.verify.plist'
Connect2LA='/Library/LaunchAgents/com.jamf.connect.plist'
DaemonLD='/Library/LaunchDaemons/com.jamf.connect.daemon.plist'

authChangerBinary="/usr/local/bin/authchanger"

# Quit Connect and Unlock if running 
UnlockProcess=$(pgrep 'UnlockToken')
ConnectProcess=$(pgrep 'Jamf Connect')

addLog "Trying to stop Jamf Connect app if it runs..."
if [ $ConnectProcess > 0 ]; then
	kill $ConnectProcess
fi

if [ $UnlockProcess > 0 ]; then
	kill $UnlockProcess
fi


#Removing unlock pair
addLog "Removing unlock pair..."
sc_auth unpair
rm -r "$jcUnlockPair"
pkgutil --regexp --forget com.jamf.connect\.\* 

rm -rf "Application Support/com.jamf.connect.login"
rm -rf "/Library/Managed Preferences/com.jamf.connect.login.plist"
rm -rf "/Library/Managed Preferences/admin/com.jamf.connect.login.plist"
rm -rf "/Library/LaunchAgents/com.jamf.connect.unlock.login.plist"
rm -rf "~/Library/Containers/com.jamf.connect.unlock.login.token"
rm -rf "~/Library/Application Scripts/com.jamf.connect.unlock.login.token"


# Remove LaunchD components

if [ -f "$SyncLA" ]; then
	addLog "Jamf Connect Sync Launch Agent is present. Unloading & removing.."
	/bin/launchctl bootout gui/"$uid" "$SyncLA"
	/bin/rm -rf "$SyncLA"
else 
	addLog "Jamf Connect Sync launch agent not installed"
fi

if [ -f "$VerifyLA" ]; then
	addLog "Jamf Connect Verify Launch Agent is present. Unloading & removing.."
	/bin/launchctl bootout gui/"$uid" "$VerifyLA"
	/bin/rm -rf "$VerifyLA"
else 
	addLog "Jamf Connect Verify launch agent not installed"
fi

if [ -f "$Connect2LA" ]; then
	addLog "Jamf Connect 2 Launch Agent is present. Unloading & removing.."
	/bin/launchctl bootout gui/"$uid" "$Connect2LA"
	/bin/rm -rf "$Connect2LA"
else 
	addLog "Jamf Connect 2 launch agent not installed"
fi

if [ -f "$DaemonLD" ]; then
	addLog "Jamf Connect Launch Daemon is present. Unloading and removing"
	/bin/launchctl unload "$DaemonLD"
	/bin/rm -f "$DaemonLD"
	/bin/rm -rf "/Library/Application Support/JamfConnect"
else
	addLog "Jamf Connect launch daemon not installed"
fi

# Removing jamf connect binary
addLog "REmoving Jamf Connect binary"
rm -f /usr/local/bin/jamfconnect

# Reset the macOS authentication database to default

if [ -f "${authChangerBinary}" ]; 
then
	/usr/local/bin/authchanger -reset
	addLog  "Default macOS loginwindow has been restored"
	/bin/rm /usr/local/bin/authchanger
	/bin/rm /usr/local/lib/pam/pam_saml.so.2
	/bin/rm -r /Library/Security/SecurityAgentPlugins/JamfConnectLogin.bundle
	addLog  "Jamf Connect Login components have been removed"

else 
	addLog  "Jamf Connect Login not installed; can't delete"
fi

# Remove Jamf Connect Applications

if [ -d "${jcSyncApp}" ]; then
	/bin/rm -rf "${jcSyncApp}"
else 
	addLog "Jamf Connect Sync is not installed; can't delete"
fi

if [ -d "${jcVerifyApp}" ]; then
	/bin/rm -rf "${jcVerifyApp}"
else 
	addLog "Jamf Connect Verify is not installed; can't delete"
fi

if [ -d "${jcConnectApp}" ]; then
	/bin/rm -rf "${jcConnectApp}"
else 
	addLog "Jamf Connect 2 is not installed; can't delete"
fi

if [ -d "${jcDaemon}" ]; then
	/bin/rm -rf "${jcDaemon}"
else 
	addLog "Jamf Connect Daemon is not installed; can't delete"
fi

# Remove Jamf Connect Evaluation Assets

if [ -d "${jcEvaluationAsset}" ]; 
then
	/bin/rm -rf "${jcEvaluationAsset}"
	addLog "Jamf Connect Assets have been removed"
else 
	addLog "Jamf Connect Assets not installed; can't delete"
fi

# Remove Jamf Connect Chrome Extensions

if [ -d "${jcChromeExtension}" ]; 
then
	/bin/rm -rf "${jcChromeExtension}"
	addLog "Jamf Connect Chrome extensions have been removed"
else 
	addLog "Jamf Connect Chrome extensions not installed; can't delete"
fi

# Remove Jamf Connect Evaluation Profiles
profilesArray=()
for i in $(profiles list | grep -i com.jamf.connect | awk '{ print $4 }'); do
	profilesArray+=("$i")
done
counter=0
for i in "${profilesArray[@]}"; do
	let "counter=counter+1"
done
if [ $counter == 0 ]; then
	addLog "There were 0 Jamf Connect Profiles found. Continuing..."
else
	addLog "There were $counter Jamf Connect Profiles found.  Removing..."
fi
for i in "${profilesArray[@]}"; do
	addLog "Removing the profile $i..."
	/usr/bin/profiles -R -p "$i"
done

#Remove user defaults
addLog  "switched to user ${user}"

sudo -u $user bash -c '
defaults delete ~/Library/Group\ Containers/483DWKW443.jamf.connect/Library/Preferences/483DWKW443.jamf.connect
defaults delete com.jamf.connect
defaults delete com.jamf.connect.state
/usr/bin/logger "Deleted Jamf Connect user defaults"
security delete-generic-password  -l "Jamf Connect"
defaults delete ~/Library/Group\ Containers/group.com.jamf.connect/Library/Preferences/group.com.jamf.connect
'

addLog "Jamf Connect components are completely removed."
addLog "================================================================="