path /bin:/usr/bin:/sbin:/usr/sbin:<env>
base cyan
ifos sunos
match cyan+:blue+ ----
match white:default is alive
ifos <any>
match cyan+:blue+ ---
ifnarg --help
match green+:cyan+ =
ifarg <any>
match white:cyan+ :
match white:green+ (
match white:default )
match green+:cyan+ [
match green+:default ]
match cyan+:default ,
match green+:default  ms
match none:green+  from 
match none:green+ From 
match blue+:none PING