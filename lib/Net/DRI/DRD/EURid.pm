## Domain Registry Interface, EURid (.EU) policy on reserved names
##
## Copyright (c) 2005,2006 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::EURid;

use strict;
use base qw/Net::DRI::DRD/;

use Net::DRI::Util;

our $VERSION=do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::DRD::EURid - EURid (.EU) policies for Net::DRI

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

Copyright (c) 2005,2006 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

#####################################################################################

our %CCA2_EU=map { $_ => 1 } qw/AT BE CZ CY DE DK ES EE FI FR GR GB HU IE IT LT LU LV MT NL PL PT SE SK SI AX GF GI GP MQ RE/;
our %LANGA2_EU=map { $_ => 1 } qw/cs da de el en es et fi fr hu it lt lv mt nl pl pt sk sl sv/;

sub new
{
 my $proto=shift;
 my $class=ref($proto) || $proto;

 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=1;

 bless($self,$class);
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1); }
sub name     { return 'EURid'; }
sub tlds     { return ('eu'); }
sub object_types { return ('domain','contact','ns','nsgroup'); }

sub transport_protocol_compatible
{
 my ($self,$to,$po)=@_;
 my $pn=$po->name();
 my $tn=$to->name();

 return 1 if (($pn eq 'EPP') && ($tn eq 'socket_inet'));
 return;
}

sub transport_protocol_default
{
 return ('Net::DRI::Transport::Socket','Net::DRI::Protocol::EPP::Extensions::EURid');
}

######################################################################################

## See terms_and_conditions_v1_0_.pdf, Section 2.2.ii
sub verify_name_domain
{
 my ($self,$ndr,$domain)=@_;
 $domain=$ndr unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 my $r=$self->SUPER::check_name($domain,1);
 return $r if ($r);
 return 10 unless $self->is_my_tld($domain);

 my @d=split(/\./,$domain);
 return 11 if exists($Net::DRI::Util::CCA2{uc($d[0])});
 return 12 if length($d[0]) < 2;
 return 13 if substr($d[0],2,2) eq '--';

 return 0;
}

sub verify_duration_transfer
{
 my ($self,$ndr,$duration,$domain,$op)=@_;
 ($duration,$domain,$op)=($ndr,$duration,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 return 0 unless ($op eq 'start'); ## we are not interested by other cases, they are always OK
 return 0; ## Always OK to start a transfer, since the new expiration is one year away from the transfer date
}

sub domain_operation_needs_is_mine
{
 my ($self,$ndr,$domain,$op)=@_;
 ($domain,$op)=($ndr,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 return unless defined($op);

 return 1 if ($op=~m/^(?:renew|update|delete)$/);
 return 0 if ($op eq 'transfer');
 return;
}

## Only transfer requests are possible
sub domain_transfer_stop    { Net::DRI::Exception->die(0,'DRD',4,'No domain transfer cancel available in .EU'); }
sub domain_transfer_query   { Net::DRI::Exception->die(0,'DRD',4,'No domain transfer query available in .EU'); }
sub domain_transfer_accept  { Net::DRI::Exception->die(0,'DRD',4,'No domain transfer approve available in .EU'); }
sub domain_transfer_refuse  { Net::DRI::Exception->die(0,'DRD',4,'No domain transfer reject in .EU'); }
sub domain_renew        { Net::DRI::Exception->die(0,'DRD',4,'No domain renew available in .EU'); }
sub contact_check       { Net::DRI::Exception->die(0,'DRD',4,'No contact check available in .EU'); }
sub contact_check_multi { Net::DRI::Exception->die(0,'DRD',4,'No contact check available in .EU'); }
sub contact_transfer    { Net::DRI::Exception->die(0,'DRD',4,'No contact transfer available in .EU'); }

#################################################################################################################
1;
