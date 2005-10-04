## Domain Registry Interface, TCP/SSL Socket Transport
##
## Copyright (c) 2005 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

our $VERSION=do { my @r=(q$Revision: 1.12 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Transport::Socket - TCP/TLS Socket connection for Net::DRI

=head1 DESCRIPTION

The following options are available at creation:

=over

=item *

C<defer> : do we open the connection right now (0) or later (1)

=item *

C<timeout> : time to wait (in seconds) for server reply

=item *

C<socktype> : ssl or tcp

=item *

C<ssl_key_file> C<ssl_cert_file> C<ssl_ca_file> C<ssl_ca_path> C<ssl_cipher_list> : if C<socktype> is 'ssl', all key materials

=item *

C<remote_host> / C<remote_port> : hostname (or IP address) & port number of endpoint

=item *

C<client_login> / C<client_password> : protocol login & password

=item *

C<protocol_connection> : Net::DRI class handling protocol connection details. (Ex: C<Net::DRI::Protocol::RRP::Connection> or C<Net::DRI::Protocol::EPP::Connection>)

=item *

C<close_after> : number of protocol commands to send to server (we will automatically close and re-open connection if needed)

=back

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Patrick Mevzek <netdri@dotandco.com>.
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

 my %opts=(@_==1 && ref($_[0]))? %{$_[0]} : @_;
 my $self=$class->SUPER::new(\%opts); ## We are now officially a Net::DRI::Transport instance
 $self->has_state(1);
 $self->is_sync(1);
 $self->name('socket_inet');
 $self->version('0.1');

 my %t;

 Net::DRI::Exception::usererr_insufficient_parameters("socktype must be defined") unless (exists($opts{socktype}));
 Net::DRI::Exception::usererr_invalid_parameters("socktype must be ssl or tcp") unless ($opts{socktype}=~m/^(ssl|tcp)$/);
 $t{socktype}=$opts{socktype};
 foreach my $p ('remote_host','remote_port','client_login','client_password','protocol_version')
 {
  Net::DRI::Exception::usererr_insufficient_parameters("$p must be defined") unless (exists($opts{$p}) && $opts{$p});
  $t{$p}=$opts{$p};
 }
 Net::DRI::Exception::usererr_insufficient_parameters("protocol_connection") unless (exists($opts{protocol_connection}) && $opts{protocol_connection});
 $t{pc}=$opts{protocol_connection};

 eval "require $t{pc}";
 my @need=qw/login logout parse_greeting parse_login parse_logout get_data/;
 Net::DRI::Exception::usererr_invalid_parameters('protocol_connection class must have: '.join(' ',@need)) if (grep { ! $t{pc}->can($_) } @need);

 Net::DRI::Exception::usererr_invalid_parameters("close_after must be an integer") if ($opts{close_after} && !Net::DRI::Util::isint($opts{close_after}));
 $t{close_after}=$opts{close_after} || 0;

 if ($t{socktype} eq 'ssl')
 {
  $IO::Socket::SSL::DEBUG=$opts{ssl_debug} if exists($opts{ssl_debug});

  my %s=(SSL_use_cert => 1);
  $s{SSL_verify_mod}=(exists($opts{ssl_verify}))? $opts{ssl_verify} : 0x01;
  foreach my $s ('key_file','cert_file','ca_file','ca_path')
  {
   next unless exists($opts{"ssl_$s"});
   $s{"SSL_$s"}=$opts{"ssl_$s"};
  }
  
  $t{ssl_context}=IO::Socket::SSL::context_init(\%s);
  Net::DRI::Exception->die(1,"transport/socket",6,"Unable to setup ssl context") unless (defined($t{ssl_context}));

  ## Library default: ALL:!ADH:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP
  $t{ssl_cipher_list}=(exists($opts{ssl_cipher_list}))? $opts{ssl_cipher_list} : 'ALL:!ADH:!LOW:+HIGH:+MEDIUM:+SSLv3'; ## 
 }

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

 if ($type eq 'ssl')
 {
  $sock=IO::Socket::SSL->new(PeerAddr => $t->{remote_host},
                             PeerPort => $t->{remote_port},
                             Proto    => 'tcp',
                             SSL_cipher_list => $t->{ssl_cipher_list},
                            );
 }
 if ($type eq 'tcp')
 {
  $sock=IO::Socket::INET->new(PeerAddr => $t->{remote_host},
                              PeerPort => $t->{remote_port},
                              Proto    => 'tcp',
                             );
 }

 Net::DRI::Exception->die(1,"transport/socket",6,"Unable to setup tcp socket") unless defined($sock);
 $sock->autoflush(1);
 $self->sock($sock);
}

sub send_login
{
 my $self=shift;
 my $t=$self->{transport};
 my $sock=$self->sock();
 my $pc=$t->{pc};
 my $cltrid=Net::DRI::Util::create_trid_1('transport');

 ## Get registry greeting
 my $dr=$pc->get_data($self,$sock);
 my $rc1=$pc->parse_greeting($dr); ## gives back a Net::DRI::Protocol::ResultStatus
 die($rc1) unless $rc1->is_success();
 my $login=$pc->login($t->{client_login},$t->{client_password},$cltrid,$dr);
 Net::DRI::Exception->die(0,'transport/socket',4,'Unable to send login message') unless ($sock->print($login));

 ## Verify login successful
 $dr=$pc->get_data($self,$sock);
 my $rc2=$pc->parse_login($dr); ## gives back a Net::DRI::Protocol::ResultStatus
 die($rc2) unless $rc2->is_success();
}

sub send_logout
{
 my $self=shift;
 my $t=$self->{transport};
 my $sock=$self->sock();
 my $pc=$t->{pc};
 my $cltrid=Net::DRI::Util::create_trid_1('transport');

 my $logout=$pc->logout($cltrid);
 Net::DRI::Exception->die(0,'transport/socket',4,'Unable to send logout message') unless ($sock->print($logout));
 my $dr=$pc->get_data($self,$sock);
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
 $self->{transport}->{exchanges_done}=0;
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
   local $SIG{ALRM}=sub { die "timeout" };
   alarm(10);
   $self->close_connection();
   alarm(0);
  };
 }
}

##########################################################################################

sub send
{
 my ($self,$tosend)=@_;
 $self->SUPER::send($tosend,\&_print,sub {});
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
 my ($self)=@_;

 return $self->SUPER::receive(\&_get);
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
 if ($t->{exchanges_done}==$t->{close_after})
 {
  $self->close_connection();
 }

 return $dr;
}

########################################################################################################
1;
