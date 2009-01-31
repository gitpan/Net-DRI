## Domain Registry Interface, Registry object
##
## Copyright (c) 2005,2006,2007,2008,2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Registry;

use strict;
use warnings;

use base qw(Class::Accessor::Chained::Fast Net::DRI::BaseClass);
__PACKAGE__->mk_ro_accessors(qw(name driver profile trid_factory logging)); ## READ-ONLY !!

use DateTime;
use DateTime::Duration;
use Time::HiRes ();

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Protocol::ResultStatus;
use Net::DRI::Data::RegistryObject;

use Net::DRI::Data::Changes;
use Net::DRI::Data::ContactSet;
use Net::DRI::Data::Hosts;

our $AUTOLOAD;

our $VERSION=do { my @r=(q$Revision: 1.30 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Registry - Specific Registry Driver Instance inside Net::DRI

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

Copyright (c) 2005,2006,2007,2008,2009 Patrick Mevzek <netdri@dotandco.com>.
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
 my ($class,$name,$drd,$cache,$trid,$logging)=@_;

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
	   last_process => {},
           trid_factory => $trid,
           logging => $logging,
          };

 bless($self,$class);
 return $self;
}

sub available_profiles
{
 my ($self,$full)=@_;
 $full||=0;
 return sort($full ? map { $_->{fullname} } values(%{$self->{profiles}}) : keys(%{$self->{profiles}}));
}

sub exist_profile
{
 my ($self,$name)=@_;
 return (defined($name) && exists($self->{profiles}->{$name}));
}

sub err_no_current_profile           { Net::DRI::Exception->die(0,'DRI',3,'No current profile available'); }
sub err_profile_name_does_not_exist  { Net::DRI::Exception->die(0,'DRI',4,'Profile name '.$_[0].' does not exist'); }

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

sub protocol_transport { my $self=shift; return ($self->protocol(),$self->transport()); }
sub create_status { return shift->_current('protocol')->create_local_object('status',@_); }

sub local_object
{
 my $self=shift;
 my $f=shift;
 return unless $self && $f;
 return DateTime->new(@_)                   if $f eq 'datetime';
 return DateTime::Duration->new(@_)         if $f eq 'duration';
 return Net::DRI::Data::Changes->new(@_)    if $f eq 'changes';
 return Net::DRI::Data::ContactSet->new(@_) if $f eq 'contactset';
 return Net::DRI::Data::Hosts->new(@_)      if $f eq 'hosts';
 return $self->_current('protocol')->create_local_object($f,@_);
}

sub _result
{
 my ($self,$f)=@_;
 my $p=$self->profile();
 err_no_current_profile() unless (defined($p));
 Net::DRI::Exception->die(0,'DRI',6,'No last status code available for current registry and profile') unless (exists($self->{profiles}->{$p}->{status}));
 my $rc=$self->{profiles}->{$p}->{status}; ## a Net::DRI::Protocol::ResultStatus object !
 Net::DRI::Exception->die(1,'DRI',5,'Status key is not a Net::DRI::Protocol::ResultStatus object') unless UNIVERSAL::isa($rc,'Net::DRI::Protocol::ResultStatus');
 return $rc if ($f eq 'self');
 Net::DRI::Exception->die(1,'DRI',5,'Method '.$f.' not implemented in Net::DRI::Protocol::ResultStatus') unless ($f && $rc->can($f));
 return $rc->$f();
}

sub result_is_success  { return shift->_result('is_success');  }
sub is_success         { return shift->_result('is_success');  } ## Alias
sub result_code        { return shift->_result('code');        }
sub result_native_code { return shift->_result('native_code'); }
sub result_message     { return shift->_result('message');     }
sub result_lang        { return shift->_result('lang');        }
sub result_status      { return shift->_result('self');        }
sub result_extra_info  { return shift->_result('info');        }

sub cache_expire { return shift->{cache}->delete_expired(); }
sub cache_clear  { return shift->{cache}->delete(); }

sub set_info
{
 my ($self,$type,$key,$data,$ttl)=@_;
 my $p=$self->profile();
 err_no_current_profile() unless defined($p);
 my $regname=$self->name();

 my $c=$self->{cache}->set($regname.'.'.$p,$type,$key,$data,$ttl);
 $self->{last_data}=$c; ## the hash exists, since we called clear_info somewhere before 

 return $c;
}

