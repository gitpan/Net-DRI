## Domain Registry Interface, OpenSRS Registry Driver
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

package Net::DRI::DRD::OpenSRS;

use strict;
use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use Net::DRI::Util;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::DRD::OpenSRS - OpenSRS Registry driver for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head2 CURRENT LIMITATIONS

Only domain_info and account_list_domains are available.

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
 return $self;
}

sub periods      { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name         { return 'OpenSRS'; }
sub tlds         { return (qw/com net org info biz mobi name asia at be ca cc ch cn de dk es eu fr it li me com.mx nl tv uk us/); } ## see http://services.tucows.com/services/domains/pricing.php
sub object_types { return ('domain'); }

sub transport_protocol_compatible 
{
 my ($self,$to,$po)=@_;
 my $pn=$po->name();
 my $pv=$po->version();
 my $tn=$to->name();

 return 1 if (($pn eq 'opensrs_xcp') && ($tn eq 'http'));
 return;
}

sub transport_protocol_default
{
 my ($drd,$ndr,$type,$ta,$pa)=@_;
 if ($type eq 'xcp')
 {
  my %ta=(ref($ta) eq 'ARRAY')? %{$ta->[0]} : %$ta;
  $ta{protocol_connection}='Net::DRI::Protocol::OpenSRS::XCP::Connection';
  my @pa=(ref($pa) eq 'ARRAY' && @$pa)? @$pa : ();
  return ('Net::DRI::Transport::HTTP',[\%ta],'Net::DRI::Protocol::OpenSRS::XCP',\@pa);
 }
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain)=@_;
 $domain=$ndr unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 my $r=$self->SUPER::check_name($domain,[1,2]);
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

sub domain_info
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->err_invalid_domain_name($domain) if $self->verify_name_domain($domain,'info');

 my $rc;
 my $exist;
 ## After a successfull domain_info, get_info('ns') must be defined and is an Hosts object, even if empty
 if (defined($exist=$ndr->get_info('exist','domain',$domain)) && $exist && defined($ndr->get_info('ns','domain',$domain)))
 {
  $ndr->set_info_from_cache('domain',$domain);
  $rc=$ndr->get_info('result_status');
 } else
 {
  ## First grab a cookie, if needed
  unless (Net::DRI::Util::has_key($rd,'cookie'))
  {
   $rd={} unless defined($rd); ## will fail in set_cookie because other params needed, but at least this will be ok for next line ; otherwise do true checks of value needed
   $rd->{domain}=$domain;
   $rc=$ndr->process('session','set_cookie',[$rd]);
   return $rc unless $rc->is_success();
   $rd->{cookie}=$ndr->get_info('value','session','cookie'); ## Store cookie somewhere (taking into account date of expiry or some TTLs) ?
  }
  ## Now do the real info
  $rc=$ndr->process('domain','info',[$domain,$rd]); ## the $domain is not really used here, as it was used during set_cookie above
 }
 return $rc;
}

####################################################################################################
1;