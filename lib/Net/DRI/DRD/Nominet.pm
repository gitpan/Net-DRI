## Domain Registry Interface, .UK (Nominet) policies for Net::DRI
##
## Copyright (c) 2007,2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::Nominet;

use strict;
use base qw/Net::DRI::DRD/;

use Net::DRI::Util;
use Net::DRI::Exception;

use DateTime::Duration;

our $VERSION=do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::DRD::Nominet - .UK (Nominet) policies for Net::DRI

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

Copyright (c) 2007,2008 Patrick Mevzek <netdri@dotandco.com>.
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

 bless($self,$class);
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (2); }
sub name     { return 'Nominet'; }
sub tlds     { return qw/co.uk ltd.uk me.uk net.uk org.uk plc.uk sch.uk/; } ## See http://www.nominet.org.uk/registrants/aboutdomainnames/rules/
sub object_types { return ('domain','contact','ns','account'); }

sub transport_protocol_compatible
{
 my ($self,$to,$po)=@_;
 my $pn=$po->name();
 my $tn=$to->name();

 return 1 if (($pn eq 'EPP') && ($tn eq 'socket_inet'));
## return 1 if (($pn eq 'DAS') && ($tn eq 'socket_inet'));
 return;
}

sub transport_protocol_default
{
 my ($drd,$ndr,$type,$ta,$pa)=@_;
 $type='epp' if (!defined($type) || ref($type));
 if ($type eq 'epp')
 {
  return ('Net::DRI::Transport::Socket','Net::DRI::Protocol::EPP::Extensions::Nominet') unless (defined($ta) && defined($pa));
  my %ta=(	%Net::DRI::DRD::PROTOCOL_DEFAULT_EPP,
		remote_host => 'epp.nominet.org.uk',
		(ref($ta) eq 'ARRAY')? %{$ta->[0]} : %$ta,
	);
  my @pa=(ref($pa) eq 'ARRAY' && @$pa)? @$pa : ('1.0');
  $ta{client_login}='#'.$ta{client_login} if (defined($ta{client_login}) && length($ta{client_login})==2); # as seen on http://www.nominet.org.uk/registrars/systems/epp/login/
  return ('Net::DRI::Transport::Socket',[\%ta],'Net::DRI::Protocol::EPP::Extensions::Nominet',\@pa);
 }
## return ('Net::DRI::Transport::Socket',[{%Net::DRI::DRD::PROTOCOL_DEFAULT_DAS,remote_host=>'dac.nic.uk',remote_port=>2043,close_after=>0}],'Net::DRI::Protocol::DAS::Nominet',[]) if (lc($type) eq 'das');
}

####################################################################################################
sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 ($domain,$op)=($ndr,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 my $r=$self->SUPER::check_name($domain,2); ## 2 dots needed
 return $r if ($r);
 return 10 unless $self->is_my_tld($domain);
 return 0;
}

## http://www.nominet.org.uk/registrars/systems/epp/renew/
sub verify_duration_renew
{
 my ($self,$ndr,$duration,$domain,$curexp)=@_;
 ($duration,$domain,$curexp)=($ndr,$duration,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

## +Renew commands will only be processed if the expiry date of the domain name is within 6 months.

 if (defined($duration))
 {
  my ($y,$m)=$duration->in_units('years','months');
  return 1 unless ($y==2 && $m==0); ## Only 24m or 2y allowed
 }

 return 0; ## everything ok
}

sub host_info
{
 my ($self,$ndr,$dh,$rh)=@_;

 my $roid=Net::DRI::Util::isa_hosts($dh)? $dh->roid() : $dh;

 my ($rc,$exist);
## when we do a domain:info we get all info needed to later on reply to a host:info (cache delay permitting)
 if (defined($exist=$ndr->get_info('exist','host',$roid)) && $exist && defined($ndr->get_info('self','host',$roid)))
 {
  $ndr->set_info_from_cache('host',$roid);
  $rc=$ndr->get_info('result_status');
 } else
 {
  $rc=$ndr->process('host','info',[$dh,$rh]); ## cache was empty, go to registry
 }

 return $rc unless $rc->is_success();
 return (wantarray())? ($rc,$ndr->get_info('self')) : $rc;
}

sub host_update
{
 my ($self,$ndr,$dh,$tochange)=@_;
 my $fp=$ndr->protocol->nameversion();

 my $name=Net::DRI::Util::isa_hosts($dh)? $dh->get_details(1) : $dh;
 $self->err_invalid_host_name($name) if $self->verify_name_host($name);
 Net::DRI::Util::check_isa($tochange,'Net::DRI::Data::Changes');

 foreach my $t ($tochange->types())
 {
  Net::DRI::Exception->die(0,'DRD',6,"Change host_update/${t} not handled") unless ($t=~m/^(?:ip|name)$/);
  next if $ndr->protocol_capable('host_update',$t);
  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable of host_update/${t}");
 }

 my %what=('ip'     => [ $tochange->all_defined('ip') ],
           'name'   => [ $tochange->all_defined('name') ],
          );
 foreach (@{$what{ip}})     { Net::DRI::Util::check_isa($_,'Net::DRI::Data::Hosts'); }
 foreach (@{$what{name}})   { $self->err_invalid_host_name($_) if $self->verify_name_host($_); }

 foreach my $w (keys(%what))
 {
  my @s=@{$what{$w}};
  next unless @s; ## no changes of that type

  my $add=$tochange->add($w);
  my $del=$tochange->del($w);
  my $set=$tochange->set($w);

  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable for host_update/${w} to add") if (defined($add) &&
                                                                                       ! $ndr->protocol_capable('host_update',$w,'add'));
  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable for host_update/${w} to del") if (defined($del) &&
                                                                                       ! $ndr->protocol_capable('host_update',$w,'del'));
  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable for host_update/${w} to set") if (defined($set) &&
                                                                                       ! $ndr->protocol_capable('host_update',$w,'set'));
  Net::DRI::Exception->die(0,'DRD',6,"Change host_update/${w} with simultaneous set and add or del not supported") if (defined($set) && (defined($add) || defined($del)));
 }

 my $rc=$ndr->process('host','update',[$dh,$tochange]);
 return $rc;
}

