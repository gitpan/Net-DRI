## Domain Registry Interface, .UK EPP Account commands
##
## Copyright (c) 2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::Nominet::Account;

use strict;

use Net::DRI::Protocol::EPP::Core::Contact;
use Net::DRI::Protocol::EPP::Extensions::Nominet::Contact;
use Net::DRI::Data::ContactSet;
use Net::DRI::Util;
use Net::DRI::Exception;;

use DateTime::Format::ISO8601;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Nominet::Account - .UK EPP Account commands for Net::DRI

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

Copyright (c) 2008 Patrick Mevzek <netdri@dotandco.com>.
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
	 	info   => [ \&info, \&info_parse ],
		update => [ \&update ],
	);

 return { 'account' => \%tmp };
}

sub build_command
{
 my ($msg,$command,$contact)=@_;
 Net::DRI::Exception->die(1,'protocol/EPP',2,'Contact id needed') unless (defined($contact));

 my $id;
 if (Net::DRI::Util::isa_contactset($contact))
 {
  my $c=$contact->get('registrant');
  Net::DRI::Exception->die(1,'protocol/EPP',2,'ContactSet must contain a registrant contact object') unless (Net::DRI::Util::isa_contact($c));
  $id=$c->roid();
 } elsif (Net::DRI::Util::isa_contact($contact))
 {
  $id=$contact->roid();
 } else
 {
  $id=$contact;
 }
 Net::DRI::Exception->die(1,'protocol/EPP',2,'Contact id needed') unless (defined($id) && $id && !ref($id));
 Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid contact id: '.$id) unless Net::DRI::Util::xml_is_token($id,3,16); ## inherited from Core EPP
 my $tcommand=(ref($command))? $command->[0] : $command;
 my @ns=@{$msg->ns()->{account}};
 my $ns=($command eq 'update')? sprintf('xmlns:account="%s" xmlns:contact="%s" xsi:schemaLocation="%s %s"',$ns[0],$msg->ns()->{contact}->[0],$ns[0],$ns[1]) : sprintf('xmlns:account="%s" xsi:schemaLocation="%s %s"',$ns[0],$ns[0],$ns[1]);
 $msg->command([$command,'account:'.$tcommand,$ns]);
 return (['account:roid',$id]);
}


####################################################################################################
########### Query commands

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

 my $infdata=$mes->get_content('infData',$mes->ns('account'));
 return unless $infdata;

 parse_infdata($po,$mes,$infdata,$oname,$rinfo);
}

sub parse_infdata
{
 my ($po,$mes,$infdata,$oname,$rinfo)=@_;
 my %c;
 my $addr=0;
 my $cs=Net::DRI::Data::ContactSet->new();
 my $cf=$po->factories()->{contact};
 my $ca=$cf->();
 my $pd=DateTime::Format::ISO8601->new();
 my $c=$infdata->getFirstChild();
 while ($c)
 {
  next unless ($c->nodeType() == 1);
  my $name=$c->localname() || $c->nodeName();
  next unless $name;
  if ($name eq 'roid')
  {
   $oname=$c->getFirstChild()->getData();
   $ca->roid($oname);
   $cs->set($ca,'registrant');
   $rinfo->{account}->{$oname}->{roid}=$rinfo->{contact}->{$oname}->{roid}=$oname;
   $rinfo->{account}->{$oname}->{action}=$rinfo->{contact}->{$oname}->{roid}='info';
   $rinfo->{account}->{$oname}->{exist}=$rinfo->{contact}->{$oname}->{roid}=1;
  } elsif (my ($w)=($name=~m/^(name|trad-name|type|co-no|opt-out)$/))
  {
   $w=~s/-/_/;
   $w='org' if $w eq 'trad_name';
   $ca->$w($c->getFirstChild()->getData());
  } elsif ($name eq 'addr')
  {
   if ($addr)
   {
    ## Creating a second registrant contact to hold optional billing address
    my $ca2=$cf->();
    parse_addr($c,$ca2);
    $cs->add($ca2,'registrant');
   } else
   {
    parse_addr($c,$ca);
    $addr++;
   }
  } elsif ($name eq 'contact')
  {
   my $type=$c->getAttribute('type'); ## admin or billing
   my $order=$c->getAttribute('order'); ## 1 or 2 or 3
   my $co=$cf->();
   Net::DRI::Protocol::EPP::Extensions::Nominet::Contact::parse_infdata($c->getElementsByTagNameNS($mes->ns('contact'),'infData')->shift(),$co,undef,$rinfo);
   $c{$type}->{$order}=$co;
  } elsif ($name=~m/^(clID|crID|upID)$/)
  {
   $rinfo->{account}->{$oname}->{$1}=get_data($c);
  } elsif ($name=~m/^(crDate|upDate)$/)
  {
   $rinfo->{account}->{$oname}->{$1}=$pd->parse_datetime($c->getFirstChild()->getData());
  }
 } continue { $c=$c->getNextSibling(); }

 $cs->set([ map { $c{'admin'}->{$_} } sort { $a <=> $b } keys(%{$c{'admin'}}) ],'admin') if (exists($c{'admin'}));
 $cs->set([ map { $c{'billing'}->{$_} } sort { $a <=> $b } keys(%{$c{'billing'}}) ],'billing') if (exists($c{'billing'}));
 $rinfo->{account}->{$oname}->{self}=$cs;
 return $cs;
}

