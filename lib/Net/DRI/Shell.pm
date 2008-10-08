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
use Net::DRI::Util;
use Term::ReadLine; ## see also Term::Shell
use Time::HiRes ();

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

exit __PACKAGE__->run(@ARGV) if (!caller() || caller() eq 'PAR'); ## This is a modulino :-)

=pod

=head1 NAME

Net::DRI::Shell - Command Line Shell for Net::DRI, with batch features

=head1 SYNOPSYS

 perl -I../../ ./Shell.pm
 or
 perl -MNet::DRI::Shell -e run

 Welcome to Net::DRI experimental shell, version 1.02
 Net::DRI object created with TTL=10s

 NetDRI> add_registry registry=EURid clID=YOURLOGIN
 NetDRI(EURid)> new_current_profile name=profile1 type=epp defer=0 client_login=YOURLOGIN client_password=YOURPASSWORD
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

This is a shell to be able to use Net::DRI without writing any code.

Most of the time commands are the name of methods to use on the Net::DRI object,
with some extra ones and some variations in API to make passing parameters simpler.

=head1 AVAILABLE COMMANDS

After having started this shell, the available commands are the following.

=head2 SESSION COMMANDS

=head3 add_registry registry=REGISTRYNAME clID=YOURLOGIN

Replace REGISTRYNAME with the Net::DRI::DRD module you want to use, and YOURLOGIN
with your client login for this registry

=head3 new_current_profile name=profile1 type=epp defer=0 client_login=YOURLOGIN client_password=YOURPASSWORD [log_fh=FILENAME]

This will really connect to the registry, replace YOURLOGIN by your client login at registry,
and YOURPASSWORD by the associated password. You may have to add parameters remote_host= and remote_port=
to connect to other endpoints than the hardcoded default which is most of the time the registry OT&E server,
and not the production one !

If you provide a FILENAME with the log_fh attribute, this file will be open for write append and
the XML EPP exchanges with the registry will be dump in it.

=head3 get_info_all

After each call to the registry, like domain_info or domain_check, this will list all available data
retrieved from registry. Things are pretty-printed as much as possible. You should call get_info_all
right after your domain_something call otherwise if you do another operation previous information
is lost. This is done automatically for you on the relevant commands, but you can also use it 
manually at any time.

=head3 show profiles

Show the list of registries and associated profiles currently in use (opened in this shell with
add_registry + new_current_profile)

=head3 show tlds

Show the list of TLDs handled by the currently selected registry

=head3 show periods

Show the list of allowed periods (domain name durations) for the currently selected registry

=head3 show objects

Show the list of managed objects types at the currently selected registry

=head3 show status

Show the list of available status for the currently selected registry, to use
as status name in some commands below (domain_update_status_* host_update_status_* 
contact_update_status_*)

=head3 target X Y

Switch to registry X (from currently available registries) and profile Y (from currently available
profiles in registry X).

=head3 run FILENAME

Will open the local FILENAME and read in it commands and execute all of them ; you can also
start your shell with a filename as argument and its commands will be run at beginning of
session before giving the control back. They will be displayed (username and password will be
masked) with their results.

=head3 quit

Leave the shell.

=head2 DOMAIN COMMANDS

=head3 domain_info DOMAIN

Do a domain_info call to the registry for the domain YOURDOMAIN ; most of the the registries
prohibit getting information on domain names you do not sponsor.

=head3 domain_check DOMAIN

Do a domain_check call to the registry for the domain ANYDOMAIN ; you can check any domain,
existing or not, if you are the sponsoring registrar or not.

=head3 domain_exist DOMAIN

A kind of simpler domain_check, just reply by YES or NO for the given domain name.

=head3 domain_transfer_start DOMAIN auth=AUTHCODE [duration=PERIOD]

=head3 domain_transfer_stop DOMAIN [auth=AUTHCODE]

=head3 domain_transfer_query DOMAIN [auth=AUTHCODE]

=head3 domain_transfer_accept DOMAIN [auth=AUTHCODE]

=head3 domain_transfer_refuse DOMAIN [auth=AUTHCODE]

Start, or stop an incoming transfer, query status of a current running transfer, accept or refuse an outgoing domain name transfer.

The AUTHCODE is mandatory or optional, depending on the registry.

