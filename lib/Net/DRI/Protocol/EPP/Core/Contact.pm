## Domain Registry Interface, EPP Contact commands (RFC3733)
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

package Net::DRI::Protocol::EPP::Core::Contact;

use strict;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP;
use Net::DRI::Protocol::EPP::Core::Status;

use DateTime::Format::ISO8601;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };
our $NS='urn:ietf:params:xml:ns:contact-1.0';

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Core::Contact - EPP Contact commands (RFC3733) for Net::DRI

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


##########################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=( 
           check  => [ \&check, \&check_parse ],
           info   => [ \&info, \&info_parse ],
           transfer_query  => [ \&transfer_query, \&transfer_parse ],
           create => [ \&create, \&create_parse ],
           delete => [ \&delete ],
           transfer_request => [ \&transfer_request, \&transfer_parse ],
           transfer_cancel  => [ \&transfer_cancel,\&transfer_parse ],
           transfer_answer  => [ \&transfer_answer,\&transfer_parse ],
	   update => [ \&update ],
         );

 $tmp{check_multi}=$tmp{check};
 return { 'contact' => \%tmp };
}

sub build_command
{
 my ($msg,$command,$contact)=@_;
 my @contact=(ref($contact) eq 'ARRAY')? @$contact : ($contact);
 my @c=map { UNIVERSAL::isa($_,'Net::DRI::Data::Contact')? $_->srid() : $_ } @contact;

 Net::DRI::Exception->die(1,'protocol/EPP',2,"Contact id needed") unless @c;
 foreach my $n (@c)
 {
  Net::DRI::Exception->die(1,'protocol/EPP',2,'Contact id needed') unless defined($n) && $n;
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid contact id: '.$n) unless Net::DRI::Util::xml_is_token($n,3,16);
 }

 my $tcommand=(ref($command))? $command->[0] : $command;
 $msg->command([$command,'contact:'.$tcommand,'xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"']);

 my @d=map { ['contact:id',$_] } @c;

 if (($tcommand=~m/^(?:info|transfer)$/) && ref($contact[0]) && UNIVERSAL::isa($contact[0],'Net::DRI::Data::Contact'))
 {
  my $az=$contact[0]->auth();
  if ($az && ref($az) && exists($az->{pw}))
  {
   push @d,['contact:authInfo',['contact:pw',$az->{pw}]];
  }
 }
 
 return @d;
}

##################################################################################################
########### Query commands

sub check
{
 my ($epp,$c)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'check',$c);
 $mes->command_body(\@d);
}


sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkdata=$mes->get_content('chkData',$NS);
 return unless $chkdata;
 foreach my $cd ($chkdata->getElementsByTagNameNS($NS,'cd'))
 {
  my $c=$cd->firstChild;
  my $contact;
  while($c)
  {
   my $n=$c->nodeName();
   if ($n eq 'contact:id')
   {
    $contact=$c->firstChild->getData();
    $rinfo->{contact}->{$contact}->{exist}=1-Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
   }
   if ($n eq 'contact:reason')
   {
    $rinfo->{contact}->{$contact}->{exist_reason}=$c->firstChild->getData();
   }
   $c=$c->getNextSibling();
  }
 }
}

sub info
{
 my ($epp,$c)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'info',$c);
 $mes->command_body(\@d);
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_content('infData',$NS);
 return unless $infdata;

 $rinfo->{contact}->{$oname}->{exist}=1;

 my $contact=$po->factories()->{'contact'}->new();
 my @s;
 my $c=$infdata->firstChild();
 while ($c)
 {
  my $name=$c->nodeName();
  next unless $name;
  if ($name eq 'contact:id')
  {
   $contact->srid($c->firstChild->getData());
  } elsif ($name eq 'contact:roid')
  {
   $contact->roid($c->firstChild->getData());
   $rinfo->{contact}->{$oname}->{roid}=$contact->roid();
  } elsif ($name eq 'contact:status')
  {
   push @s,Net::DRI::Protocol::EPP::parse_status($c);
  } elsif ($name=~m/^contact:(clID|crID|upID)$/)
  {
   $rinfo->{contact}->{$oname}->{$1}=$c->firstChild->getData();
  } elsif ($name=~m/^contact:(crDate|upDate|trDate)$/)
  {
   $rinfo->{contact}->{$oname}->{$1}=DateTime::Format::ISO8601->new()->parse_datetime($c->firstChild->getData());
  } elsif ($name eq 'contact:email')
  {
   $contact->email($c->firstChild->getData());
  } elsif ($name eq 'contact:voice')
  {
   $contact->voice(parse_tel($c));
  } elsif ($name eq 'contact:fax')
  {
   $contact->fax(parse_tel($c));
  } elsif ($name eq 'contact:postalInfo')
  {
   parse_postalinfo($c,$contact);
  } elsif ($name eq 'contact:authInfo')
  {
   my $pw=($c->getElementsByTagNameNS($NS,'pw'))[0]->firstChild->getData();
   $contact->auth({pw => $pw});
  } elsif ($name eq 'contact:disclose')
  {
   $contact->disclose(parse_disclose($c));
  }
  $c=$c->getNextSibling();
 }

 $rinfo->{contact}->{$oname}->{status}=Net::DRI::Protocol::EPP::Core::Status->new(\@s);
 $rinfo->{contact}->{$oname}->{self}=$contact;
}