sub get_data
{
 my $n=shift;
 return ($n->getFirstChild())? $n->getFirstChild()->getData() : '';
}

sub parse_addr
{
 my ($n,$c)=@_;
 my @street;

 $n=$n->getFirstChild();
 while($n)
 {
  next unless ($n->nodeType() == 1);
  my $name=$n->localname() || $n->nodeName();
  next unless $name;
  if ($name eq 'street')
  {
   push @street,get_data($n);
  } elsif ($name eq 'locality')
  {
   push @street,get_data($n);
  } elsif ($name eq 'city')
  {
   $c->city(get_data($n));
  } elsif ($name eq 'county')
  {
   $c->sp(get_data($n));
  } elsif ($name eq 'postcode')
  {
   $c->pc(get_data($n));
  } elsif ($name eq 'country')
  {
   $c->cc(get_data($n));
  }
 } continue { $n=$n->getNextSibling(); }

 $c->street(\@street);
}

sub build_addr
{
 my ($c,$type)=@_;
 my @d;
 my @s=$c->street();
 if (@s)
 {
  @s=@{$s[0]};
  push @d,['account:street',$s[0]];
  push @d,['account:locality',$s[1]];
 }
 push @d,['account:city',$c->city()] if $c->city();
 push @d,['account:county',$c->sp()] if $c->sp();
 push @d,['account:postcode',$c->pc()] if $c->pc();
 push @d,['account:country',$c->cc()] if $c->cc();
 return @d? ['account:addr',{type=>$type},@d] : ();
}

sub add_account_data
{
 my ($mes,$cs,$ischange)=@_;
 my $modtype=$ischange? 'update' : 'create';
 my @a;
 my @o=$cs->get('registrant');
 if (Net::DRI::Util::isa_contact($o[0]))
 {
  $o[0]->validate($ischange);
  push @a,['account:name',$o[0]->name()] unless $ischange;
  push @a,['account:trad-name',$o[0]->org()] if $o[0]->org();
  push @a,['account:type',$o[0]->type()] if (!$ischange || $o[0]->type());
  push @a,['account:co-no',$o[0]->co_no()] if $o[0]->co_no();
  push @a,['account:opt-out',$o[0]->opt_out()] if (!$ischange || $o[0]->opt_out());
  push @a,build_addr($o[0],'admin');
 } else
 {
  Net::DRI::Exception::usererr_insufficient_parameters('registrant data is mandatory') unless $ischange;
 }

 if (Net::DRI::Util::isa_contact($o[1]))
 {
  $o[1]->validate() unless $ischange;
  my @t=build_addr($o[1],'billing');
  push @a,($ischange && !@t)? ['account:addr',{type=>'billing'}] : @t;
 }

 @o=$cs->get('admin');
 Net::DRI::Exception::usererr_insufficient_parameters('admin data is mandatory') unless ($ischange || Net::DRI::Util::isa_contact($o[0]));
 foreach my $o (0..2)
 {
   last unless defined($o[$o]);
   my @t=Net::DRI::Protocol::EPP::Extensions::Nominet::Contact::build_cdata($o[$o]);
   my $contype=$ischange? (($o[$o]->srid())? 'update' : 'create') : $modtype;
   push @a,['account:contact',{type=>'admin',order=>$o+1},($ischange && !@t)? () : ['contact:'.$contype,@t]];
 }
 @o=$cs->get('billing');
 foreach my $o (0..2)
 {
   last unless defined($o[$o]);
   my @t=Net::DRI::Protocol::EPP::Extensions::Nominet::Contact::build_cdata($o[$o]);
   my $contype=$ischange? (($o[$o]->srid())? 'update' : 'create') : $modtype;
   push @a,['account:contact',{type=>'billing',order=>$o+1},($ischange && !@t)? () : ['contact:'.$contype,@t]];
 }
 return @a;
}

sub update
{
 my ($epp,$c,$todo)=@_;
 my $mes=$epp->message();
 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);
 my $cs=$todo->set('contact');
 Net::DRI::Exception::usererr_invalid_parameters($cs.' must be a Net::DRI::Data::ContactSet object') unless Net::DRI::Util::isa_contactset($cs);
 my @d=build_command($mes,'update',$c);
 push @d,add_account_data($mes,$cs,1);
 $mes->command_body(\@d);
}

####################################################################################################
1;
