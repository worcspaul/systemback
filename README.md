# systemback
Collection of scripts to perform system backups

The idea behind these scripts is to dump complete ext3/ext4 filesystems to files on a remote server ready for them
to be subsequently backed up by some other method. The reasons for this are twofold:

1.	The most recent Full and Incremental backups are retained on disk and are thus immediately available in
	the event a full or partial restore is required.

2.	Enterprise backup software only needs to back up a handful of files to tape or VTL. Thus, if/when
	necessary to recover those files, the recovery process takes less time as the software doesn't have to
	build up a list of thousands (or even millions) of files to restore

The main script will read an input file listing filesystem mountpoints and dump filenames, separated by colons,
and will loop through each, performing the dump. When originally written, the script would write to a local, or 
NFS mounted filesystem but this required extra storage on the host being backed up, or the maintenance of an NFS
server, with problems being caused if the NFS link went away for any length of time.  Instead, the script now
sends its output to STDOUT and pipes that to an SSH command executing dd on the remote server:


/usr/bin/dump 0uf - / |ssh -i SSH_KEY.pub backup@remoteserver.com "dd of=/backups/FQDN-of-source/Full/root.dump"



