
# PHP-FPM

![PHP 7.0](https://img.shields.io/badge/php-7.0-brightgreen.svg) ![Nginx 1.13.6.1](https://img.shields.io/badge/nginx-1.13.6.1-brightgreen.svg) ![ngx_pagespeed latest-stable](https://img.shields.io/badge/ngx_pagespeed-latest--stable-brightgreen.svg) ![OpenSSL 1.0.2o](https://img.shields.io/badge/OpenSSL-1.0.2o-brightgreen.svg)

---

Included:
-   [ngx_pagespeed](https://github.com/apache/incubator-pagespeed-ngx)
-   [NewRelic PHP monitoring](https://newrelic.com)
-   ssmtp for mail delivery via [sendgrid](https://sendgrid.net) or [mailgun](http://mailgun.net/)
-   cron daemon
-   Mozilla intermediate SSL profile

---

This container is configurable via a plethora of environment variables, some of which are re-applied on service start.

var | default | description
--- | ------- | -----------
APP_ENV |  | production, develop
APP_GID | 1000 | group_id
APP_GROUP | app | nginx and php5-fpm group
APP_HOSTNAME | `hostname -f` |  hostname of application
APP_UID | 1000 | user_id - useful when mounting volumes from host > guest to either share or delineate file access permission
APP_USER | app | nginx and php5-fpm user
CHOWN_APP_DIR | true | if true, `chown -R $APP_USER:$APP_GROUP /app/source/public`
CONTAINER_TIMEZONE | UTC | Server timezone
EXIM_DELIVERY_MODE | local | smarthost, local :: set to smarthost to enable third party SMTP
EXIM_MAIL_FROM | example.com | domain from which exim4 mail appears to originate
EXIM_SMARTHOST_AUTH_PASSWORD | password_123 | SMTP password
EXIM_SMARTHOST_AUTH_USERNAME | postmaster@example.com | SMTP username
NEWRELIC_APPNAME | $PHP_PHP_POOL_NAME | Application name in Newrelic APM list. Defaults to PHP pool name (APP_HOSTNAME with underscores instead of periods)
NEWRELIC_ENABLED | true | Enables or disables [Newrelic.com](https://newrelic.com/) reporting
NEWRELIC_LICENSE | \_\_DISABLED\_\_ | Newrelic account license key.  Available from your Newrelic account page
OPENRESTY_FASTCGI_BACKEND | unix:/run/php/php7.0-fpm.sock | Location of the PHP upstream fastcgi_backend
OPENRESTY_MAX_WORKER_PROCESSES | 8 | nginx worker_processes is determined from number of processor cores on service start, up to the maximum permitted by OPENRESTY_MAX_WORKER_PROCESSES
PHP_CLEAR_ENV | yes | yes, no :: if set to 'no', enables access to all environment variables via php `getenv()`
PHP_DISABLE_FUNCTIONS | false | Comma separated list of additional functions to disable for security.  These are appended to the default Ubuntu distribution disable_functions line
PHP_MAX_CHILDREN | 6 | process manager maximum spawned children
PHP_MAX_REQUESTS | 500 | Maximum number of requests each child process can process before terminating, which should mitigate any memory leaks. Set to 0 to disable.
PHP_MAX_SPARE_SERVERS | 3 | if PHP_PROCESS_MANAGER is dynamic, this is the maximum number of idle children
PHP_MEMORY_LIMIT | 128M | Maximum memory PHP can use per worker
PHP_MIN_SPARE_SERVERS | 2 | if PHP_PROCESS_MANAGER is dynamic, this is the minimum number of idle children
PHP_PROCESS_MANAGER | dynamic | dynamic, static, ondemand :: PHP process manager scheme
PHP_START_SERVERS | 3 | if PHP_PROCESS_MANAGER is dynamic, this is the number of children spawned on boot
UPLOAD_MAX_SIZE | 30M | Maximum upload size, applied to nginx and php5-fpm
