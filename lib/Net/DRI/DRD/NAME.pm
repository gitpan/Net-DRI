## Domain Registry Interface, .NAME policies
##
## Copyright (c) 2007,2008 HEXONET Support GmbH, www.hexonet.com,
##                    Alexander Biehl <info@hexonet.com>
##			and Patrick Mevzek <netdri@dotandco.com>.
##                    All rights reserved.
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

package Net::DRI::DRD::NAME;

use strict;
use base qw/Net::DRI::DRD/;

use Net::DRI::DRD::ICANN;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::DRD::NAME - .NAME policies for Net::DRI

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

Copyright (c) 2007,2008 HEXONET Support GmbH, E<lt>http://www.hexonet.comE<gt>,
Alexander Biehl <info@hexonet.com>
and Patrick Mevzek <netdri@dotandco.com>.
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
sub name     { return 'NAME'; }
sub tlds     { return ('name'); }
sub object_types { return ('domain','contact','ns'); }

sub transport_protocol_compatible
{
 my ($self,$to,$po)=@_;
 my $pn=$po->name();
 my $pv=$po->version();
 my $tn=$to->name();

 return 1 if (($pn eq 'EPP') && ($tn eq 'socket_inet'));
 return 1 if (($pn eq 'Whois') && ($tn eq 'socket_inet'));
 return;
}

sub transport_protocol_default
{
 my ($drd,$ndr,$type,$ta,$pa)=@_;
 $type='epp' if (!defined($type) || ref($type));
 return Net::DRI::DRD::_transport_protocol_default_epp('Net::DRI::Protocol::EPP::Extensions::NAME',$ta,$pa) if ($type eq 'epp');
 return ('Net::DRI::Transport::Socket',[{%Net::DRI::DRD::PROTOCOL_DEFAULT_WHOIS,remote_host=>'whois.nic.name'}],'Net::DRI::Protocol::Whois',[]) if (lc($type) eq 'whois');
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

sub emailfwd_check
{
 my ($self,$ndr,$email)=@_;
 ## Technical syntax check of email object needed here
 my $rc;
 if (defined($ndr->get_info('exist','emailfwd',$email)))
 {
  $ndr->set_info_from_cache('emailfwd',$email);
  $rc=$ndr->get_info('result_status');
 } else
 {
  $rc=$ndr->process('emailfwd','check',[$email]);
 }
 return $rc;
}

sub emailfwd_exist ## 1/0/undef
{
 my ($self,$ndr,$email)=@_;
 ## Technical syntax check of email object needed here
 my $rc=$ndr->emailfwd_check($email);
 return unless $rc->is_success();
 return $ndr->get_info('exist');
}

sub emailfwd_info
{
 my ($self,$ndr,$email)=@_;
 ## Technical syntax check of email object needed here
 my $rc;
 ## After a successfull domain_info, get_info('ns') must be defined and is an Hosts object, even if empty
 if (defined($ndr->get_info('exist','emailfwd',$email)))
 {
  $ndr->set_info_from_cache('emailfwd',$email);
  $rc=$ndr->get_info('result_status');
 } else
 {
  $rc=$ndr->process('emailfwd','info',[$email]);
 }
 return $rc;
}

sub emailfwd_create
{
 my ($self,$ndr,$email,$rd)=@_;
 ## Technical syntax check of email object needed here
 my $rc=$ndr->process('emailfwd','create',[$email,$rd]);
 return $rc;
}

sub emailfwd_delete
{
 my ($self,$ndr,$email)=@_;
 ## Technical syntax check of email object needed here
 my $rc=$ndr->process('emailfwd','delete',[$email]);
 return $rc;
}

sub emailfwd_update
{
 my ($self,$ndr,$email,$tochange)=@_;
 my $fp=$ndr->protocol->nameversion();

 ## Technical syntax check of email object needed here
 Net::DRI::Util::check_isa($tochange,'Net::DRI::Data::Changes');

  foreach my $t ($tochange->types())
 {
  next if $ndr->protocol_capable('emailfwd_update',$t);
  Net::DRI::Exception->die(0,'DRD',5,'Protocol '.$fp.' is not capable of emailfwd_update/'.$t);
 }

 my $rc=$ndr->process('emailfwd','update',[$email,$tochange]);
 return $rc;
}

sub emailfwd_renew
{
 my ($self,$ndr,$email,$rd)=@_;
 ## Technical syntax check of email object needed here
 Net::DRI::Util::check_isa($rd->{duration},'DateTime::Duration') if defined($rd->{duration});
 Net::DRI::Util::check_isa($rd->{current_expiration},'DateTime') if defined($rd->{current_expiration});
 return $ndr->process('emailfwd','renew',[$email,$rd->{duration},$rd->{current_expiration}]);
}

####################################################################################################
1;
