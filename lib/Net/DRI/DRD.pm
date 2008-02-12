## Domain Registry Interface, virtual superclass for all DRD modules
##
## Copyright (c) 2005,2006,2007,2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD;

use strict;

use Carp;
use DateTime;
use Net::DRI::Exception;
use Net::DRI::Util;

our $VERSION=do { my @r=(q$Revision: 1.26 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

## Nice shortcuts used in various DRDs even if it should be in Protocol/* somewhere, from RFCs & IANA assignation
our %PROTOCOL_DEFAULT_EPP=(defer => 0, socktype => 'ssl', ssl_cipher_list => 'TLSv1', remote_port => 700, protocol_connection => 'Net::DRI::Protocol::EPP::Connection', protocol_version => 1);
our %PROTOCOL_DEFAULT_RRP=(defer => 0, socktype => 'ssl', ssl_cipher_list => 'TLSv1', remote_port => 648, protocol_connection => 'Net::DRI::Protocol::RRP::Connection', protocol_version => 1);
our %PROTOCOL_DEFAULT_DAS=(defer=>1, close_after=>1, socktype=>'tcp', remote_port=>4343, protocol_connection=>'Net::DRI::Protocol::DAS::Connection', protocol_version=> 1);
our %PROTOCOL_DEFAULT_WHOIS=(defer=>1, close_after=>1, socktype=>'tcp', remote_port=>43,protocol_connection=>'Net::DRI::Protocol::Whois::Connection',protocol_version=>1);

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

Copyright (c) 2005,2006,2007,2008 Patrick Mevzek <netdri@dotandco.com>.
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
 my $self={ info => $_[0] };

 bless($self,$class);
 return $self;
}

sub info
{
 my ($self,$ndr,$key)=@_;
 $key=$ndr unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));
 return unless defined($self->{info});
 return unless (defined($key) && exists($self->{info}->{$key}));
 return $self->{info}->{$key};
}

sub is_my_tld
{
 my ($self,$domain)=@_;
 my $tlds=join('|',map { quotemeta($_) } sort { length($b) <=> length($a) } $self->tlds());
 my $r=qr/\.(?:$tlds)$/i;
 return ($domain=~$r);
}

## Methods to be defined in subclasses:
sub name     { Net::DRI::Exception::err_method_not_implemented('name in '.ref($_[0])); } ## No dot is allowed in name
sub tlds     { Net::DRI::Exception::err_method_not_implemented('tlds in '.ref($_[0])); }
sub object_types { Net::DRI::Exception::err_method_not_implemented('object_types in '.ref($_[0])); }
sub periods  { Net::DRI::Exception::err_method_not_implemented('periods in '.ref($_[0])); } ## should return an array
sub transport_protocol_compatible { Net::DRI::Exception::err_method_not_implemented('transport_protocol_compatible in '.ref($_[0])); }
sub _transport_protocol_default_epp
{
 my ($pn,$ta,$pa)=@_;
 return ('Net::DRI::Transport::Socket',$pn) unless (defined($ta) && defined($pa));
 my %ta=( %PROTOCOL_DEFAULT_EPP,
          (ref($ta) eq 'ARRAY')? %{$ta->[0]} : %$ta,
        );
 my @pa=(ref($pa) eq 'ARRAY' && @$pa)? @$pa : ('1.0');
 return ('Net::DRI::Transport::Socket',[\%ta],$pn,\@pa);
}

## We will need to deal with specific characters allowed/specific languages allowed
sub has_idn { Net::DRI::Exception::err_method_not_implemented('has_idn in '.ref($_[0])); }

sub verify_name_domain { Net::DRI::Exception::err_method_not_implemented('verify_name_domain in '.ref($_[0])); }
sub domain_operation_needs_is_mine { Net::DRI::Exception::err_method_not_implemented('domain_operation_needs_is_mine in '.ref($_[0])); }

sub is_thick { carp(q{DRD::is_thick() is deprecated, please use DRD::hash_object('contact')}); return shift->has_object('contact'); } ## DEPRECATED

sub has_object
{
 my ($self,$type)=@_;
 return 0 unless (defined($type) && $type);
 $type=lc($type);
 return (grep { lc($_) eq $type } ($self->object_types()))? 1 : 0;
}

####################################################################################################
sub verify_name_host
{
 my ($self,$ndr,$host,$checktld)=@_;
 $checktld||=0;
 ($host,$checktld)=($ndr,$host) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 $host=$host->get_names(1) if (ref($host));
 my $r=$self->check_name($host);
 return $r if ($r);
 return 10 if ($checktld && !$self->is_my_tld($host));

 return 0;
}

sub check_name 
{
 my ($self,$ndr,$data,$dots)=@_;
 ($data,$dots)=($ndr,$data) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 return 1 unless (defined($data) && $data);

 return 2 unless Net::DRI::Util::is_hostname($data);
 my @d=split(/\./,$data);
 return 3 if ($dots && 1+$dots!=@d);
 
 return 0; #everything ok
}

