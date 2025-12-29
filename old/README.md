
## Scripted install of weewx using the rtldavis driver

NOTE - THIS DOWNLOADS EVERYTHING FROM MULTIPLE UPSTREAM SITES

FWIW, I found the rtldavis installation repos and instructions very difficult to follow,
and there were also some errors for current raspi os debian-11 versions as well as edits
needed if you are a US user.   This script worked for me.

The key is pinning your go version to < 1.16 due to breaking changes from the go project
upstream.  Luc's instructions are written to the <= 1.15 versions of go.

Pointers to the reference documents and commentary for what I changed vs. those
instructions is in the code.

Usage - if you set the variables at the top of the script to '1' it will run that block. 
  Set to '0' or comment out to suppress running that block of code.  
  Hopefully it should be reasonably obvious.

Installation Notes:
===================

 - this requires that you run v5 via the 'pip' installation mechanism as user 'pi'
       with home directory /home/pi. I will not support alternate weewx installation types.

 - each set of steps has its individual INSTALL_XYZ variable at the top of the script
      so you can run them step-by-step.  I would highly recommend doing this rather than
      setting them all to '1' and running them all in one blast (and hoping).

       If you set everything = 1 and something in the middle blows up, it is entirely
       probable that following steps will fail too.

 - since go1.15 is no longer available in debian12 default repos, this script
       now installs a 'local' copy of go under /home/pi/go/bin and also
       installs rtldavis there.

 - this assumes it is run as user 'pi' on a raspi and installs code, per Luc's upstream,
      into odd locations such as /usr/local/bin and other locations.  I didn't battle
      trying to make where it puts things more sensible (to me)

 - the default weewx.conf that this installs has 'very' (like 'VERY') verbose
       logging enabled for rtldavis.  You'll almost certainly want to dial that
       back after you get things working.  See the driver section in weewx.conf
       for details.

Python Version Notes:
=====================

 - with debian trixie the underlying python version has changed warnings related to
      compiling regular expressions, so you will see syntax warnings when installing
      the actual rtldavis.py driver.  You can ignore them for now.  If you want to 
      patch your rtldavis.py file, see https://groups.google.com/g/weewx-user/c/-KOh89ur7Y8
      for how to do so.  There might be more discussion there as time goes by.

