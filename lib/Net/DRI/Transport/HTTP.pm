## Domain Registry Interface, HTTP/HTTPS Transport
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

package Net::DRI::Transport::HTTP;

use base qw(Net::DRI::Transport);
use strict;

use Net::DRI::Exception;
use Net::DRI::Util;

use LWP::UserAgent;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Transport::HTTP - HTTP/HTTPS Transport for Net::DRI

=head1 DESCRIPTION

This module implements an HTTP/HTTPS stream for establishing connections in Net::DRI

=head1 METHODS

At creation (see Net::DRI C<new_profile>) you pass a reference to an hash, with the following available keys:

=head2 timeout

time to wait (in seconds) for server reply

=head2 https_debug https_version https_cert_file https_key_file https_ca_file https_ca_dir

all key materials for https access, if needed

=head2 remote_url

URL to access

=head2 client_login client_password

protocol login & password

=head2 client_newpassword

(optional) new password if you want to change password on login for registries handling that at connection

=head2 protocol_connection

Net::DRI class handling protocol connection details. (Ex: C<Net::DRI::Protocol::OpenSRS::XCP::Connection> or C<Net::DRI::Protocol::EPP::Extensions::PL::Connection>)

=head2 protocol_data

(optional) opaque data given to protocol_connection class.
For EPP, a key login_service_filter may exist, whose value is a code ref. It will be given an array of services, and should give back a
similar array; it can be used to filter out some services from those given by the registry.

=head2 log_fh

(optional) either a reference to something that have a print() method or a filehandle (ex: \*STDERR or an anonymous filehandle) on something already opened for write ;
if defined, all exchanges (messages sent to server, messages received from server) will be printed to this filehandle

=head2 verify_response

(optional) a callback (code ref) executed after each exchange with the registry, being called with the following parameters: the transport object,
the phase (1 for greeting+login, 2 for all normal operations, 3 for logout), the count (if we retried multiple times to send the same message),
the message sent (HTTP::Request object) and the response received (HTTP::Response object). This can be used to verify/diagnose SSL details,
see example in file t/704opensrs_xcp_live.t

=head2 local_host

(optional) the local address (hostname or IP) you want to use to connect (if you are multihomed)

=head2 trid

(optional) code reference of a subroutine generating transaction id ; if not defined, Net::DRI::Util::create_trid_1 is used

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

## These ENV keys will be set each time just before doing HTTP stuff, making sure to remove pre-existing ones beforehand
## This should enable us to deal with multiple endpoints with various parameters at the same time (BUT this should be really tested)
our @HTTPS_ENV=qw/HTTPS_DEBUG HTTPS_VERSION HTTPS_CERT_FILE HTTPS_KEY_FILE HTTPS_CA_FILE HTTPS_CA_DIR/;