sub verify_duration_create
{
 my ($self,$ndr,$duration,$domain)=@_;
 ($duration,$domain)=($ndr,$duration) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 my @d=$self->periods();
 return 1 unless @d;
 foreach my $d (@d) { return 0 if (0==Net::DRI::Util::compare_durations($d,$duration)) }
 return 2;
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

  if (defined($curexp) && UNIVERSAL::isa($curexp,'DateTime'))
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

####################################################################################################
sub err_invalid_domain_name
{
 my $domain=shift;
 Net::DRI::Exception->die(0,'DRD',1,'Invalid domain name : '.((defined($domain) && $domain)? $domain : '?'));
}

sub err_invalid_host_name
{
 my $dh=shift;
 $dh||='?';
 Net::DRI::Exception->die(0,'DRD',2,'Invalid host name : '.((UNIVERSAL::isa($dh,'Net::DRI::Data::Hosts'))? $dh->get_names(1) : $dh));
}

sub err_invalid_contact
{
 my $c=shift;
 Net::DRI::Exception->die(0,'DRD',6,'Invalid contact : '.((defined($c) && $c && UNIVERSAL::can($c,'srid'))? $c->srid() : '?'));
}

####################################################################################################
## Operations on DOMAINS
####################################################################################################

sub domain_create_only
{
 my ($self,$ndr,$domain,$rd)=@_;

 err_invalid_domain_name($domain) if $self->verify_name_domain($domain,'create');
 my %rd=(defined($rd) && (ref($rd) eq 'HASH'))? %$rd : ();
 
 if (defined($rd{duration}))
 {
  Net::DRI::Exception->die(0,'DRD',3,'Invalid duration') if ((ref($rd{duration}) ne 'DateTime::Duration') || $self->verify_duration_create($rd{duration},$domain));
 }
 Net::DRI::Util::check_isa($rd{ns},'Net::DRI::Data::Hosts') if (exists($rd{ns}));

 my $rc=$ndr->process('domain','create',[$domain,\%rd]);
 return $rc;
}

sub domain_create
{
 my ($self,$ndr,$domain,$rd)=@_;

 err_invalid_domain_name($domain) if $self->verify_name_domain($domain,'create');
 my %rd=(defined($rd) && (ref($rd) eq 'HASH'))? %$rd : ();

 my @rc;
 my $nsin=$ndr->local_object('hosts');
 my $nsout=$ndr->local_object('hosts');
 if (exists($rd{ns}) && $self->has_object('ns')) ## Separate nameserver (inside & outside of domain) + Create outside nameservers if needed
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
    my $ns=$ndr->local_object('hosts')->set(@a);
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

 ## TODO ($rc1) : if contacts  && has_object('contact'), make sure they exist, or create them

 my $rc2=$self->domain_create_only($ndr,$domain,\%rd);
 $rc[2]=$rc2;
 return wantarray? @rc : $rc2 unless $rc2->is_success();

 unless ($nsin->is_empty()) ## Create inside nameservers & add them
 { 
  $rc[3]=[];
  foreach (1..$nsin->count())
  {
   my $ns=$ndr->local_object('hosts')->set($nsin->get_details($_));
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

 if ($ndr->protocol()->has_action('domain','info'))
 {
  my $rc6=$self->domain_info($ndr,$domain);
  $rc[6]=$rc6;
  return wantarray? @rc : $rc6;
 }

 return wantarray? @rc : $rc2; ## result code of domain_create_only
}

sub domain_delete_only
{
 my ($self,$ndr,$domain,$rd)=@_;
 err_invalid_domain_name($domain) if $self->verify_name_domain($domain,'delete');

 my $rc=$ndr->process('domain','delete',[$domain,$rd]);
 return $rc;
}

sub domain_delete
{
 my ($self,$ndr,$domain,$rd)=@_;
 err_invalid_domain_name($domain) if $self->verify_name_domain($domain,'delete');

 my @r;
 my $rc1=$self->domain_info($ndr,$domain);
 push @r,$rc1;
 return wantarray()? @r : $rc1 unless $rc1->is_success();

 my $ns=$ndr->get_info('ns');
 if (defined($ns) && !$ns->is_empty())
 {
  my $rc2=$self->domain_update_ns_del($ndr,$domain,$ns);
  push @r,$rc2;
  return wantarray()? @r : $rc2 unless $rc2->is_success();
 }

 my $rc=$ndr->process('domain','delete',[$domain,$rd]);
 push @r,$rc;
 return wantarray()? @r : $rc;
}

sub domain_info
{
 my ($self,$ndr,$domain,$rd)=@_;
 err_invalid_domain_name($domain) if $self->verify_name_domain($domain,'info');

 my $rc;
 my $exist;
 ## After a successfull domain_info, get_info('ns') must be defined and is an Hosts object, even if empty
 if (defined($exist=$ndr->get_info('exist','domain',$domain)) && $exist && defined($ndr->get_info('ns','domain',$domain)))
 {
  $ndr->set_info_from_cache('domain',$domain);
  $rc=$ndr->get_info('result_status');
 } else
 {
  $rc=$ndr->process('domain','info',[$domain,$rd]);
 }
 return $rc;
}

sub domain_check
{
 my ($self,$ndr,$domain,$rd)=@_;
 err_invalid_domain_name($domain) if $self->verify_name_domain($domain,'check');

 my $rc;
 if (defined($ndr->get_info('exist','domain',$domain)))
 {
  $ndr->set_info_from_cache('domain',$domain);
  $rc=$ndr->get_info('result_status');
 } else
 {
  $rc=$ndr->process('domain','check',[$domain,$rd]);
 }
 return $rc;
}

sub domain_check_multi
{
 my $self=shift;
 my $ndr=shift;

 my $rd;
 $rd=pop(@_) if ($_[-1] && (ref($_[-1]) eq 'HASH'));
 my $rc;
 my @d;
 foreach my $domain (@_)
 {
  err_invalid_domain_name($domain) if $self->verify_name_domain($domain,'check');
  if (defined($ndr->get_info('exist','domain',$domain)))
  {
   $ndr->set_info_from_cache('domain',$domain);
   $rc=$ndr->get_info('result_status');
  } else
  {
   push @d,$domain;
  }
 }

 $rc=$ndr->process('domain','check_multi',[\@d,$rd]) if @d;
 return $rc;
}

sub domain_exist ## 1/0/undef
{
 my ($self,$ndr,$domain,$rd)=@_;
 err_invalid_domain_name($domain) if $self->verify_name_domain($domain,'check');

 my $rc=$ndr->domain_check($domain,$rd);
 return unless $rc->is_success();
 return $ndr->get_info('exist');
}

sub domain_update
{
 my ($self,$ndr,$domain,$tochange,$rd)=@_;
 my $fp=$ndr->protocol->nameversion();

 err_invalid_domain_name($domain) if $self->verify_name_domain($domain,'update');
 Net::DRI::Util::check_isa($tochange,'Net::DRI::Data::Changes');

 Net::DRI::Exception->new(0,'DRD',4,'Registry does not handle contacts') if ($tochange->all_defined('contact') && ! $self->has_object('contact'));

 foreach my $t ($tochange->types())
 {
  next if $ndr->protocol_capable('domain_update',$t);
  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable of domain_update/${t}");
 }

  my %what=('ns'      => [ $tochange->all_defined('ns') ],
            'status'  => [ $tochange->all_defined('status') ],
            'contact' => [ $tochange->all_defined('contact') ],
           );

 foreach (@{$what{ns}})      { Net::DRI::Util::check_isa($_,'Net::DRI::Data::Hosts'); }
 foreach (@{$what{status}})  { Net::DRI::Util::check_isa($_,'Net::DRI::Data::StatusList'); }
 foreach (@{$what{contact}}) { Net::DRI::Util::check_isa($_,'Net::DRI::Data::ContactSet'); }

 foreach my $w (keys(%what))
 {
  my @s=@{$what{$w}};
  next unless @s; ## no changes of that type

  my $add=$tochange->add($w);
  my $del=$tochange->del($w);
  my $set=$tochange->set($w);

  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable for domain_update/${w} to add") if (defined($add) &&
                                                                                       ! $ndr->protocol_capable('domain_update',$w,'add'));
  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable for domain_update/${w} to del") if (defined($del) &&
                                                                                       ! $ndr->protocol_capable('domain_update',$w,'del'));
  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable for domain_update/${w} to set") if (defined($set) &&
                                                                                       ! $ndr->protocol_capable('domain_update',$w,'set'));
  Net::DRI::Exception->die(0,'DRD',6,"Change domain_update/${w} with simultaneous set and add or del not supported") if (defined($set) && (defined($add) || defined($del)));
 }

 my $rc=$ndr->process('domain','update',[$domain,$tochange,$rd]);
 return $rc;
}

