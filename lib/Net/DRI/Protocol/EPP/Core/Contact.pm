## Domain Registry Interface, EPP Contact commands (RFC3733)
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

package Net::DRI::Protocol::EPP::Core::Contact;

use strict;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP;
use Net::DRI::Protocol::EPP::Core::Status;

use DateTime::Format::ISO8601;

our $VERSION=do { my @r=(q$Revision: 1.8 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

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

Copyright (c) 2005,2006 Patrick Mevzek <netdri@dotandco.com>.
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
           review_complete => [ undef, \&pandata_parse ],
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
 my @ns=@{$msg->ns->{contact}};
 $msg->command([$command,'contact:'.$tcommand,sprintf('xmlns:contact="%s" xsi:schemaLocation="%s %s"',$ns[0],$ns[0],$ns[1])]);

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

 my $chkdata=$mes->get_content('chkData',$mes->ns('contact'));
 return unless $chkdata;
 foreach my $cd ($chkdata->getElementsByTagNameNS($mes->ns('contact'),'cd'))
 {
  my $c=$cd->getFirstChild();
  my $contact;
  while($c)
  {
   my $n=$c->localname() || $c->nodeName();
   if ($n eq 'id')
   {
    $contact=$c->getFirstChild()->getData();
    $rinfo->{contact}->{$contact}->{action}='check';
    $rinfo->{contact}->{$contact}->{exist}=1-Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
   }
   if ($n eq 'reason')
   {
    $rinfo->{contact}->{$contact}->{exist_reason}=$c->getFirstChild()->getData();
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

 my $infdata=$mes->get_content('infData',$mes->ns('contact'));
 return unless $infdata;

 my %cd=map { $_ => [] } qw/name org street city sp pc cc/;
 my $contact=$po->factories()->{contact}->();
 my @s;
 my $c=$infdata->getFirstChild();
 while ($c)
 {
  my $name=$c->localname() || $c->nodeName();
  next unless $name;
  if ($name eq 'id')
  {
   $oname=$c->getFirstChild()->getData();
   $rinfo->{contact}->{$oname}->{action}='info';
   $rinfo->{contact}->{$oname}->{exist}=1;
   $contact->srid($oname);
  } elsif ($name eq 'roid')
  {
   $contact->roid($c->getFirstChild()->getData());
   $rinfo->{contact}->{$oname}->{roid}=$contact->roid();
  } elsif ($name eq 'status')
  {
   push @s,Net::DRI::Protocol::EPP::parse_status($c);
  } elsif ($name=~m/^(clID|crID|upID)$/)
  {
   $rinfo->{contact}->{$oname}->{$1}=$c->getFirstChild()->getData();
  } elsif ($name=~m/^(crDate|upDate|trDate)$/)
  {
   $rinfo->{contact}->{$oname}->{$1}=DateTime::Format::ISO8601->new()->parse_datetime($c->getFirstChild()->getData());
  } elsif ($name eq 'email')
  {
   $contact->email($c->getFirstChild()->getData());
  } elsif ($name eq 'voice')
  {
   $contact->voice(parse_tel($c));
  } elsif ($name eq 'fax')
  {
   $contact->fax(parse_tel($c));
  } elsif ($name eq 'postalInfo')
  {
   parse_postalinfo($c,\%cd);
  } elsif ($name eq 'authInfo')
  {
   my $pw=($c->getElementsByTagNameNS($mes->ns('contact'),'pw'))[0]->getFirstChild()->getData();
   $contact->auth({pw => $pw});
  } elsif ($name eq 'disclose')
  {
   $contact->disclose(parse_disclose($c));
  }
  $c=$c->getNextSibling();
 }

 $contact->name(@{$cd{name}});
 $contact->org(@{$cd{org}});
 $contact->street(@{$cd{street}});
 $contact->city(@{$cd{city}});
 $contact->sp(@{$cd{sp}});
 $contact->pc(@{$cd{pc}});
 $contact->cc(@{$cd{cc}});

 $rinfo->{contact}->{$oname}->{status}=Net::DRI::Protocol::EPP::Core::Status->new(\@s);
 $rinfo->{contact}->{$oname}->{self}=$contact;
}

sub parse_tel
{
 my $node=shift;
 my $ext=$node->getAttribute('x') || '';
 my $num=get_data($node);
 $num.="x${ext}" if $ext;
 return $num;
}

sub get_data
{
 my $n=shift;
 return ($n->getFirstChild())? $n->getFirstChild()->getData() : '';
}

sub parse_postalinfo
{
 my ($c,$rcd)=@_;
 my $type=$c->getAttribute('type'); ## int or loc
 my $ti={loc=>0,int=>1}->{$type};

 my $n=$c->getFirstChild();
 while($n)
 {
  my $name=$n->localname() || $n->nodeName();
  next unless $name;
  if ($name eq 'name')
  {
   $rcd->{name}->[$ti]=get_data($n);
  } elsif ($name eq 'org')
  {
   $rcd->{org}->[$ti]=get_data($n);
  } elsif ($name eq 'addr')
  {
   my $nn=$n->getFirstChild();
   my @street;
   while($nn)
   {
    my $name2=$nn->localname() || $nn->nodeName();
    next unless $name2;
    if ($name2 eq 'street')
    {
     push @street,get_data($nn);
    } elsif ($name2 eq 'city')
    {
     $rcd->{city}->[$ti]=get_data($nn);
    } elsif ($name2 eq 'sp')
    {
     $rcd->{sp}->[$ti]=get_data($nn);
    } elsif ($name2 eq 'pc')
    {
     $rcd->{pc}->[$ti]=get_data($nn);
    } elsif ($name2 eq 'cc')
    {
     $rcd->{cc}->[$ti]=get_data($nn);
    }
    $nn=$nn->getNextSibling();
   }
   $rcd->{street}->[$ti]=\@street;
  }
  $n=$n->getNextSibling();
 }
}

sub parse_disclose ## RFC 3733 §2.9
{
 my $c=shift;
 my $flag=Net::DRI::Util::xml_parse_boolean($c->getAttribute('flag'));
 my %tmp;
 my $n=$c->getFirstChild();
 while($n)
 {
  my $name=$n->localname() || $n->nodeName();
  next unless $name;
  if ($name=~m/^(name|org|addr)$/)
  {
   my $t=$n->getAttribute('type');
   $tmp{$1}=$flag;
   $tmp{"${1}_${t}"}=$flag;
  } elsif ($name=~m/^(voice|fax|email)$/)
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

 my $trndata=$mes->get_content('trnData',$mes->ns('contact'));
 return unless $trndata;

 my $c=$trndata->getFirstChild();
 while ($c)
 {
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'id')
  {
   $oname=$c->getFirstChild()->getData();
   $rinfo->{contact}->{$oname}->{id}=$oname;
   $rinfo->{contact}->{$oname}->{action}='transfer';
   $rinfo->{contact}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(trStatus|reID|acID)$/)
  {
   $rinfo->{contact}->{$oname}->{$1}=$c->getFirstChild()->getData();
  } elsif ($name=~m/^(reDate|acDate)$/)
  {
   $rinfo->{contact}->{$oname}->{$1}=DateTime::Format::ISO8601->new()->parse_datetime($c->getFirstChild()->getData());
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

 my (@postl,@posti,@addrl,@addri);
 _do_locint(\@postl,\@posti,$contact,'name');
 _do_locint(\@postl,\@posti,$contact,'org');
 _do_locint(\@addrl,\@addri,$contact,'street');
 _do_locint(\@addrl,\@addri,$contact,'city');
 _do_locint(\@addrl,\@addri,$contact,'sp');
 _do_locint(\@addrl,\@addri,$contact,'pc');
 _do_locint(\@addrl,\@addri,$contact,'cc');
 push @postl,['contact:addr',@addrl] if @addrl;
 push @posti,['contact:addr',@addri] if @addri;
 push @d,['contact:postalInfo',@postl,{type=>'loc'}] if @postl;
 push @d,['contact:postalInfo',@posti,{type=>'int'}] if @posti;


 push @d,build_tel('contact:voice',$contact->voice()) if defined($contact->voice());
 push @d,build_tel('contact:fax',$contact->fax()) if defined($contact->fax());
 push @d,['contact:email',$contact->email()] if defined($contact->email());
 push @d,build_authinfo($contact);
 push @d,build_disclose($contact);
 return @d;


 sub _do_locint
 {
  my ($rl,$ri,$contact,$what)=@_;
  my @tmp=$contact->$what();
  return unless @tmp;
  if ($what eq 'street')
  {
   if (defined($tmp[0])) { foreach (@{$tmp[0]}) { push @$rl,['contact:street',$_]; } };
   if (defined($tmp[1])) { foreach (@{$tmp[1]}) { push @$ri,['contact:street',$_]; } };
  } else
  {
   if (defined($tmp[0])) { push @$rl,['contact:'.$what,$tmp[0]]; }
   if (defined($tmp[1])) { push @$ri,['contact:'.$what,$tmp[1]]; }
  }
 }
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

 my $credata=$mes->get_content('creData',$mes->ns('contact'));
 return unless $credata;

 my $c=$credata->getFirstChild();
 while ($c)
 {
  my $name=$c->localname() || $c->nodeName();
  if ($name eq 'id')
  {
   my $new=$c->getFirstChild()->getData();
   $rinfo->{contact}->{$oname}->{id}=$new if (defined($oname) && ($oname ne $new)); ## registry may give another id than the one we requested or not take ours into account at all !
   $oname=$new;
   $rinfo->{contact}->{$oname}->{id}=$oname;
   $rinfo->{contact}->{$oname}->{action}='create';
   $rinfo->{contact}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(crDate)$/)
  {
   $rinfo->{contact}->{$oname}->{$1}=DateTime::Format::ISO8601->new()->parse_datetime($c->getFirstChild()->getData());
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
  my @c=build_cdata($newc);
  push @d,['contact:chg',@c] if @c;
 }
 $mes->command_body(\@d);
}

####################################################################################################
## RFC3733 §3.2.6  Offline Review of Requested Actions

sub pandata_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $pandata=$mes->get_content('panData',$mes->ns('contact'));
 return unless $pandata;

 my $c=$pandata->firstChild();
 while ($c)
 {
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'id')
  {
   $oname=$c->getFirstChild()->getData();
   $rinfo->{contact}->{$oname}->{action}='create_review';
   $rinfo->{contact}->{$oname}->{result}=Net::DRI::Util::xml_parse_boolean($c->getAttribute('paResult'));
   $rinfo->{contact}->{$oname}->{exist}=$rinfo->{contact}->{$oname}->{result};
  } elsif ($name eq 'paTRID')
  {
   my @tmp=$c->getElementsByTagNameNS($mes->ns('_main'),'clTRID');
   $rinfo->{contact}->{$oname}->{trid}=$tmp[0]->getFirstChild()->getData() if (@tmp && $tmp[0]);
   $rinfo->{contact}->{$oname}->{svtrid}=($c->getElementsByTagNameNS($mes->ns('_main'),'svTRID'))[0]->getFirstChild()->getData();
  } elsif ($name eq 'paDate')
  {
   $rinfo->{contact}->{$oname}->{date}=DateTime::Format::ISO8601->new()->parse_datetime($c->firstChild->getData());
  }
  $c=$c->getNextSibling();
 }
}

####################################################################################################
1;
