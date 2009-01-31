## Domain Registry Interface, .PL policies
##
## Copyright (c) 2006,2008,2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::PL;

use strict;
use base qw/Net::DRI::DRD/;

use Net::DRI::Exception;
use DateTime::Duration;

our $VERSION=do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

__PACKAGE__->make_exception_for_unavailable_operations(qw/domain_transfer_stop domain_transfer_query domain_transfer_accept domain_transfer_refuse contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse/);

=pod

=head1 NAME

Net::DRI::DRD::PL - .PL policies for Net::DRI

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

Copyright (c) 2006,2008,2009 Patrick Mevzek <netdri@dotandco.com>.
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
 $self->{info}->{host_as_attr}=0;
 $self->{info}->{contact_i18n}=1;	## LOC only

 bless($self,$class);
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'NASK'; }
## See http://www.dns.pl/english/dns-funk.html
sub tlds     { return ('pl',map { $_.'.pl'} qw/aid agro atm auto biz com edu gmina gsm info mail miasta media mil net nieruchomosci nom org pc powiat priv realestate rel sex shop sklep sos szkola targi tm tourism travel turystyka/ ); }
sub object_types { return ('domain','contact','ns'); }

sub transport_protocol_compatible
{
 my ($self,$to,$po)=@_;
 my $pn=$po->name();
 my $tn=$to->name();

 return 1 if (($pn eq 'EPP') && ($tn eq 'http'));
 return;
}

sub transport_protocol_default
{
 my ($drd,$ndr,$type,$ta,$pa)=@_;
 $type='epp' if (!defined($type) || ref($type));
 if ($type eq 'epp') ## EPP is over HTTPS
 {
  my @a=Net::DRI::DRD::_transport_protocol_default_epp('Net::DRI::Protocol::EPP::Extensions::PL',$ta,$pa);
  $a[0]='Net::DRI::Transport::HTTP';
  $a[1]->[0]->{protocol_connection}='Net::DRI::Protocol::EPP::Extensions::PL::Connection';
  return @a;
 }
}

####################################################################################################

sub message_retrieve
{
 my ($self,$ndr,$id)=@_;
 my $rc=$ndr->process('message','plretrieve',[$id]);
 return $rc;
}

####################################################################################################
1;