sub domain_update_ns_add { my ($self,$ndr,$domain,$ns,$rd)=@_; return $self->domain_update_ns($ndr,$domain,$ns,$ndr->local_object('hosts'),$rd); }
sub domain_update_ns_del { my ($self,$ndr,$domain,$ns,$rd)=@_; return $self->domain_update_ns($ndr,$domain,$ndr->local_object('hosts'),$ns,$rd); }
sub domain_update_ns_set { my ($self,$ndr,$domain,$ns,$rd)=@_; return $self->domain_update_ns($ndr,$domain,$ns,undef,$rd); }

sub domain_update_ns
{
 my ($self,$ndr,$domain,$nsadd,$nsdel,$rd)=@_;
 Net::DRI::Util::check_isa($nsadd,'Net::DRI::Data::Hosts');
 if (defined($nsdel)) ## add + del
 {
  Net::DRI::Util::check_isa($nsdel,'Net::DRI::Data::Hosts');
  my $c=$ndr->local_object('changes');
  $c->add('ns',$nsadd) unless ($nsadd->is_empty());
  $c->del('ns',$nsdel) unless ($nsdel->is_empty());
  return $self->domain_update($ndr,$domain,$c,$rd);
 } else
 {
  return $self->domain_update($ndr,$domain,$ndr->local_object('changes')->set('ns',$nsadd),$rd);
 }
}

