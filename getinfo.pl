#!/usr/bin/perl

use Socket;
use Net::DNS;

# getinfo.pl	-	Collect important information prior to performing a backup

# This script is run prior to a system backup (using dump) being taken.  Its puprose is to gather
# information which should prove useful in the event of system recovery being required.

# Whilst it would be useful for the host to have the package  facter  installed, this cannot be 
# guaranteed, so populate the hash with alternative commands 

# $facter_path=`which wibble`;
$facter_path=`which facter`;
chop($facter_path);    #get rid of trailling CR/NL

if (length($facter_path) ne 0) {
   %info_cmds = (
      "memswap","free -m",
      "hostid","facter fqdn",
      "kernel","uname -r",
      "model", "facter productname",
      "type", "facter virtual",
      "blkinfo","lsblk",
      "filesystems", "df -hP"
   );

} else {
   %info_cmds = (
      "memswap", "free -m",
      "hostid","hostname",
      "kernel","uname -r",
      "model", "echo \"N/A\"",
      "type", "echo \"N/A\"",
      "blkinfo","lsblk",
      "filesystems", "df -hP"
   );
}

if (-e "/etc/redhat-release") {
   $OS = `cat /etc/redhat-release`;
} else {
   $OS = `cat /etc/issue`;
}
$hostname=`$info_cmds{"hostid"}`;
chop($hostname);
$resolver = new Net::DNS::Resolver();
$reply = $resolver->query($hostname,'A');
if ($reply) {
  foreach my $rr ($reply->answer) {
    next unless $rr->type eq "A";
$ipaddr=$rr->address;
  }
}

print"#############################\n";
print"######## SYSTEM INFO ########\n";
print"#############################\n\n";
printf("Hostname:     %s",`$info_cmds{"hostid"}`);
printf("IP Address:   %s\n",$ipaddr);
printf("H/w Model:    %s",`$info_cmds{"model"}`);
printf("Server type:  %s\n",`$info_cmds{"type"}`);
printf("O/S:          %s",$OS);
printf("Kernel:       %s\n",`$info_cmds{"kernel"}`);
$mem=`$info_cmds{"memswap"}`;
printf("Memory:\n%s\n",$mem);
$blkinfo=`$info_cmds{"blkinfo"}`;
print"\n###########################\n";
printf("BLOCK DEVICES");
print"\n###########################\n";
printf("%s",$blkinfo);
$fsinfo=`$info_cmds{"filesystems"}`;
print"\n###########################\n";
printf("FILESYSTEMS");
print"\n###########################\n";
printf("%s",$fsinfo);
print"\n###########################\n";

## foreach $cmd (keys %info_cmds) {
## $command = $info_cmds{$cmd};
## #print "$command\n";
## print `$command`;
## #system($command);
## }
