#!/usr/bin/perl -w

use Net::DRI;

use Test::More tests => 8;

our $R1='';
sub mysend
{
 my ($transport,$count,$msg)=@_;
 $R1=$msg->as_string();
 return 1;
}

sub munge_xmailer
{
 my $in=shift;
 $in=~s!MIME-tools \d\.\d+ \(Entity \d\.\d+\)!MIME-tools!;
 return $in;
}

my $dri=Net::DRI->new(10);
$dri->{trid_factory}=sub { return 'TRID-12345'; };

$dri->add_registry('AFNIC');
$dri->target('AFNIC')->new_current_profile('profile1','Net::DRI::Transport::Dummy',[{f_send=>\&mysend, f_recv=> sub {}}],'Net::DRI::Protocol::AFNIC::Email',['CLIENTID','CLIENTPW','test@localhost']);
$dri->transport->is_sync(0);


my $cs=$dri->local_object('contactset');
my $co=$dri->local_object('contact');
my $ns=$dri->local_object('hosts');

my $rc;

####################################################################################################

## FULL PM
$co->org('MyORG');
$co->street(['Whatever street 35','יחp אפ']);
$co->city('Alphaville');
$co->pc('99999');
$co->cc('FR');
$co->legal_form('S');
$co->legal_id('111222333');
$co->voice('+33.123456789');
$co->email('test@example.com');
$co->disclose('N');

$cs->set($co,'registrant');
$co=$dri->local_object('contact');
$co->roid('TEST-FRNIC');
$cs->set($co,'tech');

$ns->add('ns.toto.fr',['123.45.67.89']);
$ns->add('ns.toto.com');

$rc=$dri->domain_create_only('toto.fr',{contact => $cs, maintainer => 'ABCD', ns => $ns});

is($rc->code(),1001,'domain_create_only PM code');
is($rc->is_success(),1,'domain_create_only PM is_success');
is($rc->is_pending(),1,'domain_create_only PM is_pending');

my $E1=<<'EOF';
Content-Type: text/plain; charset="iso-8859-15"
Content-Disposition: inline
Content-Transfer-Encoding: 8bit
MIME-Version: 1.0
X-Mailer: Net::DRI 0.22/1.01 via MIME-tools 5.417 (Entity 5.417)
From: test@localhost
To: domain@nic.fr
Subject: CLIENTID domain_create [TRID-12345]

1a..: C
1b..: CLIENTID
1c..: CLIENTPW
1e..: TRID-12345
1f..: 2.0.0
2a..: toto.fr
3a..: MyORG
3b..: Whatever street 35
3c..: יחp אפ
3e..: Alphaville
3f..: 99999
3g..: FR
3h..: S
3j..: 111222333
3t..: +33 123456789
3v..: test@example.com
3w..: PM
3y..: ABCD
3z..: N
5a..: TEST-FRNIC
6a..: ns.toto.fr
6b..: 123.45.67.89
7a..: ns.toto.com
EOF

is(munge_xmailer($R1),munge_xmailer($E1),'domain_create_only build');

## REDUCED PP
$co=$dri->local_object('contact');
$co->roid('JOHN-FRNIC');
$co->disclose('N');
$co->key('ABCDEFGH-100');
$cs->set($co,'registrant');

$rc=$dri->domain_create_only('toto.fr',{contact => $cs, maintainer => 'ABCD', ns => $ns});
is($rc->code(),1001,'domain_create_only PPreduced code');
is($rc->is_success(),1,'domain_create_only PPreduced is_success');
is($rc->is_pending(),1,'domain_create_only PPreduced is_pending');

my $E2=<<'EOF';
Content-Type: text/plain; charset="iso-8859-15"
Content-Disposition: inline
Content-Transfer-Encoding: 8bit
MIME-Version: 1.0
X-Mailer: Net::DRI 0.22/1.01 via MIME-tools 5.417 (Entity 5.417)
From: test@localhost
To: domain@nic.fr
Subject: CLIENTID domain_create [TRID-12345]

1a..: C
1b..: CLIENTID
1c..: CLIENTPW
1e..: TRID-12345
1f..: 2.0.0
2a..: toto.fr
3q..: ABCDEFGH-100
3w..: PP
3x..: JOHN-FRNIC
5a..: TEST-FRNIC
6a..: ns.toto.fr
6b..: 123.45.67.89
7a..: ns.toto.com
EOF

is(munge_xmailer($R1),munge_xmailer($E2),'domain_create_only PPreduced build');

exit 0;