sub domain_update_status_add { my ($self,$ndr,$domain,$s,$rd)=@_; return $self->domain_update_status($ndr,$domain,$s,$ndr->local_object('status'),$rd); }
sub domain_update_status_del { my ($self,$ndr,$domain,$s,$rd)=@_; return $self->domain_update_status($ndr,$domain,$ndr->local_object('status'),$s,$rd); }
sub domain_update_status_set { my ($self,$ndr,$domain,$s,$rd)=@_; return $self->domain_update_status($ndr,$domain,$s,undef,$rd); }

sub domain_update_status
{
 my ($self,$ndr,$domain,$sadd,$sdel,$rd)=@_;
 Net::DRI::Util::check_isa($sadd,'Net::DRI::Data::StatusList');
 if (defined($sdel)) ## add + del
 {
  Net::DRI::Util::check_isa($sdel,'Net::DRI::Data::StatusList');
  my $c=$ndr->local_object('changes');
  $c->add('status',$sadd) unless ($sadd->is_empty());
  $c->del('status',$sdel) unless ($sdel->is_empty());
  return $self->domain_update($ndr,$domain,$c,$rd);
 } else
 {
  return $self->domain_update($ndr,$domain,$ndr->local_object('changes')->set('status',$sadd),$rd);
 }
}

sub domain_update_contact_add { my ($self,$ndr,$domain,$c,$rd)=@_; return $self->domain_update_contact($ndr,$domain,$c,$ndr->local_object('contactset'),$rd); }
sub domain_update_contact_del { my ($self,$ndr,$domain,$c,$rd)=@_; return $self->domain_update_contact($ndr,$domain,$ndr->local_object('contactset'),$c,$rd); }
sub domain_update_contact_set { my ($self,$ndr,$domain,$c,$rd)=@_; return $self->domain_update_contact($ndr,$domain,$c,undef,$rd); }

sub domain_update_contact
{
 my ($self,$ndr,$domain,$cadd,$cdel,$rd)=@_;
 Net::DRI::Util::check_isa($cadd,'Net::DRI::Data::ContactSet');
 if (defined($cdel)) ## add + del
 {
  Net::DRI::Util::check_isa($cdel,'Net::DRI::Data::ContactSet');
  my $c=$ndr->local_object('changes');
  $c->add('contact',$cadd) unless ($cadd->is_empty());
  $c->del('contact',$cdel) unless ($cdel->is_empty());
  return $self->domain_update($ndr,$domain,$c,$rd);
 } else
 {
  return $self->domain_update($ndr,$domain,$ndr->local_object('changes')->set('contact',$cadd),$rd);
 }
} 

sub domain_renew
{
 my ($self,$ndr,$domain,$rd,@e)=@_; ## Previous API : ($self,$ndr,$domain,$duration,$curexp,$deletedate,$rd)
 if (@e)
 {
  my ($duration,$curexp,$deletedate,$rd2)=($rd,@e);
  $rd2={} unless (defined($rd2) && (ref($rd2) eq 'HASH'));
  $rd2->{duration}=$duration if (defined($duration));
  $rd2->{current_expiration}=$curexp if (defined($curexp));
  ## deletedate should never have been there, a bug probably
  $rd=$rd2;
 } elsif (defined($rd) && (ref($rd) ne 'HASH'))
 {
  $rd={duration => $rd};
 }

 err_invalid_domain_name($domain) if $self->verify_name_domain($domain,'renew');

 Net::DRI::Util::check_isa($rd->{duration},'DateTime::Duration') if defined($rd->{duration});
 Net::DRI::Util::check_isa($rd->{current_expiration},'DateTime') if defined($rd->{current_expiration});
 Net::DRI::Exception->die(0,'DRD',3,'Invalid duration') if $self->verify_duration_renew($rd->{duration},$domain,$rd->{current_expiration});

 return $ndr->process('domain','renew',[$domain,$rd]);
}

sub domain_transfer
{
 my ($self,$ndr,$domain,$op,$rd)=@_;
 err_invalid_domain_name($domain) if $self->verify_name_domain($domain,'transfer');
 Net::DRI::Exception::usererr_invalid_parameters('Transfer operation must be start,stop,accept,refuse or query') unless ($op=~m/^(?:start|stop|query|accept|refuse)$/);

 Net::DRI::Exception->die(0,'DRD',3,'Invalid duration') if $self->verify_duration_transfer($ndr,(defined($rd) && (ref($rd) eq 'HASH') && exists($rd->{duration}))? $rd->{duration} : undef,$domain,$op);

 my $rc;
 if ($op eq 'start')
 {
  $rc=$ndr->process('domain','transfer_request',[$domain,$rd]);
 } elsif ($op eq 'stop')
 {
  $rc=$ndr->process('domain','transfer_cancel',[$domain,$rd]);
 } elsif ($op eq 'query')
 {
  $rc=$ndr->process('domain','transfer_query',[$domain,$rd]);
 } else ## accept/refuse
 {
  $rd={} unless (defined($rd) && (ref($rd) eq 'HASH'));
  $rd->{approve}=($op eq 'accept')? 1 : 0;
  $rc=$ndr->process('domain','transfer_answer',[$domain,$rd]);
 }
 
 return $rc;
}

