## Domain Registry Interface, EPP Host commands (RFC3732)
##
## Copyright (c) 2005 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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
#########################################################################################

package Net::DRI::Protocol::EPP::Core::Host;

use strict;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::Hosts;
use Net::DRI::Protocol::EPP;
use Net::DRI::Protocol::EPP::Core::Status;

use DateTime::Format::ISO8601;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };
our $NS='urn:ietf:params:xml:ns:host-1.0';

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Core::Host - EPP Host commands (RFC3732) for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut


##########################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=( create => [ \&create, \&create_parse ],
           check  => [ \&check, \&check_parse ],
           info   => [ \&info, \&info_parse ],
           delete => [ \&delete ],
	   update => [ \&update ],
         );

 $tmp{check_multi}=$tmp{check};
 return { 'host' => \%tmp };
}

sub build_command
{
 my ($msg,$command,$hostname)=@_;
 my @n=map { UNIVERSAL::isa($_,'Net::DRI::Data::Hosts')? $_->get_names() : $_ } ((ref($hostname) eq 'ARRAY')? @$hostname : ($hostname));

 Net::DRI::Exception->die(1,'protocol/EPP',2,"Host name needed") unless @n;
 foreach my $n (@n)
 {
  Net::DRI::Exception->die(1,'protocol/EPP',2,'Host name needed') unless defined($n) && $n;
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid host name: '.$n) unless Net::DRI::Util::is_hostname($n);
 }

 $msg->command([$command,'host:'.$command,'xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"']);

 my @d=map { ['host:name',$_] } @n;
 return @d;
}

##################################################################################################
########### Query commands

sub check
{
 my ($epp,$ns)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'check',$ns);
 $mes->command_body(\@d);
}


sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkdata=$mes->get_content('chkData',$NS);
 return unless $chkdata;
 foreach my $cd ($chkdata->getElementsByTagNameNS($NS,'cd'))
 {
  my $c=$cd->firstChild;
  my $host;
  while($c)
  {
   my $n=$c->nodeName();
   if ($n eq 'host:name')
   {
    $host=$c->firstChild->getData();
    $rinfo->{host}->{$host}->{exist}=1-Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
   }
   if ($n eq 'host:reason')
   {
    $rinfo->{host}->{$host}->{exist_reason}=$c->firstChild->getData();
   }
   $c=$c->getNextSibling();
  }
 }
}

sub info
{
 my ($epp,$ns)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'info',$ns);
 $mes->command_body(\@d);
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_content('infData',$NS);
 return unless $infdata;

 $rinfo->{host}->{$oname}->{exist}=1;
 my (@s,@ip4,@ip6);

 my $c=$infdata->firstChild();
 while ($c) ## host:name is not used
 {
  my $name=$c->nodeName();
  next unless $name;
  if ($name=~m/^host:(clID|crID|upID)$/)
  {
   $rinfo->{host}->{$oname}->{$1}=$c->firstChild->getData();
  } elsif ($name=~m/^host:(crDate|upDate|trDate)$/)
  {
   $rinfo->{host}->{$oname}->{$1}=DateTime::Format::ISO8601->new()->parse_datetime($c->firstChild->getData());
  } elsif ($name eq 'host:roid')
  {
   $rinfo->{host}->{$oname}->{roid}=$c->firstChild->getData();
  } elsif ($name eq 'host:status')
  {
   push @s,Net::DRI::Protocol::EPP::parse_status($c);
  } elsif ($name eq 'host:addr')
  {
   my $ip=$c->firstChild->getData();
   my $ipv=$c->getAttribute('ip');
   push @ip4,$ip if ($ipv eq 'v4');
   push @ip6,$ip if ($ipv eq 'v6');
  }
  $c=$c->getNextSibling();
 }

 $rinfo->{host}->{$oname}->{status}=Net::DRI::Protocol::EPP::Core::Status->new(\@s);
 $rinfo->{host}->{$oname}->{self}=Net::DRI::Data::Hosts->new($oname,\@ip4,\@ip6);
}

############ Transform commands

sub create
{
 my ($epp,$ns)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'create',$ns);
 push @d,add_ip($ns);
 $mes->command_body(\@d);
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_content('creData',$NS);
 return unless $infdata;

 $rinfo->{host}->{$oname}->{exist}=1;
 my $c=$infdata->firstChild();
 while ($c) ## host:name is not used
 {
  my $name=$c->nodeName();
  if ($name=~m/^host:(crDate)$/)
  {
   $rinfo->{host}->{$oname}->{$1}=DateTime::Format::ISO8601->new()->parse_datetime($c->firstChild->getData());
  }
  $c=$c->getNextSibling();
 }
}

sub delete
{
 my ($epp,$ns)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'delete',$ns);
 $mes->command_body(\@d);
}

sub update
{
 my ($epp,$ns,$todo)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo." must be a Net::DRI::Data::Changes object") unless ($todo && UNIVERSAL::isa($todo,'Net::DRI::Data::Changes'));
 if ((grep { ! /^(?:add|del)$/ } $todo->types('ip')) ||
     (grep { ! /^(?:add|del)$/ } $todo->types('status')) ||
     (grep { ! /^(?:set)$/ } $todo->types('name'))
    )
 {
  Net::DRI::Exception->die(0,'protocol/EPP',11,'Only IP/status add/del or name set available for host');
 }

 my $nsadd=$todo->add('ip');
 my $nsdel=$todo->del('ip');
 my $sadd=$todo->add('status');
 my $sdel=$todo->del('status');
 my $newname=$todo->set('name');

 unless (defined($ns) && $ns)
 {
  $ns=$nsadd->get_names(1) if (defined($nsadd) && ref($nsadd) && UNIVERSAL::can($nsadd,'get_names'));
  $ns=$nsdel->get_names(1) if (defined($nsdel) && ref($nsdel) && UNIVERSAL::can($nsdel,'get_names'));
 }
 my @d=build_command($mes,'update',$ns);
 my (@add,@rem);
 push @add,add_ip($nsadd)    if $nsadd;
 push @add,$sadd->build_xml('host:status') if $sadd;
 push @rem,add_ip($nsdel)    if $nsdel;
 push @rem,$sdel->build_xml('host:status') if $sdel;

 push @d,['host:add',@add] if (@add);
 push @d,['host:rem',@rem] if (@rem);

 if (defined($newname) && $newname)
 {
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid host name: '.$newname) unless Net::DRI::Util::is_hostname($newname);
  push @d,['host:chg',['host:name',$newname]];
 }
 $mes->command_body(\@d);
}

sub add_ip
{
 my ($ns)=@_;
 return () unless (defined($ns) && ref($ns));
 my @ip;
 my ($name,$r4,$r6)=$ns->get_details(1);
 push @ip,map { ['host:addr',$_,{ip=>'v4'}] } @$r4 if @$r4;
 push @ip,map { ['host:addr',$_,{ip=>'v6'}] } @$r6 if @$r6;
 return @ip;
}

## TODO
## RFC3732 §3.2.6.  Offline Review of Requested Actions

#########################################################################################################
1;
