
## Scripted install of weewx using the rtldavis driver

FWIW, I found the rtldavis installation repos and instructions to be very difficult to follow, and there are many pieces downloaded throughout the installation procedure from other upstream repositories.  Furthermore, there are edits needed if you a a US user.  Lastly, under the hood the 'go' steps do downloads from other upstream sites.  Assembling all the pieces at build time can be problematic and the risk is that if only one of the upstream sites disappears, it would not be possible to build a working weewx rtldavis installation from scratch.

This repo attempts to make it easier and remove such risks.   It contains all the consolidated sources and a bash script to automate building and installing the pieces of the puzzle.

Contents:
=========

* install-weewx-rtldavis.sh - script that installs everything
* src.tgz - sources for the pieces of the puzzle

Installation Notes:
===================

* Copy the two pieces to your ${HOME} making sure to get the 'raw' versions from github
    * wget https://github.com/vinceskahan/weewx/raw/refs/heads/main/weewx-rtldavis/src.tgz
    * wget https://github.com/vinceskahan/weewx/raw/refs/heads/main/weewx-rtldavis/install-weewx-rtldavis.sh
* Edit the bash script and set the desired variables at the top of the script to '1' it will run that step.
* Then run 'bash install-weewx-rtldavis.sh'

Note - the script does call sudo for installing things into /usr/local/bin, so you will need sudo to remove the src tree(s) afterward

Other notes:
============

- the script as delivered assumes you are running on a raspberry pi with a weewx 'pip' installation under '/home/pi'.

- each set of steps has its individual INSTALL_XYZ variable at the top of the script so you can run them step-by-step, running the script multiple times and turning only the next step on ste-p-by-step.  I would highly recommend doing this rather than setting them all to '1' and running them all in one blast (and hoping).

  If you set everything = 1 and something in the middle blows up, it is entirely probable that following steps will fail too.  Simplest thing to do is to 'tee' your runs ala 'bash install-weewx-rtldavis.sh | tee /tmp/debug.txt 2>&1'.  As mentioned above, it is recommended to do it step-by-step.

- the default weewx.conf that this installs has 'very' (like 'VERY') verbose logging enabled for rtldavis.  You'll almost certainly want to dial that back after you get things working.  See the driver section in weewx.conf for details.

- since everything installs under /usr/local, it is 'theoretically' possible for this to work with a packaged weewx installation, although this is not tested.  I do not plan to support alternate configurations for this repo.

- after you successfully install the driver you 'should' be able to delete the source .tgz file, extracted sources tree, and install script.  Should.  This is untested.

About Versions:
===============
This source tree was built and tested on debian13 and a debian13-based raspi os containing golang 1.24.2, and it is unknown if it will build on later versions of golang.  If you see "invalid go version '1.24.4': must match format 1.23" you are on an older os.  You might try "go mod edit -go=1.23" and hope it works.

Go is sufficiently confusing to me that I will 'not' try to figure out how to deal with earlier golang versions nor different os versions. I do know this works on debian13, FWIW.

Patches made to original sources:
=================================

 - I've patched Luc's rtldavis.py driver to remove python deprecation warnings that appear now in current python versions.  The original file is present in the source tree as rtldavis.py.dist just in case. Running the original version seems to work, although python complains with warnings on a debian13-based os.  Previous versions of python did not throw these warnings.  This is a 'python' change that we users are victims of.  The python team seems to do that a lot.


Contents/credits:
=================

The consolidated sources contain the following from the upstream providers...

```

* librtlsdr - library to turn Realtek RTL2832 based DVB dongle into a SDR receiver
from https://github.com/steve-m/librtlsdr.git

commit ae0dd6d4f09088d13500a854091b45ad281ca4f0 (HEAD -> master, origin/master, origin/HEAD)
Author: Kacper Ludwinski <kacper@ludwinski.dev>
Date:   Sun Nov 9 21:56:53 2025 +0000

* gortlsdr - 'go' wrapper around librtlsdr
from https://github.com/jpoirier/gortlsdr.git

commit 075e50ef422cf3ba193d1ba6d79a0efea89491e2 (HEAD -> master, origin/master, origin/HEAD)
Merge: 8185285 956e97e
Author: Joseph Poirier <jdpoirier@gmail.com>
Date:   Sat May 19 12:17:06 2018 -0500

* rtldavis - RTL-SDR receiver for Davis weather stations
from https://github.com/lheijst/rtldavis

commit b95d5d734e4666c90f3d7539d5e2acd9f80f7e43 (HEAD -> master, origin/master, origin/HEAD)
Author: Luc Heijst <ljm.heijst@gmail.com>
Date:   Fri Jun 5 08:43:42 2020 -0300

* weewx-rtldavis - the weewx extension as of 12/20/2025
from https://github.com/lheijst/weewx-rtldavis/archive/master.zip

commit 2f3b4b344fd70ab253aabfa837b0ffc76570c075 (HEAD -> master, origin/master, origin/HEAD)
Author: Luc Heijst <ljm.heijst@gmail.com>
Date:   Sat Jan 2 13:56:04 2021 -0300

```

Unfortunately we need to compile the librtlsdr from sources due to particular compilation settings required for rtldavis to work properly.  See the cmake command in the install script for details.