sub new
{
 my $class=shift;
 my $drd=shift;
 my $po=shift;

 my %opts=(@_==1 && ref($_[0]))? %{$_[0]} : @_;
 my $self=$class->SUPER::new(\%opts); ## We are now officially a Net::DRI::Transport instance
 $self->has_state(1); ## some registries need login (like .PL) some not (like .ES) ; see end of method & call to open_connection()
 $self->is_sync(1);
 $self->name('http');
 $self->version($VERSION);

 if (exists($opts{log_fh}) && defined($opts{log_fh})) ## convert to new api
 {
  $self->{logging}=[ \&_http_dump_to_filehandle,$opts{log_fh} ];
 }

 my %t=(message_factory => $po->factories()->{message});
 $t{trid_factory}=(exists($opts{trid}) && (ref($opts{trid}) eq 'CODE'))? $opts{trid} : \&Net::DRI::Util::create_trid_1;
 foreach my $k (qw/client_login client_password client_newpassword protocol_data/)
 {
  $t{$k}=$opts{$k} if exists($opts{$k});
 }
 Net::DRI::Exception::usererr_insufficient_parameters('protocol_connection') unless (exists($opts{protocol_connection}) && $opts{protocol_connection});
 $t{pc}=$opts{protocol_connection};
 $t{pc}->require() or Net::DRI::Exception::err_failed_load_module('transport/http',$t{pc},$@);
 my @need=qw/read_data write_message/;
 Net::DRI::Exception::usererr_invalid_parameters('protocol_connection class must have: '.join(' ',@need)) if (grep { ! $t{pc}->can($_) } @need);
 $t{protocol_data}=$opts{protocol_data} if (exists($opts{protocol_data}) && $opts{protocol_data});
 Net::DRI::Exception::usererr_insufficient_parameters('remote_url must be defined') unless (exists($opts{'remote_url'}) && defined($opts{'remote_url'}) && $opts{remote_url}=~m!^https?://\S+/\S*$!);
 $t{remote_url}=$opts{remote_url};

 my $ua=LWP::UserAgent->new();
 $ua->agent(sprintf('Net::DRI/%s Net::DRI::Transport::HTTP/%s ',$Net::DRI::VERSION,$VERSION)); ## the final space triggers LWP::UserAgent to add its own string
 $ua->cookie_jar({}); ## Cookies needed by some registries, like .PL (how strange !)
 ## Now some security settings
 $ua->max_redirect(0);
 $ua->parse_head(0);
 $ua->protocols_allowed(['http','https']);
 $ua->timeout($self->timeout()) if $self->timeout(); ## problem with our own alarm ?
 $t{ua}=$ua;

 $t{local_host}=$opts{local_host} if (exists($opts{local_host}) && $opts{local_host});
 $t{setenv}=0;
 foreach my $k (map { lc } @HTTPS_ENV) ## Backport this stuff to other Transport modules in order to handle multiple differents sets of env values ?
 {
  next unless (exists($opts{$k}) && defined($opts{$k}));
  $t{setenv}=1;
  $t{$k}=$opts{$k};
 }

 $t{verify_response}=$opts{verify_response} if (exists($opts{verify_response}) && defined($opts{verify_response}) && (ref($opts{verify_response}) eq 'CODE'));
 $self->{transport}=\%t;
 $t{pc}->init($self) if $t{pc}->can('init');

 $self->open_connection(); ## noop for registries without login, will properly setup has_state()
 return $self;
}

sub _http_dump_to_filehandle ## not a class method
{
 my ($fh,$tname,$tversion,$trid,$step,$dir,$type,$data)=@_; ## $tname,$tversion,$step not used here
 my $c=(ref($data) && UNIVERSAL::can($data,'as_string'))? $data->as_string() : $data; ## HTTP::{Request,Response} have an as_string() method !
 Net::DRI::Transport::dump_to_filehandle($fh,$tname,$tversion,$trid,$step,$dir,2,$c);
}

sub send_login
{
 my ($self)=@_;
 my $t=$self->transport_data();
 my $pc=$t->{pc};
 my ($cltrid,$dr);

 ## Get registry greeting, if available
 if ($pc->can('greeting') && $pc->can('parse_greeting'))
 {
  $cltrid=$t->{trid_factory}->($self->name()); ## not used for greeting (<hello> has no clTRID), but used in logging
  my $greeting=$pc->greeting($self,$t->{message_factory});
  $self->logging($cltrid,1,0,2,$greeting);
  Net::DRI::Exception->die(0,'transport/http',4,'Unable to send greeting message') unless $self->_http_send(1,$greeting,1);
  $dr=$self->_http_receive(1);
  $self->logging($cltrid,1,1,1,$dr);
  my $rc1=$pc->parse_greeting($dr); ## gives back a Net::DRI::Protocol::ResultStatus
  die($rc1) unless $rc1->is_success();
 }

 my $login=$pc->login($self,$t->{message_factory},$t->{client_login},$t->{client_password},$cltrid,$dr,$t->{client_newpassword},$t->{protocol_data});
 $self->logging($cltrid,1,0,2,$login);
 Net::DRI::Exception->die(0,'transport/http',4,'Unable to send login message') unless $self->_http_send(1,$login,1);
 $dr=$self->_http_receive(1);
 $self->logging($cltrid,1,1,1,$dr);
 my $rc2=$pc->parse_login($dr); ## gives back a Net::DRI::Protocol::ResultStatus
 die($rc2) unless $rc2->is_success();
}

sub open_connection
{
 my $self=shift;
 my $t=$self->transport_data();
 my $pc=$t->{pc};
 $self->has_state(0);

 if ($pc->can('login') && $pc->can('parse_login'))
 {
  $self->send_login();
  $self->has_state(1);
  $self->current_state(1);
 }
 $self->time_open(time());
 $self->time_used(time());
 $self->transport_data()->{exchanges_done}=0;

}

sub send_logout
{
 my $self=shift;
 my $t=$self->transport_data();
 my $pc=$t->{pc};

 return unless ($pc->can('logout') && $pc->can('parse_logout'));

 my $cltrid=$t->{trid_factory}->($self->name());
 my $logout=$pc->logout($self,$t->{message_factory},$cltrid);
 $self->logging($cltrid,3,0,2,$logout);
 Net::DRI::Exception->die(0,'transport/http',4,'Unable to send logout message') unless $self->_http_send(1,$logout,3);
 my $dr=$self->_http_receive(1);
 $self->logging($cltrid,3,1,1,$dr);
 my $rc1=$pc->parse_logout($dr);
 die($rc1) unless $rc1->is_success();
}

sub close_connection
{
 my $self=shift;
 $self->send_logout() if ($self->has_state() && $self->current_state());
 $self->transport_data()->{ua}->cookie_jar({});
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

sub send
{
 my ($self,$trid,$tosend)=@_;
 $self->SUPER::send($trid,$tosend,\&_http_send,sub {});
}

sub _http_send
{
 my ($self,$count,$tosend,$phase)=@_;
 $phase=2 unless defined($phase); ## Phase 2 = normal operations (1=greeting+login, 3=logout)
 my $t=$self->transport_data();

 ## Having two lines put the warnings away. This module is loaded by LWP::UserAgent anyway.
 @LWP::Protocol::http::EXTRA_SOCK_OPTS=();
 @LWP::Protocol::http::EXTRA_SOCK_OPTS=( LocalAddr => $t->{local_host} ) if exists($t->{local_host});
 if ($t->{setenv})
 {
  foreach my $k (map { lc } @HTTPS_ENV)
  {
   delete($ENV{uc($k)});
   next unless exists($t->{$k});
   $ENV{uc($k)}=$t->{$k};
  }
 }

 ## Content-Length is automatically computed and added during the request() call, no need to do it before
 my $req=$t->{pc}->write_message($self,$tosend); ## gives back an HTTP::Request object
 Net::DRI::Util::check_isa($req,'HTTP::Request');
 my $ans=$t->{ua}->request($req);
 $t->{verify_response}->($self,$phase,$count,$req,$ans) if exists($t->{verify_response});
 $t->{last_reply}=$ans;
 return 1; ## very important
}

sub receive
{
 my ($self,$trid)=@_;
 return $self->SUPER::receive($trid,\&_http_receive);
}

sub _http_receive
{
 my ($self,$count)=@_;
 my $t=$self->transport_data();

 ## Convert answer in a Net::DRI::Data::Raw object
 my $dr=$t->{pc}->read_data($self,$t->{last_reply});
 Net::DRI::Util::check_isa($dr,'Net::DRI::Data::Raw');
 $t->{last_reply}=undef;
 $t->{exchanges_done}++;
 return $dr;
}

#####################################################################################################
1;
