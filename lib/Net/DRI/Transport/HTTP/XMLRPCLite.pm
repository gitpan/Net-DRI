## Domain Registry Interface, XML-RPC Transport
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
#########################################################################################

package Net::DRI::Transport::HTTP::XMLRPCLite;

use base qw(Net::DRI::Transport);
use strict;

use Net::DRI::Exception;
use Net::DRI::Data::Raw;
use Net::DRI::Util;
use XMLRPC::Lite;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Transport::HTTP::XMLRPCLite - XML-RPC Transport for Net::DRI

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
 my $drd=shift;
 my $po=shift;
 my %opts=(@_==1 && ref($_[0]))? %{$_[0]} : @_;
 my $self=$class->SUPER::new(\%opts); ## We are now officially a Net::DRI::Transport instance
 $self->is_sync(1);
 $self->name('xmlrpclite');
 $self->version($VERSION);

 my %t=(message_factory => $po->factories()->{message});
 $t{trid_factory}=(exists($opts{trid}) && (ref($opts{trid}) eq 'CODE'))? $opts{trid} : \&Net::DRI::Util::create_trid_1;
 $t{has_login}=(exists($opts{has_login}) && defined($opts{has_login}))? $opts{has_login} : 0;
 $t{has_logout}=(exists($opts{has_logout}) && defined($opts{has_logout}))? $opts{has_logout} : 0;
 $self->has_state($t{has_login});
 if ($t{has_login})
 {
  foreach my $p (qw/client_login client_password/)
  {
   Net::DRI::Exception::usererr_insufficient_parameters($p.' must be provided') unless (exists($opts{$p}) && defined($opts{$p}));
   $t{$p}=$opts{$p};
  }
  $t{session_data}={};
 }

 foreach my $p (qw/protocol_connection wsdl_uri proxy_uri servicename portname/)
 {
  Net::DRI::Exception::usererr_insufficient_parameters($p.' must be provided') unless (exists($opts{$p}) && defined($opts{$p}));
  $t{$p}=$opts{$p};
 }
 Net::DRI::Exception::usererr_invalid_parameters('proxy_uri must be http:// or https://') unless ($t{proxy_uri}=~m!^https?://!);

 my $pc=$t{protocol_connection};
 $pc->require or Net::DRI::Exception::err_failed_load_module('transport/socket',$pc,$@);
 if ($t{has_login})
 {
  foreach my $m (qw/login parse_login extract_session/)
  {
   Net::DRI::Exception::usererr_invalid_parameters('Protocol connection class '.$pc.' must have a '.$m.'() method, since has_login=1') unless ($pc->can($m));
  }
 }

 if ($t{has_logout})
 {
  foreach my $m (qw/logout parse_logout/)
  {
   Net::DRI::Exception::usererr_invalid_parameters('Protocol connection class '.$pc.' must have a '.$m.'() method, since has_logout=1') unless ($pc->can($m));
  }
 }

 $self->{transport}=\%t;
 bless($self,$class);

 if ($self->has_state())
 {
  if ($self->defer()) ## we will open, but later
  {
   $self->current_state(0);
  } else ## we will open NOW 
  {
   $self->open_connection();
  }
 } else
 {
  $self->init();
  $self->time_open(time());
 }

 return $self;
}

sub soap { my ($self,$v)=@_; $self->{transport}->{soap}=$v if @_==2; return $self->{transport}->{soap}; }
sub session_data { my ($self,$v)=@_; $self->{transport}->{session_data}=$v if @_==2; return $self->{transport}->{session_data}; }

sub soap_fault
{
 my($soap,$res)=@_; 
 my $msg=ref($res)? $res->faultstring() : $soap->transport()->status();
 Net::DRI::Exception->die(1,'transport/http/soapwsdl',7,'SOAP fault: '.$msg);
}

sub init
{
 my ($self)=@_;
 return if defined($self->soap());
 my $soap=SOAP::WSDL->new()->on_fault(\&soap_fault);
 $soap->wsdl($self->{transport}->{wsdl_uri});
 $soap->proxy($self->{transport}->{proxy_uri});
 $soap->wsdlinit();
 $soap->servicename($self->{transport}->{servicename});
 $soap->portname($self->{transport}->{portname});
 $self->soap($soap);
}

sub send_login
{
 my ($self)=@_;
 my $t=$self->{transport};
 return unless $t->{has_login};
 foreach my $p (qw/client_login client_password/)
 {
  Net::DRI::Exception::usererr_insufficient_parameters($p.' must be defined') unless (exists($t->{$p}) && $t->{$p});
 }

 my $pc=$t->{protocol_connection};
 my $cltrid=$t->{trid_factory}->($self->name());
 my $login=$pc->login($t->{message_factory},$t->{client_login},$t->{client_password},$cltrid);
 my $res=$self->soap()->call( $login->method() => %{$login->params()});
 ## $self->logging($cltrid,1,0,1,$login);
 Net::DRI::Exception->die(1,'transport/soapwsdl',4,'Unable to send login message due to SOAP fault: '.$res->faultcode().' '.$res->faultstring()) if ($res->fault());
 ## $self->logging($cltrid,1,1,1,$dr);
 my $msg=$t->{message_factory}->();
 $msg->parse(Net::DRI::Data::Raw->new(1,[$res]));
 my $rc=$pc->parse_login($msg);
 die($rc) unless $rc->is_success();

 $self->session_data($pc->extract_session($msg));
}

sub send_logout
{
 my ($self)=@_;
 my $t=$self->{transport};
 return unless $t->{has_logout};

 my $pc=$t->{protocol_connection};
 my $cltrid=$t->{trid_factory}->($self->name());
 my $logout=$pc->logout($t->{message_factory},$cltrid,$t->{session_data});
 my $res=$self->soap()->call( $logout->method() => %{$logout->params()});
 ## $self->logging($cltrid,3,0,1,$logout);
 Net::DRI::Exception->die(1,'transport/soapwsdl',4,'Unable to send logout message due to SOAP fault: '.$res->faultcode().' '.$res->faultstring()) if ($res->fault());
 ## $self->logging($cltrid,3,1,1,$dr);
 my $msg=$t->{message_factory}->();
 $msg->parse(Net::DRI::Data::Raw->new(1,[$res]));
 my $rc=$pc->parse_logout($msg);
 die($rc) unless $rc->is_success();

 $self->session_data({});
}

sub open_connection
{
 my ($self)=@_;
 $self->init();
 $self->send_login();
 $self->current_state(1);
 $self->time_open(time());
 $self->time_used(time());
}

sub close_connection
{
 my ($self)=@_;
 $self->send_logout();
 $self->soap(undef);
 $self->current_state(0);
}

sub end
{
 my $self=shift;
 if ($self->has_state() && $self->current_state())
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
 $self->SUPER::send($trid,$tosend,\&_soap_send,sub {});
}

sub _soap_send
{
 my ($self,$count,$tosend)=@_;
 my $t=$self->{transport};
 $tosend->add_session($self->session_data());
 my $res=$self->soap()->call( $tosend->method() => %{$tosend->params()});
 $t->{last_reply}=$res;
 return 1; ## very important
}

sub receive
{
 my ($self,$trid)=@_;
 return $self->SUPER::receive($trid,\&_soap_receive);
}

sub _soap_receive
{
 my ($self,$count)=@_;
 my $t=$self->{transport};
 my $r=$t->{last_reply};
 $t->{last_reply}=undef;
 return Net::DRI::Data::Raw->new(1,[$r]);
}

####################################################################################################
1;
