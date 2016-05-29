# WP Code Reviews - Website

## Local Setup

### Dependancies

As simple as `composer install`.

### WordPress Config

First, you'll need to disable our custom config by temporarily renaming it.

```
mv wp-config.php wp-config.temp
```

Now create a MySQL database and launch the site in your browser to begin the WordPress "famous 5-minute" install.  
Alternatively, you can create the `wp/wp-config.php` file manually if you already have a database set up.

Next, you'll need a root file called `sensitive-config.php`, which will contain the DB config. You can generate it from
by running the following command, which will copy the DB config from `wp/wp-config.php`:

```
printf "<?php \n\n" > sensitive-config.php && sed -n 21,56p wp/wp-config.php >> sensitive-config.php
```

You can now delete the config file in the `wp` directory and use our custom config:

```
rm wp/wp-config.php
mv wp-config.temp wp-config.php
```

### WordPress .htaccess and Content URL

Set the correct WordPress URL options by navigating to *WordPress Admin > Settings > General* and:
* Set WordPress Address to point to the `wp/` directory, as a URL
* Set Site Address to point to the root directory, as a URL

Generate the root `.htaccess` file by navigating to *WordPress Admin > Settings > Permalinks* and:
* Choose "Post name"
* Click "Save Changes"

Finally, create a file in the root called `local-config.php` and define the full URL to your app directory:

```php
<?php

define('WP_CONTENT_URL', 'http://local.url/to/app/dir');
```

### Activate Content

Activate the "WP Code Reviews Theme 2016" theme from *WordPress Admin > Appearance > Themes* and all plugins
from *WordPress Admin > Plugins*.
