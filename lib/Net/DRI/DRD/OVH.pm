## Domain Registry Interface, OVH Registry Driver
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
#########################################################################################

package Net::DRI::DRD::OVH;

use strict;
use base qw/Net::DRI::DRD/;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::DRD::OVH - OVH Registry driver for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 CURRENT LIMITATIONS

Only domain_info and account_list_domains are implemented for now

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

sub name { return 'OVH'; }
sub tlds { return qw/fr com net org info biz eu me.uk co.uk org.uk de be re es/; } ## As seen on http://www.ovh.com/fr/particulier/produits/domaines.xml
sub object_types { return ('domain'); }

sub transport_protocol_compatible 
{
 my ($self,$to,$po)=@_;
 my $pn=$po->name();
 my $pv=$po->version();
 my $tn=$to->name();

 return 1 if (($pn eq 'ovh_ws') && ($tn eq 'soapwsdl'));
 return;
}

sub transport_protocol_default
{
 my ($drd,$ndr,$type,$ta,$pa)=@_;
 $type='ws' if (!defined($type) || ref($type));
 if ($type eq 'ws')
 {
  return ('Net::DRI::Transport::HTTP::SOAPWSDL','Net::DRI::Protocol::OVH::WS') unless (defined($ta) && defined($pa));
  my %ta=(	has_login => 1,
		has_logout => 1,
		protocol_connection => 'Net::DRI::Protocol::OVH::WS::Connection', 
		protocol_version => 0.92,
		wsdl_uri => 'https://www.ovh.com/soapi/ovh.wsdl',
		proxy_uri => 'http://www.ovh.com:1664',
		servicename => 'managerService',
		portname => 'managerPort',
		defer => 1,
		(ref($ta) eq 'ARRAY')? %{$ta->[0]} : %$ta,
          );
  my @pa=(ref($pa) eq 'ARRAY' && @$pa)? @$pa : ('1.0');
  return ('Net::DRI::Transport::HTTP::SOAPWSDL',[\%ta],'Net::DRI::Protocol::OVH::WS',\@pa);
 }
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain)=@_;
 $domain=$ndr unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 my $r=$self->SUPER::check_name($domain,1);
 return $r if ($r);
 return 10 unless $self->is_my_tld($domain);
 return 0;
}

sub domain_operation_needs_is_mine
{
 my ($self,$ndr,$domain,$op)=@_;
 ($domain,$op)=($ndr,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 return;
}

sub account_list_domains
{
 my ($self,$ndr)=@_;
 my $rc;
 if (defined($ndr->get_info('list','account','domains')))
 {
  $ndr->set_info_from_cache('account','domains');
  $rc=$ndr->get_info('result_status');
 } else
 {
  $rc=$ndr->process('account','list_domains');
 }
 return $rc;
}

####################################################################################################
1;
