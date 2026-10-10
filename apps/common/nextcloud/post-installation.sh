#!/bin/sh
# Run by the image's entrypoint once, straight after `occ maintenance:install`
# (docker-entrypoint-hooks.d/post-installation), as uid 33. A non-zero exit
# stops the container, so the app-store steps below must not be fatal: the
# store is an external dependency and can be retried by hand with the same occ
# commands.
set -eu

occ() { php /var/www/html/occ "$@"; }

# The cron sidecar in deployment.yaml calls cron.php every 5 minutes.
occ background:cron

# Lets users enter phone numbers without a country code in Contacts.
occ config:system:set default_phone_region --value=AU

# Heavy background jobs only run in this hour (UTC): 16:00 UTC is 02:00-03:00
# in Melbourne.
occ config:system:set maintenance_window_start --type=integer --value=16

# A CLI install does not add the "recommended apps" the web installer offers.
# CalDAV/CardDAV themselves are core (the dav app); these are the web UIs.
for app in calendar contacts tasks; do
  occ app:install "$app" || echo "app:install $app failed - retry by hand"
done
