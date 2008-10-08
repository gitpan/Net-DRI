## Domain Registry Interface, .COOP policies
##
## Copyright (c) 2006,2007,2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::COOP;

use strict;
use base qw/Net::DRI::DRD/;

use Net::DRI::DRD::ICANN;
use Net::DRI::Exception;
use DateTime::Duration;

our $VERSION=do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::DRD::COOP - .COOP policies for Net::DRI

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

Copyright (c) 2006,2007,2008 Patrick Mevzek <netdri@dotandco.com>.
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
 my $proto=shift;
 my $class=ref($proto) || $proto;

 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=0;

 bless($self,$class);
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'COOP'; }
sub tlds     { return ('coop'); }
sub object_types { return ('domain','contact','ns'); }

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
 my ($drd,$ndr,$type,$ta,$pa)=@_;
 $type='epp' if (!defined($type) || ref($type));
 if ($type eq 'epp')
 {
  return ('Net::DRI::Transport::Socket','Net::DRI::Protocol::EPP::Extensions::COOP')  unless (defined($ta) && defined($pa));
  my %ta=( %Net::DRI::DRD::PROTOCOL_DEFAULT_EPP,
           remote_host => '217.10.159.121', ## .COOP tests server
          (ref($ta) eq 'ARRAY')? %{$ta->[0]} : %$ta,
         );
  my @pa=(ref($pa) eq 'ARRAY' && @$pa)? @$pa : ('1.0');
  my @n=grep { ! exists($ta{$_}) || ! defined($ta{$_}) || ! $ta{$_}} qw/ssl_key_file ssl_cert_file ssl_ca_file/;
  Net::DRI::Exception::usererr_insufficient_parameters('these parameters must be defined: '.join(' ',@n)) if @n;
  return ('Net::DRI::Transport::Socket',[\%ta],'Net::DRI::Protocol::EPP::Extensions::COOP',\@pa);
 }
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 ($domain,$op)=($ndr,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 my $r=$self->SUPER::check_name($domain,1);
 return $r if ($r);
 return 10 unless $self->is_my_tld($domain);
 return 11 if Net::DRI::DRD::ICANN::is_reserved_name($domain,$op);

 return 0;
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
1;
