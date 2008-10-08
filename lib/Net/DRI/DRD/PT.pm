## Domain Registry Interface, Registry Driver for .PT
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

package Net::DRI::DRD::PT;

use strict;
use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use DateTime;
use Net::DRI::Exception;
use Net::DRI::Util;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::DRD::PT - FCCN .PT Registry driver for Net::DRI

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

sub new
{
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=1;
 $self->{info}->{contact_i18n}=1; ## LOC only
 bless($self,$class);
 return $self;
}

sub periods      { return map { DateTime::Duration->new(years => $_) } (1,3,5); }
sub name         { return 'FCCN'; }
sub tlds         { return qw/pt net.pt org.pt edu.pt int.pt publ.pt com.pt nome.pt/; }
sub object_types { return ('domain','contact'); }

sub transport_protocol_compatible 
{
 my ($self,$to,$po)=@_;
 my $pn=$po->name();
 my $pv=$po->version();
 my $tn=$to->name();

 return 1 if (($pn eq 'EPP') && ($tn eq 'socket_inet'));
## return 1 if (($pn eq 'Whois') && ($tn eq 'socket_inet'));
 return;
}

sub transport_protocol_default
{
 my ($drd,$ndr,$type,$ta,$pa)=@_;
 $type='epp' if (!defined($type) || ref($type));
 return Net::DRI::DRD::_transport_protocol_default_epp('Net::DRI::Protocol::EPP::Extensions::FCCN',$ta,$pa) if ($type eq 'epp');
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 ($domain,$op)=($ndr,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 my $r=$self->SUPER::check_name($domain,[1,2]);
 return $r if ($r);
 return 10 unless $self->is_my_tld($domain);
 return 0;
}

## We can not start a transfer, if domain name has already been transfered less than 15 days ago.
sub verify_duration_transfer
{
 my ($self,$ndr,$duration,$domain,$op)=@_;
 ($duration,$domain,$op)=($ndr,$duration,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 return 0 unless ($op eq 'start'); ## we are not interested by other cases, they are always OK
 my $rc=$self->domain_info($ndr,$domain,{hosts=>'none'});
 return 1 unless ($rc->is_success());
 my $trdate=$ndr->get_info('trDate');
 return 0 unless ($trdate && $trdate->isa('DateTime'));

 my $now=DateTime->now(time_zone => $trdate->time_zone()->name());
 my $cmp=DateTime->compare($now,$trdate+DateTime::Duration->new(days => 15));
 return ($cmp == 1)? 0 : 1; ## we must have : now > transferdate + 15days
 ## we return 0 if OK, anything else if not
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

####################################################################################################

sub domain_renounce
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->err_invalid_domain_name($domain) if $self->verify_name_domain($domain,'renounce');
 return $ndr->process('domain','renounce',[$domain,$rd]);
}

####################################################################################################

sub contact_check  { Net::DRI::Exception->die(0,'DRD',4,'No contact check available in .PT'); }
sub contact_delete { Net::DRI::Exception->die(0,'DRD',4,'No contact delete available in .PT'); }

## Only domain transfer
sub contact_transfer        { Net::DRI::Exception->die(0,'DRD',4,'No contact transfer available in .PT'); }
sub contact_transfer_start  { Net::DRI::Exception->die(0,'DRD',4,'No contact transfer available in .PT'); }
sub contact_transfer_stop   { Net::DRI::Exception->die(0,'DRD',4,'No contact transfer available in .PT'); }
sub contact_transfer_query  { Net::DRI::Exception->die(0,'DRD',4,'No contact transfer available in .PT'); }
sub contact_transfer_accept { Net::DRI::Exception->die(0,'DRD',4,'No contact transfer available in .PT'); }
sub contact_transfer_refuse { Net::DRI::Exception->die(0,'DRD',4,'No contact transfer available in .PT'); }

## No polling
sub message_retrieve { Net::DRI::Exception->die(0,'DRD',4,'No message polling features available in .PT'); }
sub message_delete   { Net::DRI::Exception->die(0,'DRD',4,'No message polling features available in .PT'); }
sub message_waiting  { Net::DRI::Exception->die(0,'DRD',4,'No message polling features available in .PT'); }
sub message_count    { Net::DRI::Exception->die(0,'DRD',4,'No message polling features available in .PT'); }

####################################################################################################
1;
