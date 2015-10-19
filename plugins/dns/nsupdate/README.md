# Notice of Export Control Law

This software distribution includes cryptographic software that is subject to the U.S. Export Administration Regulations (the "*EAR*") and other U.S. and foreign laws and may not be exported, re-exported or transferred (a) to any country listed in Country Group E:1 in Supplement No. 1 to part 740 of the EAR (currently, Cuba, Iran, North Korea, Sudan & Syria); (b) to any prohibited destination or to any end user who has been prohibited from participating in U.S. export transactions by any federal agency of the U.S. government; or (c) for use in connection with the design, development or production of nuclear, chemical or biological weapons, or rocket systems, space launch vehicles, or sounding rockets, or unmanned air vehicle systems.You may not download this software or technical information if you are located in one of these countries or otherwise subject to these restrictions. You may not provide this software or technical information to individuals or entities located in one of these countries or otherwise subject to these restrictions. You are also responsible for compliance with foreign law requirements applicable to the import, export and use of this software and technical information.

# Configuration

This plugin can authenticate updates using either TSIG or GSS-TSIG request signatures. The DNS server must be configured to accept update requests from the broker host.

The configuration file for the plugin is ```/etc/openshift/plugins.d/openshift-origin-dns-nsupdate.conf```

Three variables in the configuration file define the location of the update server:
    # The DNS server
    BIND_SERVER="127.0.0.1"
    
    # The DNS server's port
    BIND_PORT=53

    # The base zone for the DNS server
    BIND_ZONE="example.com"

Change the server and zone to match your environment.  You should not generally need to change the port number.

## TSIG (RFC 2136)

For TSIG authentication, the configuration file must contain the DNSSEC key name and the base-64 encoded signing key string.  These are set using the *BIND_KEYNAME* and *BIND_KEYVALUE* variables in the configuration file.

    # TSIG authentication
    #
    BIND_KEYNAME="example.com"
    BIND_KEYVALUE="base-64 encoded DNSSEC HMAC TSIG KEY"
    BIND_KEYALGORITHM=(HMAC-MD5|HMAC-SHA1|HMAC-SHA256|HMAC-SHA512) - MD5 default

## GSS-TSIG

For GSS-TSIG authentication the administrator must provide the name of the Kerberos principal that will be used for authentication, and the file name of the keytab file which contains the user credentials.

    # GSS-TSIG (Kerberos) Authentication
    # BIND_KRB_PRINCIPAL="" 
    # BIND_KRB_KEYTAB=""
    
Note that the keytab file must be readable by the ```apache``` user that is the user which runs the broker processes.


 



