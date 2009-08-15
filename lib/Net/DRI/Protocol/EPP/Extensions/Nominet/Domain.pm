## Domain Registry Interface, .UK EPP Domain commands
##
## Copyright (c) 2008,2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Nominet::Domain;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Core::Domain;
use Net::DRI::Protocol::EPP::Extensions::Nominet::Account;
use Net::DRI::Protocol::EPP::Extensions::Nominet::Host;

our $VERSION=do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Nominet::Domain - .UK EPP Domain commands  for Net::DRI

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

Copyright (c) 2008,2009 Patrick Mevzek <netdri@dotandco.com>.
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
		check  => [ \&Net::DRI::Protocol::EPP::Core::Domain::check, \&Net::DRI::Protocol::EPP::Core::Domain::check_parse ],
		info   => [ \&info, \&info_parse ],
		delete => [ \&Net::DRI::Protocol::EPP::Core::Domain::delete ],
		renew => [ \&renew, \&Net::DRI::Protocol::EPP::Core::Domain::renew_parse ],
		transfer_request => [ \&transfer_request ],
		transfer_answer  => [ \&transfer_answer ],
		create => [\&create, \&create_parse ],
		update => [\&update],
                unrenew => [\&unrenew],
         );

 $tmp{check_multi}=$tmp{check};
 return { 'domain' => \%tmp };
}

####################################################################################################
########### Query commands

sub info
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Core::Domain::build_command($mes,'info',$domain);
 $mes->command_body(\@d);
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_response('domain','infData');
 return unless defined $infdata;

 my $ns=$po->create_local_object('hosts');
 my @n;

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'name')
  {
   $oname=lc($c->textContent());
   $rinfo->{domain}->{$oname}->{action}='info';
   $rinfo->{domain}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(reg-status|first-bill|recur-bill|auto-bill|next-bill)$/)
  {
   ## See http://www.nominet.org.uk/registrars/systems/data/fields/
   $rinfo->{domain}->{$oname}->{$1}=$c->textContent();
  } elsif ($name eq 'notes') ## There may be more than one instance of this element. (http://www.nominet.org.uk/registrars/systems/epp/domainnamelistelements/)
  {
   push @n,$c->textContent();
  } elsif ($name eq 'account')
  {
   my $cs=Net::DRI::Protocol::EPP::Extensions::Nominet::Account::parse_infdata($po,$mes,$c->getChildrenByTagNameNS($mes->ns('account'),'infData')->get_node(1),undef,$rinfo);
   $rinfo->{domain}->{$oname}->{contact}=$cs;
  } elsif ($name eq 'ns')
  {
   foreach my $nsinf ($c->getChildrenByTagNameNS($mes->ns('ns'),'infData'))
   {
    my $dh=Net::DRI::Protocol::EPP::Extensions::Nominet::Host::parse_infdata($po,$mes,$nsinf,undef,$rinfo);
    my @a=$dh->get_details(1);
    splice(@a,3,1,1);
    $ns->add(@a);
   }
   ## We loose here roid, clId, crId, crDate, upId, upDate, but this seems useless in a domain_info call ! They can always be accessed indirectly if really needed (see test file)
   ## If really needed, they could be added to Hosts (extra parameters)
  } elsif ($name=~m/^(clID|crID|upID)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$c->textContent();
  } elsif ($name=~m/^(crDate|upDate|exDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  }
 }

 $rinfo->{domain}->{$oname}->{ns}=$ns;
 $rinfo->{domain}->{$oname}->{notes}=\@n;
}

############ Transform commands ####################################################################

sub renew
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Core::Domain::build_command($mes,'renew',$domain);
 push @d,Net::DRI::Protocol::EPP::Core::Domain::build_period($rd->{duration}) if Net::DRI::Util::has_duration($rd);
 $mes->command_body(\@d);
}

sub transfer_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Core::Domain::build_command($mes,['transfer',{'op'=>'request'}],$domain);

 Net::DRI::Exception::usererr_insufficient_parameters('Extra parameters must be provided for domain transfer request, at least a registrar_tag') unless Net::DRI::Util::has_key($rd,'registrar_tag');
 Net::DRI::Exception::usererr_invalid_parameters('Registrar tag must be an XML token from 2 to 16 characters') unless Net::DRI::Util::xml_is_token($rd->{registrar_tag},2,16);
 push @d,['domain:registrar-tag',$rd->{registrar_tag}];

 if (Net::DRI::Util::has_key($rd,'account_id'))
 {
  my $id=Net::DRI::Util::isa_contactset($rd->{account_id})? $rd->{account_id}->get('registrant')->srid() : $rd->{account_id};
  Net::DRI::Exception::usererr_invalid_parameters('Account id must be an XML token with pattern [0-9]*(-UK)?') unless (Net::DRI::Util::xml_is_token($id) && $id=~m/^\d+(?:-UK)?$/);
  push @d,['domain:account',['domain:account-id',$id]];
 }
 $mes->command_body(\@d);
}

