#!/bin/bash
#===============================================================================
# INSTASH - WordPress Site Installer
# 
# ENVIRONMENT VARIABLES:
# 
# 	INSTASH_SITE_URL		The site's root URL
# 	INSTASH_SITE_TITLE		The site's title
# 	INSTASH_ADMIN_USER		The admin username
# 	INSTASH_ADMIN_PASS		The admin password
# 	INSTASH_ADMIN_EMAIL             The admin email
# 	INSTASH_DB_NAME                 The database name
# 	INSTASH_DB_USER                 The database username
# 	INSTASH_DB_PASS                 The database password
# 	INSTASH_DB_HOST                 The database host
# 	INSTASH_DB_PREFIX		The database table prefix
# ===============================================================================

#-------------------------------------
# Constants
#-------------------------------------
ME='instash'

# Text Colors
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[0;32m'
RED='\033[0;91m'

# No Text Color
NOC='\033[0m'

# wp-cli executable
WP="vendor/bin/wp"
# The path to the WP installation
WP_ROOT="wp"
# Name of the WP config file
WP_CONFIG="wp-config.php"
# Name of WP sensitive config file
WP_SCONFIG="sensitive-config.php"
# Name of WP local config file
WP_LCONFIG="local-config.php"
# Temporary file prefix
_TMP=".tmp"

#-------------------------------------
# Help Function
#-------------------------------------
function showhelp() {
    echo -e "\nUsage:\n"
    echo -e "  ${YELLOW}install.sh [<args>]${NOC}"
    echo -e "\nArguments:\n"
    echo -e "  ${GREEN}-v, --verbose          ${NOC}Turns on verbose output."
    echo -e "  ${GREEN}-i, --interactive      ${NOC}Turns on interactive input for setup values."
    echo -e "  ${GREEN}-r, --reset            ${NOC}Resets the directory back to git HEAD via a hard git reset. Retains any existing 'wp-cli.local.yml' file."
    echo -e "  ${GREEN}-p, --phase  [n]       ${NOC}Starts the installation at phase n."
    echo -e "  ${GREEN}-h, --help             ${NOC}Shows this message."
    echo -e "  ${GREEN}-n, --no-clear         ${NOC}Used with -r, prevents clearing of files."
}

#-------------------------------------
# Utility Functions
#-------------------------------------

# Outputs a yellow message, for logging purposes.
# Only outputs if VERBOSE is on.
# 
# Params:
# 	$1 The message to output.
function logmsg() {
    if [ $VERBOSE = 1 ]
        then echo -e "${YELLOW}[${ME}] $1 ${NOC}"
    fi
}

function logsuccess() {
    echo -e "${GREEN}[${ME}] $1 ${NOC}"
}

function logerror() {
    echo -e "${RED}[${ME}] ${1} ${NOC}"
}

# Prints a yellow divider, for logging purposes.
# Only outputs if VERBOSE is in.
function div() {
    if [ $VERBOSE = 1 ]
        then logmsg "---------------------------------------------------"
    fi
}

# Logs a message between two dividers.
# 
# Only outputs if VERBOSE is on.
# 
# Params:
# 	$1 The message to log.
function divlog() {
    echo -e "\n"
    div
    logmsg "$1"
    div
    echo -e "\n"
}

# Checks the status code of the last command that executed.
# 
# Depending on whether the code is zero or not, one of the two param
# string messages will be outputted, if VERBOSE is on.
# 
# Params:
# 	$1 The message to show if the status code is 0
# 	$2 The message to show if the status code is not 0
function check_exit_code() {
    if [ $? = 0 ]
        then logmsg $1
        else logmsg $2
    fi
}

# Print a message in red, and run fail procedures
# Params:
#   $1 Whether failing or not
#   $2 Error message
#   $3 Success message
#   $4 If 1, executes graceful fail procedure. Default: 1.
function failing() {
    local isSuccess=${1:-'1'}
    local failMessage=${2:-'Error!'}
    local successMessage=${3:-'0'}
    local doFail=${4:-'1'}
    # All is well
    if [ $isSuccess -eq 0 ]; then
        [ "$successMessage" = '0' ] && logmsg "$successMessage"
        return $isSuccess
    fi
    # The message
    logerror "$failMessage"
    # Fail gracefully
    if [[ $doFail = 1 ]]; then
        gracefulFail
    fi
    # Propagating exit code
    exit $isSuccess
}

# What to do when something doesn't work out
function gracefulFail() {
    use_root_config
}

#-------------------------------------
# WP CLI Wrapper Function
#-------------------------------------

# WP CLI main wrapper function.
# 
# Passes all function args to wp-cli.
# Enables debug if VERBOSE is on
function wpcli() {
    local cmd=$1
    local plain=${2:-false} # no
    local debug="--debug"
    # The command to execute
    cmd="$WP $cmd --path='$WP_ROOT'"
    # More detail
    if [ $plain = false ] && [ $VERBOSE = 1 ]; then
        cmd="$cmd $debug"
        logmsg "Running wp-cli command:"
        echo "$cmd"
    fi
    # Running the command, optionally with colour
    [ "$plain" = false ] && echo -e "${BLUE}"
    eval "$cmd"
    local result=$?
    [ "$plain" = false ] && echo -e "${NOC}"

    return $result
}

#-------------------------------------
# WP CLI Command Generators
#-------------------------------------

# Handles the setting of a var as a command argument.
# 
# Checks if INTERACTIVE is enabled, if so asks for user input.
# Otherwise, checks if the variable is already set from ENV.
# Finally, if the variable is not found, the argument is omitted from the arg string.
# This will result in the WP CLI command to use the value in the YAML file, if specified.
# 
# Params:
# $1 name The name of the var
# $2 args The arguments string to append to, if the var exists
# $3 arg  The argument name
function handle_var_arg() {
    local name=$1
    local arg=$2
    local result_var=$3
    local result=""
    # If interactive
    if [ $INTERACTIVE = 1 ]; then
        echo -e "$name: \c"
        read -e value
        local result="$arg=$value"
    # If variable exists
    elif [ -n "${!name}" ]; then
        logmsg "Got $name from ENV"
        local value=${!name}
        local result="$arg=$value"
    # If variable does not exist
    else
        logmsg "$name not specified. wp-cli will default to value in YAML file."
    fi
    eval $result_var="'$result'"
}

# Runs `wp core config`
# 
# Utilizes the INSTASH_DB_* ENV or script vars to generate the command.
# If any of the vars is not set, their respective argument is not specificied
# in the final command allowing the value in the YAML file to be used.
function wpcli_core_config() {
    local args=""
    # Handle args
    handle_var_arg "INSTASH_DB_NAME" "--dbname" "dbname"
    handle_var_arg "INSTASH_DB_USER" "--dbuser" "dbuser"
    handle_var_arg "INSTASH_DB_PASS" "--dbpass" "dbpass"
    handle_var_arg "INSTASH_DB_HOST" "--dbhost" "dbhost"
    handle_var_arg "INSTASH_DB_PREFIX" "--dbprefix" "dbprefix"
    # Log generated args
    logmsg "Prepared args for wpcli core config: $dbname $dbuser $dbpass $dbhost $dbprefix"
    # Remove any existing wp/wp-config.php
    local wpconfig="$WP_ROOT/$WP_CONFIG"
    if [ -f "$wpconfig" ];  then
        rm "$wpconfig" && logmsg "Removed any existing $wpconfig"
    fi
    # Run command
    wpcli "core config $dbname $dbuser $dbpass $dbhost $dbprefix"

    return $?
}

# Runs `wp db create`
# 
# Does not use any ENV vars
function wpcli_db_create() {
    # Log
    logmsg "Preparing to 'wpcli db create'"
    # Run command
    wpcli "db create"
    failing $? 'Could not create WP database'
    
    return $?
}

# Runs `wp core install`
# 
# Uses the INSTASH_SITE_* and INSTASH_ADMIN_* ENV/script vars to generate the command.
# If any of the vars is not set, their respective argument is not specificied
# in the final command allowing the value in the YAML file to be used.
function wpcli_core_install() {
    local args=""
    # Handle args
    handle_var_arg "INSTASH_SITE_URL" "--url" "url"
    handle_var_arg "INSTASH_SITE_TITLE" "--title" "title"
    handle_var_arg "INSTASH_ADMIN_USER" "--admin_user" "user"
    handle_var_arg "INSTASH_ADMIN_PASS" "--admin_password" "pass"
    handle_var_arg "INSTASH_ADMIN_EMAIL" "--admin_email" "email"
    # Log generated args
    logmsg "Prepared args for wpcli core install: '$url $title $user $pass $email --skip-email'"
    # Run command
    wpcli "core install $url $title $user $pass $email --skip-email"

    return $?
}

# Gets the home URL.
# 
# Prioritizes the ENV var.
# If not set, uses wp-cli to get the value from the datbase.
function get_home_url() {
    local home=""
    if [[ -z $SITEURL ]]
        then home=$($WP option get home)
        else home=$SITEURL
    fi
    echo "$home"
}

#-------------------------------------
# Functions used during the install
#-------------------------------------

function composer_install() {
    composer install --prefer-dist
    failing $? 'Could not install dependencies' "Done! Dependencies installed."
}

# Temporarily renames the root config file.
# 
# This allows WP CLI to default to /wp/wp-config.php
function use_wp_config() {
    local wpconfig="$WP_CONFIG"
    local tmpconfig="${wpconfig}${_TMP}"
    if [ -f "$wpconfig" ]; then
        logmsg "Renaming root $wpconfig to $tmpconfig"
        mv "$wpconfig" "$tmpconfig"
    fi
}

# Restores the root config file from the temporary file.
# 
# This allows WP CLI to use this config file instead.
function use_root_config() {
    local wpconfig="$WP_CONFIG"
    local tmpconfig="${wpconfig}${_TMP}"
    if [ -f "$tmpconfig" ]; then
        logmsg "Renaming root $tmpconfig to $wpconfig"
        mv "$tmpconfig" "$wpconfig"
    fi
}

# Prepares the database configuration
function configure_database() {
    # Reset any existing wp-config file
    local wpconfig="$WP_ROOT/$WP_CONFIG"
    if [ -f "$wpconfig" ]; then
        rm "$wpconfig"
    fi
    # Generate wp-config
    wpcli_core_config
    failing $? 'Could not drop database' "Generated $wpconfig"
}

# Creates the database
function create_database() {
    logmsg "Dropping any existing database ..."
    if [ $INTERACTIVE = 0 ]
        then yes="--yes"
        else yes=""
    fi
    wpcli "db drop $yes"
    failing $? 'Could not drop database'
    logmsg "Creating database ..."
    wpcli "db create"
    failing $? 'Could not create WP' "Created database!"

    return 
}

# Installs WordPress in the database.
function install_wordpress() {
    logmsg "Installing WordPress ..."
    # Install
    wpcli_core_install
    failing $? "Failed to install WordPress! Exiting ..." "Installed WordPress!"

    return $?
}

# Updates the WordPress site URL
function update_wp_siteurl() {
    # Set WordPress Core URL
    local home="$(get_home_url)"
    logmsg "Updating 'siteurl' option to '$home' ..."
    wpcli "option update siteurl '$home/$WP_ROOT'"
    failing $? 'Could not update "siteurl" option'

    return $?
}

# Generates the local configuration file
function generate_local_config() {
    # Generate local-config.php file
    local lconfig="$WP_LCONFIG"
    logmsg "Generating $lconfig ..."
    home=$(get_home_url)
    printf "<?php \n\ndefine('WP_CONTENT_URL', '$home/app');" > "$lconfig"
    failing $? 'Could not generate config' "Done!"
}

# Generates the sensitive data configuration file
function generate_sensitive_config() {
    # Generate sensitive-config.php file
    local wpconfig="$WP_ROOT/$WP_CONFIG"
    local sconfig="$WP_SCONFIG"
    logmsg "Generating $sconfig ..."
    printf "<?php \n\n" > "$sconfig" && sed -n 4,31p "$wpconfig" >> "$sconfig"
    failing $? 'Could not generate config' "Done!"
}

# Deletes the wp/wp-config.php file
function delete_wp_config() {
    local wpconfig="$WP_ROOT/$WP_CONFIG"
    # Delete wp-config.php in the WP root directory and undo temp rename of root wp-config.php
    logmsg "Deleting $wpconfig ..."
    rm "$wpconfig"
}

# Customizes the installed WordPress for INSTASH
function site_customization() {
    logmsg "Switching theme ..."
    wpcli theme activate wpcr-website-theme-2016
    # Set permalinks and flush rewrite rules
    logmsg "Setting permalink structure"
    wpcli rewrite structure '/%postname%/' --hard
    logmsg "Flushing rewrite rules"
    wpcli rewrite flush --hard
    # Activate plugins
    logmsg "Activating plugins"
    wpcli plugin activate --all
}


#-------------------------------------
# Parse Arguments
#-------------------------------------
#
INTERACTIVE=0
VERBOSE=0
PHASE=1
NO_CLEAR=0

while [[ $# > 0 ]]
do
    key="$1"
    case $key in
        # Interactive flag
        -i|--interactive)
            INTERACTIVE=1
            shift
        ;;
        # Verbose flag
        -v|--verbose)
            VERBOSE=1
            shift
        ;;
        # Phase flag
        -p|--phase)
            shift
            PHASE="$1"
            shift
        ;;
        # Help flag
        -h|--help)
            showhelp
            exit 0
        ;;
        # Reset flag
        -r|--reset)
            PHASE=0
            shift
        ;;
        # Prevent clearing
        -n|--no-clear)
            NO_CLEAR=1
            shift
        ;;
        # default case
        *)
        ;;
    esac
