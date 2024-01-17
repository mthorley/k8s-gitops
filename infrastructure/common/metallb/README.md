

# To see which IPs have already been allocated via BGP from unifi

```
ssh <username><usg-gateway-ip>
show ip bgp
```

will return something like

```
BGP table version is 0, local router ID is 192.168.2.1
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
              r RIB-failure, S Stale, R Removed
Origin codes: i - IGP, e - EGP, ? - incomplete

   Network          Next Hop            Metric LocPrf Weight Path
* i192.168.2.10/32  192.168.2.111                   0      0 ?
*>i                 192.168.2.101                   0      0 ?
* i                 192.168.2.113                   0      0 ?
* i                 192.168.2.112                   0      0 ?
* i192.168.2.11/32  192.168.2.111                   0      0 ?
*>i                 192.168.2.101                   0      0 ?
* i                 192.168.2.113                   0      0 ?
* i                 192.168.2.112                   0      0 ?
* i192.168.2.18/32  192.168.2.111                   0      0 ?
*>i                 192.168.2.101                   0      0 ?
* i                 192.168.2.113                   0      0 ?
* i                 192.168.2.112                   0      0 ?
*> 192.168.3.10/32  192.168.3.101                          0 64511 ?
*                   192.168.3.113                          0 64511 ?
*                   192.168.3.112                          0 64511 ?
*                   192.168.3.111                          0 64511 ?
*  192.168.3.11/32  192.168.3.113                          0 64511 ?
*                   192.168.3.112                          0 64511 ?
*                   192.168.3.111                          0 64511 ?
*>                  192.168.3.101                          0 64511 ?
*  192.168.3.12/32  192.168.3.113                          0 64511 ?
```