sub parse_tel
{
 my $node=shift;
 my $ext=$node->getAttribute('x') || '';
 my $num=$node->firstChild()->getData();
 $num.="x${ext}" if $ext;
 return $num;
}

sub parse_postalinfo
{
 my ($c,$contact)=@_;
 my $type=$c->getAttribute('type'); ## int or loc, but for now we do not take care of that
 return if (($type eq 'loc') && ($contact->name())); ## we prefer int over loc
 my $n=$c->getFirstChild();
 while($n)
 {
  my $name=$n->nodeName();
  next unless $name;
  if ($name eq 'contact:name')
  {
   $contact->name($n->getFirstChild()->getData());
  } elsif ($name eq 'contact:org')
  {
   $contact->org($n->getFirstChild()->getData());
  } elsif ($name eq 'contact:addr')
  {
   my $nn=$n->getFirstChild();
   my @street;
   while($nn)
   {
    my $name2=$nn->nodeName();
    next unless $name2;
    if ($name2 eq 'contact:street')
    {
     push @street,$nn->getFirstChild->getData();
    } elsif ($name2 eq 'contact:city')
    {
     $contact->city($nn->getFirstChild->getData());
    } elsif ($name2 eq 'contact:sp')
    {
     $contact->sp($nn->getFirstChild->getData());
    } elsif ($name2 eq 'contact:pc')
    {
     $contact->pc($nn->getFirstChild->getData());
    } elsif ($name2 eq 'contact:cc')
    {
     $contact->cc($nn->getFirstChild->getData());
    }
    $nn=$nn->getNextSibling();
   }
   $contact->street(\@street);
  }
  $n=$n->getNextSibling();
 }
}

sub parse_disclose ## RFC 3733 �2.9
{
 my $c=shift;
 my $flag=Net::DRI::Util::xml_parse_boolean($c->getAttribute('flag'));
 my %tmp;
 my $n=$c->firstChild;
 while($n)
 {
  my $name=$n->nodeName();
  next unless $name;
  if ($name=~m/^contact:(name|org|addr)$/)
  {
   my $t=$n->getAttribute('type');
   $tmp{$1}=$flag;
   $tmp{"${1}_${t}"}=$flag;
  } elsif ($name=~m/^contact:(voice|fax|email)$/)
  {
   $tmp{$1}=$flag;
  }
  $n=$n->getNextSibling();
 }
 return \%tmp;
}


sub transfer_query
{
 my ($epp,$c)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,['transfer',{'op'=>'query'}],$c);
 $mes->command_body(\@d);
}

sub transfer_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $trndata=$mes->get_content('trnData',$NS);
 return unless $trndata;

 $rinfo->{contact}->{$oname}->{exist}=1;

 my $c=$trndata->firstChild();
 while ($c)
 {
  my $name=$c->nodeName();
  next unless $name;

  if ($name=~m/^contact:(trStatus|reID|acID)$/) ## we do not use contact:id
  {
   $rinfo->{contact}->{$oname}->{$1}=$c->getFirstChild->getData();
  } elsif ($name=~m/^contact:(reDate|acDate)$/)
  {
   $rinfo->{contact}->{$oname}->{$1}=DateTime::Format::ISO8601->new()->parse_datetime($c->getFirstChild->getData());
  }
  $c=$c->getNextSibling();
 }
}

############ Transform commands

sub build_tel
{
 my ($name,$tel)=@_;
 if ($tel=~m/^(\S+)x(\S+)$/)
 {
  return [$name,$1,{x=>$2}];
 } else
 {
  return [$name,$tel];
 }
}

sub build_authinfo
{
 my $contact=shift;
 my $az=$contact->auth();
 return () unless ($az && ref($az) && exists($az->{pw}));
 return ['contact:authInfo',['contact:pw',$az->{pw}]];
}

