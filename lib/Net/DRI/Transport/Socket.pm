## Domain Registry Interface, TCP/SSL Socket Transport
##
## Copyright (c) 2005,2006,2007 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Transport::Socket;

use base qw(Net::DRI::Transport);

use strict;

use IO::Socket::INET;
## At least this version is needed, to have getline()
use IO::Socket::SSL 0.90;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Data::Raw;

our $VERSION=do { my @r=(q$Revision: 1.24 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Transport::Socket - TCP/TLS Socket connection for Net::DRI

=head1 DESCRIPTION

This module implements a socket (tcp or tls) for establishing connections in Net::DRI

=head1 METHODS

At creation (see Net::DRI C<new_profile>) you pass a reference to an hash, with the following available keys:

=head2 defer
 
do we open the connection right now (0) or later (1)

=head2 timeout

time to wait (in seconds) for server reply

=head2 socktype

ssl or tcp

=head2 ssl_key_file ssl_cert_file ssl_ca_file ssl_ca_path ssl_cipher_list ssl_version

if C<socktype> is 'ssl', all key materials

=head2 ssl_verify ssl_verify_callback

see IO::Socket::SSL documentation about verify_mode (by default 0x00 here) and verify_callback (used only if provided)

=head2 remote_host remote_port

hostname (or IP address) & port number of endpoint

=head2 client_login client_password

protocol login & password

=head2 client_newpassword

(optional) new password if you want to change password on login for registries handling that at connection

=head2 protocol_connection

Net::DRI class handling protocol connection details. (Ex: C<Net::DRI::Protocol::RRP::Connection> or C<Net::DRI::Protocol::EPP::Connection>)

=head2 protocol_data

(optional) opaque data given to protocol_connection class.
For EPP, a key login_service_filter may exist, whose value is a code ref. It will be given an array of services, and should give back a
similar array; it can be used to filter out some services from those given by the registry.

=head2 close_after

number of protocol commands to send to server (we will automatically close and re-open connection if needed)

=head2 log_fh

either a reference to something that have a print() method or a filehandle (ex: \*STDERR or an anonymous filehandle) on something already opened for write ;
if defined, all exchanges (messages sent to server, messages received from server) will be printed to this filehandle

=head2 local_host 

(optional) the local address (hostname or IP) you want to use to connect

=head2 trid 

(optional) code reference of a subroutine generating transaction id ; if not defined, Net::DRI::Util::create_trid_1 is used

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005,2006,2007 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

################################################################################################################
sub new
{
 my $proto=shift;
 my $class=ref($proto) || $proto;

 my $drd=shift;
 my $po=shift;

 my %opts=(@_==1 && ref($_[0]))? %{$_[0]} : @_;
 my $self=$class->SUPER::new(\%opts); ## We are now officially a Net::DRI::Transport instance
 $self->has_state(1);
 $self->is_sync(1);
 $self->name('socket_inet');
 $self->version('0.1');

 my %t=(message_factory => $po->factories()->{message});
 $t{trid_factory}=(exists($opts{trid}) && (ref($opts{trid}) eq 'CODE'))? $opts{trid} : \&Net::DRI::Util::create_trid_1;

 Net::DRI::Exception::usererr_insufficient_parameters('socktype must be defined') unless (exists($opts{socktype}));
 Net::DRI::Exception::usererr_invalid_parameters('socktype must be ssl or tcp') unless ($opts{socktype}=~m/^(ssl|tcp)$/);
 $t{socktype}=$opts{socktype};
 $t{client_login}=$opts{client_login};
 $t{client_password}=$opts{client_password};
 $t{client_newpassword}=$opts{client_newpassword} if (exists($opts{client_newpassword}) && $opts{client_newpassword});
 foreach my $p ('remote_host','remote_port','protocol_version')
 {
  Net::DRI::Exception::usererr_insufficient_parameters($p.' must be defined') unless (exists($opts{$p}) && $opts{$p});
  $t{$p}=$opts{$p};
 }
 Net::DRI::Exception::usererr_insufficient_parameters('protocol_connection') unless (exists($opts{protocol_connection}) && $opts{protocol_connection});
 $t{pc}=$opts{protocol_connection};
 $t{protocol_data}=$opts{protocol_data} if (exists($opts{protocol_data}) && $opts{protocol_data});

 eval 'require '.$t{pc}; ## no critic (ProhibitStringyEval)
 my @need=qw/get_data/;
 Net::DRI::Exception::usererr_invalid_parameters('protocol_connection class must have: '.join(' ',@need)) if (grep { ! $t{pc}->can($_) } @need);

 Net::DRI::Exception::usererr_invalid_parameters('close_after must be an integer') if ($opts{close_after} && !Net::DRI::Util::isint($opts{close_after}));
 $t{close_after}=$opts{close_after} || 0;

 if ($t{socktype} eq 'ssl')
 {
  $IO::Socket::SSL::DEBUG=$opts{ssl_debug} if exists($opts{ssl_debug});

  my %s=(SSL_use_cert => 0);
  $s{SSL_verify_mode}=(exists($opts{ssl_verify}))? $opts{ssl_verify} : 0x00; ## by default, no authentication whatsoever
  $s{SSL_verify_callback}=$opts{ssl_verify_callback} if (exists($opts{ssl_verify_callback}) && defined($opts{ssl_verify_callback}));
  foreach my $s ('key_file','cert_file','ca_file','ca_path','version')
  {
   next unless exists($opts{'ssl_'.$s});
   $s{'SSL_'.$s}=$opts{'ssl_'.$s};
  }
  $s{SSL_use_cert}=1 if exists($s{SSL_cert_file});

  ## Library default: ALL:!ADH:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP
  $s{SSL_cipher_list}=(exists($opts{ssl_cipher_list}))? $opts{ssl_cipher_list} : 'ALL:!ADH:!LOW:+HIGH:+MEDIUM:+SSLv3';

  $t{ssl_context}=\%s;
 }

 $t{local_host}=$opts{local_host} if (exists($opts{local_host}) && $opts{local_host});

 $self->{transport}=\%t;
 bless($self,$class); ## rebless in my class
 
 if ($self->defer()) ## we will open, but later
 {
  $self->current_state(0);
 } else ## we will open NOW 
 {
  $self->open_connection();
  $self->current_state(1);
 }

 return $self;
}

sub sock { my ($self,$v)=@_; $self->{transport}->{sock}=$v if defined($v); return $self->{transport}->{sock}; }

sub open_socket
{
 my $self=shift;
 my $t=$self->{transport};
 my $type=$t->{socktype};
 my $sock;
 
 my %n=( PeerAddr   => $t->{remote_host},
         PeerPort   => $t->{remote_port},
         Proto      => 'tcp',
         Blocking   => 1,
	 MultiHomed => 1,
       );
 $n{LocalAddr}=$t->{local_host} if exists($t->{local_host});

 if ($type eq 'ssl')
 {
  $sock=IO::Socket::SSL->new(%{$t->{ssl_context}},
                             %n,
                            );
 }
 if ($type eq 'tcp')
 {
  $sock=IO::Socket::INET->new(%n);
 }

 Net::DRI::Exception->die(1,'transport/socket',6,'Unable to setup the '.$type.' socket'.($type eq 'ssl'? ' with SSL error: '.IO::Socket::SSL::errstr() : '')) unless defined($sock);
 $sock->autoflush(1);
 $self->sock($sock);
}

sub send_login
{
 my $self=shift;
 my $t=$self->{transport};
 my $sock=$self->sock();
 my $pc=$t->{pc};

 return unless ($pc->can('parse_greeting') && $pc->can('login') && $pc->can('parse_login'));
 foreach my $p (qw/client_login client_password/)
 {
  Net::DRI::Exception::usererr_insufficient_parameters($p.' must be defined') unless (exists($t->{$p}) && $t->{$p});
 }

 ## Get registry greeting
 my $cltrid=$t->{trid_factory}->($self->name());
 my $dr=$pc->get_data($self,$sock);
 $self->logging($cltrid,1,1,1,$dr);
 my $rc1=$pc->parse_greeting($dr); ## gives back a Net::DRI::Protocol::ResultStatus
 die($rc1) unless $rc1->is_success();
 my $login=$pc->login($t->{message_factory},$t->{client_login},$t->{client_password},$cltrid,$dr,$t->{client_newpassword},$t->{protocol_data});
 $self->logging($cltrid,1,0,1,$login);
 Net::DRI::Exception->die(0,'transport/socket',4,'Unable to send login message') unless ($sock->print($login));

 ## Verify login successful
 $dr=$pc->get_data($self,$sock);
 $self->logging($cltrid,1,1,1,$dr);
 my $rc2=$pc->parse_login($dr); ## gives back a Net::DRI::Protocol::ResultStatus
 die($rc2) unless $rc2->is_success();
}

sub send_logout
{
 my $self=shift;
 my $t=$self->{transport};
 my $sock=$self->sock();
 my $pc=$t->{pc};

 return unless ($pc->can('logout') && $pc->can('parse_logout'));

 my $cltrid=$t->{trid_factory}->($self->name());
 my $logout=$pc->logout($t->{message_factory},$cltrid);
 $self->logging($cltrid,3,0,1,$logout);
 Net::DRI::Exception->die(0,'transport/socket',4,'Unable to send logout message') unless ($sock->print($logout));
 my $dr=$pc->get_data($self,$sock); ## We expect this to throw an exception, since the server will probably cut the connection
 $self->logging($cltrid,3,1,1,$dr);
 my $rc1=$pc->parse_logout($dr);
 die($rc1) unless $rc1->is_success();
}

sub open_connection
{
 my ($self)=@_;
 $self->open_socket();
 $self->send_login();
 $self->current_state(1);
 $self->time_open(time());
 $self->time_used(time());
 $self->{transport}->{exchanges_done}=0;
}

sub ping
{
 my ($self,$autorecon)=@_;
 $autorecon||=0;
 my $t=$self->{transport};
 my $sock=$self->sock();
 my $pc=$t->{pc};
 Net::DRI::Exception::err_method_not_implemented() unless ($pc->can('keepalive') && $pc->can('parse_keepalive'));

 my $cltrid=$t->{trid_factory}->($self->name());
 eval
 {
  local $SIG{ALRM}=sub { die 'timeout' };
  alarm(10);
  my $noop=$pc->keepalive($t->{message_factory},$cltrid);
  $self->logging($cltrid,2,0,1,$noop);
  Net::DRI::Exception->die(0,'transport/socket',4,'Unable to send ping message') unless ($sock->print($noop));
  $self->time_used(time());
  $t->{exchanges_done}++;
  my $dr=$pc->get_data($self,$sock);
  $self->logging($cltrid,2,1,1,$dr);
  my $rc=$pc->parse_keepalive($dr);
  die($rc) unless $rc->is_success();
 };
 alarm(0);

 if ($@)
 {
  $self->current_state(0);
  $self->open_connection() if $autorecon;
 } else
 {
  $self->current_state(1);
 }
 return $self->current_state();
}

sub close_connection
{
 my ($self)=@_;
 $self->send_logout();
 $self->sock()->close();
 $self->sock(undef);
 $self->current_state(0);
}

sub end
{
 my $self=shift;
 if ($self->current_state())
 {
  eval
  {
   local $SIG{ALRM}=sub { die 'timeout' };
   alarm(10);
   $self->close_connection();
  };
  alarm(0); ## since close_connection may die, this must be outside of eval to be executed in all cases
 }
}

####################################################################################################

sub send
{
 my ($self,$trid,$tosend)=@_;
 ## We do a very crude error handling : if first send fails, we reset connection.
 ## Thus if you put retry=>2 when creating this object, the connection will be re-established and the message resent
 $self->SUPER::send($trid,$tosend,\&_print,sub { shift->current_state(0) });
}

sub _print ## here we are sure open_connection() was called before
{
 my ($self,$count,$tosend)=@_;
 my $sock=$self->sock();

 Net::DRI::Exception->die(0,'transport/socket',4,'Unable to send message') unless ($sock->print($tosend->as_string('tcp')));
 return 1; ## very important
}

sub receive
{
 my ($self,$trid)=@_;

 return $self->SUPER::receive($trid,\&_get);
}

sub _get
{
 my ($self,$count)=@_;
 my $t=$self->{transport};
 my $sock=$self->sock();
 my $pc=$t->{pc};

 ## Answer
 my $dr=$pc->get_data($self,$sock);

 ## Do we allow other messages ?
 $t->{exchanges_done}++;
 if ($t->{exchanges_done}==$t->{close_after} && $self->current_state())
 {
  $self->close_connection();
 }

 return $dr;
}

########################################################################################################
1;
