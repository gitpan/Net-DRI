## Domain Registry Interface, Gandi Registry Driver
##
## Copyright (c) 2005,2008,2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::Gandi;

use strict;
use base qw/Net::DRI::DRD/;

our $VERSION=do { my @r=(q$Revision: 1.5 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::DRD::Gandi - Gandi Registry driver for Net::DRI

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

Copyright (c) 2005,2008,2009 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

#####################################################################################

sub name         { return 'Gandi'; }
sub tlds         { return ('com','net','org','biz','info','name','be'); }
sub object_types { return ('domain','contact'); }

sub transport_protocol_compatible 
{
 my ($self,$to,$po)=@_;
 my $pn=$po->name();
 my $pv=$po->version();
 my $tn=$to->name();

 return 1 if (($pn eq 'gandi_ws') && ($tn eq 'xmlrpclite'));
 return;
}

sub transport_protocol_default
{
 my ($drd,$ndr,$type,$ta,$pa)=@_;
 $type='ws' if (!defined($type) || ref($type));
 if ($type eq 'ws')
 {
  return ('Net::DRI::Transport::HTTP::XMLRPCLite','Net::DRI::Protocol::Gandi::WS') unless (defined($ta) && defined($pa));
  my %ta=( has_login => 1,
           has_logout => 0,
           protocol_connection => 'Net::DRI::Protocol::Gandi::WS::Connection',
           protocol_version => 1.0,
           proxy_uri => 'https://api.gandi.net/xmlrpc/',
           defer => 1,
           (ref($ta) eq 'ARRAY')? %{$ta->[0]} : %$ta,
        );
  my @pa=(ref($pa) eq 'ARRAY' && @$pa)? @$pa : ('1.0');
  return ('Net::DRI::Transport::HTTP::XMLRPCLite',[\%ta],'Net::DRI::Protocol::Gandi::WS',\@pa);
 }
}

####################################################################################################

sub domain_operation_needs_is_mine
{
 my ($self,$ndr,$domain,$op)=@_;
 return;
}

sub account_list_domains
{
 my ($self,$ndr)=@_;
 my $rc=$ndr->try_restore_from_cache('account','domains','list');
 if (! defined $rc) { $rc=$ndr->process('account','list_domains'); }
 return $rc;
}

####################################################################################################
1;