sub domain_transfer_start   { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_transfer($ndr,$domain,'start',$rd); }
sub domain_transfer_stop    { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_transfer($ndr,$domain,'stop',$rd); }
sub domain_transfer_query   { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_transfer($ndr,$domain,'query',$rd); }
sub domain_transfer_accept  { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_transfer($ndr,$domain,'accept',$rd); }
sub domain_transfer_refuse  { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_transfer($ndr,$domain,'refuse',$rd); }


sub domain_can
{
 my ($self,$ndr,$domain,$what,$rd)=@_;

 my $sok=$self->domain_status_allows($ndr,$domain,$what,$rd);
 return 0 unless ($sok);

 my $ismine=$self->domain_is_mine($ndr,$domain,$rd);
 my $n=$self->domain_operation_needs_is_mine($domain,$what);
 return unless (defined($n));
 return ($ismine xor $n)? 0 : 1;
}

sub domain_status_allows_delete   { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_status_allows($ndr,$domain,'delete',$rd); }
sub domain_status_allows_update   { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_status_allows($ndr,$domain,'update',$rd); }
sub domain_status_allows_transfer { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_status_allows($ndr,$domain,'transfer',$rd); }
sub domain_status_allows_renew    { my ($self,$ndr,$domain,$rd)=@_; return $self->domain_status_allows($ndr,$domain,'renew',$rd); }

sub domain_status_allows
{
 my ($self,$ndr,$domain,$what,$rd)=@_;

 return 0 unless ($what=~m/^(?:delete|update|transfer|renew)$/);
 my $s=$self->domain_current_status($ndr,$domain,$rd);
 return 0 unless (defined($s));

 return $s->can_delete()   if ($what eq 'delete');
 return $s->can_update()   if ($what eq 'update');
 return $s->can_transfer() if ($what eq 'transfer');
 return $s->can_renew()    if ($what eq 'renew');
 return 0; ## failsafe
}

sub domain_current_status
{
 my ($self,$ndr,$domain,$rd)=@_;
 my $rc=$self->domain_info($ndr,$domain,$rd);
 return unless $rc->is_success();
 my $s=$ndr->get_info('status');
 return unless (defined($s) && UNIVERSAL::isa($s,'Net::DRI::Data::StatusList'));
 return $s;
}

sub domain_is_mine
{
 my ($self,$ndr,$domain,$rd)=@_;
 my $clid=$self->info('clid');
 return 0 unless defined($clid);
 my $id;
 eval
 {
  my $rc=$self->domain_info($ndr,$domain,$rd);
  $id=$ndr->get_info('clID') if ($rc->is_success());
 };
 return 0 unless (!$@ && defined($id));
 return ($clid=~m/^${id}$/)? 1 : 0;
}

####################################################################################################
## Operations on HOSTS
####################################################################################################

sub host_create
{
 my ($self,$ndr,$dh,$rh)=@_;

 my $name=(UNIVERSAL::isa($dh,'Net::DRI::Data::Hosts'))? $dh->get_details(1) : $dh;
 err_invalid_host_name($name) if $self->verify_name_host($name,1);
 my $rc=$ndr->process('host','create',[$dh,$rh]);

 return $rc;
}

sub host_delete
{
 my ($self,$ndr,$dh,$rh)=@_;

 my $name=(UNIVERSAL::isa($dh,'Net::DRI::Data::Hosts'))? $dh->get_details(1) : $dh;
 err_invalid_host_name($name) if $self->verify_name_host($name);
 my $rc=$ndr->process('host','delete',[$dh,$rh]);

 return $rc;
}

sub host_info
{
 my ($self,$ndr,$dh,$rh)=@_;

 my $name=(UNIVERSAL::isa($dh,'Net::DRI::Data::Hosts'))? $dh->get_details(1) : $dh;
 err_invalid_host_name($name) if $self->verify_name_host($name);

 my ($rc,$exist);
 if (defined($exist=$ndr->get_info('exist','host',$name)) && $exist && defined($ndr->get_info('self','host',$name)))
 {
  $ndr->set_info_from_cache('host',$name);
  $rc=$ndr->get_info('result_status');
 } else
 {
  $rc=$ndr->process('host','info',[$dh,$rh]); ## cache was empty, go to registry
 }

 return $rc unless $rc->is_success();
 return (wantarray())? ($rc,$ndr->get_info('self')) : $rc;
}

sub host_check
{
 my ($self,$ndr,$dh,$rh)=@_;

 my $name=UNIVERSAL::isa($dh,'Net::DRI::Data::Hosts')? $dh->get_details(1) : $dh;
 err_invalid_host_name($name) if $self->verify_name_host($name);

 my $rc;
 if (defined($ndr->get_info('exist','host',$name))) ## check cache
 {
  $ndr->set_info_from_cache('host',$name);
  $rc=$ndr->get_info('result_status');
 } else
 {
  $rc=$ndr->process('host','check',[$dh,$rh]); ## go to registry
 }
 return $rc;
}

