#	In the following instructions <BACKUPHOME> refers to the location of these scripts.
#	By default, this will be  /usr/local/backups

PRE-REQUISITES

1.	The dump and restore commands must be present on the system:

	RedHat/CentOS
	sudo yum install dump -y

	Debian/Ubuntu/Mint:
	sudo apt-get install dump

2.	A file FS.INI stored in <BACKUPHOME> listing filesystem mountpoints and dumpfiles, separated by colons, e.g

	/:root.dump
	/home:home.dump
	/usr/local:usr_local.dump

3.	The backup server will need a mountpoint  /backups  with sufficient storage to accommodate the dumps.
	Within this filesystem create the directories to hold the backups:

	mkdir -p /backups/<FQDN-of-host>/Full /backups/<FQDN-of-host>/Inc

	Example: 	mkdir -p /backups/myserver.mydomain.com/Full /backups/myserver.mydomain.com/Inc

	(NOTE: If you only ever intend to take Full backups, the Inc directory can be omitted)

4.	The user  backup  must exist on the backup server and have persmissions to store the dump files within /backups

5.	A passphrase-less SSH key needs to be created for root on each host being backed up and sent to the backup server

	cd <BACKUPHOME>
	ssh-keygen -t ed25519 -a 500 -f SSH_KEY

	Press RETURN when prompted for a passphrase

	Add key to authorized_keys file for backup user on the backup server

	ssh-copy-id -i SSH_KEY.pub backup@backupserver.mydomain.com


###########

getinfo.pl

This script can optionally be run in order to gather information about the system being backed
up which may prove useful in a Disaster Recovery situation.

backupsys.pl

This script reads the input file and, having checked if the filesystem is mounted, executes th
