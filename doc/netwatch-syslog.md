This script has been dropped. Filtering in firewall is advised, which should
look something like this:

    /ip/firewall/filter/add action=reject chain=output out-interface-list=WAN port=514 protocol=udp reject-with=icmp-admin-prohibited;
    /ip/firewall/filter/add action=reject chain=forward out-interface-list=WAN port=514 protocol=udp reject-with=icmp-admin-prohibited;
