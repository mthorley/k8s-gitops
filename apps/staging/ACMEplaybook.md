


# Design Decisions

* Split horizon DNS
* Cloudflare authoritative for cynonomy.net
* No public A/AAAA records (internal services only)
* Blue green per cluster - cluster0.cyonomy.net and cluster1.cyonomy.net

# 1) Cloudflare - API token for cert-manager

Navigate to Account API tokens and create API token with the following settings:

Permissions
 - Zone - DNS - Edit
 - Zone - Zone - Read

Zone Resources
 - Include - All Zones

