## Domain Registry Interface, EPP Domain commands (RFC4931)
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

package Net::DRI::Protocol::EPP::Core::Domain;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.20 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Core::Domain - EPP Domain commands (RFC4931 obsoleting RFC3731) for Net::DRI

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

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           check  => [ \&check, \&check_parse ],
           info   => [ \&info, \&info_parse ],
           transfer_query  => [ \&transfer_query, \&transfer_parse ],
           create => [ \&create, \&create_parse ],
           delete => [ \&delete ],
           renew => [ \&renew, \&renew_parse ],
           transfer_request => [ \&transfer_request, \&transfer_parse ],
           transfer_cancel  => [ \&transfer_cancel,\&transfer_parse ],
           transfer_answer  => [ \&transfer_answer,\&transfer_parse ],
           update => [ \&update ],
           review_complete => [ undef, \&pandata_parse ],
         );

 $tmp{check_multi}=$tmp{check};
 return { 'domain' => \%tmp };
}

sub build_command
{
 my ($msg,$command,$domain,$domainattr)=@_;
 my @dom=(ref($domain))? @$domain : ($domain);
 Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless @dom;
 foreach my $d (@dom)
 {
  Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless defined($d) && $d;
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid domain name: '.$d) unless Net::DRI::Util::is_hostname($d);
 }

 my $tcommand=(ref($command))? $command->[0] : $command;
 $msg->command([$command,'domain:'.$tcommand,sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$msg->nsattrs('domain'))]);

 my @d=map { ['domain:name',$_,$domainattr] } @dom;
 return @d;
}

sub build_authinfo
{
 my ($epp,$rauth,$isupdate)=@_;
 return ['domain:authInfo',['domain:null']] if ((! defined $rauth->{pw} || $rauth->{pw} eq '') && $epp->{usenullauth} && (defined($isupdate) && $isupdate));
 return ['domain:authInfo',['domain:pw',$rauth->{pw},exists($rauth->{roid})? { 'roid' => $rauth->{roid} } : undef]];
}

sub build_period
{
 my $dtd=shift; ## DateTime::Duration
 my ($y,$m)=$dtd->in_units('years','months'); ## all values are integral, but may be negative
 ($y,$m)=(0,$m+12*$y) if ($y && $m);
 my ($v,$u);
 if ($y)
 {
  Net::DRI::Exception::usererr_invalid_parameters('years must be between 1 and 99') unless ($y >= 1 && $y <= 99);
  $v=$y;
  $u='y';
 } else
 {
  Net::DRI::Exception::usererr_invalid_parameters('months must be between 1 and 99') unless ($m >= 1 && $m <= 99);
  $v=$m;
  $u='m';
 }

 return ['domain:period',$v,{'unit' => $u}];
}

####################################################################################################
########### Query commands

sub check
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'check',$domain);
 $mes->command_body(\@d);
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkdata=$mes->get_response('domain','chkData');
 return unless defined $chkdata;

 foreach my $cd ($chkdata->getChildrenByTagNameNS($mes->ns('domain'),'cd'))
 {
  my $domain;
  foreach my $el (Net::DRI::Util::xml_list_children($cd))
  {
   my ($n,$c)=@$el;
   if ($n eq 'name')
   {
    $domain=lc($c->textContent());
    $rinfo->{domain}->{$domain}->{action}='check';
    $rinfo->{domain}->{$domain}->{exist}=1-Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
   } elsif ($n eq 'reason')
   {
    $rinfo->{domain}->{$domain}->{exist_reason}=$c->textContent();
   }
  }
 }
}

sub info
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my $hosts='all';
 $hosts=$rd->{hosts} if (defined($rd) && (ref($rd) eq 'HASH') && exists($rd->{hosts}) && ($rd->{hosts}=~m/^(?:all|del|sub|none)$/));
 my @d=build_command($mes,'info',$domain,{'hosts'=> $hosts});
 push @d,build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);
 $mes->command_body(\@d);
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_response('domain','infData');
 return unless defined $infdata;

 my (@s,@host);
 my $cs=$po->create_local_object('contactset');
 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'name')
  {
   $oname=lc($c->textContent());
   $rinfo->{domain}->{$oname}->{action}='info';
   $rinfo->{domain}->{$oname}->{exist}=1;
  } elsif ($name eq 'roid')
  {
   $rinfo->{domain}->{$oname}->{roid}=$c->textContent();
  } elsif ($name eq 'status')
  {
   push @s,$po->parse_status($c);
  } elsif ($name eq 'registrant')
  {
   $cs->set($po->create_local_object('contact')->srid($c->textContent()),'registrant');
  } elsif ($name eq 'contact')
  {
   $cs->add($po->create_local_object('contact')->srid($c->textContent()),$c->getAttribute('type'));
  } elsif ($name eq 'ns')
  {
   $rinfo->{domain}->{$oname}->{ns}=parse_ns($po,$c);
  } elsif ($name eq 'host')
  {
   push @host,$c->textContent();
  } elsif ($name=~m/^(clID|crID|upID)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$c->textContent();
  } elsif ($name=~m/^(crDate|upDate|trDate|exDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  } elsif ($name eq 'authInfo') ## we only try to parse the authInfo version defined in the RFC, other cases are to be handled by extensions
  {
   $rinfo->{domain}->{$oname}->{auth}={pw => scalar Net::DRI::Util::xml_child_content($c,$mes->ns('domain'),'pw')};
  }
 }

 $rinfo->{domain}->{$oname}->{contact}=$cs;
 $rinfo->{domain}->{$oname}->{status}=$po->create_local_object('status')->add(@s);
 $rinfo->{domain}->{$oname}->{host}=$po->create_local_object('hosts')->set(@host) if @host;
}

