# for -exec's, if another color wrapped program is called it will not
# be colored. (lets this definition file take over)
$NOCOLOR_NEXT=1
path /bin:/usr/bin:/sbin:/usr/sbin:<env>
base cyan
match cyan+:default /
match cyan+:default [
match cyan+:default ]
match cyan+:default (
match cyan+:default )
match grey:default :
match grey:default ;
match grey:default .