sub transfer_answer
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 $mes->command([['transfer',{'op'=>(Net::DRI::Util::has_key($rd,'approve') && $rd->{approve})? 'approve' : 'reject'}]]);

 Net::DRI::Exception::usererr_insufficient_parameters('Extra parameters must be provided for domain transfer request, at least a case_id') unless Net::DRI::Util::has_key($rd,'case_id');
 Net::DRI::Exception::usererr_invalid_parameters('Case id must be an XML token up to 12 characters') unless Net::DRI::Util::xml_is_token($rd->{case_id},undef,12);

 my @ns=@{$mes->ns()->{notifications}};
 my @d=['n:rcCase',{ 'xmlns:n' => $ns[0], 'xsi:schemaLocation' => $ns[0].' '.$ns[1]},['n:case-id',$rd->{case_id}]];
 $mes->command_body(\@d);
}

sub build_ns
{
 my ($mes,$ns)=@_;
 my @d;
 my $l=$ns->count();
 $l=10 if $l>10;
 my $needns=0;

 foreach my $i (1..$l)
 {
  my ($n,$r4,$r6,$rextra)=$ns->get_details($i);

  if (defined($rextra) && exists($rextra->{roid}) && $rextra->{roid})
  {
    push @d,['domain:nsObj',$rextra->{roid}];
  } else
  {
   my @h;
   push @h,['ns:name',$n];
   push @h,['ns:addr',{ip=>'v4'},$r4->[0]] if @$r4; ## it seems only one IP is allowed
   push @h,['ns:addr',{ip=>'v6'},$r6->[0]] if @$r6; ## ditto
   push @d,['ns:create',@h];
   $needns=1;
  }
 }
 return ['domain:ns',@d,$needns? {'xmlns:ns'=>$mes->ns('ns')} : {}];
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Core::Domain::build_command($mes,'create',$domain);
 push @d,Net::DRI::Protocol::EPP::Core::Domain::build_period($rd->{duration}) if Net::DRI::Util::has_duration($rd);

 ## account=contact
 Net::DRI::Exception::usererr_insufficient_parameters('account data is mandatory') unless Net::DRI::Util::has_key($rd,'contact');
 if (Net::DRI::Util::isa_contactset($rd->{contact}))
 {
  push @d,['domain:account',['account:create',{'xmlns:account'=>$mes->ns('account'),'xmlns:contact'=>$mes->ns('contact')},Net::DRI::Protocol::EPP::Extensions::Nominet::Account::add_account_data($mes,$rd->{contact},0)]];
 } else
 {
  push @d,['domain:account',['domain:account-id',$rd->{contact}]];
 }

 ## ns, optional
 push @d,build_ns($mes,$rd->{ns}) if (Net::DRI::Util::has_ns($rd));

 ## See http://www.nominet.org.uk/registrars/systems/data/fields/#billing
 push @d,['domain:first-bill',$rd->{'first-bill'}] if (Net::DRI::Util::has_key($rd,'first-bill') && $rd->{'first-bill'}=~m/^(?:th|bc)$/);
 push @d,['domain:recur-bill',$rd->{'recur-bill'}] if (Net::DRI::Util::has_key($rd,'recur-bill') && $rd->{'recur-bill'}=~m/^(?:th|bc)$/);
 push @d,['domain:auto-bill',$rd->{'auto-bill'}] if (Net::DRI::Util::has_key($rd,'auto-bill') && $rd->{'auto-bill'}=~m/^\d+$/ && $rd->{'auto-bill'}>=1 && $rd->{'auto-bill'}<=182);
 push @d,['domain:next-bill',$rd->{'next-bill'}] if (Net::DRI::Util::has_key($rd,'next-bill') && $rd->{'next-bill'}=~m/^\d+$/ && $rd->{'next-bill'}>=1 && $rd->{'next-bill'}<=182);
  push @d,['domain:notes',$rd->{notes}] if Net::DRI::Util::has_key($rd,'notes');

 $mes->command_body(\@d);
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $credata=$mes->get_response('domain','creData');
 return unless defined $credata;

 my $cs=$po->create_local_object('contactset');
 foreach my $el (Net::DRI::Util::xml_list_children($credata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'name')
  {
   $oname=lc($c->textContent());
   $rinfo->{domain}->{$oname}->{action}='create';
   $rinfo->{domain}->{$oname}->{exist}=1;
  } elsif ($name eq 'account')
  {
   my $node=$c->getChildrenByTagNameNS($mes->ns('account'),'creData')->get_node(1);
   my $roid=Net::DRI::Protocol::EPP::Extensions::Nominet::Account::parse_credata($mes,$node,$po,$cs,$rinfo);
   $rinfo->{account}->{$roid}->{action}='create';
   $rinfo->{domain}->{$oname}->{contact}=$cs;
  } elsif ($name eq 'ns')
  {
    my $ns=$po->create_local_object('hosts');
    my $nsns=$mes->ns('ns');
    foreach my $node ($c->getChildrenByTagNameNS($nsns,'creData'))
    {
     my $roid=$node->getChildrenByTagNameNS($nsns,'roid')->get_node(1)->textContent();
     my $name=$node->getChildrenByTagNameNS($nsns,'name')->get_node(1)->textContent();
     my $date=$po->parse_iso8601($node->getChildrenByTagNameNS($nsns,'crDate')->get_node(1)->textContent());
     $ns->add($name,[],[],undef,{roid => $roid});
     ## See Host::parse_infdata
     $rinfo->{host}->{$name}->{exist}=$rinfo->{host}->{$roid}->{exist}=1;
     $rinfo->{host}->{$name}->{roid}=$roid;
     $rinfo->{host}->{$name}->{crDate}=$date;
     $rinfo->{host}->{$roid}->{name}=$name;
     $rinfo->{host}->{$roid}->{crDate}=$date;
    }
   $rinfo->{domain}->{$oname}->{ns}=$ns
  } elsif ($name=~m/^(crDate|exDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$po->parse_iso8601($c->textContent());
  }
 }
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);

 my @d=Net::DRI::Protocol::EPP::Core::Domain::build_command($mes,'update',$domain);
 my $ns=$todo->set('ns');
 my $co=$todo->set('contact');

 ## account
 if (Net::DRI::Util::isa_contactset($co))
 {
  push @d,['domain:account',['account:update',{'xmlns:account'=>$mes->ns('account'),'xmlns:contact'=>$mes->ns('contact')},Net::DRI::Protocol::EPP::Extensions::Nominet::Account::add_account_data($mes,$co,1)]];
 }

 ## NS
 if (Net::DRI::Util::isa_hosts($ns,1))
 {
  if ($ns->is_empty())
  {
   push @d,['domain:ns']; ## empty domain:ns means removal of all nameservers from domain
  } else
  {
   push @d,build_ns($mes,$ns);
  }
 }

 my $tmp=$todo->set('first-bill');
 push @d,['domain:first-bill',$tmp] if (defined($tmp) && $tmp=~m/^(?:th|bc)$/);
 $tmp=$todo->set('recur-bill');
 push @d,['domain:recur-bill',$tmp] if (defined($tmp) && $tmp=~m/^(?:th|bc)$/);
 Net::DRI::Exception::usererr_invalid_parameters('For domain_update auto-bill and next-bill can not be there at the same time') if (defined($todo->set('auto-bill')) && $todo->set('auto-bill') && defined($todo->set('next-bill')) && $todo->set('next-bill'));
 $tmp=$todo->set('auto-bill');
 push @d,['domain:auto-bill',$tmp] if (defined($tmp) && ($tmp eq '' || ($tmp=~m/^\d+$/ && $tmp>=1 && $tmp<=182)));
 $tmp=$todo->set('next-bill');
 push @d,['domain:next-bill',$tmp] if (defined($tmp) && ($tmp eq '' || ($tmp=~m/^\d+$/ && $tmp>=1 && $tmp<=182)));
 $tmp=$todo->set('notes');
 push @d,['domain:notes',$tmp] if defined($tmp);

 $mes->command_body(\@d);
}

## Warning: this can also be used for multiple domain names at once,
## see http://www.nominet.org.uk/registrars/systems/nominetepp/Unrenew/
## However, if we accept that, we will probably have to tweak Core::Domain::renew_parse
## to handle multiple renData nodes in the response.
sub unrenew
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless defined($domain) && $domain;
 Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid domain name: '.$domain) unless Net::DRI::Util::is_hostname($domain);

 $mes->command(['update','domain:unrenew',sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('domain'))]);
 my @d=(['domain:name',$domain]);
 $mes->command_body(\@d);
}

####################################################################################################
1;
