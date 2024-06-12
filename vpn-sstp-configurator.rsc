{
:put ""
:put "- Welcome to SSTP VPN CONFIGURATOR -"
:put ""

:local defaultRemoteNetwork "192.168.150.0/24";
:put "Enter the network assigned to VPN clients (press enter to use default: $defaultRemoteNetwork): ";
:local input1 do={:return};
:local remoteNetwork [$input1];
:if ([:len $remoteNetwork] = 0) do={
    :set remoteNetwork $defaultRemoteNetwork;
}

:local defaultVpnPort "443";
:put "Enter the VPN port (press enter to use default: $defaultVpnPort): ";
:local input2 do={:return};
:local vpnPort [$input2];
:if ([:len $vpnPort] = 0) do={
    :set vpnPort $defaultVpnPort;
}

:local vpnUsername;
:while ([:typeof $vpnUsername] = "nothing" || [:len $vpnUsername] = 0) do={
    :put "Enter the VPN username: ";
    :local input3 do={:return};
    :set vpnUsername [$input3];
}

:local vpnPassword;
:while ([:typeof $vpnPassword] = "nothing" || [:len $vpnPassword] = 0) do={
    :put "Enter the VPN password: ";
    :local input4 do={:return};
    :set vpnPassword [$input4];
}

:local country;
:while ([:typeof $country] = "nothing" || [:len $country] = 0) do={
    :put "Enter the country for SSL certificate (e.g., US): ";
    :local input5 do={:return};
    :set country [$input5];
}

:local state;
:while ([:typeof $state] = "nothing" || [:len $state] = 0) do={
    :put "Enter the state for SSL certificate (e.g., California): ";
    :local input6 do={:return};
    :set state [$input6];
}

:local locality;
:while ([:typeof $locality] = "nothing" || [:len $locality] = 0) do={
    :put "Enter the locality for SSL certificate (e.g., San Francisco): ";
    :local input7 do={:return};
    :set locality [$input7];
}

:local organization;
:while ([:typeof $organization] = "nothing" || [:len $organization] = 0) do={
    :put "Enter the organization for SSL certificate (e.g., Github): ";
    :local input8 do={:return};
    :set organization [$input8];
}


    #### SCRIPT ###
    :put ""
    :put "--- STARTING CONFIGURATOR ---"

    # Enable DDNS
    :if ( [/ip cloud get ddns-enabled] = true ) do={
        :put "DDNS already enabled"
    } else={
        :put "DDNS is not enabled, enabling..."
        /ip cloud set ddns-enabled=yes
        # Wait for cloud to be enabled
        :delay 10s
    }

    # Get Cloud Address
    :local cloudAddress [/ip cloud get dns-name]
    :put "Cloud DNS Name: $cloudAddress"

    # CREATE SSL CERTIFICATE
    /certificate
    add name=VPN_CA common-name=$cloudAddress country=$country state=$state locality=$locality organization=$organization key-usage=key-cert-sign,crl-sign
    sign VPN_CA
    add name=VPN_SERVER common-name=$cloudAddress country=$country state=$state locality=$locality organization=$organization key-usage=digital-signature,key-encipherment,tls-server
    sign VPN_SERVER ca=VPN_CA
    :delay 10s
    :put "SSL Certificates created successfully"

    # CREATE IP POOL
    :local ipBase [:pick $remoteNetwork 0 ([:find $remoteNetwork "/"] - 1)]
    :local ipRange ($ipBase . "2-" . $ipBase . "254")
    /ip pool add name=vpn-pool ranges=$ipRange
    :put "VPN IP Pool created successfully"

    # CREATE VPN PROFILE
    /ppp profile add name=vpn-profile local-address=($ipBase . "1") remote-address=vpn-pool
    :put "VPN Profile created successfully"

    # ENABLE SSTP VPN
    /interface sstp-server server set enabled=yes certificate=VPN_SERVER default-profile=vpn-profile tls-version=only-1.2
    :put "SSTP VPN enabled successfully"

    # CREATE VPN USER
    /ppp secret add name=$vpnUsername password=$vpnPassword profile=vpn-profile
    :put "VPN User created successfully"

    # CREATE MASQUERADE RULE FOR VPN
    /ip firewall nat add chain=srcnat action=masquerade src-address=$remoteNetwork
    :put "Masquerade rule for VPN created successfully"

    # CREATE FIREWALL FILTER INPUT RULE
    /ip firewall filter add chain=input action=accept protocol=tcp dst-port=$vpnPort place-before=3

    # EXPORT CLIENT CERTIFICATE
    /certificate export-certificate VPN_CA

    :put ""
    :put "[SUCCESS] SSTP VPN CONFIGURED"
    :put "The client certificate is waiting in the files section for you to download"
    :put ""
    :put "- github.com/cattalurdai -"
}
