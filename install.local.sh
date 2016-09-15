
logmsg "Switching theme ..."
wpcli "theme activate 'wpcr-website-theme-2016'"
# Set permalinks and flush rewrite rules
failing $? "Could not activate theme"

logmsg "Setting permalink structure"
wpcli "rewrite structure '/%postname%/' --hard"
failing $? "Could change rewrite rules"

logmsg "Flushing rewrite rules"
wpcli "rewrite flush --hard"
failing $? "Could flush rewrite rules"
# Activate plugins
logmsg "Activating plugins"
wpcli "plugin activate --all"
failing $? "Could not activate all plugins"