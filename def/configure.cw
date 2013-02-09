# Configure scripts may include some third party programs that may be
# colored by cw, which could mess up the configure script.
$NOCOLOR=1
command ./configure {}
match highlight yes$
match error no$
match punctuation \.
match punctuation -
match punctuation /
match punctuation \\
match bright :
match bright '
match bright `
match bright "
match highlight &
match neutral =
match neutral \[
match neutral \]
match highlight \*\*\*
match neutral \*
match neutral checking
match warning updating
match bright creating
match bright loading
match punctuation \(cached\)
match highlight warning: 
match error error: 
match error Error
match warning Interrupt