sub host_check_multi
{
 my $self=shift;
 my $ndr=shift;

 my $rh;
 $rh=pop(@_) if ($_[-1] && (ref($_[-1]) eq 'HASH'));
 my ($rc,@h);
 foreach my $host (map {UNIVERSAL::isa($_,'Net::DRI::Data::Hosts')? $_->get_names() : $_ } @_)
 {
  err_invalid_host_name($host) if $self->verify_name_host($host);
  if (defined($ndr->get_info('exist','host',$host)))
  {
   $ndr->set_info_from_cache('host',$host);
   $rc=$ndr->get_info('result_status');
  } else
  {
   push @h,$host;
  }
 }

 $rc=$ndr->process('host','check_multi',[\@h,$rh]) if @h;
 return $rc;
}

sub host_exist ## 1/0/undef
{
 my ($self,$ndr,$dh,$rh)=@_;

 my $name=(UNIVERSAL::isa($dh,'Net::DRI::Data::Hosts'))? $dh->get_details(1) : $dh;
 err_invalid_host_name($name) if $self->verify_name_host($name);

 my $rc=$ndr->host_check($name,$rh);
 return unless $rc->is_success();
 return $ndr->get_info('exist');
}

sub host_update
{
 my ($self,$ndr,$dh,$tochange,$rh)=@_;
 my $fp=$ndr->protocol->nameversion();

 my $name=(UNIVERSAL::isa($dh,'Net::DRI::Data::Hosts'))? $dh->get_details(1) : $dh;
 err_invalid_host_name($name) if $self->verify_name_host($name);
 Net::DRI::Util::check_isa($tochange,'Net::DRI::Data::Changes');

 foreach my $t ($tochange->types())
 {
  Net::DRI::Exception->die(0,'DRD',6,"Change host_update/${t} not handled") unless ($t=~m/^(?:ip|status|name)$/);
  next if $ndr->protocol_capable('host_update',$t);
  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable of host_update/${t}");
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

  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable for host_update/${w} to add") if (defined($add) &&
                                                                                       ! $ndr->protocol_capable('host_update',$w,'add'));
  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable for host_update/${w} to del") if (defined($del) &&
                                                                                       ! $ndr->protocol_capable('host_update',$w,'del'));
  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable for host_update/${w} to set") if (defined($set) &&
                                                                                       ! $ndr->protocol_capable('host_update',$w,'set'));
  Net::DRI::Exception->die(0,'DRD',6,"Change host_update/${w} with simultaneous set and add or del not supported") if (defined($set) && (defined($add) || defined($del)));
 }

 my $rc=$ndr->process('host','update',[$dh,$tochange,$rh]);
 return $rc;
}

sub host_update_ip_add { my ($self,$ndr,$dh,$ip,$rh)=@_; return $self->host_update_ip($ndr,$dh,$ip,$ndr->local_object('hosts'),$rh); }
sub host_update_ip_del { my ($self,$ndr,$dh,$ip,$rh)=@_; return $self->host_update_ip($ndr,$dh,$ndr->local_object('hosts'),$ip,$rh); }
sub host_update_ip_set { my ($self,$ndr,$dh,$ip,$rh)=@_; return $self->host_update_ip($ndr,$dh,$ip,undef,$rh); }

sub host_update_ip
{
 my ($self,$ndr,$dh,$ipadd,$ipdel,$rh)=@_;
 Net::DRI::Util::check_isa($ipadd,'Net::DRI::Data::Hosts');
 if (defined($ipdel)) ## add + del
 {
  Net::DRI::Util::check_isa($ipdel,'Net::DRI::Data::Hosts');
  my $c=$ndr->local_object('changes');
  $c->add('ip',$ipadd) unless ($ipadd->is_empty());
  $c->del('ip',$ipdel) unless ($ipdel->is_empty());
  return $self->host_update($ndr,$dh,$c,$rh);
 } else ## just set
 {
  return $self->host_update($ndr,$dh,$ndr->local_object('changes')->set('ip',$ipadd),$rh);
 }
}

sub host_update_status_add { my ($self,$ndr,$dh,$s,$rh)=@_; return $self->host_update_status($ndr,$dh,$s,$ndr->local_object('status'),$rh); }
sub host_update_status_del { my ($self,$ndr,$dh,$s,$rh)=@_; return $self->host_update_status($ndr,$dh,$ndr->local_object('status'),$s,$rh); }
sub host_update_status_set { my ($self,$ndr,$dh,$s,$rh)=@_; return $self->host_update_status($ndr,$dh,$s,undef,$rh); }

sub host_update_status
{
 my ($self,$ndr,$dh,$sadd,$sdel,$rh)=@_;
 Net::DRI::Util::check_isa($sadd,'Net::DRI::Data::StatusList');
 if (defined($sdel)) ## add + del
 {
  Net::DRI::Util::check_isa($sdel,'Net::DRI::Data::StatusList');
  my $c=$ndr->local_object('changes');
  $c->add('status',$sadd) unless ($sadd->is_empty());
  $c->del('status',$sdel) unless ($sdel->is_empty());
  return $self->host_update($ndr,$dh,$c,$rh);
 } ## just set
 {
  return $self->host_update($ndr,$dh,$ndr->local_object('changes')->set('status',$sadd),$rh);
 }
}