## Returns a $rc object or undef if nothing found in cache for the specific object ($type/$key) and action ($action)
sub try_restore_from_cache
{
 my ($self,$type,$key,$action)=@_;
 if (! Net::DRI::Util::all_valid($type,$key,$action)) { Net::DRI::Exception::err_assert('try_restore_from_cache improperly called'); }

 my $a=$self->get_info('action',$type,$key);
 ## not in cache or in cache but for some other action
 if (! defined $a || ($a ne $action)) { $self->log_output('debug','core',sprintf('Cache MISS for type=%s key=%s',$type,$key)); return; }

 ## retrieve from cache, copy, and do some cleanup
 $self->{last_data}=$self->get_info_all($type,$key);
 ## since we passed the above test on get_info('action'), we know here we received something defined by get_info_all,
 ## but we test explicitely again (get_info_all returns an empty ref hash on problem, not undef), to avoid race conditions and such
 if (! keys(%{$self->{last_data}})) { $self->log_output('debug','core',sprintf('Cache MISS for type=%s key=%s',$type,$key)); return; }

 ## get_info_all makes a copy, but only at first level ! so this high level change is ok (no pollution), but be warned for below !
 $self->{last_data}->{result_from_cache}=1;

 ## however we must take care of what we do in levels further below, as the same data is probably in the original $rc object (if not thrown away by application)
 my $rd=$self->{last_data}->{result_status}->get_data_collection();

 ## we first make a copy (here it is a plain ref hash, no objects inside, otherwise a proper clone() would be needed, see Clone::* modules), then we can update it.
 ## If something more complex is needed, a proper clone() should be implemented
 $rd->{session}={ %{$rd->{session}} };
 ## (if there are other keys than exchange, we do not need to copy them, since we do not change their content)
 $rd->{session}->{exchange}={ %{$rd->{session}->{exchange}} };
 $rd->{session}->{exchange}->{result_from_cache}=1;
 ## Should we delete the raw exchange (session/exchange/command,duration,reply) data too ?

 $self->log_output('debug','core',sprintf('Cache HIT for type=%s key=%s',$type,$key));
 return $self->get_info('result_status');
}

sub clear_info { shift->{last_data}={}; }

sub get_info
{
 my ($self,$what,$type,$key)=@_;
 return unless (defined($what) && $what);

 if (Net::DRI::Util::all_valid($type,$key)) ## search the cache, by default same registry & profile !
 {
  my $p=$self->profile();
  err_no_current_profile() unless defined($p);
  my $regname=$self->name();
  return $self->{cache}->get($type,$key,$what,$regname.'.'.$p);
 } else
 {
  return unless exists($self->{last_data}->{$what});
  return $self->{last_data}->{$what};
 }
}

sub get_info_all
{
 my ($self,$type,$key)=@_;
 my $rh;

 if (Net::DRI::Util::all_valid($type,$key))
 {
  my $p=$self->profile();
  err_no_current_profile() unless defined($p);
  my $regname=$self->name();
  $rh=$self->{cache}->get($type,$key,undef,$regname.'.'.$p);
 } else
 {
  $rh=$self->{last_data};
 }

 if (defined($rh) && ref($rh) && keys(%$rh))
 {
  foreach my $k (grep { /^_/ } keys(%$rh)) { delete($rh->{$k}); }
 } else
 {
  $rh={};
 }
 my %h=%$rh;
 return \%h;
}

sub get_info_keys
{
 my ($self,$type,$key)=@_;
 my $rh=$self->get_info_all($type,$key);
 return sort { $a cmp $b } keys(%$rh);
}

####################################################################################################
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
 return unless (exists($at->{$otype}));
 my $ac=$at->{$otype};
 return unless (defined($ac) && ref($ac));
 $oaction='_default' unless (exists($ac->{$oaction}));
 return unless (exists($ac->{$oaction}));
 return $ac->{$oaction};
}

sub add_current_profile
{
 my ($self,@p)=@_;
 my $rc=$self->add_profile(@p);
 if ($rc->is_success()) { $self->target($p[0]); }
 return $rc;
}

