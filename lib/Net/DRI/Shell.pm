## Domain Registry Interface, Shell interface
##
## Copyright (c) 2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#
# 
#
####################################################################################################

package Net::DRI::Shell;

use strict;
use Net::DRI;
use Term::ReadLine; ## see also Term::Shell

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };
our $DRI;
our %VAR;
our $DPROMPT='NetDRI';

exit __PACKAGE__->run(@ARGV) if (!caller() || caller() eq 'PAR'); ## This is a modulino :-)

=pod

=head1 NAME

Net::DRI::Shell - (Experimental) Shell for Net::DRI

=head1 SYNOPSYS

 perl -I../../ ./Shell.pm
 or
 perl -MNet::DRI::Shell -e run

 Welcome to Net::DRI experimental shell, version 0
 Net::DRI object created with TTL=10s

 NetDRI> add_registry EURid clID YOURLOGIN
 NetDRI(EURid)> new_current_profile profile1 epp defer=0 client_login=YOURLOGIN client_password=YOURPASSWORD
 Profile profile1 added successfully (1000/COMMAND_SUCCESSFUL) SUCCESS
 NetDRI(EURid,profile1)> domain_info example.eu
 Command completed successfully (1000/1000) SUCCESS
 NetDRI(EURid,profile1)> get_info_all

 ... all data related to the domain name queried ...

 NetDRI(EURid,profile1)> domain_check whatever.eu
 Command completed successfully (1000/1000) SUCCESS
 NetDRI(EURid,profile1)> get_info_all

 ... all data related to the domain name queried ...

 NetDRI(EURid,profile1)> show profiles
 EURid: profile1
 NetDRI(EURid,profile1)> quit


=head1 DESCRIPTION

This is an experimental shell to be able to use Net::DRI without writing any code.
For now, domain_check and domain_info operations should work with all real-time registries.
Most of the time commands are the name of methods to use on the Net::DRI object,
with some extra ones and some variations in API to make passing parameters simpler.

WARNING: the API is not finalized, everything can change in future versions, based
on feedback, suggestions, problems, needs, etc.

After having started this shell, the available commands are:

=head2 add_registry REGISTRYNAME clID YOURLOGIN

Replace REGISTRYNAME with the Net::DRI::DRD module you want to use, and YOURLOGIN
with your client login for this registry

=head2 new_current_profile profile1 epp defer=0 client_login=YOURLOGIN client_password=YOURPASSWORD

This will really connect to the registry, replace YOURLOGIN by your client login at registry,
and YOURPASSWORD by the associated password. You may have to add parameters remote_host= and remote_port=
to connect to other endpoints than the hardcoded default which is most of the time the registry OT&E server,
and not the production one !

=head2 domain_info YOURDOMAIN

Do a domain_info call to the registry for the domain YOURDOMAIN ; most of the the registries
prohibit getting information on domain names you do not sponsor.

=head2 domain_check ANYDOMAIN

Do a domain_check call to the registry for the domain ANYDOMAIN ; you can check any domain,
existing or not, if you are the sponsoring registrar or not.

=head2 get_info_all

After each call to the registry, like domain_info or domain_check, this will list of available data
retrieved from registry. Things are pretty-printed as much as possible. You should call get_info_all
right after your domain_something call otherwise if you do another operation previous information
is lost.

=head2 show profiles

Show the list of registries and associated profiles currently in use (opened in this shell with
add_registry + new_current_profile)

=head2 target X Y

Switch to registry X (from currently available registries) and profile Y (from currently available
profiles in registry X).

=head2 quit

Leave this shell.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2008 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub run
{
 my $term=Term::ReadLine->new('Net::DRI shell');
 my $prompt=$DPROMPT;
 my $OUT=$term->OUT() || \*STDOUT;

 print "Welcome to Net::DRI experimental shell, version $VERSION\n";

 $DRI=Net::DRI->new(10);
 print "Net::DRI object created with TTL=10s\n\n";

 while (defined(my $l=$term->readline($prompt.'> '))) 
 {
  next if ($l=~m/^\s*$/);
  if ($l eq 'quit' || $l eq 'q' || $l eq 'exit')
  {
   $DRI->end();
   last;
  }
  $l=~s/^\s*//;
  $l=~s/\s*$//;
  my ($cmd)=($l=~m/^(\S+)(?:\s|$)/);

  my ($rc,$msg,$newprompt);
  eval 
  {
   ($rc,$msg,$newprompt)=process($cmd,$l);
  };
  
  if ($@)
  {
   print $OUT 'An error happened:',"\n";
   if (ref($@))
   {
    print $OUT $@->as_string();
   } else
   {
    print $OUT $@;
   }
  } else
  {
   print $OUT $rc->as_string(1),"\n" if (defined($rc));
   print $OUT $msg,"\n" if (defined($msg));
  }
  $prompt=$newprompt if (defined($newprompt) && $newprompt);
  $term->addhistory($l);
 }

 return 0; ## TODO : should reflect true result of last command ?
}