sub build_disclose
{
 my $contact=shift;
 my $d=$contact->disclose();
 return () unless ($d && ref($d));
 my %v=map { $_ => 1 } values(%$d);
 return () unless (keys(%v)==1); ## 1 or 0 as values, not both at same time
 my @d;
 push @d,['contact:name',{type=>'int'}] if (exists($d->{name_int}) && !exists($d->{name}));
 push @d,['contact:name',{type=>'loc'}] if (exists($d->{name_loc}) && !exists($d->{name}));
 push @d,['contact:name',{type=>'int'}],['contact:name',{type=>'loc'}] if exists($d->{name});
 push @d,['contact:org',{type=>'int'}] if (exists($d->{org_int}) && !exists($d->{org}));
 push @d,['contact:org',{type=>'loc'}] if (exists($d->{org_loc}) && !exists($d->{org}));
 push @d,['contact:org',{type=>'int'}],['contact:org',{type=>'loc'}] if exists($d->{org});
 push @d,['contact:addr',{type=>'int'}] if (exists($d->{addr_int}) && !exists($d->{addr}));
 push @d,['contact:addr',{type=>'loc'}] if (exists($d->{addr_loc}) && !exists($d->{addr}));
 push @d,['contact:addr',{type=>'int'}],['contact:addr',{type=>'loc'}] if exists($d->{addr});
 push @d,['contact:voice'] if exists($d->{voice});
 push @d,['contact:fax']   if exists($d->{fax});
 push @d,['contact:email'] if exists($d->{email});
 return ['contact:disclose',@d,{flag=>(keys(%v))[0]}];
}

sub build_cdata
{
 my $contact=shift;
 my @d;
 my @post;
 push @post,['contact:name',$contact->name()] if defined($contact->name());
 push @post,['contact:org',$contact->org()] if defined($contact->org());
 my @addr;
 if (defined($contact->street())) { foreach (@{$contact->street()}) { push @addr,['contact:street',$_]; } }
 push @addr,['contact:city',$contact->city()];
 push @addr,['contact:sp',$contact->sp()] if defined($contact->sp());
 push @addr,['contact:pc',$contact->pc()] if defined($contact->pc());
 push @addr,['contact:cc',$contact->cc()];
 push @post,['contact:addr',@addr];
 push @d,['contact:postalInfo',@post,{type=>'int'}];
 push @d,build_tel('contact:voice',$contact->voice()) if defined($contact->voice());
 push @d,build_tel('contact:fax',$contact->fax()) if defined($contact->fax());
 push @d,['contact:email',$contact->email()] if defined($contact->email());
 push @d,build_authinfo($contact);
 push @d,build_disclose($contact);
 return @d;
}

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'create',$contact);
 
 Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid contact '.$contact) unless (UNIVERSAL::isa($contact,'Net::DRI::Data::Contact'));
 $contact->validate(); ## will trigger an Exception if needed
 push @d,build_cdata($contact);
 $mes->command_body(\@d);
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $credata=$mes->get_content('creData',$NS);
 return unless $credata;

 $rinfo->{contact}->{$oname}->{exist}=1;
 my $c=$credata->firstChild();
 while ($c) ## contact:id is not used
 {
  my $name=$c->nodeName();
  if ($name=~m/^contact:(crDate)$/)
  {
   $rinfo->{contact}->{$oname}->{$1}=DateTime::Format::ISO8601->new()->parse_datetime($c->firstChild->getData());
  }
  $c=$c->getNextSibling();
 }
}

sub delete
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'delete',$contact);
 $mes->command_body(\@d);
}

sub transfer_request
{
 my ($epp,$c)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,['transfer',{'op'=>'request'}],$c);
 $mes->command_body(\@d);
}

sub transfer_cancel
{
 my ($epp,$c)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,['transfer',{'op'=>'cancel'}],$c);
 $mes->command_body(\@d);
}

sub transfer_answer
{
 my ($epp,$c,$approve)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,['transfer',{'op'=>((defined($approve) && $approve)? 'approve' : 'reject' )}],$c);
 $mes->command_body(\@d);
}

sub update
{
 my ($epp,$contact,$todo)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo." must be a Net::DRI::Data::Changes object") unless ($todo && ref($todo) && $todo->isa('Net::DRI::Data::Changes'));
 if ((grep { ! /^(?:add|del)$/ } $todo->types('status')) ||
     (grep { ! /^(?:set)$/ } $todo->types('info'))
    )
 {
  Net::DRI::Exception->die(0,'protocol/EPP',11,'Only status add/del or info set available for contact');
 }

 my @d=build_command($mes,'update',$contact);

 my $sadd=$todo->add('status');
 my $sdel=$todo->del('status');
 push @d,['contact:add',$sadd->build_xml('contact:status')] if ($sadd);
 push @d,['contact:rem',$sdel->build_xml('contact:status')] if ($sdel);

 my $newc=$todo->set('info');
 if ($newc)
 {
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid contact '.$newc) unless (UNIVERSAL::isa($newc,'Net::DRI::Data::Contact'));
  $newc->validate(1); ## will trigger an Exception if needed
  push @d,['contact:chg',build_cdata($newc)];
 }
 $mes->command_body(\@d);
}

## TODO
## RFC3733 �3.2.6.  Offline Review of Requested Actions

#########################################################################################################
1;