sub account_info
{
 my ($self,$ndr,$c)=@_;
 return $ndr->process('account','info',[$c]);
 }

sub account_update
{
 my ($self,$ndr,$c,$cs)=@_;
 return $ndr->process('account','update',[$c,$cs]);
}

####################################################################################################

## No status at all with Nominet
sub domain_update_status_add { Net::DRI::Exception->die(0,'DRD',4,'No domain status update available in .UK'); }
sub domain_update_status_del { Net::DRI::Exception->die(0,'DRD',4,'No domain status update available in .UK'); }
sub domain_update_status_set { Net::DRI::Exception->die(0,'DRD',4,'No domain status update available in .UK'); }
sub domain_update_status { Net::DRI::Exception->die(0,'DRD',4,'No domain status update available in .UK'); }
sub domain_status_allows_delete { Net::DRI::Exception->die(0,'DRD',4,'No domain status update available in .UK'); }
sub domain_status_allows_update { Net::DRI::Exception->die(0,'DRD',4,'No domain status update available in .UK'); }
sub domain_status_allows_transfer { Net::DRI::Exception->die(0,'DRD',4,'No domain status update available in .UK'); }
sub domain_status_allows_renew { Net::DRI::Exception->die(0,'DRD',4,'No domain status update available in .UK'); }
sub domain_status_allows { Net::DRI::Exception->die(0,'DRD',4,'No domain status update available in .UK'); }
sub domain_current_status { Net::DRI::Exception->die(0,'DRD',4,'No domain status update available in .UK'); }
sub host_update_status_add { Net::DRI::Exception->die(0,'DRD',4,'No host status update available in .UK'); }
sub host_update_status_del { Net::DRI::Exception->die(0,'DRD',4,'No host status update available in .UK'); }
sub host_update_status_set { Net::DRI::Exception->die(0,'DRD',4,'No host status update available in .UK'); }
sub host_update_status { Net::DRI::Exception->die(0,'DRD',4,'No host status update available in .UK'); }
sub host_current_status { Net::DRI::Exception->die(0,'DRD',4,'No host status update available in .UK'); }
sub contact_update_status_add { Net::DRI::Exception->die(0,'DRD',4,'No contact status update available in .UK'); }
sub contact_update_status_del { Net::DRI::Exception->die(0,'DRD',4,'No contact status update available in .UK'); }
sub contact_update_status_set { Net::DRI::Exception->die(0,'DRD',4,'No contact status update available in .UK'); }
sub contact_update_status { Net::DRI::Exception->die(0,'DRD',4,'No contact status update available in .UK'); }
sub contact_current_status { Net::DRI::Exception->die(0,'DRD',4,'No contact status update available in .UK'); }

## Only domain:check is available
sub host_check { Net::DRI::Exception->die(0,'DRD',4,'No host check available in .UK'); }
sub host_check_multi { Net::DRI::Exception->die(0,'DRD',4,'No host check available in .UK'); }
sub host_exist { Net::DRI::Exception->die(0,'DRD',4,'No host check available in .UK'); }
sub contact_check { Net::DRI::Exception->die(0,'DRD',4,'No contact check available in .UK'); }
sub contact_check_multi { Net::DRI::Exception->die(0,'DRD',4,'No contact check available in .UK'); }
sub contact_exist { Net::DRI::Exception->die(0,'DRD',4,'No contact check available in .UK'); }

## Only domain transfer
sub contact_transfer { Net::DRI::Exception->die(0,'DRD',4,'No contact transfer available in .UK'); }
sub contact_transfer_start { Net::DRI::Exception->die(0,'DRD',4,'No contact transfer available in .UK'); }
sub contact_transfer_stop { Net::DRI::Exception->die(0,'DRD',4,'No contact transfer available in .UK'); }
sub contact_transfer_query { Net::DRI::Exception->die(0,'DRD',4,'No contact transfer available in .UK'); }
sub contact_transfer_accept { Net::DRI::Exception->die(0,'DRD',4,'No contact transfer available in .UK'); }
sub contact_transfer_refuse { Net::DRI::Exception->die(0,'DRD',4,'No contact transfer available in .UK'); }

## Only transfer op=req and refuse/accept
sub domain_transfer_stop { Net::DRI::Exception->die(0,'DRD',4,'Not possible to stop an ongoing transfer in .UK'); }
sub domain_transfer_query { Net::DRI::Exception->die(0,'DRD',4,'Not possible to query an ongoing transfer in .UK'); }

## The delete command applies only to domain names.  Accounts, contacts and nameservers cannot be explicitly deleted, but are automatically deleted when no longer referenced.
sub host_delete { Net::DRI::Exception->die(0,'DRD',4,'No host delete available in .UK'); }
sub contact_delete { Net::DRI::Exception->die(0,'DRD',4,'No contact delete available in .UK'); }

## No direct contact/host create
sub host_create { Net::DRI::Exception->die(0,'DRD',4,'No direct host creation possible in .UK'); }
sub contact_create { Net::DRI::Exception->die(0,'DRD',4,'No direct contact creation possible in .UK'); }

####################################################################################################
1;