done

#-------------------------------------
# BEGIN
#-------------------------------------

if [ $INTERACTIVE = 1 ]
    then logmsg "Interactive mode enabled."
fi

if [ -f "wp-cli.local.yml" ] || [ -f "wp-cli.yml" ]
    then logmsg "YAML file found!"
    else logmsg "YAML file NOT found!"
fi

# Actual installation process

logmsg "Starting at phase $PHASE"

case "$PHASE" in
    0) # Reset phase
        reset=1
        # interactive is on, show confirmation
        if [ $INTERACTIVE = 1 ]; then
            echo -e "Are you sure you want to reset? (y/n) \c"
            read -e reset_conf
            # Set $reset depending on user input
            if [[ $reset_conf = "y" ]]
                then reset=1
                else reset=0
            fi
        fi
        # If reset accepted ... well, reset!
        if [[ $reset = 1 ]]; then
            if [[ $NO_CLEAR = 0 ]]; then
                logmsg "Clearing files, leaving config and repo data"
                ls | grep -v -e 'wp-cli.local.yml' -e 'wp-cli.yml' -e 'install.sh' -e '.git' | xargs rm -rf
            fi
            logmsg "Hard resetting back to git HEAD"
            [[ $VERBOSE = 0 ]] && git reset --hard --quiet || git reset --hard
        fi
        ;;
    1)
        divlog "Phase 1: Install Dependencies"
        composer_install
        ;&
    2)
        divlog "Phase 2: Generate WP Config"
        use_wp_config
        configure_database
        ;&
    3)
        divlog "Phase 3: Create Database"
        create_database
        ;&
    4)
        divlog "Phase 4: Install WordPress into Database"
        install_wordpress
        ;&
    5)
        divlog "Phase 5: Update Database"
        update_wp_siteurl
        ;&
    6)
        divlog "Phase 6: Generate sensitive and local configs"
        generate_local_config
        generate_sensitive_config
        ;&
    7)
        divlog "Phase 7: Switch to root config"
        delete_wp_config
        use_root_config
        ;&
    8)
        divlog "Phase 8: WordPress site customization"
        site_customization
        ;&
    *)
        logmsg "${GREEN}FINISHED!${NOC}\n"
        ;&
esac

#-------------------------------------
# END
#-------------------------------------
