## Domain Registry Interface, EPP Host commands (RFC3732)
##
## Copyright (c) 2005,2006,2007 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Core::Host;

use strict;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::Hosts;
use Net::DRI::Protocol::EPP;

use DateTime::Format::ISO8601;

our $VERSION=do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

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

Copyright (c) 2005,2006,2007 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=( create => [ \&create, \&create_parse ],
           check  => [ \&check, \&check_parse ],
           info   => [ \&info, \&info_parse ],
           delete => [ \&delete ],
	   update => [ \&update ],
           review_complete => [ undef, \&pandata_parse ],
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

 my @ns=@{$msg->ns->{host}};
 $msg->command([$command,'host:'.$command,sprintf('xmlns:host="%s" xsi:schemaLocation="%s %s"',$ns[0],$ns[0],$ns[1])]);

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

 my $chkdata=$mes->get_content('chkData',$mes->ns('host'));
 return unless $chkdata;
 foreach my $cd ($chkdata->getElementsByTagNameNS($mes->ns('host'),'cd'))
 {
  my $c=$cd->getFirstChild();
  my $host;
  while($c)
  {
   my $n=$c->localname() || $c->nodeName();
   if ($n eq 'name')
   {
    $host=lc($c->getFirstChild()->getData());
    $rinfo->{host}->{$host}->{action}='check';
    $rinfo->{host}->{$host}->{exist}=1-Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
   }
   if ($n eq 'reason')
   {
    $rinfo->{host}->{$host}->{exist_reason}=$c->getFirstChild()->getData();
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

 my $infdata=$mes->get_content('infData',$mes->ns('host'));
 return unless $infdata;

 my (@s,@ip4,@ip6);
 my $c=$infdata->getFirstChild();
 while ($c)
 {
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'name')
  {
   $oname=lc($c->getFirstChild()->getData());
   $rinfo->{host}->{$oname}->{action}='info';
   $rinfo->{host}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(clID|crID|upID)$/)
  {
   $rinfo->{host}->{$oname}->{$1}=$c->getFirstChild()->getData();
  } elsif ($name=~m/^(crDate|upDate|trDate)$/)
  {
   $rinfo->{host}->{$oname}->{$1}=DateTime::Format::ISO8601->new()->parse_datetime($c->getFirstChild()->getData());
  } elsif ($name eq 'roid')
  {
   $rinfo->{host}->{$oname}->{roid}=$c->getFirstChild()->getData();
  } elsif ($name eq 'status')
  {
   push @s,Net::DRI::Protocol::EPP::parse_status($c);
  } elsif ($name eq 'addr')
  {
   my $ip=$c->getFirstChild()->getData();
   my $ipv=$c->getAttribute('ip');
   $ipv='v4' unless (defined($ipv) && $ipv);
   push @ip4,$ip if ($ipv eq 'v4');
   push @ip6,$ip if ($ipv eq 'v6');
  }
  $c=$c->getNextSibling();
 }

 $rinfo->{host}->{$oname}->{status}=$po->create_local_object('status')->add(@s);
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

 my $infdata=$mes->get_content('creData',$mes->ns('host'));
 return unless $infdata;

 my $c=$infdata->getFirstChild();
 while ($c) ## host:name is not used
 {
  my $name=$c->localname() || $c->nodeName();
  next unless $name;
 
  if ($name eq 'name')
  {
   $oname=lc($c->getFirstChild()->getData());
   $rinfo->{host}->{$oname}->{action}='create';
   $rinfo->{host}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(crDate)$/)
  {
   $rinfo->{host}->{$oname}->{$1}=DateTime::Format::ISO8601->new()->parse_datetime($c->getFirstChild()->getData());
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

####################################################################################################
## RFC3732 §3.2.6  Offline Review of Requested Actions

sub pandata_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $pandata=$mes->get_content('panData',$mes->ns('host'));
 return unless $pandata;

 my $c=$pandata->firstChild();
 while ($c)
 {
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'name')
  {
   $oname=lc($c->getFirstChild()->getData());
   $rinfo->{host}->{$oname}->{action}='create_review';
   $rinfo->{host}->{$oname}->{result}=Net::DRI::Util::xml_parse_boolean($c->getAttribute('paResult'));
   $rinfo->{host}->{$oname}->{exist}=$rinfo->{host}->{$oname}->{result};
  } elsif ($name eq 'paTRID')
  {
   my @tmp=$c->getElementsByTagNameNS($mes->ns('_main'),'clTRID');
   $rinfo->{host}->{$oname}->{trid}=$tmp[0]->getFirstChild()->getData() if (@tmp && $tmp[0]);
   $rinfo->{host}->{$oname}->{svtrid}=($c->getElementsByTagNameNS($mes->ns('_main'),'svTRID'))[0]->getFirstChild()->getData();
  } elsif ($name eq 'paDate')
  {
   $rinfo->{host}->{$oname}->{date}=DateTime::Format::ISO8601->new()->parse_datetime($c->firstChild->getData());
  }
  $c=$c->getNextSibling();
 }
}

####################################################################################################
1;
