## Domain Registry Interface, .UK EPP Domain commands
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

package Net::DRI::Protocol::EPP::Extensions::Nominet::Domain;

use strict;


use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::Hosts;
use Net::DRI::Protocol::EPP::Core::Domain;
use Net::DRI::Protocol::EPP::Extensions::Nominet::Account;
use Net::DRI::Protocol::EPP::Extensions::Nominet::Host;

use DateTime::Format::ISO8601;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Nominet::Domain - .UK EPP Domain commands  for Net::DRI

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
		check  => [ \&Net::DRI::Protocol::EPP::Core::Domain::check, \&Net::DRI::Protocol::EPP::Core::Domain::check_parse ],
		info   => [ \&info, \&info_parse ],
		delete => [ \&Net::DRI::Protocol::EPP::Core::Domain::delete ],
		renew => [ \&renew, \&Net::DRI::Protocol::EPP::Core::Domain::renew_parse ],
		transfer_request => [ \&transfer_request ],
		transfer_answer  => [ \&transfer_answer ],
         );

 $tmp{check_multi}=$tmp{check};
 return { 'domain' => \%tmp };
}

####################################################################################################
########### Query commands

sub info
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Core::Domain::build_command($mes,'info',$domain);
 $mes->command_body(\@d);
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_content('infData',$mes->ns('domain'));
 return unless $infdata;

 my $pd=DateTime::Format::ISO8601->new();
 my $ns=Net::DRI::Data::Hosts->new();
 my $c=$infdata->getFirstChild();
 while ($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  next unless $name;
  if ($name eq 'name')
  {
   $oname=lc($c->getFirstChild()->getData());
   $rinfo->{domain}->{$oname}->{action}='info';
   $rinfo->{domain}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(reg-status|first-bill|recur-bill|auto-bill|next-bill|notes)$/)
  {
   ## See http://www.nominet.org.uk/registrars/systems/data/fields/
   $rinfo->{domain}->{$oname}->{$1}=$c->getFirstChild()->getData();
  } elsif ($name eq 'account')
  {
   my $cs=Net::DRI::Protocol::EPP::Extensions::Nominet::Account::parse_infdata($po,$mes,$c->getElementsByTagNameNS($mes->ns('account'),'infData')->shift(),undef,$rinfo);
   $rinfo->{domain}->{$oname}->{contact}=$cs;
  } elsif ($name eq 'ns')
  {
   foreach my $nsinf ($c->getElementsByTagNameNS($mes->ns('ns'),'infData'))
   {
    my $dh=Net::DRI::Protocol::EPP::Extensions::Nominet::Host::parse_infdata($po,$mes,$nsinf,undef,$rinfo);
    my @a=$dh->get_details(1);
    $ns->add(@a,1);
   }
   ## We loose here roid, clId, crId, crDate, upId, upDate, but this seems useless in a domain_info call ! They can always be accessed indirectly if really needed (see test file)
  } elsif ($name=~m/^(clID|crID|upID)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$c->getFirstChild()->getData();
  } elsif ($name=~m/^(crDate|upDate|exDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$pd->parse_datetime($c->getFirstChild()->getData());
  }
 } continue { $c=$c->getNextSibling(); }

 $rinfo->{domain}->{$oname}->{ns}=$ns;
}

############ Transform commands ####################################################################

sub renew
{
 my ($epp,$domain,$rd)=@_;
 my $period=Net::DRI::Protocol::EPP::Core::Domain::verify_rd($rd,'duration')? $rd->{duration} : undef;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Core::Domain::build_command($mes,'renew',$domain);
 if (defined($period))
 {
  Net::DRI::Util::check_isa($period,'DateTime::Duration');
  push @d,Net::DRI::Protocol::EPP::Core::Domain::build_period($period);
 }

 $mes->command_body(\@d);
}

sub transfer_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Core::Domain::build_command($mes,['transfer',{'op'=>'request'}],$domain);

 Net::DRI::Exception::usererr_insufficient_parameters('Extra parameters must be provided for domain transfer request, at least a registrar_tag') unless (defined($rd) && (ref($rd) eq 'HASH') && exists($rd->{registrar_tag}));
 Net::DRI::Exception::usererr_invalid_parameters('Registrar tag must be an XML token from 2 to 16 characters') unless Net::DRI::Util::xml_is_token($rd->{registrar_tag},2,16);
 push @d,['domain:registrar-tag',$rd->{registrar_tag}];

 if (exists($rd->{account_id}) && defined($rd->{account_id}))
 {
  my $id=(ref($rd->{account_id}) eq 'Net::DRI::Data::ContactSet')? $rd->{account_id}->get('registrant')->srid() : $rd->{account_id};
  Net::DRI::Exception::usererr_invalid_parameters('Account id must be an XML token with pattern [0-9]*(-UK)?') unless (Net::DRI::Util::xml_is_token($id) && $id=~m/^\d+(?:-UK)?$/);
  push @d,['domain:account',['domain:account-id',$id]];
 }
 $mes->command_body(\@d);
}

sub transfer_answer
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 $mes->command([['transfer',{'op'=>(Net::DRI::Protocol::EPP::Core::Domain::verify_rd($rd,'approve') && $rd->{approve})? 'approve' : 'reject'}]]);

 Net::DRI::Exception::usererr_insufficient_parameters('Extra parameters must be provided for domain transfer request, at least a case_id') unless (defined($rd) && (ref($rd) eq 'HASH') && exists($rd->{case_id}));
 Net::DRI::Exception::usererr_invalid_parameters('Case id must be an XML token up to 12 characters') unless Net::DRI::Util::xml_is_token($rd->{case_id},undef,12);

 my @ns=@{$mes->ns()->{notifications}};
 my @d=['n:rcCase',{ 'xmlns:n' => $ns[0], 'xsi:schemaLocation' => $ns[0].' '.$ns[1]},['n:case-id',$rd->{case_id}]];
 $mes->command_body(\@d);
}

####################################################################################################
1;
