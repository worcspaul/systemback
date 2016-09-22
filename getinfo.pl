#!/usr/bin/perl

#====================================================================
# collect_info	 - Collect useful information
#====================================================================
sub collect_info {

   $hostname=`hostname`;
         $memswap= `free -m`;
         $hostid=`hostname`;
         $kernel=`uname -r`;
         $model= "N/A";
         $type= "N/A";
         $blkinfo=`lsblk`;
         $filesystems= `df -hP`;

   if (-e "/etc/redhat-release") {
      $OS = `cat /etc/redhat-release`;
   } else {
      $OS = `cat /etc/issue`;
   }
#   chop($hostname);
#   $resolver = new Net::DNS::Resolver();
#   $reply = $resolver->query($hostname,'A');
#   if ($reply) {
#     foreach my $rr ($reply->answer) {
#       next unless $rr->type eq "A";
#      $ipaddr=$rr->address;
#     }
#   }
}

#====================================================================
# write_info	 - write info to file
#====================================================================
#
sub write_info {
print"#############################\n";
print"######## SYSTEM INFO ########\n";
print"#############################\n\n";
printf("Hostname:     %s",$hostname);
#printf("IP Address:   %s",$ipaddr);
printf("H/w Model:    %s",$model);
printf("Server type:  %s",$svrtype);
printf("O/S:          %s",$OS);
printf("Kernel:       %s",$kernel);
printf("Memory:\n%s\n",$memswap);
print"\n###########################\n";
printf("BLOCK DEVICES");
print"\n###########################\n";
printf("%s",$blkinfo);
print"\n###########################\n";
printf("FILESYSTEMS");
print"\n###########################\n";
printf("%s",$filesystems);
print"\n###########################\n";

}

&collect_info;
&write_info;