sub parse_ns ## RFC 4931 §1.1
{
 my ($po,$node)=@_;
 my $ns=$po->create_local_object('hosts');

 foreach my $el (Net::DRI::Util::xml_list_children($node))
 {
  my ($name,$n)=@$el;
  if ($name eq 'hostObj')
  {
   $ns->add($n->textContent());
  } elsif ($name eq 'hostAttr')
  {
   my ($hostname,@ip4,@ip6);
   foreach my $sel (Net::DRI::Util::xml_list_children($n))
   {
    my ($name2,$nn)=@$sel;
    if ($name2 eq 'hostName')
    {
     $hostname=$nn->textContent();
    } elsif ($name2 eq 'hostAddr')
    {
     my $ip=$nn->getAttribute('ip') || 'v4';
     if ($ip eq 'v6')
     {
      push @ip6,$nn->textContent();
     } else
     {
      push @ip4,$nn->textContent();
     }
    }
   }
   $ns->add($hostname,\@ip4,\@ip6,1);
  }
 }
 return $ns;
}

sub transfer_query
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,['transfer',{'op'=>'query'}],$domain);
 push @d,build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);
 $mes->command_body(\@d);
}

sub transfer_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $trndata=$mes->get_response('domain','trnData');
 return unless defined $trndata;

 foreach my $el (Net::DRI::Util::xml_list_children($trndata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'name')
  {
   $oname=lc($c->textContent());
   $rinfo->{domain}->{$oname}->{action}='transfer';
   $rinfo->{domain}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(trStatus|reID|acID)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$c->textContent();
  } elsif ($name=~m/^(reDate|acDate|exDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  }
 }
}

############ Transform commands

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'create',$domain);

 my $def=$epp->default_parameters();
 if ($def && (ref($def) eq 'HASH') && exists($def->{domain_create}) && (ref($def->{domain_create}) eq 'HASH'))
 {
  $rd={} unless ($rd && (ref($rd) eq 'HASH') && keys(%$rd));
  while(my ($k,$v)=each(%{$def->{domain_create}}))
  {
   next if exists($rd->{$k});
   $rd->{$k}=$v;
  }
 }

 ## Period, OPTIONAL
 push @d,build_period($rd->{duration}) if Net::DRI::Util::has_duration($rd);

 ## Nameservers, OPTIONAL
 push @d,build_ns($epp,$rd->{ns},$domain) if Net::DRI::Util::has_ns($rd);

 ## Contacts, all OPTIONAL
 if (Net::DRI::Util::has_contact($rd))
 {
  my $cs=$rd->{contact};
  my @o=$cs->get('registrant');
  push @d,['domain:registrant',$o[0]->srid()] if (@o && Net::DRI::Util::isa_contact($o[0]));
  push @d,build_contact_noregistrant($epp,$cs);
 }

 ## AuthInfo
 Net::DRI::Exception::usererr_insufficient_parameters('authInfo is mandatory') unless Net::DRI::Util::has_auth($rd);
 push @d,build_authinfo($epp,$rd->{auth});
 $mes->command_body(\@d);
}

sub build_contact_noregistrant
{
 my ($epp,$cs)=@_;
 my @d;
 # All nonstandard contacts go into the extension section
 my %r=map { $_ => 1 } $epp->core_contact_types();
 foreach my $t (sort(grep { exists($r{$_}) } $cs->types()))
 {
  my @o=$cs->get($t);
  push @d,map { ['domain:contact',$_->srid(),{'type'=>$t}] } @o;
 }
 return @d;
}

sub build_ns
{
 my ($epp,$ns,$domain,$xmlns,$noip)=@_;

 my @d;
 my $asattr=$epp->{hostasattr};

 if ($asattr)
 {
  foreach my $i (1..$ns->count())
  {
   my ($n,$r4,$r6)=$ns->get_details($i);
   my @h;
   push @h,['domain:hostName',$n];
   if ((($n=~m/\S+\.${domain}$/i) || (lc($n) eq lc($domain)) || ($asattr==2)) && (!defined($noip) || !$noip))
   {
    push @h,map { ['domain:hostAddr',$_,{ip=>'v4'}] } @$r4 if @$r4;
    push @h,map { ['domain:hostAddr',$_,{ip=>'v6'}] } @$r6 if @$r6;
   }
   push @d,['domain:hostAttr',@h];
  }
 } else
 {
  @d=map { ['domain:hostObj',$_] } $ns->get_names();
 }

 $xmlns='domain' unless defined($xmlns);
 return [$xmlns.':ns',@d];
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $credata=$mes->get_response('domain','creData');
 return unless defined $credata;

 foreach my $el (Net::DRI::Util::xml_list_children($credata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'name')
  {
   $oname=lc($c->textContent());
   $rinfo->{domain}->{$oname}->{action}='create';
   $rinfo->{domain}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(crDate|exDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  }
 }
}

sub delete
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'delete',$domain);
 $mes->command_body(\@d);
}