sub host_update_name_set
{
 my ($self,$ndr,$newname,$rh)=@_;
 $newname=$newname->get_names(1) if ($newname && UNIVERSAL::isa($newname,'Net::DRI::Data::Hosts'));
 err_invalid_host_name($newname) if $self->verify_name_host($newname);
 return $self->host_update($ndr,$ndr->local_object('changes')->set('name',$newname),$rh);
}

sub host_current_status
{
 my ($self,$ndr,$dh,$rh)=@_;
 my $rc=$self->host_info($ndr,$dh,$rh);
 return unless $rc->is_success();
 my $s=$ndr->get_info('status');
 return unless (defined($s) && UNIVERSAL::isa($s,'Net::DRI::Data::StatusList'));
 return $s;
}

sub host_is_mine
{
 my ($self,$ndr,$dh,$rh)=@_;
 my $clid=$self->info('clid');
 return 0 unless defined($clid);
 my $id;
 eval
 {
  my $rc=$self->host_info($ndr,$dh,$rh);
  $id=$ndr->get_info('clID') if ($rc->is_success());
 };
 return 0 unless (!$@ && defined($id));
 return ($clid=~m/^${id}$/)? 1 : 0;
}

####################################################################################################
## Operations on CONTACTS
####################################################################################################

sub contact_create
{
 my ($self,$ndr,$contact)=@_;
 err_invalid_contact($contact) unless (defined($contact) && UNIVERSAL::isa($contact,'Net::DRI::Data::Contact'));
 $contact->init('create') if $contact->can('init');
 $contact->validate(); ## will trigger an Exception if validation not ok
 my $rc=$ndr->process('contact','create',[$contact]);
 return $rc;
}

sub contact_delete
{
 my ($self,$ndr,$contact)=@_;
 err_invalid_contact($contact) unless (defined($contact) && UNIVERSAL::isa($contact,'Net::DRI::Data::Contact') && $contact->srid());
 my $rc=$ndr->process('contact','delete',[$contact]);
 return $rc;
}

sub contact_info
{
 my ($self,$ndr,$contact,$ep)=@_;
 err_invalid_contact($contact) unless (defined($contact) && UNIVERSAL::isa($contact,'Net::DRI::Data::Contact') && $contact->srid());
 
 my $rc;
 my $exist;
 ## See comments in domain_info
 if (defined($exist=$ndr->get_info('exist','contact',$contact->srid())) && $exist && defined($ndr->get_info('self','contact',$contact->srid())))
 {
  $ndr->set_info_from_cache('contact',$contact->srid());
  $rc=$ndr->get_info('result_status');
 } else
 {
  $rc=$ndr->process('contact','info',[$contact,$ep]);
 }
 return $rc;
}

sub contact_check
{
 my ($self,$ndr,$contact)=@_;
 err_invalid_contact($contact) unless (defined($contact) && UNIVERSAL::isa($contact,'Net::DRI::Data::Contact') && $contact->srid());

 my $rc;
 if (defined($ndr->get_info('exist','contact',$contact->srid())))
 {
  $ndr->set_info_from_cache('contact',$contact->srid());
  $rc=$ndr->get_info('result_status');
 } else
 {
  $rc=$ndr->process('contact','check',[$contact]);
 }
 return $rc;
}

sub contact_check_multi
{
 my $self=shift;
 my $ndr=shift;

 my ($rc,@c);
 foreach my $contact (@_)
 {
  err_invalid_contact($contact) unless (defined($contact) && UNIVERSAL::isa($contact,'Net::DRI::Data::Contact') && $contact->srid());
  if (defined($ndr->get_info('exist','contact',$contact->srid())))
  {
   $ndr->set_info_from_cache('contact',$contact->srid());
   $rc=$ndr->get_info('result_status');
  } else
  {
   push @c,$contact;
  }
 }

 $rc=$ndr->process('contact','check_multi',[\@c]) if @c;
 return $rc;
}

sub contact_exist ## 1/0/undef
{
 my ($self,$ndr,$contact)=@_;
 err_invalid_contact($contact) unless (defined($contact) && UNIVERSAL::isa($contact,'Net::DRI::Data::Contact') && $contact->srid());

 my $rc=$ndr->contact_check($contact);
 return unless $rc->is_success();
 return $ndr->get_info('exist');
}

sub contact_update
{
 my ($self,$ndr,$contact,$tochange)=@_;
 my $fp=$ndr->protocol->nameversion();
 
 err_invalid_contact($contact) unless (defined($contact) && UNIVERSAL::isa($contact,'Net::DRI::Data::Contact') && $contact->srid());
 Net::DRI::Util::check_isa($tochange,'Net::DRI::Data::Changes');

 foreach my $t ($tochange->types())
 {
  next if $ndr->protocol_capable('contact_update',$t);
  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable of contact_update/${t}");
 }

 foreach ($tochange->all_defined('status')) { Net::DRI::Util::check_isa($_,'Net::DRI::Data::StatusList'); }

 foreach my $w ($tochange->types())
 {
  my $add=$tochange->add($w);
  my $del=$tochange->del($w);
  my $set=$tochange->set($w);

  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable for contact_update/${w} to add") if (defined($add) && ! $ndr->protocol_capable('contact_update',$w,'add'));
  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable for contact_update/${w} to del") if (defined($del) && ! $ndr->protocol_capable('contact_update',$w,'del'));
  Net::DRI::Exception->die(0,'DRD',5,"Protocol ${fp} is not capable for contact_update/${w} to set") if (defined($set) && ! $ndr->protocol_capable('contact_update',$w,'set'));

  Net::DRI::Exception->die(0,'DRD',6,"Change contact_update/${w} with simultaneous set and add or del not supported") if (defined($set) && (defined($add) || defined($del)));
 }

 my $rc=$ndr->process('contact','update',[$contact,$tochange]);
 return $rc;
}

