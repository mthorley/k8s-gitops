


# Design Decisions

* Split horizon DNS
* Cloudflare authoritative for cynonomy.net
* No public A/AAAA records (internal services only)
* Blue green per cluster - cluster0.cyonomy.net and cluster1.cyonomy.net

# 1) Cloudflare - API token for cert-manager

1. Navigate to Account API tokens

2. Create API token with the following settings:

Permissions
 - Zone - DNS - Edit
 - Zone - Zone - Read

Zone Resources
 - Include - All Zones

