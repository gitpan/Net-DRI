## Domain Registry Interface, Gandi Web Domain commands
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

package Net::DRI::Protocol::Gandi::Web::Domain;

use strict;

our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::Gandi::Web::Domain - Gandi web Domain commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head2 CURRENT LIMITATIONS

Only domain_update_ns_* are provided

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

our $NSMAX=5; ## number of nameservers per domain on web form.

##########################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
	   update => [ \&mod, \&mod_parse ],
         );

 return { 'domain' => \%tmp };
}

sub build_msg
{
 my ($msg,$command,$domain)=@_;
 Net::DRI::Exception->die(1,'protocol/gandi/web',2,"Domain name needed") unless defined($domain) && $domain;
 Net::DRI::Exception->die(1,'protocol/gandi/web',10,"Invalid domain name") unless ($domain=~m/^[a-z0-9]([a-z0-9\-]{0,61}[a-z0-9])?\.[a-z0-9]([a-z0-9\-]{0,61}[a-z0-9])?$/i); ## from RRP grammar

 $msg->otype('domain');
 $msg->oname($domain);
 $msg->command($command);
}

sub mod
{
 my ($gweb,$domain,$todo)=@_;
 my $mes=$gweb->message();
 build_msg($mes,'mod',$domain);

 Net::DRI::Exception::usererr_invalid_parameters($todo." must be a Net::DRI::Data::Changes object") unless ($todo && UNIVERSAL::isa($todo,'Net::DRI::Data::Changes'));
 if ((grep { ! /^(?:ns)$/ } $todo->types()) ||
     (grep { ! /^(?:add|del|set)$/ } $todo->types('ns'))
    )
 {
  Net::DRI::Exception->die(0,'protocol/gandi/web',11,'Only ns add/del/set available for domain');
 }

 my $nsadd=$todo->add('ns'); ## Net::DRI::Data::Hosts objects
 my $nsdel=$todo->del('ns');
 my $nsset=$todo->set('ns');

 $mes->method(\&mod_act);
 $mes->params([$domain,$nsadd,$nsdel,$nsset]);
 $mes->oname($domain);
}

sub mod_act
{
 my ($rp,$to)=@_;
 my $wm=$to->wm();
 my $ctx=$to->ctx();
 my $pc=$to->pc();

 my ($domain,$nsadd,$nsdel,$nsset)=@$rp;
 die(Net::DRI::Protocol::ResultStatus->new_error(2201,"Authorization error: ${domain} not in list of domains that can be modified")) unless exists($ctx->{urls}->{lc($domain)});

 $wm->get($ctx->{urls}->{lc($domain)});
 Net::DRI::Exception->die(0,'transport',4,'Unable to send message to registry') unless $wm->success();
 my $c=$wm->content();

 Net::DRI::Exception->die(0,'transport',7,'Unable to analyze modification page (page change ?)') unless ($c=~m/Changement des serveurs de noms du domaine ${domain}/i);

 $wm->form_number(1);
 my $form=$wm->current_form();

 my @cn=map { [lc($form->find_input("NS${_}N","text")->value()) || '',$form->find_input("NS${_}I","text")->value() || ''] } (1..$NSMAX); ## current list of nameservers' name
 @cn=grep { $_->[0] } @cn; ## remove empty nameservers

 if (defined($nsset))
 {
  @cn=map { [details_to_nip4($nsset,$_)] } (1..$nsset->count());
 } else ## add and/or del
 {
  if (defined($nsdel))
  {
   my %ns=map { $_ => 1 } $nsdel->get_names($NSMAX);
   @cn=grep { ! exists($ns{$_->[0]}) } @cn;
  }
  if (defined($nsadd))
  {
   my %ns=map { $_->[0] => 1 } @cn;
   foreach my $c (grep { ! exists($ns{$nsadd->get_details($_)}) } (1..$nsadd->count()))
   {
    push @cn,[details_to_nip4($nsadd,$c)];
   }
  }
 }

 foreach my $i (1..$NSMAX)
 {
  if ($cn[$i-1] && $cn[$i-1]->[0])
  {
   $wm->field("NS${i}N",$cn[$i-1]->[0]);
   $wm->field("NS${i}I",$cn[$i-1]->[1]);
  } else
  {
   $wm->field("NS${i}N",'');
   $wm->field("NS${i}I",'');
  }
 }

 $pc->sleep();
 $wm->submit();
 Net::DRI::Exception->die(0,'transport',4,'Unable to send message to registry') unless $wm->success();
}

sub details_to_nip4
{
 my ($ns,$c)=@_;
 my @d=$ns->get_details($c);
 my $ip=(@{$d[1]} > 0)? $d[1]->[0] : '';
 return ($d[0],$ip); ## name + first IPv4 address
}

sub mod_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();

 my $c=$mes->pagecontent();
 if ($c=~m/\QLa modification s'est effectu&eacute;e.\E/i)
 {
  $mes->errcode(1000); ## command completed successfully
 } else ## try to extract the error message, crude way
 {
  $mes->errcode(2400); ## command failed
  my ($e)=($c=~m/pour les raisons suivantes : (.+)Merci de revenir en arri/s);
  $e=~s/<[^>]+>//g;
  $e=~s/^\s*$//mg;
  $e=~s/^\n//;
  $e=~s/\n$//;
  $mes->errmsg($e);
 }
}

#########################################################################################################
1;