sub renew
{
 my ($epp,$domain,$rd)=@_;
 my $curexp=Net::DRI::Util::has_key($rd,'current_expiration')? $rd->{current_expiration} : undef;
 Net::DRI::Exception::usererr_insufficient_parameters('current expiration date') unless defined($curexp);
 $curexp=$curexp->set_time_zone('UTC')->strftime('%Y-%m-%d') if (ref($curexp) && Net::DRI::Util::check_isa($curexp,'DateTime'));
 Net::DRI::Exception::usererr_invalid_parameters('current expiration date must be YYYY-MM-DD') unless $curexp=~m/^\d{4}-\d{2}-\d{2}$/;

 my $mes=$epp->message();
 my @d=build_command($mes,'renew',$domain);
 push @d,['domain:curExpDate',$curexp];
 push @d,build_period($rd->{duration}) if Net::DRI::Util::has_duration($rd);

 $mes->command_body(\@d);
}

sub renew_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $rendata=$mes->get_response('domain','renData');
 return unless defined $rendata;

 foreach my $el (Net::DRI::Util::xml_list_children($rendata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'name')
  {
   $oname=lc($c->textContent());
   $rinfo->{domain}->{$oname}->{action}='renew';
   $rinfo->{domain}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(exDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  }
 }
}

sub transfer_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,['transfer',{'op'=>'request'}],$domain);
 push @d,build_period($rd->{duration}) if Net::DRI::Util::has_duration($rd);
 push @d,build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);
 $mes->command_body(\@d);
}

sub transfer_answer
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,['transfer',{'op'=>(Net::DRI::Util::has_key($rd,'approve') && $rd->{approve})? 'approve' : 'reject'}],$domain);
 push @d,build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);
 $mes->command_body(\@d);
}

sub transfer_cancel
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,['transfer',{'op'=>'cancel'}],$domain);
 push @d,build_authinfo($epp,$rd->{auth}) if Net::DRI::Util::has_auth($rd);
 $mes->command_body(\@d);
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);

 my $nsadd=$todo->add('ns');
 my $nsdel=$todo->del('ns');
 my $sadd=$todo->add('status');
 my $sdel=$todo->del('status');
 my $cadd=$todo->add('contact');
 my $cdel=$todo->del('contact');

 my (@add,@del);
 push @add,build_ns($epp,$nsadd,$domain)            if Net::DRI::Util::isa_hosts($nsadd);
 push @add,build_contact_noregistrant($epp,$cadd)   if Net::DRI::Util::isa_contactset($cadd);
 push @add,$sadd->build_xml('domain:status','core') if Net::DRI::Util::isa_statuslist($sadd);
 push @del,build_ns($epp,$nsdel,$domain,undef,1)    if Net::DRI::Util::isa_hosts($nsdel);
 push @del,build_contact_noregistrant($epp,$cdel)   if Net::DRI::Util::isa_contactset($cdel);
 push @del,$sdel->build_xml('domain:status','core') if Net::DRI::Util::isa_statuslist($sdel);

 my @d=build_command($mes,'update',$domain);
 push @d,['domain:add',@add] if @add;
 push @d,['domain:rem',@del] if @del;

 my $chg=$todo->set('registrant');
 my @chg;
 push @chg,['domain:registrant',$chg->srid()] if Net::DRI::Util::isa_contact($chg);
 $chg=$todo->set('auth');
 push @chg,build_authinfo($epp,$chg,1) if ($chg && (ref $chg eq 'HASH') && exists $chg->{pw});
 push @d,['domain:chg',@chg] if @chg;
 $mes->command_body(\@d);
}

####################################################################################################
## RFC4931 §3.3  Offline Review of Requested Actions

sub pandata_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $pandata=$mes->get_response('domain','panData');
 return unless defined $pandata;

 foreach my $el (Net::DRI::Util::xml_list_children($pandata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'name')
  {
   $oname=lc($c->textContent());
   $rinfo->{domain}->{$oname}->{action}='review';
   $rinfo->{domain}->{$oname}->{result}=Net::DRI::Util::xml_parse_boolean($c->getAttribute('paResult'));
  } elsif ($name eq 'paTRID')
  {
   my $ns=$mes->ns('_main');
   my $tmp=Net::DRI::Util::xml_child_content($c,$ns,'clTRID');
   $rinfo->{domain}->{$oname}->{trid}=$tmp if defined $tmp;
   $rinfo->{domain}->{$oname}->{svtrid}=Net::DRI::Util::xml_child_content($c,$ns,'svTRID');
  } elsif ($name eq 'paDate')
  {
   $rinfo->{domain}->{$oname}->{date}=$po->parse_iso8601($c->textContent());
  }
 }
}

####################################################################################################
1;