The duration is optional and can be specified (the allowed values depend on the registry) as Ayears or Bmonths
where A and B are integers for the number of years or months (this can be abbreviated as Ay or Bm).

=head3 domain_update_ns_set DOMAIN HOSTNAMEA IPA1 IPA2 ... HOSTNAMEB IPB1 IPB2 ...

=head3 domain_update_ns_add DOMAIN HOSTNAMEA IPA1 IPA2 ... HOSTNAMEB IPB1 IPB2 ...

=head3 domain_update_ns_del DOMAIN HOSTNAMEA IPA1 IPA2 ... HOSTNAMEB IPB1 IPB2 ...

Set the current list of nameservers associated to this DOMAIN, add to the current list or delete from the current list.

=head3 domain_update_status_set DOMAIN STATUS1 STATUS2 ...

=head3 domain_update_status_add DOMAIN STATUS1 STATUS2 ...

=head3 domain_update_status_del DOMAIN STATUS1 STATUS2 ...

Set the current list of status associated to this DOMAIN, add to the current
list or delete from the current list. First parameter is the domain name, then status names,
as needed.

The status names are those in the list given back by the show status command (see above).

=head3 domain_update_contact_set DOMAIN SRVID1 SRVID2 ...

=head3 domain_update_contact_add DOMAIN SRVID2 SRVID2 ...

=head3 domain_update_contact_del DOMAIN SRVID1 SRVID2 ...

Set the current list of contacts associated to this DOMAIN, add to the current list or delete from the current list
by providing the contact server ids.

=head3 domain_create DOMAIN [duration=X] [ns=HOSTNAMEA IPA1 IPA2 ... HOSTNAMEB IPB1 IPB2 ...] [admin=SRID1] [registrant=SRID2] [billing=SRID3] [tech=SRID4] [auth=X]

Create the given domain name. See above for the duration format to use. Admin, registrant, billing and tech
contact ids are mandatory or optional depending on the registry. They may be repeated (except registrant)
for registries allowing multiple contacts per role.

=head3 domain_renew DOMAIN [duration=X] [current_expiration=YYYY-MM-DD]

Renew the given domain name. Duration and current expiration are optional. See above for the duration format to use.

=head3 domain_delete DOMAIN

Delete the given domain name.


=head2 HOST COMMANDS

For registries handling nameservers as separate objects.

=head3 host_create HOSTNAME IP1 IP2 ...

Create the host named HOSTNAME at the registry with the list of IP (IPv4 and IPv6
depending on registry support) given.

=head3 host_delete HOSTNAME

=head3 host_info HOSTNAME

=head3 host_check HOSTNAME

Various operations on host objects.

=head3 host_update_ip_set HOSTNAME IP1 IP2 ...

=head3 host_update_ip_add HOSTNAME IP1 IP2 ...

=head3 host_update_ip_del HOSTNAME IP1 IP2 ...

Set the current list of IP addresses associated to this HOSTNAME, add to the current
list or delete from the current list. First parameter is the nameserver hostname, then IP addresses,
as needed.

=head3 host_update_status_set HOSTNAME STATUS1 STATUS2 ...

=head3 host_update_status_add HOSTNAME STATUS1 STATUS2 ...

=head3 host_update_status_del HOSTNAME STATUS1 STATUS2 ...

Set the current list of status associated to this HOSTNAME, add to the current
list or delete from the current list. First parameter is the nameserver hostname, then status names,
as needed.

The status names are those in the list given back by the show status command (see above).

=head3 host_update_name_set HOSTNAME NEWNAME

Change the current name of host objects from HOSTNAME to NEWNAME


=head2 CONTACT COMMANDS

For registries handling contacts as separate objects.

=head3 contact_create name=X org=Y street=Z1 street=Z2 email=A voice=B ...

Create a new contact object.

The list of mandatory attributes depend on the registry. Some attributes (like street) may appear multiple times.

Some registry allow setting an ID (using srid=yourchoice), others create the ID, in which case you need
to do a get_info_all after contact_create to retrieve the given server ID.

=head3 contact_delete SRID

=head3 contact_info SRID

=head3 contact_check SRID

Various operations on contacts.

=head3 contact_update_status_set SRID STATUS1 STATUS2 ...

