## Domain Registry Interface, DENIC policies
##
## Copyright (c) 2007,2008,2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
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

package Net::DRI::DRD::DENIC;

use strict;
use base qw/Net::DRI::DRD/;

use Net::DRI::DRD::ICANN;
use DateTime::Duration;

our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::DRD::DENIC - DENIC (.DE) policies for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>tonnerre.lombard@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2007,2008,2009 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
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

 bless($self,$class);
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'DENIC'; }
sub tlds     { return ('de','9.4.e164.arpa'); } ## *.9.4.e164.arpa can be queried over IRIS DCHK, do not know about RRI support
sub object_types { return ('domain','contact'); }

sub transport_protocol_compatible
{
 my ($self,$to,$po)=@_;
 my $pn=$po->name();
 my $pv=$po->version();
 my $tn=$to->name();

 return 1 if (($pn eq 'RRI') && ($tn eq 'socket_inet'));
 return 1 if (($pn eq 'IRIS') && ($tn eq 'socket_inet'));
 return;
}

## TODO: see if that could be useful (such as being used by Net::DRI::Shell) ; if so propagate to other DRD modules
sub available_profile_types { return qw/rri dchk/; }

sub transport_protocol_default
{
 my ($drd,$ndr,$type,$ta,$pa)=@_;
 $type='rri' if (!defined($type) || ref($type));
 if ($type eq 'rri')
 {
  return ('Net::DRI::Transport::Socket','Net::DRI::Protocol::RRI') unless (defined($ta) && defined($pa));
  my %ta=( defer=>1,
           close_after=>1,
           socktype=>'tcp',
           remote_host=>'rri.test.denic.de',
           remote_port=>51131,
           protocol_connection=>'Net::DRI::Protocol::RRI::Connection',
           protocol_version=>'2.0',
           (ref($ta) eq 'ARRAY')? %{$ta->[0]} : %$ta,
         );
  my @pa=(ref($pa) eq 'ARRAY' && @$pa)? @$pa : ('2.0');
  return ('Net::DRI::Transport::Socket',[\%ta],'Net::DRI::Protocol::RRI',\@pa);
 }
 if ($type eq 'dchk')
 {
  my %ta=( defer=>1,
           socktype=>'udp',
           find_remote_server => ['de.','DCHK1:iris.lwz'], ## authority / service
           protocol_connection=>'Net::DRI::Protocol::IRIS::LWZ',
           protocol_version=>'1.0',
           timeout => 1, ## RFC4993 Section 4 gives recommandation for timeouts and retry algorithm
           pause => 2,
           retry => 5, ## computed so that the whole sequence stops after 60 seconds: t,p+2t,3/2(p+2)-2+4t,3/2*3/2*(p+2)-2+8t,...
           (ref($ta) eq 'ARRAY')? %{$ta->[0]} : %$ta,
         );
  my @pa=(ref($pa) eq 'ARRAY' && @$pa)? @$pa : ('1.0','de'); ## (version,authority)
  return ('Net::DRI::Transport::Socket',[\%ta],'Net::DRI::Protocol::IRIS',\@pa);
 }
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{check_name => 1,
                                               my_tld => 1,
                                               icann_reserved => 1, ## is that right ??
                                              });
}

sub contact_update
{
 my ($self, $reg, $c, $changes, $rd) = @_;
 my $oc = $reg->get_info('self', 'contact', $c->srid());

 if (!defined($oc))
 {
  my $res = $reg->process('contact', 'info',
	[$reg->local_object('contact')->srid($c->srid())]);
  $oc = $reg->get_info('self', 'contact', $c->srid())
	if ($res->is_success());
 }

 $c->type($oc->type()) if (defined($oc));

 return $self->SUPER::contact_update($reg, $c, $changes, $rd);
}

sub domain_update
{
 my ($self, $reg, $dom, $changes, $rd) = @_;
 my $cs = $reg->get_info('contact', 'domain', $dom);
 my $ns = $reg->get_info('ns', 'domain', $dom);

 if (!defined($cs) || !defined($ns))
 {
  my $res = $reg->process('domain', 'info', [$dom]);
  $cs = $reg->get_info('contact', 'domain', $dom) if ($res->is_success());
  $ns = $reg->get_info('ns', 'domain', $dom) if ($res->is_success());
 }

 $rd->{contact} = $cs unless (defined($rd->{contact}));
 $rd->{ns} = $ns unless (defined($rd->{ns}));

 return $self->SUPER::domain_update($reg, $dom, $changes, $rd);
}

sub domain_trade
{
 my ($self, $reg, $dom, $rd) = @_;
 return $reg->process('domain', 'trade', [$dom, $rd]);
}

####################################################################################################
1;
