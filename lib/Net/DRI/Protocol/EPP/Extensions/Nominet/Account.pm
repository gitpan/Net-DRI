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

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

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
	);

 return { 'account' => \%tmp };
}

sub build_command
{
 my ($msg,$command,$contact)=@_;
 Net::DRI::Exception->die(1,'protocol/EPP',2,'Contact id needed') unless (defined($contact));

 my $id;
 if (UNIVERSAL::isa($contact,'Net::DRI::Data::ContactSet'))
 {
  my $c=$contact->get('registrant');
  Net::DRI::Exception->die(1,'protocol/EPP',2,'ContactSet must contain a registrant contact') unless (defined($c));
  $id=$c->roid();
 } elsif (UNIVERSAL::isa($contact,'Net::DRI::Data::Contact'))
 {
  $id=$contact->roid();
 } else
 {
  $id=$contact;
 }
 Net::DRI::Exception->die(1,'protocol/EPP',2,'Contact id needed') unless defined($id) && $id;
 Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid contact id: '.$id) unless Net::DRI::Util::xml_is_token($id,3,16); ## inherited from Core EPP
 my $tcommand=(ref($command))? $command->[0] : $command;
 my @ns=@{$msg->ns->{account}};
 $msg->command([$command,'account:'.$tcommand,sprintf('xmlns:account="%s" xsi:schemaLocation="%s %s"',$ns[0],$ns[0],$ns[1])]);
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

####################################################################################################
1;