=head3 contact_update_status_add SRID STATUS1 STATUS2 ...

=head3 contact_update_status_del SRID STATUS1 STATUS2 ...

Set the current list of status associated to this contact SRID, add to the current
list or delete from the current list. First parameter is the contact server ID, then status names,
as needed.

The status names are those in the list given back by the show status command (see above).

=head3 contact_transfer_start SRID

=head3 contact_transfer_stop SRID

=head3 contact_transfer_query SRID

=head3 contact_transfer_accept SRID

=head3 contact_transfer_refuse SRID

Start, or stop an incoming transfer, query status of a current running transfer, accept or refuse an outgoing contact transfer.


=head2 MESSAGE COMMANDS

For registries handling messages, like EPP poll features.

=head3 message_retrieve [ID]

Retrieve a message waiting at registry

=head3 message_delete [ID]

Delete a message waiting at registry

=head3 message_waiting

Notifies if messages are waiting at registry

=head3 message_count

Get the numbers of messages waiting at the registry

=head1 BATCH OPERATIONS

Batch operations are available for some domain name commands: domain_create,
domain_delete, domain_renew, domain_check, domain_info, domain_transfer and
all domain_update commands. It can be used on a list of domain names for which
all other parameters needed by the command are the same.

To do that, just use the command normally as outlined above, but instead of the
domain name, put a file path, with at least one / (so for a file batch.txt in the
current directory, use ./batch.txt)

The shell will then apply the command and its parameters on the domain names
listed in the specified file: you should have one domain name per line, blank
lines and lines starting with # are ignored.

At the same place a new file is created with a name derived from the given name
in which the result of each domain name command will be written. If input is 
the filename used, the results will be written to input.PID.TIME.results
where PID is the program id of the running shell for these commands and time the
Unix epoch when the batch started.

As output the shell will give a summary of the number of operations done
for each possible outcome (success or error), as well as time statistics.

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
 my (@args)=@_;
 my $term=Term::ReadLine->new('Net::DRI shell');
 my $ctx={ term    => $term,
           dprompt => 'NetDRI',
           output  => $term->OUT() || \*STDOUT,
         };
 $ctx->{prompt}=$ctx->{dprompt};
 my $oldfh=select($ctx->{output}); $|++; select($oldfh);

 output($ctx,"Welcome to Net::DRI experimental shell, version $VERSION\n");

 $ctx->{dri}=Net::DRI->new(10);
 output($ctx,"Net::DRI object created with TTL=10s\n\n");

 shift(@args) if ($args[0] eq 'Net::DRI::Shell');
 handle_line($ctx,'run '.$args[0]) if (@args);

 while (defined(my $l=$ctx->{term}->readline($ctx->{prompt}.'> '))) 
 {
  last if handle_line($ctx,$l);
 }
 $ctx->{dri}->end();
 return 0; ## TODO : should reflect true result of last command ?
}

sub output
{
 my $ctx=shift;
 print { $ctx->{output} } @_;
}

