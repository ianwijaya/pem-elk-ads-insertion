when CLIENT_ACCEPTED {
   set hsl [HSL::open -proto UDP -pool pool_elk]
}

when HTTP_REQUEST {
    STREAM::disable
    #log local0. [HTTP::uri]
    set ip_addr [IP::client_addr]
    set syslog_timestamp [clock format [clock seconds] -format "%b %d %T"]
    set f5_hostname $static::tcl_platform(machine)
    set f5_source_ip "10.1.1.1"
    set subs_id [PEM::session info $ip_addr subscriber-id]
    set calling_station_id [PEM::session info $ip_addr calling-station-id]
    set called_station_id [PEM::session info $ip_addr called-station-id]
    set src_ip_addr $ip_addr
    #log local0. "$ip_addr $subs_id $called_station_id"
    set user_agent [HTTP::header user-agent]
    if {[HTTP::uri] starts_with "/click"} {
        set ads_id [URI::query [HTTP::uri] ads_id]
        set ads_name [URI::query [HTTP::uri] ads_name]
        if {$ads_id!="" } {
            HSL::send $hsl "${syslog_timestamp} ${f5_hostname} ${f5_source_ip}#${subs_id}#${calling_station_id}#${called_station_id}#${src_ip_addr}#${user_agent}#${ads_id}#${ads_name}#clicked"
            set ads_url [string trimright [getfield [HTTP::uri] "url=" 2] "\""]
            HTTP::redirect $ads_url
        }
    }
}

when HTTP_RESPONSE {
    set f5_source_ip [IP::local_addr]
    set ads_id [HTTP::header values ads_id]
    set ads_name [HTTP::header values ads_name]
    #log local0. "${syslog_timestamp} ${f5_hostname} ${f5_source_ip}#${subs_id}#${calling_station_id}#${called_station_id}#${src_ip_addr}#${user_agent}#${ads_id}#${ads_name}#inserted"
    if {$ads_id!="" } {
        HSL::send $hsl "${syslog_timestamp} ${f5_hostname} ${f5_source_ip}#${subs_id}#${calling_station_id}#${called_station_id}#${src_ip_addr}#${user_agent}#${ads_id}#${ads_name}#inserted"
    }
    if {[HTTP::header value Content-Type] contains "text"} {
      #STREAM::expression {@href@href1@}
      set find "href=\""
      set replace "href=\"http://10.89.121.65/click?ads_id=${ads_id}&ads_name=${ads_name}&url="
      STREAM::expression "@$find@$replace@"
      STREAM::enable

    }
 }
