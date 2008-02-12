## Domain Registry Interface, .AT policy
## Contributed by Michael Braunoeder from NIC.AT <mib@nic.at>
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

package Net::DRI::DRD::AT;

use strict;
use base qw/Net::DRI::DRD/;

use Net::DRI::Util;

our $VERSION=do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::DRD::AT - .AT policies for Net::DRI

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
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=2; ## this means we want IPs in all cases (even for nameservers in domain name)
 $self->{info}->{contact_i18n}=2; ## INT only
 bless($self,$class);
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1); }
sub name     { return 'NICAT'; }
sub tlds     { return ('at'); }
sub object_types { return ('domain','contact'); }

sub transport_protocol_compatible
{
 my ($self,$to,$po)=@_;
 my $pn=$po->name();
 my $tn=$to->name();

 return 1 if (($pn eq 'EPP') && ($tn eq 'socket_inet'));
 return 1 if (($pn eq 'Whois') && ($tn eq 'socket_inet'));
 return;
}

sub transport_protocol_default
{
 my ($drd,$ndr,$type,$ta,$pa)=@_;
 $type='epp' if (!defined($type) || ref($type));
 return Net::DRI::DRD::_transport_protocol_default_epp('Net::DRI::Protocol::EPP::Extensions::AT',$ta,$pa) if ($type eq 'epp');
 return ('Net::DRI::Transport::Socket',[{%Net::DRI::DRD::PROTOCOL_DEFAULT_WHOIS,remote_host=>'whois.nic.at'}],'Net::DRI::Protocol::Whois',[]) if (lc($type) eq 'whois');
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain)=@_;
 $domain=$ndr unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 my @splited = split /\./,$domain;
 my $count = @splited;
 $count--;
 my $r=$self->SUPER::check_name($domain,$count);
 return $r if ($r);

 return 10 unless $self->is_my_tld($domain);

 return 0;
}

sub is_my_tld
{
   my ($self,$ndr,$domain)=@_;
   ($domain)=($ndr) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));
   my ($tld) = uc($self->tlds());

   return 1 if (uc($domain) =~ /.*$tld$/);
   return 0;
}

sub verify_duration_transfer
{
 my ($self,$ndr,$duration,$domain,$op)=@_;
 ($duration,$domain,$op)=($ndr,$duration,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 return 0 unless ($op eq 'start'); ## we are not interested by other cases, they are always OK
 return 0;
}

sub domain_operation_needs_is_mine
{
 my ($self,$ndr,$domain,$op)=@_;
 ($domain,$op)=($ndr,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 return unless defined($op);

 return 1 if ($op=~m/^(?:update|delete)$/);
 return 0 if ($op eq 'transfer');
 return;
}

sub domain_withdraw
{
 my ($self,$ndr,$domain,$rd)=@_;
 err_invalid_domain_name($domain) if $self->verify_name_domain($domain);

 $rd={} unless (defined($rd) && (ref($rd) eq 'HASH'));
 $rd->{transactionname} = 'withdraw';

 my $rc=$ndr->process('domain','nocommand',[$domain,$rd]);
 return $rc;
}

sub domain_transfer_execute
{
 my ($self,$ndr,$domain,$rd)=@_;
 err_invalid_domain_name($domain) if $self->verify_name_domain($domain);

 $rd={} unless (defined($rd) && (ref($rd) eq 'HASH'));
 $rd->{transactionname} = 'transfer_execute';

 my $rc=$ndr->process('domain','nocommand',[$domain,$rd]);
 return $rc;
}

sub message_retrieve
{
 my ($self,$ndr,$id)=@_;
 my $rc=$ndr->process('message','atretrieve',[$id]);
 return $rc;
}

sub message_delete
{
 my ($self,$ndr,$id)=@_;
 my $rc=$ndr->process('message','atdelete',[$id]);
 return $rc;
}

sub message_waiting
{
 my ($self,$ndr)=@_;
 my $c=$self->message_count($ndr);
 return (defined($c) && $c)? 1 : 0;
}

sub message_count
{
 my ($self,$ndr)=@_;
 my $rc=$ndr->process('message','atretrieve');
 return unless $rc->is_success();
 my $count=$ndr->get_info('count','message','info');
 return (defined($count) && $count)? $count : 0;
}

## unsupported transactions
sub domain_transfer_accept  { Net::DRI::Exception->die(0,'DRD',4,'No domain transfer approve available in .AT'); }
sub domain_transfer_refuse  { Net::DRI::Exception->die(0,'DRD',4,'No domain transfer reject in .AT'); }
sub domain_renew { Net::DRI::Exception->die(0,'DRD',4,'No domain renew in .AT'); }

sub contact_transfer_stop   { Net::DRI::Exception->die(0,'DRD',4,'No contact transfer cancel available in .AT'); }
sub contact_transfer_query  { Net::DRI::Exception->die(0,'DRD',4,'No contact transfer query available in .AT'); }
sub contact_transfer_accept { Net::DRI::Exception->die(0,'DRD',4,'No contact transfer approve available in .AT'); }
sub contact_transfer_refuse { Net::DRI::Exception->die(0,'DRD',4,'No contact transfer reject in .AT'); }
sub contact_check { Net::DRI::Exception->die(0,'DRD',4,'No contact check in .AT'); }

####################################################################################################
1;