sub handle_file
{
 my ($ctx,$file)=@_;
 output($ctx,'Executing commands from file '.$file." :\n");
 open(my $ch,'<',$file) or die $!;
 while(defined(my $l=<$ch>))
 {
  chomp($l);
  next if ($l=~m/^\s*$/ || $l=~m/^#/);
  my $pl=$l;
  $pl=~s/(clID|client_login|client_password)=\S+/$1=********/g;
  output($ctx,$pl."\n");
  handle_line($ctx,$l);
 }
 close($ch) or die $!;
 return;
}

sub handle_line
{
 my ($ctx,$l)=@_;
 return 0 if ($l=~m/^\s*$/);
 return 1 if ($l eq 'quit' || $l eq 'q' || $l eq 'exit');

 $l=~s/^\s*//;
 $l=~s/\s*$//;

 my ($rc,$msg);
 eval 
 { 
  ($rc,$msg)=process($ctx,$l);
  $msg.="\n".(process($ctx,'get_info_all'))[1] if ($l=~m/^(?:(?:domain|contact|host)_(?:check|info|create)|domain_renew) / && index($msg,'on average')==-1);
 };
 if ($@)
 {
  output($ctx,"An error happened:\n");
  output($ctx,ref($@)? sprintf('EXCEPTION %d@%s : %s',$@->code(),$@->area(),$@->msg()) : $@);
  output($ctx,"\n");
 } else
 {
  output($ctx,$rc->as_string(1),"\n") if (defined($rc));
  output($ctx,$msg,"\n") if (defined($msg));
 }

 $ctx->{term}->addhistory($l);
 return 0;
}

sub process
{
 my ($ctx,$wl)=@_;
 my ($rc,$m);

 my ($cmd,$params)=split(/\s+/,$wl,2);
 my @p=split(/\s+/,$params);
 my %p;
 my @g=($params=~m/\s*(\S+)=(\S[^=]*)(?:\s|$)/g);
 while (@g)
 {
  my $n=shift(@g);
  my $v=shift(@g);
  if (exists($p{$n}))
  {
   $p{$n}=[$p{$n}] unless (ref($p{$n}) eq 'ARRAY');
   push @{$p{$n}},$v;
  } else
  {
   $p{$n}=$v;
  }
 }

 return handle_file($ctx,$p[0]) if ($cmd eq 'run');
 return do_dri($ctx,$cmd,\@p,\%p) if ($cmd=~m/^message_(?:retrieve|delete)$/); ## Not for contacts due to lc() !
 return do_domain($ctx,$cmd,\@p,\%p) if ($cmd=~m/^domain_(?:check|info)$/);
 return do_domain_transfer($ctx,$cmd,\@p,\%p) if ($cmd=~m/^domain_transfer_(?:start|stop|query|accept|refuse)$/);
 return do_domain_update_ns($ctx,$cmd,\@p,\%p) if ($cmd=~m/^domain_update_ns_(?:add|del|set)$/);
 return do_domain_update_status($ctx,$cmd,\@p,\%p) if ($cmd=~m/^domain_update_status_(?:add|del|set)$/);
 return do_domain_update_contact($ctx,$cmd,\@p,\%p) if ($cmd=~m/^domain_update_contact_(?:add|del|set)$/);

 if ($cmd=~m/^host_(?:create|delete|info|check|update_(?:ip|status|name)_(?:add|del|set))$/)
 {
  return (undef,'Registry does not support host objects') unless $ctx->{dri}->has_object('ns');
  return do_host($ctx,$cmd,\@p,\%p);
 }

 if ($cmd=~m/^contact_(?:create|delete|info|check|update|update_status_(?:add|del|set)|transfer_(?:start|stop|query|accept|refuse))$/)
 {
  return (undef,'Registry does not support contact objects') unless $ctx->{dri}->has_object('contact');
  return do_contact($ctx,$cmd,\@p,\%p);
 }

 {
  no strict 'refs'; ## no critic (ProhibitNoStrict)
  my $sub='do_'.$cmd;
  return $sub->($ctx,$cmd,\@p,\%p) if (exists(&$sub));
 }

 return (undef,'Unknown command '.$cmd);
}

sub do_add_registry
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $reg=$rh->{registry};
 delete($rh->{registry});
 $ctx->{dri}->add_registry($reg,$rh);
 $ctx->{dri}->target($reg);
 $ctx->{prompt}=$ctx->{dprompt}.'('.$reg.')';
 return;
}

sub do_target
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 $ctx->{dri}->target(@$ra);
 $ctx->{prompt}=$ctx->{dprompt}.'('.join(',',@$ra).')';
 return;
}

## only this variant is handled: name, type, transport params, protocol params
sub do_new_current_profile
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $name=$rh->{name};
 my $type=$rh->{type};
 my @p=split(/,/,$rh->{protocol}); ## not needed most of the time, otherwise find better API ?
 delete(@{$rh}{qw/name type protocol/});
 if (exists($rh->{log_fh}))
 {
  open(my $fh,'>>',$rh->{log_fh}) || die $!;
  my $oldfh=select($fh); $|++; select($oldfh);
  $rh->{log_fh}=$fh;
 }
 my $rc=$ctx->{dri}->$cmd($name,$type,[$rh],\@p);
 if ($rc->is_success() && $cmd eq 'new_current_profile')
 {
  my @t=$ctx->{dri}->registry();
  $ctx->{prompt}=$ctx->{dprompt}.'('.$t[0].','.$t[1]->profile().')';
 }
 return ($rc,undef);
}

