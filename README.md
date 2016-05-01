MMAtransfer
===========

Overview

* mmatransfer.rb - transfer massive media files from a local storage system to a remote storage service.
* pstore.rb - show contents of a specified database.
* delstore.rb - delete a value from a specified database.

## Description

* mmatransfer.rb - If you have massive media files (such as huge amount of motion picture files of recorded TV program, animation, and so on), sometimes it is difficult to manage them. Especially filename that does not conflict to other ones can be a serious problem. This script uses a hash value and a size of a file as an identifier of the files. It transfers the files from a specified local storage to a specified remote storage service via various transfer protocol (only Globus Toolkit is supported now).  The files on a remote storage are renamed and saved with the new filename that is equal to its hash value.  The database of a hash value and a size of files are recorded on a specified file (only pstore is supported now).

## Usage

* mmatransfer.rb

    ruby mmatransfer.rb [-d|--target-directory <target Directory name>] 
                        [-f|--target-file <target File name>]
                        [-i|--index-file <Index File Name>]
                        [-c|--config-file <Config File Name>]`
