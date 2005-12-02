## Domain Registry Interface, Superclass of all Transport/* modules (hence virtual class, never used directly)
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

package Net::DRI::Transport;

use strict;

use base qw(Class::Accessor::Chained::Fast);
__PACKAGE__->mk_accessors(qw/name version retry pause trace timeout defer current_state has_state is_sync time_open/);

use Net::DRI::Exception;
use Time::HiRes;

our $VERSION=do { my @r=(q$Revision: 1.9 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Transport - Superclass of all Net::DRI Transports

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

Copyright (c) 2005 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

########################################################################################################
sub new
{
 my $proto=shift;
 my $class=ref($proto) || $proto;

 my %opts=(@_==1 && ref($_[0]))? %{$_[0]} : @_;
 my $self={
 	   is_sync   => exists($opts{is_sync})? $opts{is_sync} : 1, ## do we need to wait for reply as soon as command sent ?
           retry     => exists($opts{retry})?   $opts{retry}   : 1,  ## by default, we will try once only
           pause     => exists($opts{pause})?   $opts{pause}   : 10, ## time in seconds to wait between two retries
#           trace     => exists($opts{trace})?   $opts{trace}   : 0, ## NOT IMPL
           timeout   => exists($opts{timeout})? $opts{timeout} : 0,
           defer     => exists($opts{defer})?   $opts{defer}   : 0, ## defer opening connection as long as possible (irrelevant if stateless) ## XX maybe not here, too low
           log_fh    => exists($opts{log_fh})? $opts{log_fh} : undef,
           current_state => undef, ## for stateless transport, otherwise 0=close, 1=open
           has_state     => undef, ## do we need to open a session before sending commands ?
           transport     => undef, ## will be defined in subclasses
           creation      => time(),
          };

 bless($self,$class);
 return $self;
}

sub send
{
 my ($self,$tosend,$cb1,$cb2)=@_; ## $cb1=how to send, $cb2=how to test if fatal (to break loop) or not (retry once more)

 Net::DRI::Exception::err_insufficient_parameters() unless ($cb1 && (ref($cb1) eq 'CODE'));

 my $timeout=$self->timeout();
 my $prevalarm=alarm(0); ## removes current alarm
 my $c=1;
 my $ok=0;
 for (1)
 {
  eval
  {
   local $SIG{ALRM}=sub { die "timeout" };
   alarm($timeout) if ($timeout);

   ## Try to reconnect if needed
   $self->open_connection() if ($self->has_state() && !$self->current_state());
   $self->log('C=>S',$tosend);
   $ok=$self->$cb1($c,$tosend);
  }; ## end of try

  alarm(0) if ($timeout); ## removes our alarm
  if ($@) ## some die happened inside the eval
  {
   die($@) if (ref($@) eq 'Net::DRI::Protocol::ResultStatus');
   my $is_timeout=(!ref($@) && ($@=~m/timeout/))? 1 : 0;
   $@=Net::DRI::Exception->new(1,'internal',0,"Error not handled: $@") unless ref($@);
   die($@) unless ($cb2 && (ref($cb2) eq 'CODE'));
   $self->$cb2($@,$c,$is_timeout,$ok); ## will determine if 1) we break now the loop/we propagate the error (fatal error) 2) we retry
  }

  last if ($ok);
  last if (++$c > $self->retry());
  sleep($self->pause()) if $self->pause();
 } ## end of loop, no more retries

 ## Get inner error message ?
 Net::DRI::Exception->die(0,'transport',4,'Unable to send message to registry') unless $ok;
 
 alarm($prevalarm) if $prevalarm; ## re-enable previous alarm (warning, time is off !!)
}

sub receive
{
 my ($self,$cb1,$cb2)=@_;
 Net::DRI::Exception::err_insufficient_parameters() unless ($cb1 && (ref($cb1) eq 'CODE'));
 my $timeout=$self->timeout();
 my $prevalarm=alarm(0); ## removes current alarm
 my $c=1;
 my $ans;

 for (1)
 {
  eval
  {
   local $SIG{ALRM}=sub { die "timeout" };
   alarm($timeout) if ($timeout);

   $ans=$self->$cb1($c);
  }; ## end of try

  alarm(0) if ($timeout); ## removes our alarm
  if ($@) ## some die happened inside the eval
  {
   my $is_timeout=(!ref($@) && ($@=~m/timeout/))? 1 : 0;
   $@=Net::DRI::Exception->new(1,'internal',0,"Error not handled: $@") unless ref($@);
   die($@) unless ($cb2 && (ref($cb2) eq 'CODE'));
   $self->$cb2($@,$c,$is_timeout,defined($ans)); ## will determine if 1) we break now the loop/we propagate the error (fatal error) 2) we retry
  }

  last if (defined($ans));
  last if (++$c > $self->retry());
  sleep($self->pause()) if $self->pause();
 } ## end of loop, no more retries

 Net::DRI::Exception->die(0,'transport',5,'Unable to receive message from registry') unless defined($ans);

 alarm($prevalarm) if $prevalarm; ## re-enable previous alarm (warning, time is off !!)
 $self->log('C<=S',$ans);
 return $ans;
}

sub log
{
 my $self=shift;
 my $fh=$self->{log_fh};
 return unless defined($fh);
 my $tp=join(' ',map {UNIVERSAL::can($_,'as_string')? $_->as_string() : $_} @_);
 $tp=~s/^\s+//mg;
 $tp=~s/\s+$//mg;
 $tp=~s/\n/ /g;
 $tp=~s/> </></g;
 my ($t,$v)=Time::HiRes::gettimeofday();
 my @t=localtime($t);
 my $when=sprintf('%d-%02d-%02d %02d:%02d:%02d.%06d',1900+$t[5],$t[4],$t[3],$t[2],1+$t[1],$t[0],$v);
 $tp=$when.' '.$tp."\n";
 if (UNIVERSAL::can($fh,'print'))
 {
  $fh->print($tp);
 } else
 {
  print $fh $tp;
 }
}

####################################################################################################
## Returns 1 if we are still connected, 0 otherwise (and sets current_state to 0)
sub ping
{
 my $self=shift;
 return unless $self->has_state();
 Net::DRI::Exception::err_method_not_implemented();
}

sub open_connection
{
 my $self=shift;
 return unless $self->has_state();
 Net::DRI::Exception::err_method_not_implemented();
}

sub end
{
 my $self=shift;
 return unless $self->has_state();
 Net::DRI::Exception::err_method_not_implemented();
}

####################################################################################################
1;