## API: profile name, profile type, transport params {}, protocol params []
sub add_profile
{
 my ($self,$name,$type,$trans_p,$prot_p)=@_;
 if (! Net::DRI::Util::all_valid($name,$type)) { Net::DRI::Exception::usererr_insufficient_parameters('add_profile needs at least 2 parameters: new profile name and type'); }
 if ($self->exist_profile($name)) { Net::DRI::Exception->die(0,'DRI',12,'New profile name '.$name.' already in use'); }

 if (! defined $trans_p) { $trans_p={}; }
 if (! defined $prot_p)  { $prot_p=[]; }

 ## When new_profile/new_current_profile are finally removed, rewrite the following and all transport_protocol_default :
 ## - we do not need $ndr in transport_protocol_default, so do $self->driver->transport_protocol_default(...)
 ## - remove case of t_p_d output API with only 2 elements in list
 ## - remove $ta/$pa and do the merge here (see below about hash ref) ?
 ## - better output API => change test @d==4 + 2 dereferences
 ## + rewrite all Transport::new to use only one ref hash (already ok for superclass)
 ## + rewrite all Protocol::new to use only one ref hash ?
 ## + merge back _create_profile here (or not, depending on where it is used)
 my ($tc,$tp,$pc,$pp)=$self->transport_protocol_default($type,[$trans_p],$prot_p); ## Output: Transport Class, Transport Params, Protocol Class, Protocol Params
 if (! Net::DRI::Util::all_valid($tc,$tp,$pc,$pp)) { Net::DRI::Exception::usererr_invalid_parameters(sprintf('Registry "%s" does not know anything about profile type "%s"',$self->name(),$type)); }

 ## when updates mentioned above are done, here we will need to merge $trans_p + $tp + $pc->transport_default() [too early for that last one] and $prot_p + $pp
 ## (so no need anymore to use _transport_protocol_default_epp/PROTOCOL_DEFAULT_* inside t_p_d)

 return $self->_create_profile($name,$tc,$tp,$pc,$pp);
}

## This is to be used only for tests !
sub add_current_test_profile
{
 my ($self,$name,$trans_c,$trans_p,$prot_c,$prot_p)=@_;
 if (! Net::DRI::Util::all_valid($name,$trans_c,$prot_c)) { Net::DRI::Exception::usererr_insufficient_parameters('add_current_test_profile needs at least 3 valid parameters: new profile name, transport class, protocol class'); }
 if ($self->exist_profile($name)) { Net::DRI::Exception->die(0,'DRI',12,'New profile name '.$name.' already in use'); }

 if (! defined $trans_p) { $trans_p={}; }
 if (! defined $prot_p)  { $prot_p=[]; }

 if ($prot_c=~m/^[a-z]+$/) ## if no uppercase letter, protocol class is taken as a profile type
 {
  my $kpc=$prot_c;
  (undef,undef,$prot_c,$prot_p)=$self->transport_protocol_default($prot_c,[{}],$prot_p); ## TODO add something so that t_p_d knows we are in test_profile mode ? or just test if second param is empty ? (specifically needed for t/619* but this SSL check should be ported in many other DRDs)
  ## some kind of merging needed here also ?
 }

 my $rc=$self->_create_profile($name,$trans_c,[$trans_p],$prot_c,$prot_p);
 if ($rc->is_success()) { $self->target($name); }
 return $rc;
}

sub new_current_profile
{
 my $self=shift(@_);
 my $rc=$self->new_profile(@_);
 $self->target($_[0]) if ($rc->is_success());
 return $rc;
}

sub new_profile
{
 print STDERR 'Consider using the new API with add_profile()/add_current_profile() instead of new_profile()/new_current_profile()',"\n";
 my ($self,$name,$transport,$t_params,$protocol,$p_params)=@_;
 Net::DRI::Exception->die(0,'DRI',12,'New profile name already in use') if $self->exist_profile($name);

 ## This API is a mess, due to non-optimal initial design
 ## This first case added last should have been the only one
 if (!defined($p_params) && $self->can('transport_protocol_default'))
 {
  if (defined($protocol))
  {
   ($transport,$t_params,$protocol,$p_params)=$self->transport_protocol_default($transport,$t_params,$protocol);
   Net::DRI::Exception::usererr_invalid_parameters('New form of new_profile is not available for this DRD, please report') unless (defined($t_params) && ref($t_params) && defined($p_params) && ref($p_params));
  } else
  {
   $p_params=(defined($t_params) && ref($t_params) eq 'ARRAY')? $t_params : [];
   $t_params=(defined($transport) && ref($transport) eq 'ARRAY')? $transport : [];
   my @a=$self->transport_protocol_default($transport);
   if (@a==2) ## this case should be deprecated
   {
    ($transport,$protocol)=@a;
   } elsif (@a==4)
   {
    ($transport,$protocol)=@a[0,2];
    $t_params=$a[1] unless @$t_params;
    $p_params=$a[3] unless @$p_params;
   } else ## this case should not happen
   {
     Net::DRI::Exception::usererr_invalid_parameters();
   }
  }
 }
 return $self->_create_profile($name,$transport,$t_params,$protocol,$p_params);
}

