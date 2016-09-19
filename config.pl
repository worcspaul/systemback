#####################################################################
# Local settings - Update these to suit your environment
#####################################################################

# Paths to commands. We could use "which <command>" but would then have to chop off
# trailling CR/LF
 
$SSH             = "/usr/bin/ssh";
$BACKUP_COMMAND  = "/sbin/dump";
$RESTORE_COMMAND = "/sbin/restore";
$MAIL_COMMAND    = "/usr/bin/mailx";  # Path to mail client such as mailx. Could even be path to sendmail
$MAIL_RECIPIENT  = "my_email\@mydomain.com";     
$BACKUP_HOME     = "/backups";
$LOGPATH         = "/var/log/backups";

# FQDN of host to backup to
$BACKUPHOST      = "backupserver.example.com";  


#####################################################################
