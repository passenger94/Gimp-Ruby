
# Gimp-Ruby 
*(started here at 0.1.5)*

A ruby plug_in for The Gimp, initially wrote by Scott Lembcke in 2006 (https://github.com/slembcke).

The original Gimp-Ruby 0.1.3 is still available from the GNOME Git.

Just because i love Gimp and Shoes and incidentally to learn a bit of coding

Works/tested on ruby 2.1.5/2.2.4 (works probably from 1.9 to 2.xx) and Gimp 2.8.14 / 2.9.1 - Linux (Ubuntu).

Can not mix with the 2 versions of gimp, API is different, nothing awful in plug-ins (scripts) code, though
(lots of constants names have changed, like BACKGROUND_FILL to FILL_BACKGROUND for example)
i'm developping mainly under gimp-2.9, so gimp-2.8 version might be slightly behind

i've added "shoes" optional facilty : https://github.com/Shoes3/shoes3


### to install/compile 
clone the repository, cd into Gimp-Ruby directory and issue a "rake" command (you need libtool apart the obvious ruby, gimp, gtk2 or gtk3), optionally install Gimp-Ruby (libs and plugins) into your user gimp directory with "rake install" 
    (make a backup of your beloved plugins before, until gimp-ruby is better tested under several environments (if ever), should not be necessary at all but better safe ...)


### installation options must be set in "app.yaml" file :
- prefix : leave it blank if you have gimp installed in the usual place, otherwise specify here the path to your gimp (same prefix given when installing Gimp)
- shoes : the path to your shoes executable, leave it blank if for some reason you don't want to have shoes support
 
at the moment installation routine  only checks for ruby installed via rvm.
If you don't use rvm, you need to create manually 2 files in your user gimp directory : "ruby.env" in "environ" directory and "ruby.interp" in "interpreters" directory.
- feed ruby.env with
```
    RUBYLIB=USERDIR/ruby
```
where USERDIR is your gimp user directory (something like /home/user/.gimp-2.8)
- ruby.interp with
```
    ruby=PATH/TO/YOUR/RUBY
    /usr/bin/ruby=PATH/TO/YOUR/RUBY
    :Ruby:E::rb::ruby:
```