sub _create_profile
{
 my ($self,$name,$transport,$t_params,$protocol,$p_params)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters() unless (Net::DRI::Util::all_valid($transport,$t_params,$protocol,$p_params));
 Net::DRI::Exception::usererr_invalid_parameters() unless ((ref($t_params) eq 'ARRAY') && (ref($p_params) eq 'ARRAY'));

 $transport='Net::DRI::Transport::'.$transport unless ($transport=~m/::/);
 $protocol ='Net::DRI::Protocol::'.$protocol   unless ($protocol=~m/::/);

 $transport->require or Net::DRI::Exception::err_failed_load_module('DRI',$transport,$@);
 $protocol->require  or Net::DRI::Exception::err_failed_load_module('DRI',$protocol,$@);

 my $drd=$self->{driver};
 my $po=$protocol->new($drd,@{$p_params}); ## Protocol must come first, as it may be needed during transport setup
 ## After the switch to the new API, we will need *here* to call $po->transport_default() or something like it and merge result with $t_params
 my $to;
 eval {
  $to=$transport->new({registry=>$self,profile=>$name,protocol=>$po},@{$t_params}); ## this may die !
 };
 if ($@) ## some kind of error happened
 {
  return $@ if (ref($@) eq 'Net::DRI::Protocol::ResultStatus');
  $@=Net::DRI::Exception->new(1,'internal',0,'Error not handled: '.$@) unless ref($@);
  die($@);
 }

 my $compat=$self->driver()->transport_protocol_compatible($to,$po); ## 0/1/undef
 if (! defined $compat)
 {
  my $c1=($to->can('is_compatible_with_protocol'))?  $to->is_compatible_with_protocol($po)  : 0; ## TODO : should it be undef if can not ?
  my $c2=($po->can('is_compatible_with_transport'))? $po->is_compatible_with_transport($to) : 0;
  $compat=$c1 || $c2;
 }
 if (! defined $compat) { Net::DRI::Exception->die(0,'DRI',13,sprintf('Transport %s & Protocol %s are not compatible for registry %s (profile %s)',$to->name(),$po->name(),$self->name(),$name)); }

 $self->{profiles}->{$name}={ fullname => sprintf('%s (%s/%s)',$name,$po->name(),$to->name()), transport => $to, protocol => $po, status => undef };
 return Net::DRI::Protocol::ResultStatus->new_success('COMMAND_SUCCESSFUL','Profile '.$name.' added successfully');
}

sub del_profile
{
 my ($self,$name)=@_;
 if (defined($name))
 {
  err_profile_name_does_not_exist($name) unless ($self->exist_profile($name));
 } else
 {
  err_no_current_profile() unless (defined($self->{profile}));
  $name=$self->{profile};
 }

 my $p=$self->{profiles}->{$name};
 $p->{protocol}->end()  if (ref($p->{protocol})  && $p->{protocol}->can('end'));
 $p->{transport}->end({registry => $self, profile => $name}) if (ref($p->{transport}) && $p->{transport}->can('end'));
 delete($self->{profiles}->{$name});
 $self->{profile}=undef if $self->{profile} eq $name; ## current profile is not defined anymore
 return Net::DRI::Protocol::ResultStatus->new_success('COMMAND_SUCCESSFUL','Profile '.$name.' deleted successfully');
}

