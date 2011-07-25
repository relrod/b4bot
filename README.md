b4bot
=====
Welcome to the b4bot project! Please file bug reports for any issues you find, or maybe even a patch. They are gladly accepted.

Installation
------------
Installing b4bot on most systems should be a simple matter of:

     git clone git://github.com/codeblock/b4bot.git/
     cd b4bot
     perl Makefile.PL
     sudo make installdeps
     nano config.yaml
     # sudo make updatedb # Eventually. This will update your database to the latest schema. THIS SHOULD NEVER CAUSE DATA LOSS.
     perl b4bot.pl

Updating
--------
Updating should be easy too.

    git pull origin master
    perl Makefile.PL
    sudo make installdeps
    # sudo make updatedb # Eventually. This will update your database to the latest schema. THIS SHOULD NEVER CAUSE DATA LOSS.
    perl b4bot.pl

Experimental
------------
Experimental features and other interesting tidbits of code relating to the project are found in the various other git branches. One example includes the `historic` branch, which includes an older copy of the core code.