sub contact_update_status_add { my ($self,$ndr,$contact,$s)=@_; return $self->contact_update_status($ndr,$contact,$s,$ndr->local_object('status')); }
sub contact_update_status_del { my ($self,$ndr,$contact,$s)=@_; return $self->contact_update_status($ndr,$contact,$ndr->local_object('status'),$s); }
sub contact_update_status_set { my ($self,$ndr,$contact,$s)=@_; return $self->contact_update_status($ndr,$contact,$s); }

sub contact_update_status
{
 my ($self,$ndr,$contact,$sadd,$sdel)=@_;
 Net::DRI::Util::check_isa($sadd,'Net::DRI::Data::StatusList');
 if (defined($sdel)) ## add + del
 {
  Net::DRI::Util::check_isa($sdel,'Net::DRI::Data::StatusList');
  my $c=$ndr->local_object('changes');
  $c->add('status',$sadd) unless ($sadd->is_empty());
  $c->del('status',$sdel) unless ($sdel->is_empty());
  return $self->contact_update($ndr,$contact,$c);
 } else
 {
  return $self->contact_update($ndr,$contact,$ndr->local_object('changes')->set('status',$sadd));
 }
}


sub contact_transfer
{
 my ($self,$ndr,$contact,$op)=@_;
 err_invalid_contact($contact) unless (defined($contact) && UNIVERSAL::isa($contact,'Net::DRI::Data::Contact') && $contact->srid());
 Net::DRI::Exception::usererr_invalid_parameters("Transfer operation must be start,stop,accept,refuse or query") unless ($op=~m/^(?:start|stop|query|accept|refuse)$/);

 my $rc;
 if ($op eq 'start')
 {
  $rc=$ndr->process('contact','transfer_request',[$contact]);
 } elsif ($op eq 'stop')
 {
  $rc=$ndr->process('contact','transfer_cancel',[$contact]);
 } elsif ($op eq 'query')
 {
  $rc=$ndr->process('contact','transfer_query',[$contact]);
 } else ## accept/refuse
 {
  $rc=$ndr->process('contact','transfer_answer',[$contact,($op eq 'accept')? 1 : 0]);
 }

 return $rc;
}

sub contact_transfer_start   { my ($self,$ndr,$contact)=@_; return $self->contact_transfer($ndr,$contact,'start'); }
sub contact_transfer_stop    { my ($self,$ndr,$contact)=@_; return $self->contact_transfer($ndr,$contact,'stop'); }
sub contact_transfer_query   { my ($self,$ndr,$contact)=@_; return $self->contact_transfer($ndr,$contact,'query'); }
sub contact_transfer_accept  { my ($self,$ndr,$contact)=@_; return $self->contact_transfer($ndr,$contact,'accept'); }
sub contact_transfer_refuse  { my ($self,$ndr,$contact)=@_; return $self->contact_transfer($ndr,$contact,'refuse'); }

sub contact_current_status
{
 my ($self,$ndr,$contact)=@_;
 my $rc=$self->contact_info($ndr,$contact);
 return unless $rc->is_success();
 my $s=$ndr->get_info('status');
 return unless (defined($s) && UNIVERSAL::isa($s,'Net::DRI::Data::StatusList'));
 return $s;
}

sub contact_is_mine
{
 my ($self,$ndr,$contact)=@_;
 my $clid=$self->info('clid');
 return 0 unless defined($clid);
 my $id;
 eval
 {
  my $rc=$self->contact_info($ndr,$contact);
  $id=$ndr->get_info('clID') if ($rc->is_success());
 };
 return 0 unless (!$@ && defined($id));
 return ($clid=~m/^${id}$/)? 1 : 0;
}

####################################################################################################
## Message commands (like POLL in EPP)
####################################################################################################

sub message_retrieve
{
 my ($self,$ndr,$id)=@_;
 my $rc=$ndr->process('message','retrieve',[$id]);
 return $rc;
}

sub message_delete
{
 my ($self,$ndr,$id)=@_;
 my $rc=$ndr->process('message','delete',[$id]);
 return $rc;
}

sub message_waiting
{
 my ($self,$ndr)=@_;
 my $c=$self->message_count($ndr);
 return (defined($c) && $c)? 1 : 0;
}

sub message_count
{
 my ($self,$ndr)=@_;
 my $rc=$ndr->process('message','retrieve');
 return unless $rc->is_success();
 my $count=$ndr->get_info('count','message','info');
 return (defined($count) && $count)? $count : 0;
}

####################################################################################################
1;
