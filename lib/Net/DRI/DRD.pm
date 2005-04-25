## Domain Registry Interface, virtual superclass for all DRD modules
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

package Net::DRI::DRD;

use strict;

use DateTime;
use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Data::Changes;
use Net::DRI::Data::Hosts;
use Net::DRI::Data::StatusList;

our $VERSION=do { my @r=(q$Revision: 1.5 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::DRD - Superclass of all Net::DRI Domain Registry Drivers

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


#####################################################################

sub new
{
 my $proto=shift;
 my $class=ref($proto) || $proto;
 
 my $self={ info => $_[0] };

 bless($self,$class);
 return $self;
}

sub info
{
 my ($self,$key)=@_;
 return undef unless defined($self->{info});
 return undef unless (defined($key) && exists($self->{info}->{$key}));
 return $self->{info}->{$key};
}

sub is_my_tld
{
 my ($self,$domain)=@_;
 my ($tld)=($domain=~m/\.([^\.]+)$/);
 my @tlds=grep { uc($_) eq uc($tld) } $self->tlds();
 return (@tlds)? 1 : 0;
}

## Methods to be defined in subclasses:
sub name     { Net::DRI::Exception::err_method_not_implemented("name in ".ref($_[0])); } ## No dot is allowed in name
sub tlds     { Net::DRI::Exception::err_method_not_implemented("tlds in ".ref($_[0])); }
sub is_thick { Net::DRI::Exception::err_method_not_implemented("is_thick in ".ref($_[0])); }
sub periods  { Net::DRI::Exception::err_method_not_implemented("periods in ".ref($_[0])); } ## should return an array
sub root_servers { Net::DRI::Exception::err_method_not_implemented("root_servers in ".ref($_[0])); }

sub transport_protocol_compatible { Net::DRI::Exception::err_method_not_implemented("transport_protocol_compatible in ".ref($_[0])); }

sub has_idn { Net::DRI::Exception::err_method_not_implemented("has_idn in ".ref($_[0])); }

sub verify_name_domain { Net::DRI::Exception::err_method_not_implemented("verify_name_domain in ".ref($_[0])); }
sub domain_operation_needs_is_mine { Net::DRI::Exception::err_method_not_implemented("domain_operation_needs_is_mine in ".ref($_[0])); }

##############################################################################################################
sub verify_name_host
{
 my ($self,$ndr,$host)=@_;
 $host=$ndr unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 $host=$host->get_names(1) if (ref($host));
 my $r=$self->check_name($host);
 return $r if ($r);
 return 10 unless $self->is_my_tld($host);

 return 0;
}

sub check_name 
{
 my ($self,$ndr,$data,$dots)=@_;
 ($data,$dots)=($ndr,$data) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 return 1 unless (defined($data) && $data);

 return 2 unless Net::DRI::Util::is_hostname($data);
 my @d=split(/\./,$data);
 return 3 if ($dots && $dots!=@d);
 
 return 0; #everything ok
}

sub verify_duration_create
{
 my ($self,$ndr,$duration,$domain)=@_;
 ($duration,$domain)=($ndr,$duration) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 my @d=$self->periods();
 return undef unless @d;
 return $d[0] unless (defined($duration));
 foreach my $d (@d) { return $d if (0==Net::DRI::Util::compare_durations($d,$duration)) }
 return undef;
}

sub verify_duration_renew
{
 my ($self,$ndr,$duration,$domain,$curexp)=@_;
 ($duration,$domain,$curexp)=($ndr,$duration,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 my @d=$self->periods();
 if (defined($duration) && @d)
 {
  my $ok=0;
  foreach my $d (@d)
  {
   next unless (0==Net::DRI::Util::compare_durations($d,$duration));
   $ok=1;
   last;
  }
  return 1 unless $ok;

  if (defined($curexp) && ref($curexp) && $curexp->isa('DateTime'))
  {
   my $maxdelta=$d[-1];
   my $newexp=$curexp+$duration; ## New expiration
   my $now=DateTime->now(time_zone => $curexp->time_zone()->name());
   my $cmp=DateTime->compare($newexp,$now+$maxdelta);
   return 2 unless ($cmp == -1); ## we must have : curexp+duration < now + maxdelta
  }
 }

 return 0; ## everything ok
}

sub verify_duration_transfer
{
 my ($self,$ndr,$duration,$domain,$op)=@_;
 ($duration,$domain,$op)=($ndr,$duration,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 return 0; ## everything ok
}

#####################################################################################################
sub err_invalid_domain_name
{
 my $domain=shift;
 Net::DRI::Exception->new(0,'DRD',1,'Invalid domain name : '.(defined($domain) && $domain)? $domain : '?');
}

sub err_invalid_host_name
{
 my $dh=shift;
 $dh||='?';
 Net::DRI::Exception->new(0,'DRD',2,'Invalid host name : '.(ref($dh))? $dh->get_names(1) : $dh);
}


########################################################################################################################
## Operations on DOMAINS
########################################################################################################################

sub domain_create_only
{
 my ($self,$ndr,$domain,$rd)=@_;

 err_invalid_domain_name($domain) if $self->verify_name_domain($domain);
 my %rd=(defined($rd) && ref($rd))? %$rd : ();
 
 $rd{duration}=$self->verify_duration_create($rd{duration},$domain);
 Net::DRI::Exception->new(0,'DRD',3,'Invalid duration') unless (defined($rd{duration}) && (ref($rd{duration}) eq 'DateTime::Duration'));
 Net::DRI::Util::check_isa($rd{ns},'Net::DRI::Data::Hosts') if (exists($rd{ns}));

 my $rc=$ndr->process('domain','create',[$domain,\%rd]);
 return $rc;
}

sub domain_create
{
 my ($self,$ndr,$domain,$rd)=@_;

 err_invalid_domain_name($domain) if $self->verify_name_domain($domain);
 my %rd=(defined($rd) && ref($rd))? %$rd : ();

 ## TODO : if contacts  && is_thick, make sure they exist, or create them

 my @rc;
 my $nsin=Net::DRI::Data::Hosts->new();
 my $nsout=Net::DRI::Data::Hosts->new();
 if (exists($rd{ns})) ## Separate nameserver (inside & outside of domain) + Create outside nameservers if needed
 {
  Net::DRI::Util::check_isa($rd{ns},'Net::DRI::Data::Hosts');
  $rc[0]=[];
  foreach (1..$rd{ns}->count())
  {
   my @a=$rd{ns}->get_details($_);
   if ($a[0]=~m/^(.+\.)?${domain}$/i)
   {
    $nsin->add(@a);
   } else
   {
    my $ns=Net::DRI::Data::Hosts->new_set(@a);
    unless ($self->host_exist($ndr,$ns))
    {
     my $rc0=$self->host_create($ndr,$ns);
     push @{$rc[0]},$rc0;
     return wantarray? @rc : $rc0 unless $rc0->is_success();
    }
    $nsout->add(@a);
   }
  }

  $rd{ns}=$nsout;
 }

 ## TODO ($rc1) : if contacts  && is_thick, make sure they exist, or create them

 my $rc2=$self->domain_create_only($ndr,$domain,\%rd);
 $rc[2]=$rc2;
 return wantarray? @rc : $rc2 unless $rc2->is_success();

 unless ($nsin->is_empty()) ## Create inside nameservers & add them
 { 
  $rc[3]=[];
  foreach (1..$nsin->count())
  {
   my $ns=Net::DRI::Data::Hosts->new_set($nsin->get_details($_));
   my $rc3=$self->host_create($ndr,$ns);
   push @{$rc[3]},$rc3;
   return wantarray? @rc : $rc3 unless $rc3->is_success();
  }

  my $rc4=$self->domain_update_ns_add($ndr,$domain,$nsin);
  $rc[4]=$rc4;
  return wantarray? @rc : $rc4 unless $rc4->is_success();
 }

 if (exists($rd{status})) ## if provided, add status to domain
 {
  my $rc5=$self->domain_update_status_add($ndr,$domain,$rd{status});
  $rc[5]=$rc5;
  return wantarray? @rc : $rc5 unless $rc5->is_success();
 }

 my $rc6=$self->domain_info($ndr,$domain);
 $rc[6]=$rc6;
 return wantarray? @rc : $rc6;
}

sub domain_delete_only
{
 my ($self,$ndr,$domain)=@_;
 err_invalid_domain_name($domain) if $self->verify_name_domain($domain);

 my $rc=$ndr->process('domain','delete',[$domain]);
 return $rc;
}

sub domain_delete
{
 my ($self,$ndr,$domain)=@_;
 err_invalid_domain_name($domain) if $self->verify_name_domain($domain);

 my @r;
 my $rc1=$self->domain_info($ndr,$domain);
 push @r,$rc1;
 return wantarray()? @r : $rc1 unless $rc1->is_success();

 my $ns=$ndr->get_info('ns');
 unless ($ns->is_empty())
 {
  my $rc2=$self->domain_update_ns_del($ndr,$domain,$ns);
  push @r,$rc2;
  return wantarray()? @r : $rc2 unless $rc2->is_success();
 }

 ## TO FIX : try to rename nameservers created in domain about to be deleted

 my $rc=$ndr->process('domain','delete',[$domain]);
 push @r,$rc;
 return wantarray()? @r : $rc;
}

sub domain_info
{
 my ($self,$ndr,$domain)=@_;
 err_invalid_domain_name($domain) if $self->verify_name_domain($domain);

 my $rc;
 my $exist;
 if (defined($exist=$ndr->get_info('exist','domain',$domain)) && $exist)
 {
  $ndr->set_info_from_cache('domain',$domain);
  $rc=get_info('rc');
 } else
 {
  $rc=$ndr->process('domain','info',[$domain]);
 }
 return $rc;
}

sub domain_check
{
 my ($self,$ndr,$domain)=@_;
 err_invalid_domain_name($domain) if $self->verify_name_domain($domain);

 my $rc;
 if (defined($ndr->get_info('exist','domain',$domain)))
 {
  $ndr->set_info_from_cache('domain',$domain);
  $rc=$ndr->get_info('rc');
 } else
 {
  $rc=$ndr->process('domain','check',[$domain]);
 }
 return $rc;
}

sub domain_exist
{
 my ($self,$ndr,$domain)=@_;
 err_invalid_domain_name($domain) if $self->verify_name_domain($domain);

 my $rc=$ndr->domain_check($domain);
 my $c=$rc->code();
 return 1 if ($c==2302); ## object exists
 return 0 if ($c==2303); ## object does not exist
 return undef;
}

sub domain_update
{
 my ($self,$ndr,$domain,$tochange)=@_;
 my $fp=$ndr->protocol->nameversion();

 err_invalid_domain_name($domain) if $self->verify_name_domain($domain);
 Net::DRI::Util::check_isa($tochange,'Net::DRI::Data::Changes');

 foreach my $t ($tochange->types())
 {
  Net::DRI::Exception->new(0,'DRD',6,"Change domain_update/${t} not handled") unless ($t=~m/^(?:ns|status)$/);
  next if $ndr->protocol_capable('domain_update',$t);
  Net::DRI::Exception->new(0,'DRD',5,"Protocol ${fp} is not capable of domain_update/${t}");
 }

  my %what=('ns'     => [ $tochange->all_defined('ns') ],
            'status' => [ $tochange->all_defined('status') ],
           );

 foreach (@{$what{ns}})     { Net::DRI::Util::check_isa($_,'Net::DRI::Data::Hosts'); }
 foreach (@{$what{status}}) { Net::DRI::Util::check_isa($_,'Net::DRI::Data::StatusList'); }

 foreach my $w (keys(%what))
 {
  my @s=@{$what{$w}};
  next unless @s; ## no changes of that type

  my $add=$tochange->add($w);
  my $del=$tochange->del($w);
  my $set=$tochange->set($w);

  Net::DRI::Exception->new(0,'DRD',5,"Protocol ${fp} is not capable for domain_update/${w} to add") if (defined($add) &&
                                                                                       ! $ndr->protocol_capable('domain_update',$w,'add'));
  Net::DRI::Exception->new(0,'DRD',5,"Protocol ${fp} is not capable for domain_update/${w} to del") if (defined($del) &&
                                                                                       ! $ndr->protocol_capable('domain_update',$w,'del'));
  Net::DRI::Exception->new(0,'DRD',5,"Protocol ${fp} is not capable for domain_update/${w} to set") if (defined($set) &&
                                                                                       ! $ndr->protocol_capable('domain_update',$w,'set'));
  Net::DRI::Exception->new(0,'DRD',6,"Change domain_update/${w} with simultaneous set and add or del not supported") if (defined($set) && (defined($add) || defined($del)));
 }

 my $rc=$ndr->process('domain','update',[$domain,$tochange]);

 return $rc;
}

sub domain_update_ns_add { my ($self,$ndr,$domain,$ns)=@_; return $self->domain_update_ns($ndr,$domain,$ns,Net::DRI::Data::Hosts->new()); }
sub domain_update_ns_del { my ($self,$ndr,$domain,$ns)=@_; return $self->domain_update_ns($ndr,$domain,Net::DRI::Data::Hosts->new(),$ns); }
sub domain_update_ns_set { my ($self,$ndr,$domain,$ns)=@_; return $self->domain_update_ns($ndr,$domain,$ns); }

sub domain_update_ns
{
 my ($self,$ndr,$domain,$nsadd,$nsdel)=@_;
 Net::DRI::Util::check_isa($nsadd,'Net::DRI::Data::Hosts');
 if (defined($nsdel)) ## add + del
 {
  Net::DRI::Util::check_isa($nsdel,'Net::DRI::Data::Hosts');
  my $c=Net::DRI::Data::Changes->new();
  $c->add('ns',$nsadd) unless ($nsadd->is_empty());
  $c->del('ns',$nsdel) unless ($nsdel->is_empty());
  return $self->domain_update($ndr,$domain,$c);
 } else
 {
  return $self->domain_update($ndr,$domain,Net::DRI::Data::Changes->new_set('ns',$nsadd));
 }
}

sub domain_update_status_add { my ($self,$ndr,$domain,$s)=@_; return $self->domain_update_status($ndr,$domain,$s,Net::DRI::Data::StatusList->new()); }
sub domain_update_status_del { my ($self,$ndr,$domain,$s)=@_; return $self->domain_update_status($ndr,$domain,Net::DRI::Data::StatusList->new(),$s); }
sub domain_update_status_set { my ($self,$ndr,$domain,$s)=@_; return $self->domain_update_status($ndr,$domain,$s); }

sub domain_update_status
{
 my ($self,$ndr,$domain,$sadd,$sdel)=@_;
 Net::DRI::Util::check_isa($sadd,'Net::DRI::Data::StatusList');
 if (defined($sdel)) ## add + del
 {
  Net::DRI::Util::check_isa($sdel,'Net::DRI::Data::StatusList');
  my $c=Net::DRI::Data::Changes->new();
  $c->add('status',$sadd) unless ($sadd->is_empty());
  $c->del('status',$sdel) unless ($sdel->is_empty());
  return $self->domain_update($ndr,$domain,$c);
 } else
 {
  return $self->domain_update($ndr,$domain,Net::DRI::Data::Changes->new_set('status',$sadd));
 }
}

## TO FIX : sub domain_update_contacts_*

sub domain_renew
{
 my ($self,$ndr,$domain,$duration,$curexp)=@_;
 err_invalid_domain_name($domain) if $self->verify_name_domain($domain);

 Net::DRI::Util::check_isa($duration,'DateTime::Duration') if defined($duration);
 Net::DRI::Util::check_isa($curexp,'DateTime') if defined($curexp);

 Net::DRI::Exception->new(0,'DRD',3,'Invalid duration') if $self->verify_duration_renew($duration,$domain,$curexp);

 my $rc=$ndr->process('domain','renew',[$duration,$curexp]);
 return $rc;
}

sub domain_transfer
{
 my ($self,$ndr,$domain,$op)=@_;
 err_invalid_domain_name($domain) if $self->verify_name_domain($domain);
 Net::DRI::Exception::usererr_invalid_parameters("Transfer operation must be start,stop,accept,refuse or query") unless ($op=~m/^(?:start|stop|query|accept|refuse)$/);

 Net::DRI::Exception->new(0,'DRD',3,'Invalid duration') if $self->verify_duration_transfer(undef,$domain,$op);

 my $rc;
 if ($op eq 'start')
 {
  $rc=$ndr->process('domain','transfer_start',[$domain]);
 } elsif ($op eq 'stop')
 {
  $rc=$ndr->process('domain','transfer_cancel',[$domain]);
 } elsif ($op eq 'query')
 {
  $rc=$ndr->process('domain','transfer_query',[$domain]);
 } else ## accept/refuse
 {
  $rc=$ndr->process('domain','transfer_answer',[$domain,($op eq 'accept')? 1 : 0]);
 }
 
 return $rc;
}

sub domain_transfer_start   { my ($self,$ndr,$domain)=@_; return $self->domain_transfer($ndr,$domain,'start'); }
sub domain_transfer_stop    { my ($self,$ndr,$domain)=@_; return $self->domain_transfer($ndr,$domain,'stop'); }
sub domain_transfer_query   { my ($self,$ndr,$domain)=@_; return $self->domain_transfer($ndr,$domain,'query'); }
sub domain_transfer_accept  { my ($self,$ndr,$domain)=@_; return $self->domain_transfer($ndr,$domain,'accept'); }
sub domain_transfer_refuse  { my ($self,$ndr,$domain)=@_; return $self->domain_transfer($ndr,$domain,'refuse'); }


sub domain_can
{
 my ($self,$ndr,$domain,$what)=@_;

 my $sok=$self->domain_status_allow($ndr,$domain,$what);
 return 0 unless ($sok);

 my $ismine=$self->domain_is_mine($ndr,$domain);
 my $n=$self->domain_operation_needs_is_mine($domain,$what);
 return undef unless (defined($n));
 return ($ismine xor $n)? 0 : 1;
}

sub domain_status_allows_delete   { my ($self,$ndr,$domain)=@_; return $self->domain_status_allows($ndr,$domain,'delete'); }
sub domain_status_allows_update   { my ($self,$ndr,$domain)=@_; return $self->domain_status_allows($ndr,$domain,'update'); }
sub domain_status_allows_transfer { my ($self,$ndr,$domain)=@_; return $self->domain_status_allows($ndr,$domain,'transfer'); }
sub domain_status_allows_renew    { my ($self,$ndr,$domain)=@_; return $self->domain_status_allows($ndr,$domain,'renew'); }

sub domain_status_allows
{
 my ($self,$ndr,$domain,$what)=@_;

 return 0 unless ($what=~m/^(?:delete|update|transfer|renew)$/);
 my $s=$self->domain_current_status($ndr,$domain);
 return 0 unless (defined($s));

 return $s->can_delete()   if ($what eq 'delete');
 return $s->can_update()   if ($what eq 'update');
 return $s->can_transfer() if ($what eq 'transfer');
 return $s->can_renew()    if ($what eq 'renew');
 return 0; ## failsafe
}

sub domain_current_status
{
 my ($self,$ndr,$domain)=@_;
 my $rc=$self->domain_info($ndr,$domain);
 return undef unless $rc->is_success();
 my $s=$ndr->get_info('status');
 return undef unless (defined($s) && ref($s) && $s->isa('Net::DRI::Data::StatusList'));
 return $s;
}

sub domain_is_mine
{
 my ($self,$ndr,$domain)=@_;
 my $clid=$self->info('clid');
 return 0 unless defined($clid);
 my $id;
 eval
 {
  my $rc=$self->domain_info($ndr,$domain);
  $id=$ndr->get_info('clID') if ($rc->is_success());
 };
 return 0 unless (!$@ && defined($id));
 return ($clid=~m/^${id}$/)? 1 : 0;
}

########################################################################################################################
## Operations on HOSTS
########################################################################################################################

sub host_create
{
 my ($self,$ndr,$dh)=@_;

 err_invalid_host_name($dh) if $self->verify_name_host($dh);
 my $rc=$ndr->process('host','create',[$dh]);

 return $rc;
}

sub host_delete
{
 my ($self,$ndr,$dh)=@_;

 err_invalid_host_name($dh) if $self->verify_name_host($dh);
 my $rc=$ndr->process('host','delete',[$dh]);

 return $rc;
}

sub host_info
{
 my ($self,$ndr,$dh)=@_;

 my $name=(ref($dh))? $dh->get_names(1) : $dh;
 err_invalid_host_name($name) if $self->verify_name_host($name);

 my ($rc,$exist);
 if (defined($exist=$ndr->get_info('exist','host',$name)) && $exist) ## check cache
 {
  $ndr->set_info_from_cache('host',$name);
  $rc=$ndr->get_info('rc');
 } else
 {
  $rc=$ndr->process('host','info',[$dh]); ## cache was empty, go to registry
 }

 return $rc unless $rc->is_success();
 return (wantarray())? ($rc,$ndr->get_info('self')) : $rc;
}

sub host_check
{
 my ($self,$ndr,$dh)=@_;

 my $name=(ref($dh))? $dh->get_names(1) : $dh;
 err_invalid_host_name($name) if $self->verify_name_host($name);

 my $rc;
 if (defined($ndr->get_info('exist','host',$name))) ## check cache
 {
  $ndr->set_info_from_cache('host',$name);
  $rc=$ndr->get_info('rc');
 } else
 {
  $rc=$ndr->process('host','check',[$dh]); ## go to registry
 }
 return $rc;
}


sub host_exist
{
 my ($self,$ndr,$dh)=@_;

 my $name=(ref($dh))? $dh->get_names(1) : $dh;
 err_invalid_host_name($name) if $self->verify_name_host($name);

 my $rc=$ndr->host_check($name);
 my $c=$rc->code();
 return 1 if ($c==2302); ## object exists
 return 0 if ($c==2303); ## object does not exist
 return undef;
}

sub host_update
{
 my ($self,$ndr,$dh,$tochange)=@_;
 my $fp=$ndr->protocol->nameversion();

 err_invalid_host_name($dh) if $self->verify_name_host($dh);
 Net::DRI::Util::check_isa($tochange,'Net::DRI::Data::Changes');

 foreach my $t ($tochange->types())
 {
  Net::DRI::Exception->new(0,'DRD',6,"Change host_update/${t} not handled") unless ($t=~m/^(?:ip|status|name)$/);
  next if $ndr->protocol_capable('host_update',$t);
  Net::DRI::Exception->new(0,'DRD',5,"Protocol ${fp} is not capable of host_update/${t}");
 }

 my %what=('ip'     => [ $tochange->all_defined('ip') ],
           'status' => [ $tochange->all_defined('status') ],
           'name'   => [ $tochange->all_defined('name') ],
          );
 foreach (@{$what{ip}})     { Net::DRI::Util::check_isa($_,'Net::DRI::Data::Hosts'); }
 foreach (@{$what{status}}) { Net::DRI::Util::check_isa($_,'Net::DRI::Data::StatusList'); }
 foreach (@{$what{name}})   { err_invalid_host_name($_) if $self->verify_name_host($_); }

 foreach my $w (keys(%what))
 {
  my @s=@{$what{$w}};
  next unless @s; ## no changes of that type

  my $add=$tochange->add($w);
  my $del=$tochange->del($w);
  my $set=$tochange->set($w);

  Net::DRI::Exception->new(0,'DRD',5,"Protocol ${fp} is not capable for host_update/${w} to add") if (defined($add) &&
                                                                                       ! $ndr->protocol_capable('host_update',$w,'add'));
  Net::DRI::Exception->new(0,'DRD',5,"Protocol ${fp} is not capable for host_update/${w} to del") if (defined($del) &&
                                                                                       ! $ndr->protocol_capable('host_update',$w,'del'));
  Net::DRI::Exception->new(0,'DRD',5,"Protocol ${fp} is not capable for host_update/${w} to set") if (defined($set) &&
                                                                                       ! $ndr->protocol_capable('host_update',$w,'set'));
  Net::DRI::Exception->new(0,'DRD',6,"Change host_update/${w} with simultaneous set and add or del not supported") if (defined($set) && (defined($add) || defined($del)));
 }

 my $rc=$ndr->process('host','update',[$dh,$tochange]);
 return $rc;
}

sub host_update_ip_add { my ($self,$ndr,$dh,$ip)=@_; return $self->host_update_ip($ndr,$ip,Net::DRI::Data::Hosts->new()); }
sub host_update_ip_del { my ($self,$ndr,$dh,$ip)=@_; return $self->host_update_ip($ndr,Net::DRI::Data::Hosts->new(),$ip); }
sub host_update_ip_set { my ($self,$ndr,$dh,$ip)=@_; return $self->host_update_ip($ndr,$ip); }

sub host_update_ip
{
 my ($self,$ndr,$dh,$ipadd,$ipdel)=@_;
 Net::DRI::Util::check_isa($ipadd,'Net::DRI::Data::Hosts');
 if (defined($ipdel)) ## add + del
 {
  Net::DRI::Util::check_isa($ipdel,'Net::DRI::Data::Hosts');
  my $c=Net::DRI::Data::Changes->new();
  $c->add('ip',$ipadd) unless ($ipadd->is_empty());
  $c->del('ip',$ipdel) unless ($ipdel->is_empty());
  return $self->host_update($ndr,$dh,$c);
 } else ## just set
 {
  return $self->host_update($ndr,$dh,Net::DRI::Data::Changes->new_set('ip',$ipadd));
 }
}

sub host_update_status_add { my ($self,$ndr,$dh,$s)=@_; return $self->host_update_status($ndr,$dh,$s,Net::DRI::Data::StatusList->new()); }
sub host_update_status_del { my ($self,$ndr,$dh,$s)=@_; return $self->host_update_status($ndr,$dh,Net::DRI::Data::StatusList->new(),$s); }
sub host_update_status_set { my ($self,$ndr,$dh,$s)=@_; return $self->host_update_status($ndr,$dh,$s); }

sub host_update_status
{
 my ($self,$ndr,$dh,$sadd,$sdel)=@_;
 Net::DRI::Util::check_isa($sadd,'Net::DRI::Data::StatusList');
 if (defined($sdel)) ## add + del
 {
  Net::DRI::Util::check_isa($sdel,'Net::DRI::Data::StatusList');
  my $c=Net::DRI::Data::Changes->new();
  $c->add('status',$sadd) unless ($sadd->is_empty());
  $c->del('status',$sdel) unless ($sdel->is_empty());
  return $self->host_update($ndr,$dh,$c);
 } ## just set
 {
  return $self->host_update($ndr,$dh,Net::DRI::Data::Changes->new_set('status',$sadd));
 }
}

sub host_update_name_set
{
 my ($self,$ndr,$newname)=@_;
 $newname=$newname->get_names(1) if ($newname && ref($newname) && $newname->can('get_details'));
 err_invalid_host_name($newname) if $self->verify_name_host($newname);
 return $self->host_update($ndr,Net::DRI::Data::Changes->new_set('name',$newname));
}

sub host_current_status
{
 my ($self,$ndr,$dh)=@_;
 my $rc=$self->host_info($ndr,$dh);
 return undef unless $rc->is_success();
 my $s=$ndr->get_info('status');
 return undef unless (defined($s) && ref($s) && $s->isa('Net::DRI::Data::StatusList'));
 return $s;
}

sub host_is_mine
{
 my ($self,$ndr,$$dh)=@_;
 my $clid=$self->info('clid');
 return 0 unless defined($clid);
 my $id;
 eval
 {
  my $rc=$self->host_info($ndr,$dh);
  $id=$ndr->get_info('clID') if ($rc->is_success());
 };
 return 0 unless (!$@ && defined($id));
 return ($clid=~m/^${id}$/)? 1 : 0;
}

##########################################################################################################################
## Operations on CONTACTS
##########################################################################################################################

############################################################################################
1;
