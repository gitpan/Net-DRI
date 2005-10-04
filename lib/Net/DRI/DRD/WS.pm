## Domain Registry Interface, ``WorldSite.WS'' Registry Driver for .WS
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

package Net::DRI::DRD::WS;

use strict;
use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use DateTime;
use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::DRD::WS - Website.WS .WS Registry driver for Net::DRI

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


#####################################################################################

sub is_thick     { return 0; }
sub periods      { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name         { return "WS"; }
sub tlds         { return ('ws'); }

sub transport_protocol_compatible 
{
 my ($self,$to,$po)=@_;
 my $pn=$po->name();
 my $pv=$po->version();
 my $tn=$to->name();

 return 1 if (($pn eq 'RRP') && ($tn eq 'socket_inet'));
 return undef;
}

######################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain)=@_;
 $domain=$ndr unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 my $r=$self->SUPER::check_name($domain,1);
 return $r if ($r);
 return 10 unless $self->is_my_tld($domain);
 return 0;
}

sub verify_duration_transfer
{
 return 1; ## no transfer possible at all
}


sub domain_operation_needs_is_mine
{
 my ($self,$ndr,$domain,$op)=@_;
 ($domain,$op)=($ndr,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 return undef unless defined($op);

 return 1 if ($op=~m/^(?:renew|update|delete)$/);
 return undef;
}

## Transfer operations are not possible

sub domain_transfer        { Net::DRI::Exception->die(0,'DRD',4,'No transfer available in .WS'); }
sub domain_transfer_start  { Net::DRI::Exception->die(0,'DRD',4,'No transfer available in .WS'); }
sub domain_transfer_stop   { Net::DRI::Exception->die(0,'DRD',4,'No transfer available in .WS'); }
sub domain_transfer_query  { Net::DRI::Exception->die(0,'DRD',4,'No transfer available in .WS'); }
sub domain_transfer_accept { Net::DRI::Exception->die(0,'DRD',4,'No transfer available in .WS'); }
sub domain_transfer_refuse { Net::DRI::Exception->die(0,'DRD',4,'No transfer available in .WS'); }

######################################################################################
1;
