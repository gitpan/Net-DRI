## Domain Registry Interface, Protocol superclass
##
## Copyright (c) 2005,2006 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol;

use strict;

use base qw(Class::Accessor::Chained::Fast);
__PACKAGE__->mk_accessors(qw(name version factories commands message capabilities default_parameters));

use Net::DRI::Exception;
use Net::DRI::Util;

our $VERSION=do { my @r=(q$Revision: 1.14 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol - Superclass of all Net::DRI Protocols

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

Copyright (c) 2005,2006 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut


##############################################################################################################

sub new
{
 my $h=shift;
 my $c=ref($h) || $h;
 my $self={}; ## more to do ?
 bless($self,$c);

 $self->message(undef);
 $self->capabilities({});
 $self->default_parameters({});
 return $self;
}

sub create_local_object
{
 my $self=shift;
 my $what=shift;
 my $fn=$self->factories();
 return unless (defined($fn) && ref($fn) && exists($fn->{$what}) && (ref($fn->{$what}) eq 'CODE'));
 return $fn->{$what}->(@_);
}

sub _load
{
 my $self=shift;
 my $etype='protocol/'.$self->name();
 my $version=$self->version();
 my $rcapa=$self->capabilities();

 my %c;
 foreach my $class (@_)
 {
  ## eval needed to make sure the variable is taken into account correctly;
  eval "require $class";
  Net::DRI::Exception->die(1,$etype,6,"Failed to load Perl module ${class}") if $@;
  Net::DRI::Exception::err_method_not_implemented("register_commands() in $class") unless $class->can('register_commands');
  my $rh=$class->register_commands($version);
  Net::DRI::Util::hash_merge(\%c,$rh); ## { object type => { action type => [ build action, parse action ]+ } }
  if ($class->can('capabilities_add'))
  {
   my $rca=$class->capabilities_add();
   Net::DRI::Util::hash_merge($rcapa,$rca);
  }
 }

 $self->commands(\%c);
} 

sub _load_commands
{
 my ($self,$otype,$oaction)=@_;

 my $etype='protocol/'.$self->name();
 Net::DRI::Exception->die(1,$etype,7,"Object type and/or action not defined") unless (defined($otype) && $otype && defined($oaction) && $oaction);
 my $h=$self->commands();
 Net::DRI::Exception->die(1,$etype,8,"No actions defined for object of type <${otype}>") unless exists($h->{$otype});
 Net::DRI::Exception->die(1,$etype,9,"No action name <${oaction}> defined for object of type <${otype}> in ".ref($self)) unless exists($h->{$otype}->{$oaction});
 return $h;
}

sub has_action
{
 my ($self,$otype,$oaction)=@_;
 eval {
  my $h=$self->_load_commands($otype,$oaction);
 };

 return ($@)? 0 : 1;
}

sub action
{
 my $self=shift;
 my $otype=shift;
 my $oaction=shift;
 my $trid=shift;
 my $h=$self->_load_commands($otype,$oaction);

 ## Create a new message from scratch and loop through all functions registered for given action & type
 my $f=$self->factories();
 my $msg=$f->{message}->($trid,$otype,$oaction);
 Net::DRI::Exception->die(0,'protocol',1,'Unsuccessfull message creation') unless ($msg && ref($msg) && $msg->isa('Net::DRI::Protocol::Message'));
 $self->message($msg); ## store it for later use (in loop below)
 
 foreach my $t (@{$h->{$otype}->{$oaction}})
 {
  my $pf=$t->[0];
  next unless (defined($pf) && (ref($pf) eq 'CODE'));
  $pf->($self,@_);
 }

 $self->message(undef); ## needed ? useful ?
 return $msg;
}

sub reaction
{
 my ($self,$otype,$oaction,$dr,$sent)=@_;
 my $h=$self->_load_commands($otype,$oaction);
 my $f=$self->factories();
 my $msg=$f->{message}->();
 Net::DRI::Exception->die(0,'protocol',1,'Unsuccessfull message creation') unless ($msg && ref($msg) && $msg->isa('Net::DRI::Protocol::Message'));

 my %info;
 $msg->parse($dr,\%info); ## will trigger an Exception by itself if problem
 $self->message($msg); ## store it for later use (in loop below)

 my $oname; ## Should be done by retrieving information from sent object (will be with LocalStorage) ## WARNING : what about messages for multiple names, like check_multi ?
 $oname=$sent->get_name_from_message() if $sent->can('get_name_from_message');
 $info{$otype}->{$oname}->{name}=$oname if (defined($oname) && $oname);

 foreach my $t (@{$h->{$otype}->{$oaction}})
 {
  my $pf=$t->[1];
  next unless (defined($pf) && (ref($pf) eq 'CODE'));
  $pf->($self,$otype,$oaction,$oname,\%info);
 }

 my $rc=$msg->result_status();
 $info{$otype}->{$oname}->{result_status}=$rc if (defined($oname) && $oname);
 $self->message(undef); ## needed ? useful ?

 return ($rc,\%info,$oname);
}

sub nameversion
{
 my $self=shift;
 return $self->name().'/'.$self->version();
}

##############################################################################################################
1;