sub process
{
 my ($cmd,$wl)=@_;
 my ($rc,$m,$p);
 my @l=split(/\s+/,$wl);
 shift(@l); ## $cmd
 my $var;

 if ($cmd eq 'add_registry')
 {
  my $reg=shift(@l);
  $DRI->add_registry($reg,{ @l });
  $DRI->target($reg);
  $p=$DPROMPT.'('.$reg.')';
 } elsif ($cmd eq 'target')
 {
  $DRI->target(@l);
  $p=$DPROMPT.'('.join(',',@l).')';
 } elsif ($cmd eq 'new_profile' || $cmd eq 'new_current_profile')
 {
  ## only this variant is handled: name, type, transport params, protocol params
  my $name=shift(@l);
  my $type=shift(@l);
  my %t=();
  my @p=();
  foreach my $o (@l)
  {
   if (my ($k,$v)=($o=~m/^(\S+)\s*=\s*(\S+)$/))
   {
    $t{$k}=$v;
   } else
   {
    push @p,$o;
   }
  }
  $rc=$DRI->$cmd($name,$type,[\%t],\@p);
  return $rc unless $rc->is_success();
  if ($cmd eq 'new_current_profile')
  {
   my @t=$DRI->registry();
   $p=$DPROMPT.'('.$t[0].','.$t[1]->profile().')';
  }
 } elsif (($var)=($cmd=~m/^([A-Z0-9]+)=new_contact/))
 {
  $VAR{$var}=$DRI->local_object('contact');
  $wl=~s/^$cmd\s*//;
  while ($wl=~s/^(\S+?)\((.+?)\)(?:\s*|$)//g)
  {
   my ($method,$params)=($1,$2);
   $VAR{$var}->$method($params);
  }
 } elsif (($var)=($cmd=~m/^([A-Z0-9]+)/))
 {
  if (exists($VAR{$var}))
  {
   $wl=~s/^$var\s*//;
   while ($wl=~s/^(\S+?)\((.+?)\)(?:\s*|$)//g)
   {
    my ($method,$params)=($1,$2);
    $VAR{$var}->$method($params);
   }
  } else
  {
   $m='Unknown local variable '.$var;
  }
 } elsif ($cmd eq 'show')
 {
  if ($l[0] eq 'profiles')
  {
   my $rh=$DRI->available_registries_profiles();
   foreach my $reg (sort(keys(%$rh)))
   {
    $m.=$reg.': '.join(' ',@{$rh->{$reg}})."\n";
   }
  } else
  {
   $m=exists($VAR{$l[0]})? pretty_string($VAR{$l[0]},1) : 'Unknown local variable '.$l[0];
  }
 } elsif ($cmd eq 'get_info')
 {
  $m=$DRI->get_info(@l);
 } elsif ($cmd eq 'get_info_all')
 {
  my $rh=$DRI->get_info_all(@l);
  foreach my $k (sort(keys(%$rh)))
  {
   $m.=$k.': '.pretty_string($rh->{$k},0)."\n";
  }
 } elsif ($cmd=~m/^domain_\S+$/)
 {
  $rc=$DRI->$cmd(@l);
 } else
 {
  $m='Unknown command '.$cmd;
 }

 return ($rc,$m,$p);
}

sub pretty_string
{
 my ($v,$full)=@_;
 $full||=0;
 return $v unless ref($v);
 return join(' ',@$v) if (ref($v) eq 'ARRAY');
 return $full? "Ns:\n".$v->as_string(1) : $v->as_string(1) if ($v->isa('Net::DRI::Data::Hosts'));
 return $full? "Contact:\n".$v->as_string() : $v->as_string() if ($v->isa('Net::DRI::Data::Contact'));
 if ($v->isa('Net::DRI::Data::ContactSet'))
 {
  my @v;
  foreach my $t ($v->types())
  {
   push @v,'['.$t.'] '.join(' ',map { pretty_string($_,$full) } $v->get($t));
  }
  return $full? "ContactSet:\n".join("\n",@v) : join(' ',@v);
 }
 return $full? "Status:\n".join(' ',$v->list_status()) : join(' ',$v->list_status()) if ($v->isa('Net::DRI::Data::StatusList'));
 return $full? "Command result:\n".$v->as_string(1) : $v->as_string(1) if ($v->isa('Net::DRI::Protocol::ResultStatus'));
 return $full? "Date:\n".$v->set_time_zone('UTC')->strftime('%Y-%m-%d %T').' UTC' : $v->set_time_zone('UTC')->strftime('%Y-%m-%d %T').' UTC' if ($v->isa('DateTime'));
 ## TODO : DateTime::Duration
 return $v;
}

####################################################################################################
1;