sub do_new_profile { return do_new_current_profile(@_); }

sub do_show
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $m='';
 if ($ra->[0] eq 'profiles')
 {
  my $rp=$ctx->{dri}->available_registries_profiles();
  foreach my $reg (sort(keys(%$rp)))
  {
   $m.=$reg.': '.join(' ',@{$rp->{$reg}})."\n";
  }
 } elsif ($ra->[0] eq 'tlds')
 {
  $m=join("\n",$ctx->{dri}->registry()->driver()->tlds());
 } elsif ($ra->[0] eq 'periods' || $ra->[0] eq 'durations')
 {
  $m=join("\n",map { pretty_string($_,0); } $ctx->{dri}->registry()->driver()->periods());
 } elsif ($ra->[0] eq 'objects')
 {
  $m=join("\n",$ctx->{dri}->registry()->driver()->object_types());
 } elsif ($ra->[0] eq 'status')
 {
  $m=join("\n",map { 'no'.$_ } $ctx->{dri}->local_object('status')->possible_no());
 }
 return (undef,$m);
}

sub do_get_info
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $m=$ctx->{dri}->get_info(@$ra); 
 return (undef,pretty_string($m,0));
}

sub do_get_info_all
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $rp=$ctx->{dri}->get_info_all(@$ra);
 my $m='';
 foreach my $k (sort(keys(%$rp)))
 {
  $m.=$k.': '.pretty_string($rp->{$k},0)."\n";
 }
 return (undef,$m);
}

sub do_dri
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 return ($ctx->{dri}->$cmd(@$ra),undef);
}

sub do_message_waiting
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $e=$ctx->{dri}->$cmd(@$ra);
 return (undef,'Unable to find if messages are waiting at the registry') unless defined($e);
 return (undef,'Messages waiting at the registry? '.($e? 'YES' : 'NO'));
}

sub do_message_count
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $e=$ctx->{dri}->$cmd(@$ra);
 return (undef,'Unable to find the number of messages waiting at the registry') unless defined($e);
 return (undef,'Number of messages waiting at the registry: '.$e);
}

sub do_domain
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $dom=shift(@$ra);
 return wrap_command_domain($ctx,$cmd,$dom);
}

sub do_domain_exist
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $e=$ctx->{dri}->$cmd(lc($ra->[0]));
 return (undef,'Unable to find if domain name '.$ra->[0].' exists') unless defined($e);
 return (undef,'Does domain name '.$ra->[0].' exists at registry? '.($e? 'YES' : 'NO'));
}

sub do_domain_transfer
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 build_auth($rh);
 build_duration($ctx,$rh);
 return wrap_command_domain($ctx,$cmd,$ra->[0],$rh);
}

sub do_domain_update_ns
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $dom=shift(@$ra);
 my $ns=build_hosts($ctx,$ra);
 return wrap_command_domain($ctx,$cmd,$dom,$ns);
}

sub do_domain_update_status
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $dom=shift(@$ra);
 my $s=build_status($ctx,$ra);
 return wrap_command_domain($ctx,$cmd,$dom,$s);
}

sub do_domain_update_contact
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $dom=shift(@$ra);
 my $cs=$ctx->{dri}->local_object('contactset');
 while(my ($type,$ids)=each(%$rh))
 {
  foreach my $id (ref($ids)? @$ids : ($ids))
  {
   $cs->add($ctx->{dri}->local_object('contact')->srid($id),$type);
  }
 }
 return wrap_command_domain($ctx,$cmd,$dom,$cs);
}

sub do_domain_create
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $dom=shift(@$ra);
 build_duration($ctx,$rh);
 build_auth($rh);
 $rh->{ns}=build_hosts($ctx,[split(/\s+/,$rh->{ns})]) if exists($rh->{ns});
 my $cs=$ctx->{dri}->local_object('contactset');
 foreach my $t (qw/admin registrant billing tech/)
 {
  next unless exists($rh->{$t});
  foreach my $c (ref($rh->{$t})? @{$rh->{$t}} : ($rh->{$t}))
  {
   $cs->add($ctx->{dri}->local_object('contact')->srid($c),$t);
  }
  delete($rh->{$t});
 }
 $rh->{contact}=$cs unless $cs->is_empty();
 $rh->{pure_create}=1;
 return wrap_command_domain($ctx,$cmd,$dom,$rh);
}

