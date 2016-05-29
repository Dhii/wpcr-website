<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to "wp-config.php" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

// Directory separator shortcut constant
define('DS', DIRECTORY_SEPARATOR);

/**
 * Generates a path.
 * 
 * @param array $args An array of arguments or a variable number of parameters. Default: array()
 * @return string
 */
function _path($args = array())
{
    $actualArgs = (!is_array($args) && func_num_args() > 1)
            ? func_get_args()
            : $args;
    return implode(DS, $actualArgs);
}

// Load sensitive configuration
require_once _path(__DIR__, 'sensitive-config.php');

// Load local configuration
if (file_exists($localConfig = _path(__DIR__, 'local-config.php'))) {
    require_once $localConfig;
}

// Load Autoloader
if (file_exists($autoloader = _path(__DIR__, 'vendor', 'autoload.php'))) {
    require_once $autoloader;
}

/* Custom WP CONTENT DIRECTORY */
if (!defined('WP_CONTENT_DIR')) {
    define( 'WP_CONTENT_DIR', dirname(__FILE__) . '/app' );
}

if (!defined('WP_CONTENT_URL')) {
    define( 'WP_CONTENT_URL', 'http://wpcodereviews.com/app' );
}

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix  = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
if (!defined('WP_DEBUG')) {
    define('WP_DEBUG', false);
}

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') ) {
    define('ABSPATH', dirname(__FILE__) . DIRECTORY_SEPARATOR);
}

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');