sub end
{
 my $self=shift;
 foreach my $name (keys(%{$self->{profiles}}))
 {
  my $p=$self->{profiles}->{$name};
  $p->{protocol}->end()  if (ref($p->{protocol})  && $p->{protocol}->can('end'));
  $p->{transport}->end({registry => $self, profile => $name}) if (ref($p->{transport}) && $p->{transport}->can('end'));
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

####################################################################################################
####################################################################################################

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
 $self->{last_process}=[$otype,$oaction,$pa,$ta]; ## should be handled more generally by LocalStorage/Exchange

 ## Automated switch, if enabled
 $self->profile_auto_switch($otype,$oaction);

 ## Current protocol/transport objects for current profile
 my ($po,$to)=$self->protocol_transport();
 my $trid=$self->generate_trid();
 my $ctx={trid => $trid, registry => $self, profile => $self->profile(), otype => $otype, oaction => $oaction };
 my $tosend;

 eval { $tosend=$po->action($otype,$oaction,$trid,@$pa); }; ## TODO : this may need to be pushed in loop below if we need to change message to send when failure
 return $self->format_error($@) if $@;

 $self->{ops}->{$trid}=[0,$tosend,undef]; ## 0 = todo, not sent ## This will be done in/with LocalStorage
 my $timeout=$to->timeout();
 my $prevalarm=alarm(0); ## removes current alarm
 my $pause=$to->pause();
 my $start=Time::HiRes::time();
 $self->{ops}->{$trid}->[2]=$start;

 my $count=0;
 my $r;
 while (++$count <= $to->retry())
 {
  $self->log_output('debug','core',sprintf('New process loop iteration for TRID=%s with count=%d pause=%f timeout=%f',$trid,$count,$pause,$timeout));
  Time::HiRes::sleep($pause) if (defined($pause) && $pause && ($count > 1));
  $r=eval
  {
   local $SIG{ALRM}=sub { die 'timeout' };
   alarm($timeout) if ($timeout);
   $self->log_output('debug','core','Attempting to send information for TRID='.$trid);
   ## Should we also pass the current registry driver (or at least its name), and the current profile name ? This may be useful in logging
   $to->send($ctx,$tosend,$count,$ta); ## either success or exception, no result code
   $self->log_output('debug','core','Information sent for TRID='.$trid);
   $self->{ops}->{$trid}->[0]=1; ## now it is sent
   return $self->process_back($trid,$po,$to,$otype,$oaction,$count) if $to->is_sync();
   my $rc=Net::DRI::Protocol::ResultStatus->new_success('COMMAND_SUCCESSFUL_PENDING');
   $rc->_set_trid([ $trid ]);
   $self->status($rc);
   return $rc;
  };
  alarm(0) if ($timeout); ## removes our alarm
  if ($@) ## some die happened inside the eval
  {
   return $self->format_error($@) if (ref($@) eq 'Net::DRI::Protocol::ResultStatus'); ## should probably be a return here see below TODOXXX
   my $is_timeout=(!ref($@) && ($@=~m/timeout/))? 1 : 0;
   $@=$is_timeout? Net::DRI::Exception->new(1,'transport',1,'timeout') : Net::DRI::Exception->new(1,'internal',0,'Error not handled: '.$@) unless ref($@);
   next if $to->try_again($po,$@,$count,$is_timeout,$self->{ops}->{$trid}->[0],\$pause,\$timeout); ## will determine if 1) we break now the loop/we propagate the error (fatal error) 2) we retry
   die($@);
  }
  last if defined($r);
 } ## end of while
 alarm($prevalarm) if $prevalarm; ## re-enable previous alarm (warning, time is off !!)
 Net::DRI::Exception->die(0,'transport',1,sprintf('Unable to communicate with registry after %d retries for a total delay of %.03f seconds',$to->retry(),Time::HiRes::time()-$start)) unless defined($r);

 return $r;
}

sub format_error
{
 my ($self,$err)=@_;
 if (ref($err) eq 'Net::DRI::Protocol::ResultStatus')
 {
  $self->status($err); ## should that be done above also ? TODOXXX
  return $err;
 }
 $err=Net::DRI::Exception->new(1,'internal',0,'Error not handled: '.$err) unless ref($err);
 die($err);
}

## also called directly , when we found something to do for asynchronous case, through TRID (TODO)
## We are already in an eval here, and a while loop for retries
sub process_back
{
 my ($self,$trid,$po,$to,$otype,$oaction,$count)=@_;
 my $ctx={trid => $trid, registry => $self, profile => $self->profile(), otype => $otype, oaction => $oaction }; ## How will we fill that in case of async operation (direct call here) ?
 my ($rc,$ri,$oname);

 $self->log_output('debug','core','Attempting to receive information for TRID='.$trid);
 my $res=$to->receive($ctx,$count); ## a Net::DRI::Data::Raw or die inside
 my $stop=Time::HiRes::time();
 $self->log_output('debug','core','Information received for TRID='.$trid);
 Net::DRI::Exception->die(0,'transport',5,'Unable to receive message from registry') unless defined($res);
 $self->{ops}->{$trid}->[0]=2; ## now it is received
 $self->clear_info(); ## make sure we will overwrite current latest info
 $oname=_extract_oname($otype,$oaction,$self->{last_process}->[2]); ## lc() would be good here but this breaks a lot of things !
 ($rc,$ri)=$po->reaction($otype,$oaction,$res,$self->{ops}->{$trid}->[1],$oname); ## $tosend needed to propagate EPP version, for example
 $rc->_set_trid([ $trid ]) unless $rc->trid(); ## if not done inside Protocol::*::Message::result_status, make sure we save at least our transaction id

 if ($rc->is_closing() || (exists($ri->{_internal}) && exists($ri->{_internal}->{must_reconnect}) && $ri->{_internal}->{must_reconnect}))
 {
  $to->current_state(0);
 }
 delete($ri->{_internal});

 ## Set latest status from what we got
 $self->status($rc);

 $ri->{session}->{exchange}->{result_from_cache}=0;

 ## set_info stores also data in last_data, so we make sure to call last for current object
 foreach my $type (keys(%$ri))
 {
  foreach my $key (keys(%{$ri->{$type}}))
  {
   next if ($oname && ($type eq $otype) && ($key eq $oname));
   $self->set_info($type,$key,$ri->{$type}->{$key});
  }
 }

 ## Now set the last info, the one regarding directly the object
 if ($oname && $otype)
 {
  my $rli={ result_status => $rc };
  $rli=$ri->{$otype}->{$oname} if (exists($ri->{$otype}) && exists($ri->{$otype}->{$oname})); ## result_status already done in Protocol
  $self->set_info($otype,$oname,$rli);
 }

 ## Not before !
 ## Remove all ResultStatus object, to avoid all circular references
 foreach my $v1 (values(%$ri))
 {
  foreach my $v2 (values(%{$v1}))
  {
   delete($v2->{result_status}) if exists($v2->{result_status});
  }
 }
 ## Names of keys (duration/command/reply) have been carefully chosen so that in default aphabetical order, we have first the command sent, then the duration, and finally the reply
 $ri->{session}->{exchange}={ 'duration_seconds' => $stop-$self->{ops}->{$trid}->[2], command => $self->{ops}->{$trid}->[1]->as_string(), reply => $res->as_string(), result_from_cache => 0, type => $otype, action => $oaction };
 $rc->_set_data($ri);
 delete($self->{ops}->{$trid});
 return $rc;
}

sub _extract_oname
{
 my ($otype,$oaction,$pa)=@_;

 return 'domains' if ($otype eq 'account' && $oaction eq 'list_domains');
 my $o=$pa->[0];
 return 'session' unless defined($o);
 $o=$o->[1] if (ref($o) eq 'ARRAY'); ## should be enough for _multi but still a little strange
 return $o unless ref($o);
 return ($otype eq 'nsgroup')? $o->name() : $o->get_details(1) if Net::DRI::Util::isa_hosts($o);
 return $o->srid() if Net::DRI::Util::isa_contact($o);
 return 'session';
}

####################################################################################################

sub protocol_capable
{
 my ($ndr,$op,$subop,$action)=@_;
 return 0 unless ($op && $subop); ## $action may be undefined
 my $po=$ndr->protocol();
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

####################################################################################################

sub AUTOLOAD
{
 my $self=shift;
 my $attr=$AUTOLOAD;
 $attr=~s/.*:://;
 return unless $attr=~m/[^A-Z]/; ## skip DESTROY and all-cap methods

 my $drd=$self->driver(); ## This is a DRD object
 Net::DRI::Exception::err_method_not_implemented($attr.' in '.$drd) unless (ref($drd) && $drd->can($attr));
 $self->log_output('debug','core',sprintf('Calling %s from Net::DRI::Registry (%s/%s)',$attr,$drd->name(),$self->{profile} || ''));
 return $drd->$attr($self,@_);
}

####################################################################################################
1;