sub do_domain_renew
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $dom=shift(@$ra);
 build_duration($ctx,$rh);
 if (exists($rh->{current_expiration}))
 {
  my @t=split(/-/,$rh->{current_expiration});
  $rh->{current_expiration}=$ctx->{dri}->local_object('datetime','year' => $t[0], 'month' => $t[1], 'day' => $t[2]);
 }
 return wrap_command_domain($ctx,$cmd,$dom,$rh);
}

sub do_domain_delete
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my $dom=shift(@$ra);
 $rh->{pure_delete}=1;
 return wrap_command_domain($ctx,$cmd,$dom,$rh);
}

sub do_host
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my @p;
 if ($cmd eq 'host_create')
 {
  @p=build_hosts($ctx,$ra);
 } elsif ($cmd=~m/^host_update_ip_(?:add|del|set)$/)
 {
  my $h=shift(@$ra);
  @p=($h,build_hosts($ctx,[ $h, @$ra ]));
 } elsif ($cmd=~m/^host_update_status_(?:add|del|set)$/)
 {
  my $h=shift(@$ra);
  @p=($h,build_status($ctx,$ra));
 } else
 {
  @p=@$ra;
 }
 return ($ctx->{dri}->$cmd(@p),undef);
}

sub do_contact
{
 my ($ctx,$cmd,$ra,$rh)=@_;
 my @p;
 my $c=$ctx->{dri}->local_object('contact');
 if ($cmd eq 'contact_create')
 {
  build_contact($c,$rh);
 } elsif ($cmd=~m/^contact_update_status_(?:add|del|set)$/)
 {
  $c->srid(shift(@$ra));
  @p=(build_status($ctx,$ra));
 } elsif ($cmd eq 'contact_update')
 {
  $c->srid(shift(@$ra));
  my $toc=$ctx->{dri}->local_object('changes');
  my $c2=$ctx->{dri}->local_object('contact');
  build_contact($c2,$rh); 
  $toc->set('info',$c2);
  @p=($toc);
 } else
 {
  $c->srid(shift(@$ra));
  @p=@$ra;
 }
 return ($ctx->{dri}->$cmd($c,@p),undef);
}

####################################################################################################

sub wrap_command_domain
{
 my $ctx=shift;
 my $cmd=shift;
 my $dom=shift;
 return (undef,'Undefined domain name') unless (defined($dom) && $dom);

 if ($dom=~m!/!) ## Local file
 {
  return (undef,'Local file '.$dom.' does not exist or unreadable') unless (-e $dom && -r _);
  my $res=$dom.'.'.$$.'.'.time().'.results';
  open(my $fin,'<',$dom)  or return (undef,'Unable to read local file '.$dom.' : '.$!);
  open(my $fout,'>',$res) or return (undef,'Unable to write (for results) local file '.$res.' : '.$!);
  my $withinfo=($cmd eq 'domain_check' || $cmd eq 'domain_info')? 1 : 0;
  my @rc;
  my $tstart=Time::HiRes::time();
  while(defined(my $l=<$fin>))
  {
   chomp($l);
   my @r=($l);

   if (Net::DRI::Util::is_hostname($l))
   {
    my $rc=$ctx->{dri}->$cmd(lc($l),@_);
    push @r,$rc->as_string(1);
    push @r,$ctx->{dri}->get_info_all() if $withinfo;
   } else
   {
    push @r,'Invalid domain name';
   }
   push @rc,\@r;
   output($ctx,'.');
  }
  my $tstop=Time::HiRes::time();
  output($ctx,"\n");
  close($fin);

  my %r;
  ## We write the whole file at the end for better performances (but we opened it right at the beginning to test its writability)
  foreach my $rc (@rc)
  {
   my $l=shift(@$rc);
   my $rcm=shift(@$rc);
   if ($cmd eq 'domain_check')
   {
    my $rh=shift(@$rc);
    $rcm.=' exist='.$rh->{exist}.' exist_reason='.$rh->{exist_reason};
   } elsif ($cmd eq 'domain_info')
   {
    my $rh=shift(@$rc);
    $rcm.=' '.join(' ',map { $_.'=['.pretty_string($rh->{$_},0).']' } qw/clID crDate exDate contact ns status auth/);
   }
   print { $fout } $l,' ',$rcm,"\n";
   $r{$rcm}++;
  }
  close($fout);
  my $t=@rc;

  my $m=join("\n",map { sprintf('%d/%d (%.02f%%) : %s',$r{$_},$t,100*$r{$_}/$t,$_) } sort { $a cmp $b } keys(%r));
  $m.="\n".sprintf('%d operations in %d seconds, on average %.2f op/s = %.2f s/op',$t,$tstop-$tstart,$t/($tstop-$tstart),($tstop-$tstart)/$t);
  return (undef,$m);
 } else ## True domain name
 {
  return (undef,'Invalid domain name: '.$dom) unless Net::DRI::Util::is_hostname($dom);
  return ($ctx->{dri}->$cmd(lc($dom),@_),undef);
 }
}

