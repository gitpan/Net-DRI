## Domain Registry Interface, Registry object
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

package Net::DRI::Registry;

use strict;

use base qw(Class::Accessor::Chained::Fast);
__PACKAGE__->mk_ro_accessors(qw(name driver profile trid)); ## READ-ONLY !!

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Protocol::ResultStatus;
use Net::DRI::Data::RegistryObject;

our $AUTOLOAD;

our $VERSION=do { my @r=(q$Revision: 1.13 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Registry - Specific instance of driver inside Net::DRI

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


##############################################################################################
sub new
{
 my $proto=shift;
 my $class=ref($proto) || $proto;

 my ($name,$drd,$cache,$trid)=@_;

 my $self={name   => $name,
           driver => $drd,
           cache  => $cache,
           profiles => {}, ## { profile name => { protocol  => X 
                           ##                     transport => X
                           ##                     status    => Net::DRI::Protocol::ResultStatus
                           ##                     %extra
                           ##                   }
                           ## }
           profile => undef, ## current profile
           auto_target => {},
           last_data => {},
           trid => $trid,
          };

 bless($self,$class);
 return $self;
}

sub available_profiles
{
 my $self=shift;
 return keys(%{$self->{profiles}});
}

sub exist_profile
{
 my ($self,$name)=@_;
 return (defined($name) && exists($self->{profiles}->{$name}));
}

sub err_no_current_profile           { Net::DRI::Exception->die(0,'DRI',3,"No current profile available"); }
sub err_profile_name_does_not_exist  { Net::DRI::Exception->die(0,'DRI',4,"Profile name $_[0] does not exist"); }

sub remote_object
{
 my $self=shift;
 return Net::DRI::Data::RegistryObject->new($self,@_);
}

sub _current
{
 my ($self,$what,$tostore)=@_;
 err_no_current_profile()                          unless (defined($self->{profile}));
 err_profile_name_does_not_exist($self->{profile}) unless (exists($self->{profiles}->{$self->{profile}}));
 Net::DRI::Exception::err_method_not_implemented($what) unless (exists($self->{profiles}->{$self->{profile}}->{$what}));

 if (($what eq 'status') && $tostore)
 {
  $self->{profiles}->{$self->{profile}}->{$what}=$tostore;
 }

 return $self->{profiles}->{$self->{profile}}->{$what};
}

sub transport { return shift->_current('transport'); }
sub protocol  { return shift->_current('protocol');  }
sub status    { return shift->_current('status',@_); }

sub create_status { return shift->_current('protocol')->create_local_object('status',@_); }

sub local_object { return shift->_current('protocol')->create_local_object(@_); }

sub protocol_transport { my $self=shift; return ($self->protocol(),$self->transport()); }


sub _result
{
 my ($self,$f)=@_;
 my $p=$self->profile();
 err_no_current_profile() unless (defined($p));
 Net::DRI::Exception->die(0,'DRI',6,"No last status code available for current registry and profile") unless (exists($self->{profiles}->{$p}->{status}));
 my $rc=$self->{profiles}->{$p}->{status}; ## a Net::DRI::Protocol::ResultStatus object !
 Net::DRI::Exception->die(1,'DRI',5,'Status key if not a Net::DRI::Protocol::ResultStatus object') unless UNIVERSAL::isa($rc,'Net::DRI::Protocol::ResultStatus');
 Net::DRI::Exception->die(1,'DRI',5,"Method $f not implemented in Net::DRI::Protocol::ResultStatus") unless ($f && $rc->can($f));

 return $rc->$f();
}

sub result_is_success  { return shift->_result('is_success');  }
sub is_success         { return shift->_result('is_success');  } ## Alias
sub result_code        { return shift->_result('code');        }
sub result_native_code { return shift->_result('native_code'); }
sub result_message     { return shift->_result('message');     }
sub result_lang        { return shift->_result('lang');        }


sub cache_expire { return shift->{cache}->delete_expired(); }
sub cache_clear  { return shift->{cache}->delete(); }

sub set_info
{
 my ($self,$type,$key,$data,$ttl)=@_;
 my $p=$self->profile();
 err_no_current_profile() unless defined($p);
 my $regname=$self->name();

 my $c=$self->{cache}->set("${regname}.${p}",$type,$key,$data,$ttl);
 $self->{last_data}=$c; ## the hash exists, since we called clear_info somewhere before 

 return $c;
}

sub set_info_from_cache
{
 my ($self,$type,$key)=@_;
 $self->{last_data}=$self->{cache}->get($type,$key);
}

sub clear_info
{
 my $self=shift;
 $self->{last_data}={};
}

sub get_info
{
 my ($self,$what,$type,$key)=@_;
 return undef unless (defined($what) && $what);

 if (Net::DRI::Util::all_valid($type,$key)) ## search the cache, by default same registry & profile !
 {
  my $p=$self->profile();
  err_no_current_profile() unless defined($p);
  my $regname=$self->name();
  return $self->{cache}->get($type,$key,$what,"${regname}.${p}");
 } else
 {
  return (exists($self->{last_data}->{$what}))? $self->{last_data}->{$what} : undef;
 }
}

#####################################################################################################
## Change profile
sub target
{
 my ($self,$profile)=@_;
 err_profile_name_does_not_exist($profile) unless ($profile && exists($self->{profiles}->{$profile}));
 $self->{profile}=$profile;
}

sub profile_auto_switch
{
 my ($self,$otype,$oaction)=@_;
 my $p=$self->get_auto_target($otype,$oaction);
 return unless defined($p);
 $self->target($p);
 return;
}

sub set_auto_target
{
 my ($self,$profile,$otype,$oaction)=@_; ## $otype/$oaction may be undef
 err_profile_name_does_not_exist($profile) unless ($profile && exists($self->{profiles}->{$profile}));

 my $rh=$self->{auto_target};
 $otype||='_default';
 $oaction||='_default';
 $rh->{$otype}={} unless (exists($rh->{$otype}));
 $rh->{$otype}->{$oaction}=$profile;
}

sub get_auto_target
{
 my ($self,$otype,$oaction)=@_;
 my $at=$self->{auto_target};
 $otype='_default' unless (exists($at->{$otype}));
 return undef unless (exists($at->{$otype}));
 my $ac=$at->{$otype};
 return undef unless (defined($ac) && ref($ac));
 $oaction='_default' unless (exists($ac->{$oaction}));
 return undef unless (exists($ac->{$oaction}));
 return $ac->{$oaction};
}

sub new_profile
{
 my ($self,$name,$transport,$t_params,$protocol,$p_params)=@_;
 Net::DRI::Exception::err_insufficient_parameters() unless (Net::DRI::Util::all_valid($transport,$t_params,$protocol,$p_params));
 Net::DRI::Exception::err_invalid_parameters() unless ((ref($t_params) eq 'ARRAY') && (ref($p_params) eq 'ARRAY'));
 Net::DRI::Exception->die(0,'DRI',12,"New profile name already in use") if $self->exist_profile($name);

 $transport='Net::DRI::Transport::'.$transport unless ($transport=~m/::/);
 $protocol ='Net::DRI::Protocol::'.$protocol   unless ($protocol=~m/::/);

 eval "require $transport";
 Net::DRI::Exception->die(1,'DRI',8,"Failed to load Perl module $transport") if $@;
 eval "require $protocol";
 Net::DRI::Exception->die(1,'DRI',8,"Failed to load Perl module $protocol") if $@;

 my $drd=$self->{driver};
 my $po=$protocol->new($drd,@{$p_params}); ## Protocol must come first, as it may be needed during transport setup
 my $to;
 eval {
  $to=$transport->new($drd,$po,@{$t_params}); ## this may die !
 };
 if ($@) ## some kind of error happened
 {
  if (ref($@) eq 'Net::DRI::Protocol::ResultStatus')
  {
   return $@;
  }
  $@=Net::DRI::Exception->new(1,'internal',0,"Error not handled: $@") unless ref($@);
  die($@);
 }

 my $compat=$self->driver()->transport_protocol_compatible($to,$po); ## 0/1/undef
 unless (defined($compat))
 {
  my $c1=($to->can('is_compatible_with_protocol'))?  $to->is_compatible_with_protocol($po)  : 0;
  my $c2=($po->can('is_compatible_with_transport'))? $po->is_compatible_with_transport($to) : 0;
  $compat=$c1 || $c2;
 }
 Net::DRI::Exception->die(0,'DRI',13,"Transport & Protocol not compatible") unless $compat;

 $self->{profiles}->{$name}={ transport => $to, protocol => $po, status => undef };
 return Net::DRI::Protocol::ResultStatus->new_success('COMMAND_SUCCESSFUL',"Profile ${name} added successfully");
}

sub new_current_profile
{
 my $self=shift(@_);
 my $rc=$self->new_profile(@_);
 $self->target($_[0]) if ($rc->is_success());
 return $rc;
}

sub end
{
 my $self=shift;
 foreach my $p (values(%{$self->{profiles}}))
 {
  $p->{protocol}->end()  if (ref($p->{protocol})  && $p->{protocol}->can('end'));
  $p->{transport}->end() if (ref($p->{transport}) && $p->{transport}->can('end'));
  ## extra ?
  $p={};
 }

 $self->{driver}->end() if $self->{driver}->can('end');
}

sub can
{
 my ($self,$what)=@_;
 return $self->UNIVERSAL::can($what) || $self->driver->can($what);
}

################################################################################################
################################################################################################

sub has_action
{
 my ($self,$otype,$oaction)=@_;
 my ($po,$to)=$self->protocol_transport();
 return $po->has_action($otype,$oaction); 
}

sub process
{
 my ($self,$otype,$oaction)=@_[0,1,2];
 my $pa=$_[3] || []; ## store them ?
 my $ta=$_[4] || [];

 ## Automated switch, if enabled
 $self->profile_auto_switch($otype,$oaction);

 ## Current protocol/transport objects for current profile
 my ($po,$to)=$self->protocol_transport();
 my $trid=$self->trid->($self->name());

 eval {
  my $tosend=$po->action($otype,$oaction,$trid,@$pa);
  $self->{ops}->{$trid}=[0,$tosend]; ## 0 = todo, not sent ## This will be done in/with LocalStorage

  $to->send($tosend,@$ta); ## if synchronous, store results somewhere in dri, keyed by trid, store also $tosend + params passed that created $tosend (domain name, etc...)

  $self->{ops}->{$trid}->[0]=1; ## now it is sent
 };

 if ($@) ## some kind of error happened
 {
  if (ref($@) eq 'Net::DRI::Protocol::ResultStatus')
  {
   $self->status($@);
   return $@;
  }
  $@=Net::DRI::Exception->new(1,'internal',0,"Error not handled: $@") unless ref($@);
  die($@);
 }

 return undef unless $to->is_sync();
 $self->process_back($trid,$po,$to,$otype,$oaction);
}

## also called directly , when we found something to do for asynchronous case, through TRID
sub process_back
{
 my ($self,$trid,$po,$to,$otype,$oaction)=@_;

 $self->clear_info(); ## make sure we will overwrite current latest info
 my ($rc,$ri,$oname);
 
 eval
 {
  ## transport parameters ?
  my $res=$to->receive(); ## a Net::DRI::Data::Raw or die inside
  ###  return $self->protocol()->new_from_reply($tosend,$gotback);
  ###  ## $tosend needed to propagate EPP version, for example
  ($rc,$ri,$oname)=$po->reaction($otype,$oaction,$res,$self->{ops}->{$trid}->[1]);
 };

 if ($@) ## some kind of error happened
 {
  if (ref($@) eq 'Net::DRI::Protocol::ResultStatus')
  {
   $self->status($@);
   return $@;
  }
  $@=Net::DRI::Exception->new(1,'internal',0,"Error not handled: $@") unless ref($@);
  die($@);
 }

 ## Set latest status from what we got
 $self->status($rc);

 ## set_info stores also data in last_data, so we make sure to call last for current object
 foreach my $type (keys(%$ri))
 {
  foreach my $key (keys(%{$ri->{$type}}))
  {
   next if (($type eq $otype) && ($key eq $oname));
   $self->set_info($type,$key,$ri->{$type}->{$key});
  }
 }

 ## Now set the last info, the one regarding directly the object
 my $rli={};
 $rli=$ri->{$otype}->{$oname} if (exists($ri->{$otype}) && exists($ri->{$otype}->{$oname}));
 $rli->{rc}=$rc;
 $self->set_info($otype,$oname,$rli);

 delete($self->{ops}->{$trid});
 return $rc;
}


################################################################################################
################################################################################################

sub protocol_capable
{
 my ($ndr,$op,$subop,$action)=@_;
 return 0 unless ($op && $subop); ## $action may be undefined
 my $po=shift->protocol();
 my $cap=$po->capabilities(); ## hashref

 return 0 unless ($cap && (ref($cap) eq 'HASH') && exists($cap->{$op}) 
                       && (ref($cap->{$op}) eq 'HASH') && exists($cap->{$op}->{$subop})
                       && (ref($cap->{$op}->{$subop}) eq 'ARRAY'));


 return 1 unless (defined($action) && $action);

 foreach my $a (@{$cap->{$op}->{$subop}})
 {
  return 1 if ($a eq $action);
 }
 return 0;
}

##############################################################################################
sub AUTOLOAD
{
 my $self=shift;
 my $attr=$AUTOLOAD;
 $attr=~s/.*:://;
 return unless $attr=~m/[^A-Z]/; ## skip DESTROY and all-cap methods

 my $drd=$self->driver(); ## This is a DRD object
 Net::DRI::Exception::err_method_not_implemented("$attr in $drd") unless (ref($drd) && $drd->can($attr));

 return $drd->$attr($self,@_);
}


##############################################################################################
1;
