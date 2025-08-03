

# To see which IPs have already been allocated via BGP from unifi

```
ssh root@udm-pro-ip

root@UDM-Pro-Max:~# vtysh -c 'show ip bgp'
```

example response

```
BGP table version is 11, local router ID is 192.168.2.1, vrf id 0
Default local pref 100, local AS 65023
Status codes:  s suppressed, d damped, h history, u unsorted, * valid, > best, = multipath,
               i internal, r RIB-failure, S Stale, R Removed
Nexthop codes: @NNN nexthop's vrf id, < announce-nh-self
Origin codes:  i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

     Network          Next Hop            Metric LocPrf Weight Path
 *>  192.168.2.0/24   0.0.0.0                  0         32768 i
 *>  192.168.2.11/32  192.168.2.111                          0 64512 i
 *=                   192.168.2.112                          0 64512 i
 *=                   192.168.2.113                          0 64512 i
 *>  192.168.2.13/32  192.168.2.111                          0 64512 i
 *=                   192.168.2.112                          0 64512 i
 *=                   192.168.2.113                          0 64512 i
 *>  192.168.2.14/32  192.168.2.111                          0 64512 i
 *=                   192.168.2.112                          0 64512 i
 *=                   192.168.2.113                          0 64512 i
 *>  192.168.2.17/32  192.168.2.113                          0 64512 i
 *>  192.168.2.19/32  192.168.2.111                          0 64512 i
 *=                   192.168.2.112                          0 64512 i
 *=                   192.168.2.113                          0 64512 i
 *>  192.168.2.20/32  192.168.2.111                          0 64512 i
 *=                   192.168.2.112                          0 64512 i
 *=                   192.168.2.113                          0 64512 i
 *>  192.168.2.26/32  192.168.2.111                          0 64512 i
 *=                   192.168.2.112                          0 64512 i
 *=                   192.168.2.113                          0 64512 i
 *>  192.168.2.28/32  192.168.2.111                          0 64512 i
 *=                   192.168.2.112                          0 64512 i
 *=                   192.168.2.113                          0 64512 i
 *>  192.168.2.29/32  192.168.2.111                          0 64512 i
 *=                   192.168.2.112                          0 64512 i
 *=                   192.168.2.113                          0 64512 i
 *>  192.168.2.31/32  192.168.2.111                          0 64512 i
 *=                   192.168.2.112                          0 64512 i
 *=                   192.168.2.113                          0 64512 i

Displayed 11 routes and 29 total paths
```