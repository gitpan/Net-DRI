## Domain Registry Interface, OpenSRS XCP Domain commands
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

package Net::DRI::Protocol::OpenSRS::XCP::Domain;

use strict;

use DateTime::Format::ISO8601;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Data::ContactSet;
use Net::DRI::Data::Contact;
use Net::DRI::Data::Hosts;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::OpenSRS::XCP::Domain - OpenSRS XCP Domain commands for Net::DRI

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

Copyright (c) 2008 Patrick Mevzek <netdri@dotandco.com>.
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
 my %tmp=(
		info => [\&info, \&info_parse ],
	  );

 return { 'domain' => \%tmp };
}

sub build_msg_cookie
{
 my ($msg,$action,$cookie,$regip)=@_;
 my %r=(action=>$action,object=>'domain',cookie=>$cookie);
 $r{registrant_ip}=$regip if defined($regip);
 $msg->command(\%r);
}

sub info
{
 my ($xcp,$domain,$rd)=@_;
 my $msg=$xcp->message();
 Net::DRI::Exception::usererr_insufficient_parameters('A cookie is needed for domain_info') unless Net::DRI::Util::has_key($rd,'cookie');
 build_msg_cookie($msg,'get',$rd->{cookie},$rd->{registrant_ip});
 $msg->command_attributes({type => 'all_info'});

}

sub info_parse
{
 my ($xcp,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$xcp->message();
 return unless $mes->is_success();

 $rinfo->{domain}->{$oname}->{action}='info';
 $rinfo->{domain}->{$oname}->{exist}=1;
 my $pd=DateTime::Format::ISO8601->new();
 my $ra=$mes->response_attributes(); ## Not parsed: dns_errors, descr

 my %d=(registry_createdate => 'crDate', registry_expiredate => 'exDate', registry_updatedate => 'upDate', registry_transferdate => 'trDate', expiredate => 'exDateLocal');
 while (my ($k,$v)=each(%d))
 {
  next unless exists($ra->{$k});
  $ra->{$k}=~s/ /T/; ## with a little effort we become ISO8601
  $rinfo->{domain}->{$oname}->{$v}=$pd->parse_datetime($ra->{$k});
 }

 my $ns=$ra->{nameserver_list};
 if (defined($ns) && ref($ns) && @$ns)
 {
  my $nso=Net::DRI::Data::Hosts->new();
  foreach my $h (@$ns)
  {
   $nso->add($h->{name},[$h->{ipaddress}]);
  }
  $rinfo->{domain}->{$oname}->{ns}=$nso;
 }

 foreach my $bool (qw/sponsoring_rsp auto_renew let_expire/)
 {
  next unless exists($ra->{$bool});
  $rinfo->{domain}->{$oname}->{$bool}=$ra->{$bool};
 }

 my $c=$ra->{contact_set};
 if (defined($c) && ref($c) && keys(%$c))
 {
  my $cs=Net::DRI::Data::ContactSet->new();
  while (my ($type,$v)=each(%$c))
  {
   my $c=parse_contact($v);
   $cs->add($c,$type eq 'owner'? 'registrant' : $type);
  }
  $rinfo->{domain}->{$oname}->{contact}=$cs;
 }

 ## No data about status ?
}

sub parse_contact
{
 my $rh=shift;
 my $c=Net::DRI::Data::Contact->new();
 ## No ID given back ! Waouh that is great... not !
 my $n1=$rh->{first_name};
 my $n2=$rh->{last_name};
 if (defined($n1))
 {
  if (defined($n2))
  {
   $c->name($n1.', '.$n2);
  } else
  {
   $c->name($n1);
  }
 } else
 {
  $c->name($n2) if defined($n2);
 }
 $c->org($rh->{org_name}) if exists($rh->{org_name});
 $c->street([map { $rh->{'address'.$_} } grep {exists($rh->{'address'.$_}) && defined($rh->{'address'.$_}) } (1,2,3)]);
 $c->city($rh->{city}) if exists($rh->{city});
 $c->sp($rh->{state}) if exists($rh->{state});
 $c->pc($rh->{postal_code}) if exists($rh->{postal_code});
 $c->cc($rh->{country}) if exists($rh->{country});
 $c->voice($rh->{phone}) if exists($rh->{voice});
 $c->fax($rh->{fax}) if exists($rh->{fax});
 $c->email($rh->{email}) if exists($rh->{email});
 return $c;
}

####################################################################################################
1;