####################################################################################################

sub build_contact
{
 my ($c,$rh)=@_;
 no strict 'refs'; ## no critic (ProhibitNoStrict)
 while(my ($m,$v)=each(%$rh))
 {
  $c->$m($v);
 }
}

sub build_status
{
 my ($ctx,$ra)=@_;
 my $s=$ctx->{dri}->local_object('status');
 foreach (@$ra) { s/^no//; $s->no($_); }
 return $s; 
}

sub build_hosts
{
 my ($ctx,$ra)=@_;
 my $ns=$ctx->{dri}->local_object('hosts');
 my ($name,@ips);
 foreach my $o (@$ra)
 {
  if ($o=~m/[a-z]/i) ## hostname (safe since at least the TLD is not numeric)
  {
   if (defined($name))
   {
    $ns->add($name,\@ips);
    $name=$o;
    @ips=();
   } else
   {
    $name=$o;
   }
  } else ## or IP address
  {
   push @ips,$o;
  }
 }
 $ns->add($name,\@ips);
 return $ns;
}

sub build_auth
{
 my $rd=shift;
 return unless exists($rd->{auth});
 $rd->{auth}={ pw => $rd->{auth} };
}

sub build_duration
{
 my ($ctx,$rd)=@_;
 return unless exists($rd->{duration});
 my ($v,$u)=($rd->{duration}=~m/^(\d+)(\S+)$/);
 $rd->{duration}=$ctx->{dri}->local_object('duration','years'  => $v) if ($u=~m/^y(?:ears?)?$/i);
 $rd->{duration}=$ctx->{dri}->local_object('duration','months' => $v) if ($u=~m/^m(?:onths?)?$/i);
}

sub pretty_string
{
 my ($v,$full)=@_;
 $full||=0;
 return $v unless ref($v);
 return join(' ',@$v) if (ref($v) eq 'ARRAY');
 return join(' ',map { $_.'='.$v->{$_} } keys(%$v)) if (ref($v) eq 'HASH');
 return ($full? "Ns:\n": '').$v->as_string(1) if ($v->isa('Net::DRI::Data::Hosts'));
 return ($full? "Contact:\n" : '').$v->as_string() if ($v->isa('Net::DRI::Data::Contact'));
 if ($v->isa('Net::DRI::Data::ContactSet'))
 {
  my @v;
  foreach my $t ($v->types())
  {
   push @v,$t.'='.join(',',map { pretty_string($_,$full) } $v->get($t));
  }
  return ($full? "ContactSet:\n" : '').join(' ',@v);
 }
 return ($full? "Status:\n" : '').join(' ',$v->list_status()) if ($v->isa('Net::DRI::Data::StatusList'));
 return ($full? "Command result:\n" : '').$v->as_string(1) if ($v->isa('Net::DRI::Protocol::ResultStatus'));
 return ($full? "Date:\n" : '').$v->set_time_zone('UTC')->strftime('%Y-%m-%d %T').' UTC' if ($v->isa('DateTime'));
 return ($full? "Duration:\n" : '').sprintf('P%dY%dM%dDT%dH%dM%dS',$v->in_units(qw/years months days hours minutes seconds/)) if ($v->isa('DateTime::Duration')); ## ISO8601
 return $v;
}

####################################################################################################
1;
