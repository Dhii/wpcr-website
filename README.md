# WP Code Reviews - Website

## Installer Requirements

* `bash` >=4.0
* `php` >=5.4
* `mysql` command

## Automated Installation

Clone the repo and invoke the `./install.sh` script.

The script requires some configuration. You have a few options:

### Option A: Interactive Mode

Running the script as `./install.sh --interactive` or `./install.sh -i` will make the script interactive.

This means that the script will prompt you toy enter the required information. You will be required to input the data into your terminal application, as well as allow you to accept/decline various confirmation messages.

### Option B: YAML file

Create either a `wp-cli.yml` or a `wp-cli.local.yml` in the cloned directory. Don't worry, these files are gitignored ;)

This file is used by WP CLI to obtain the values of any paramters that are not specified. Example:

```yaml
core config:
  dbname: wpcr
  dbuser: root
  dbpass:
  dbhost: localhost
core install:
  url: http://localhost/wpcr/deploy-test
  title: "WP Code Reviews"
  admin_user: admin
  admin_password: admin
  admin_email: admin@dhii.co
```

You can also specify additional information, such as the following:

```yaml
path: wp
apache_modules:
  - mod_rewrite
core config:
  ...
  extra-php: |
    define('WP_DEBUG', true);
```

### Option C: Environment Variables

You can specify the following environment variables:

```
WPCR_SITE_URL     The site's root URL
WPCR_SITE_TITLE   The site's title
WPCR_ADMIN_USER   The admin username
WPCR_ADMIN_PASS   The admin password
WPCR_ADMIN_EMAIL  The admin email
WPCR_DB_NAME      The database name
WPCR_DB_USER      The database username
WPCR_DB_PASS      The database password
WPCR_DB_HOST      The database host
WPCR_DB_PREFIX    The database table prefix
```

These will be detected by the script and used for configuration.

### Option D: Mix of options B and C

The script will first attempt to locate the environment variable for a specific configuration. If not found, it will omitt the argument from the WP CLI command, which results in the command defaulting to the YAML file.

You can utilize this to only specify a subset of the environment variables, and specify the rest as values in the YAML file.

This can be useful, for instance, if you wish to have the same database and admin credentials system-wide but different local site URLs, site names and database names. Example:

Environment variables:
```
  WPCR_ADMIN_USER    "admin"
  WPCR_ADMIN_PASS    "admin123"
  WPCR_ADMIN_EMAIL   "admin@whatever.com"
  WPCR_DB_USER       "root"
  WPCR_DB_PASS       ""
  WPCR_DB_HOST       "localhost"
  WPCR_DB_PREFIX     "wp_"
```

wp-cli.local.yml
```yaml
core config:
  dbname: wpcr
core install:
  url: http://localhost/wpcr/deploy-test
  title: "WP Code Reviews"
```

# Manual Installation

Clone the repo and invoke `composer install` to download the dependancies.

Temporarily rename the root config file: `mv wp-config.php wp-config.temp`

Create an empty MySQL database.

Launch the site in your browser to begin the WordPress "famous 5-minute" install, to generate `wp/wp-config.php`.  
Alternatively, you can create the `wp/wp-config.php` file manually if you already have a database set up.

Create a file in the site root directory called `sensitive-config.php`, which will contain the DB config.  
You can generate it from by running the following command, which will copy the DB config from `wp/wp-config.php`:

```
printf "<?php \n\n" > sensitive-config.php && sed -n 21,56p wp/wp-config.php >> sensitive-config.php
```

If the above command fails, you can manually copy the database constants AND the auth keys and salts from `wp/wp-config.php` to `sensitive-config.php`. Remember to start the file with `<?php`!

Now delete the `wp/wp-config.php` file and undo the rename of the root config file:

```
rm wp/wp-config.php
mv wp-config.temp wp-config.php
```

Set the correct WordPress URL options by navigating to *WordPress Admin > Settings > General* and:
* Set WordPress Address to point to the `wp/` directory, as a URL
* Set Site Address to point to the root directory, as a URL

Generate the root `.htaccess` file by navigating to *WordPress Admin > Settings > Permalinks* and:
* Choose "Post name"
* Click "Save Changes"

Create a file in the root called `local-config.php` and define the full URL to your app directory:

```php
<?php

define('WP_CONTENT_URL', 'http://local.url/to/app/dir');
```

Finally, activate the "WP Code Reviews Theme 2016" theme and all plugins. The theme might need further customization to be a perfect clone.
