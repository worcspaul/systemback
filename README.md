# systemback
Collection of scripts to perform system backups

These scripts are used to dump complete ext3/ext4 (future support will include xfs) filesystems to files on a remote
server ready for them to be subsequently backed up by some other method. 

PRE-REQUISITES

The dump and restore commands must be present on the system:

RedHat/CentOS
	sudo yum install dump -y

Debian/Ubuntu/Mint:
	sudo apt-get install dump

A file listing filesystem mountpoints and dumpfiles, separated by colons, e.g

/:root.dump
/home:home.dump
/usr/local:usr_local.dump

The user  backup  must exist on the remote host and have persmissions to store the dump files

A passphrase-less SSH key needs to be created for root on each host being backed up and sent to the target host



###########

getinfo.pl

This script can optionally be run in order to gather information about the system being backed
up which may prove useful in a Disaster Recovery situation.

backupsys.pl

This script reads the input file and, having checked if the filesystem is mounted, executes th
