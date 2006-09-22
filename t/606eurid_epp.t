#!/usr/bin/perl -w

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 157;

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:contact="http://www.eurid.eu/xml/epp/contact-1.0" xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd http://www.eurid.eu/xml/epp/contact-1.0 contact-1.0.xsd http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd">';

our $E2='</epp>';
our $TRID='<trID><clTRID>TRID-0001</clTRID><svTRID>eurid-488059</svTRID></trID>';

our $R1;
sub mysend
{
 my ($transport,$count,$msg)=@_;
 $R1=$msg->as_string();
 return 1;
}

our $R2;
sub myrecv
{
 return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2);
}

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}

my $dri=Net::DRI->new(10);
$dri->{trid_factory}=sub { return 'TRID-0001'; };
$dri->add_registry('EURid');
$dri->target('EURid')->new_current_profile('p1','Net::DRI::Transport::Dummy',[{f_send=>\&mysend,f_recv=>\&myrecv}],'Net::DRI::Protocol::EPP::Extensions::EURid',[]);
my $rc;
my $s;
my $d;
my ($dh,@c);

########################################################################################################
## Examples taken from registration_guidelines_v1_0E-epp.pdf 

## Contact
## p.22
$R2=$E1.'<response>'.r().'<resData><contact:creData><contact:id>sb3249</contact:id><contact:crDate>2005-09-22T13:28:28.000Z</contact:crDate></contact:creData></resData><extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('sb3249');
$co->name('Smith Bill');
$co->org('EPP Company');
$co->street(['Blue Tower','Main street, 58']);
$co->city('Paris');
$co->pc('571234');
$co->cc('FR');
$co->voice('+33.16345656');
$co->fax('+33.16345656');
$co->email('noreply@eurid.eu');
$co->type('registrant');
$co->vat('FR3455345645');
$co->lang('fr');
$rc=$dri->contact_create($co);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><create><contact:create xmlns:contact="http://www.eurid.eu/xml/epp/contact-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/contact-1.0 contact-1.0.xsd"><contact:id>sb3249</contact:id><contact:postalInfo type="loc"><contact:name>Smith Bill</contact:name><contact:org>EPP Company</contact:org><contact:addr><contact:street>Blue Tower</contact:street><contact:street>Main street, 58</contact:street><contact:city>Paris</contact:city><contact:pc>571234</contact:pc><contact:cc>FR</contact:cc></contact:addr></contact:postalInfo><contact:voice>+33.16345656</contact:voice><contact:fax>+33.16345656</contact:fax><contact:email>noreply@eurid.eu</contact:email><contact:authInfo><contact:pw/></contact:authInfo></contact:create></create><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:create><eurid:contact><eurid:type>registrant</eurid:type><eurid:vat>FR3455345645</eurid:vat><eurid:lang>fr</eurid:lang></eurid:contact></eurid:create></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','contact_create build 1');
is($rc->is_success(),1,'contact_create is_success 1');
is($dri->get_info('exist'),1,'contact_create get_info(exist) 1');
is($dri->get_info('id'),'sb3249','contact_create get_info(id) 1');
is(''.$dri->get_info('crDate'),'2005-09-22T13:28:28','contact_create get_info(crdate) 1');


## p.23
$R2=$E1.'<response>'.r().'<resData><contact:creData><contact:id>bg2022</contact:id><contact:crDate>2005-09-22T13:36:45.000Z</contact:crDate></contact:creData></resData><extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('bg2022');
$co->name('Banderas George');
$co->street(['Yellow Tower','Main street, 85']);
$co->city('Brussels');
$co->pc('1000');
$co->cc('BE');
$co->voice('+32.16345656');
$co->fax('+32.16345656');
$co->email('noreply@eurid.eu');
$co->type('registrant');
$co->lang('en');
$rc=$dri->contact_create($co);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><create><contact:create xmlns:contact="http://www.eurid.eu/xml/epp/contact-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/contact-1.0 contact-1.0.xsd"><contact:id>bg2022</contact:id><contact:postalInfo type="loc"><contact:name>Banderas George</contact:name><contact:addr><contact:street>Yellow Tower</contact:street><contact:street>Main street, 85</contact:street><contact:city>Brussels</contact:city><contact:pc>1000</contact:pc><contact:cc>BE</contact:cc></contact:addr></contact:postalInfo><contact:voice>+32.16345656</contact:voice><contact:fax>+32.16345656</contact:fax><contact:email>noreply@eurid.eu</contact:email><contact:authInfo><contact:pw/></contact:authInfo></contact:create></create><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:create><eurid:contact><eurid:type>registrant</eurid:type><eurid:lang>en</eurid:lang></eurid:contact></eurid:create></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','contact_create build 2');
is($rc->is_success(),1,'contact_create is_success 2');
is($dri->get_info('exist'),1,'contact_create get_info(exist) 2');
is($dri->get_info('id'),'bg2022','contact_create get_info(id) 2');
is(''.$dri->get_info('crDate'),'2005-09-22T13:36:45','contact_create get_info(crdate) 2');


## p.28
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('sb3249');
$toc=$dri->local_object('changes');
my $co2=$dri->local_object('contact');
$co2->org('Newco');
$co2->street(['Green Tower','City Square']);
$co2->city('London');
$co2->pc('1111');
$co2->cc('GB');
$co2->voice('+44.1865332156');
$co2->fax('+44.1865332157');
$co2->email('noreply@eurid.eu');
$co2->vat('GB12345678');
$co2->lang('en');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><update><contact:update xmlns:contact="http://www.eurid.eu/xml/epp/contact-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/contact-1.0 contact-1.0.xsd"><contact:id>sb3249</contact:id><contact:chg><contact:postalInfo type="loc"><contact:org>Newco</contact:org><contact:addr><contact:street>Green Tower</contact:street><contact:street>City Square</contact:street><contact:city>London</contact:city><contact:pc>1111</contact:pc><contact:cc>GB</contact:cc></contact:addr></contact:postalInfo><contact:voice>+44.1865332156</contact:voice><contact:fax>+44.1865332157</contact:fax><contact:email>noreply@eurid.eu</contact:email></contact:chg></contact:update></update><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:update><eurid:contact><eurid:chg><eurid:vat>GB12345678</eurid:vat><eurid:lang>en</eurid:lang></eurid:chg></eurid:contact></eurid:update></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','contact_update build 1');
is($rc->is_success(),1,'contact_update is_success 1');


## p.29
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$toc=$dri->local_object('changes');
$co2=$dri->local_object('contact');
$co2->voice('+44.1865332156');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><update><contact:update xmlns:contact="http://www.eurid.eu/xml/epp/contact-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/contact-1.0 contact-1.0.xsd"><contact:id>sb3249</contact:id><contact:chg><contact:voice>+44.1865332156</contact:voice></contact:chg></contact:update></update><clTRID>TRID-0001</clTRID></command></epp>','contact_update build 2');
is($rc->is_success(),1,'contact_update is_success 2');


## p.30
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$toc=$dri->local_object('changes');
$co2=$dri->local_object('contact');
$co2->lang('nl');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><update><contact:update xmlns:contact="http://www.eurid.eu/xml/epp/contact-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/contact-1.0 contact-1.0.xsd"><contact:id>sb3249</contact:id></contact:update></update><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:update><eurid:contact><eurid:chg><eurid:lang>nl</eurid:lang></eurid:chg></eurid:contact></eurid:update></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','contact_update build 3');
is($rc->is_success(),1,'contact_update is_success 3');


## p.31
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$toc=$dri->local_object('changes');
$co2=$dri->local_object('contact');
$co2->org('');
$co2->vat('');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><update><contact:update xmlns:contact="http://www.eurid.eu/xml/epp/contact-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/contact-1.0 contact-1.0.xsd"><contact:id>sb3249</contact:id><contact:chg><contact:postalInfo type="loc"><contact:org/></contact:postalInfo></contact:chg></contact:update></update><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:update><eurid:contact><eurid:chg><eurid:vat/></eurid:chg></eurid:contact></eurid:update></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','contact_update build 4');
is($rc->is_success(),1,'contact_update is_success 4');


## p.32
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->contact_delete($dri->local_object('contact')->srid('sj5'));

is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><delete><contact:delete xmlns:contact="http://www.eurid.eu/xml/epp/contact-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/contact-1.0 contact-1.0.xsd"><contact:id>sj5</contact:id></contact:delete></delete><clTRID>TRID-0001</clTRID></command></epp>','contact_delete build');
is($rc->is_success(),1,'contact_delete is_success');


## p.35
$R2=$E1.'<response>'.r().'<resData><contact:infData><contact:id>sb3249</contact:id><contact:roid>477365-EURID</contact:roid><contact:status s="ok"/><contact:postalInfo type="loc"><contact:name>Smith Bill</contact:name><contact:org/><contact:addr><contact:street>Green Tower</contact:street><contact:street>City Square</contact:street><contact:city>London</contact:city><contact:pc>1111</contact:pc><contact:cc>GB</contact:cc></contact:addr></contact:postalInfo><contact:voice>+44.1865332156</contact:voice><contact:fax>+44.1865332157</contact:fax><contact:email>noreply@eurid.eu</contact:email><contact:clID>t000006</contact:clID><contact:crID>t000006</contact:crID><contact:crDate>2005-09-22T13:28:31.000Z</contact:crDate><contact:upDate>2005-09-22T14:41:48.000Z</contact:upDate></contact:infData></resData><extension><eurid:ext><eurid:infData><eurid:contact><eurid:type>registrant</eurid:type><eurid:lang>nl</eurid:lang></eurid:contact></eurid:infData></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->contact_info($dri->local_object('contact')->srid('sb3249'));
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><info><contact:info xmlns:contact="http://www.eurid.eu/xml/epp/contact-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/contact-1.0 contact-1.0.xsd"><contact:id>sb3249</contact:id></contact:info></info><clTRID>TRID-0001</clTRID></command></epp>','contact_info build');
is($rc->is_success(),1,'contact_info is_success');
is($dri->get_info('exist'),1,'contact_info get_info(exist)');
$co=$dri->get_info('self');
isa_ok($co,'Net::DRI::Data::Contact::EURid','contact_info get_info(self)');
is($co->srid(),'sb3249','contact_info get_info(self) srid');
is($co->roid(),'477365-EURID','contact_info get_info(self) roid');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','contact_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'contact_info get_info(status) list_status');
is($s->can_delete(),1,'contact_info get_info(status) can_delete');
is($co->name(),'Smith Bill','contact_info get_info(self) name');
is($co->org(),'','contact_info get_info(self) org');
is_deeply($co->street(),['Green Tower','City Square'],'contact_info get_info(self) street');
is($co->city(),'London','contact_info get_info(self) city');
is($co->pc(),'1111','contact_info get_info(self) pc');
is($co->cc(),'GB','contact_info get_info(self) cc');
is($co->voice(),'+44.1865332156','contact_info get_info(self) voice');
is($co->fax(),'+44.1865332157','contact_info get_info(self) fax');
is($co->email(),'noreply@eurid.eu','contact_info get_info(self) email');
is($dri->get_info('clID'),'t000006','contact_info get_info(clID)');
is($dri->get_info('crID'),'t000006','contact_info get_info(crID)'),
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','contact_info get_info(crDate)');
is(''.$d,'2005-09-22T13:28:31','contact_info get_info(crDate) value');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','contact_info get_info(upDate)');
is(''.$d,'2005-09-22T14:41:48','contact_info get_info(upDate) value');
is($co->type(),'registrant','contact_info get_info(self) type');
is($co->lang(),'nl','contact_info get_info(self) lang');


#############################################################################################################
## Nsgroup

## p.39
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$dh=$dri->local_object('hosts');
$dh->name('nsgroup-eurid');
$dh->add('ns1.eurid.eu');
$dh->add('ns2.eurid.eu');
$dh->add('ns3.eurid.eu');
$dh->add('ns4.eurid.eu');
$dh->add('ns5.eurid.eu');
my $ro=$dri->remote_object('nsgroup');
$rc=$ro->create($dh);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><create><nsgroup:create xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>nsgroup-eurid</nsgroup:name><nsgroup:ns>ns1.eurid.eu</nsgroup:ns><nsgroup:ns>ns2.eurid.eu</nsgroup:ns><nsgroup:ns>ns3.eurid.eu</nsgroup:ns><nsgroup:ns>ns4.eurid.eu</nsgroup:ns><nsgroup:ns>ns5.eurid.eu</nsgroup:ns></nsgroup:create></create><clTRID>TRID-0001</clTRID></command>'.$E2,'nsgroup_create build');
is($rc->is_success(),1,'nsgroup_create is_success');


## p.42
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$dh=$dri->local_object('hosts')->name('nsgroup-eurid3');
$toc=$dri->local_object('changes');
$toc->set('ns',$dri->local_object('hosts')->name('nsgroup-eurid3')->add('ns2.eurid.eu'));
$rc=$ro->update($dh,$toc);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><update><nsgroup:update xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>nsgroup-eurid3</nsgroup:name><nsgroup:ns>ns2.eurid.eu</nsgroup:ns></nsgroup:update></update><clTRID>TRID-0001</clTRID></command>'.$E2,'nsgroup_update build');
is($rc->is_success(),1,'nsgroup_update is_success');


## p.44
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$dh->name('nsgroup-eurid3');
$rc=$ro->delete($dh);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><delete><nsgroup:delete xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>nsgroup-eurid3</nsgroup:name></nsgroup:delete></delete><clTRID>TRID-0001</clTRID></command>'.$E2,'nsgroup_delete build');
is($rc->is_success(),1,'nsgroup_delete is_success');


## p.46
$R2=$E1.'<response>'.r().'<resData><nsgroup:chkData><nsgroup:cd><nsgroup:name avail="1">nsgroup-eurid1</nsgroup:name></nsgroup:cd><nsgroup:cd><nsgroup:name avail="0">nsgroup-eurid2</nsgroup:name></nsgroup:cd><nsgroup:cd><nsgroup:name avail="1">nsgroup-eurid3</nsgroup:name></nsgroup:cd><nsgroup:cd><nsgroup:name avail="0">nsgroup-eurid4</nsgroup:name></nsgroup:cd><nsgroup:cd><nsgroup:name avail="1">nsgroup-eurid5</nsgroup:name></nsgroup:cd><nsgroup:cd><nsgroup:name avail="1">nsgroup-eurid6</nsgroup:name></nsgroup:cd><nsgroup:cd><nsgroup:name avail="1">nsgroup-eurid7</nsgroup:name></nsgroup:cd></nsgroup:chkData></resData>'.$TRID.'</response>'.$E2;
my @dh=map { $dri->local_object('hosts')->name('nsgroup-eurid'.$_) } (1..7);
$rc=$ro->check_multi(@dh);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><check><nsgroup:check xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>nsgroup-eurid1</nsgroup:name><nsgroup:name>nsgroup-eurid2</nsgroup:name><nsgroup:name>nsgroup-eurid3</nsgroup:name><nsgroup:name>nsgroup-eurid4</nsgroup:name><nsgroup:name>nsgroup-eurid5</nsgroup:name><nsgroup:name>nsgroup-eurid6</nsgroup:name><nsgroup:name>nsgroup-eurid7</nsgroup:name></nsgroup:check></check><clTRID>TRID-0001</clTRID></command>'.$E2,'nsgroup_check_multi build');
is($rc->is_success(),1,'nsgroup_check_multi is_success');
is($dri->get_info('exist','nsgroup','nsgroup-eurid1'),0,'nsgroup_check_multi get_info(exist) 1');
is($dri->get_info('exist','nsgroup','nsgroup-eurid2'),1,'nsgroup_check_multi get_info(exist) 2');
is($dri->get_info('exist','nsgroup','nsgroup-eurid3'),0,'nsgroup_check_multi get_info(exist) 3');
is($dri->get_info('exist','nsgroup','nsgroup-eurid4'),1,'nsgroup_check_multi get_info(exist) 4');
is($dri->get_info('exist','nsgroup','nsgroup-eurid5'),0,'nsgroup_check_multi get_info(exist) 5');
is($dri->get_info('exist','nsgroup','nsgroup-eurid6'),0,'nsgroup_check_multi get_info(exist) 6');
is($dri->get_info('exist','nsgroup','nsgroup-eurid7'),0,'nsgroup_check_multi get_info(exist) 7');

$R2=$E1.'<response>'.r().'<resData><nsgroup:chkData><nsgroup:cd><nsgroup:name avail="1">nsgroup-eurid1</nsgroup:name></nsgroup:cd></nsgroup:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$ro->check('nsgroup-eurid1');
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><check><nsgroup:check xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>nsgroup-eurid1</nsgroup:name></nsgroup:check></check><clTRID>TRID-0001</clTRID></command>'.$E2,'nsgroup_check build');
is($rc->is_success(),1,'nsgroup_check is_success');
is($dri->get_info('exist','nsgroup','nsgroup-eurid1'),0,'nsgroup_check get_info(exist) 1');
is($dri->get_info('exist'),0,'nsgroup_check get_info(exist) 2');


## p.48
$R2=$E1.'<response>'.r().'<resData><nsgroup:infData><nsgroup:name>nsgroup-eurid4</nsgroup:name><nsgroup:ns>ns1.eurid.eu</nsgroup:ns><nsgroup:ns>ns2.eurid.eu</nsgroup:ns><nsgroup:ns>ns3.eurid.eu</nsgroup:ns><nsgroup:ns>ns4.eurid.eu</nsgroup:ns><nsgroup:ns>ns5.eurid.eu</nsgroup:ns><nsgroup:ns>ns6.eurid.eu</nsgroup:ns><nsgroup:ns>ns7.eurid.eu</nsgroup:ns><nsgroup:ns>ns8.eurid.eu</nsgroup:ns><nsgroup:ns>ns9.eurid.eu</nsgroup:ns></nsgroup:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$ro->info('nsgroup-eurid4');
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><info><nsgroup:info xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><nsgroup:name>nsgroup-eurid4</nsgroup:name></nsgroup:info></info><clTRID>TRID-0001</clTRID></command>'.$E2,'nsgroup_info build');
is($rc->is_success(),1,'nsgroup_info is_success');
$s=$dri->get_info('self');
isa_ok($s,'Net::DRI::Data::Hosts','nsgroup_info get_info(self) isa');
is_deeply([$s->get_names()],['ns1.eurid.eu','ns2.eurid.eu','ns3.eurid.eu','ns4.eurid.eu','ns5.eurid.eu','ns6.eurid.eu','ns7.eurid.eu','ns8.eurid.eu','ns9.eurid.eu'],'nsgroup_info get_info(self) get_names');

############################################################################################################
## Domain

## p.50
$R2=$E1.'<response>'.r().'<resData><domain:creData><domain:name>mykingdom.eu</domain:name><domain:crDate>2005-09-29T13:47:32.000Z</domain:crDate></domain:creData></resData><extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('mvw14'),'registrant');
$cs->set($dri->local_object('contact')->srid('mt24'),'tech');
$cs->set($dri->local_object('contact')->srid('jj1'),'billing');
$rc=$dri->domain_create_only('mykingdom.eu',{contact=>$cs});
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><create><domain:create xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>mykingdom.eu</domain:name><domain:registrant>mvw14</domain:registrant><domain:contact type="billing">jj1</domain:contact><domain:contact type="tech">mt24</domain:contact><domain:authInfo><domain:pw/></domain:authInfo></domain:create></create><clTRID>TRID-0001</clTRID></command>'.$E2,'domain_create build 1');
is($rc->is_success(),1,'domain_create is_success 1');
my $crdate=$dri->get_info('crDate');
is(''.$crdate,'2005-09-29T13:47:32','domain_create get_info(crDate) 1');


## p.52
$R2=$E1.'<response>'.r().'<resData><domain:creData><domain:name>everything.eu</domain:name><domain:crDate>2005-09-29T14:25:50.000Z</domain:crDate></domain:creData></resData><extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$cs->set($dri->local_object('contact')->srid('mt24'),'admin');
$dh=$dri->local_object('hosts');
$dh->add('ns.eurid.eu');
$dh->add('ns.everything.eu',['193.12.11.1']);
$rc=$dri->domain_create_only('everything.eu',{contact=>$cs,duration=>DateTime::Duration->new(years=>1),ns=>$dh});
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><create><domain:create xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>everything.eu</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostAttr><domain:hostName>ns.eurid.eu</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns.everything.eu</domain:hostName><domain:hostAddr ip="v4">193.12.11.1</domain:hostAddr></domain:hostAttr></domain:ns><domain:registrant>mvw14</domain:registrant><domain:contact type="admin">mt24</domain:contact><domain:contact type="billing">jj1</domain:contact><domain:contact type="tech">mt24</domain:contact><domain:authInfo><domain:pw/></domain:authInfo></domain:create></create><clTRID>TRID-0001</clTRID></command></epp>','domain_create build 2');
is($rc->is_success(),1,'domain_create is_success 2');
$crdate=$dri->get_info('crDate');
is(''.$crdate,'2005-09-29T14:25:50','domain_create get_info(crDate) 2');


## p.55
$R2=$E1.'<response>'.r().'<resData><domain:creData><domain:name>ecom.eu</domain:name><domain:crDate>2005-09-29T14:45:34.000Z</domain:crDate></domain:creData></resData><extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('mvw14'),'registrant');
$cs->set($dri->local_object('contact')->srid('mt24'),'tech');
$cs->set($dri->local_object('contact')->srid('jj1'),'billing');
$dh=$dri->local_object('hosts');
$dh->add('ns.anything.eu');
$dh->add('ns.everything.eu');
my $dh2=$dri->local_object('hosts');
$dh2->name('nsgroup-eurid');
$rc=$dri->domain_create_only('ecom.eu',{contact=>$cs,ns=>$dh,nsgroup=>$dh2,duration=>DateTime::Duration->new(years=>1)});
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><create><domain:create xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>ecom.eu</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostAttr><domain:hostName>ns.anything.eu</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns.everything.eu</domain:hostName></domain:hostAttr></domain:ns><domain:registrant>mvw14</domain:registrant><domain:contact type="billing">jj1</domain:contact><domain:contact type="tech">mt24</domain:contact><domain:authInfo><domain:pw/></domain:authInfo></domain:create></create><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:create><eurid:domain><eurid:nsgroup>nsgroup-eurid</eurid:nsgroup></eurid:domain></eurid:create></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_create_only build');
is($rc->is_success(),1,'domain_create is_success 3');
$crdate=$dri->get_info('crDate');
is(''.$crdate,'2005-09-29T14:45:34','domain_create get_info(crDate) 3');


## p.58
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$toc=$dri->local_object('changes');
$toc->add('ns',$dri->local_object('hosts')->add('ns.unknown.eu'));
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('mmai1'),'tech');
$toc->add('contact',$cs);
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('mt24'),'tech');
$toc->del('contact',$cs);
$toc->add('nsgroup',$dri->local_object('hosts')->name('nsgroup-eurid2'));
$toc->del('nsgroup',$dri->local_object('hosts')->name('nsgroup-eurid'));
$rc=$dri->domain_update('ecom.eu',$toc);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><update><domain:update xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>ecom.eu</domain:name><domain:add><domain:ns><domain:hostAttr><domain:hostName>ns.unknown.eu</domain:hostName></domain:hostAttr></domain:ns><domain:contact type="tech">mmai1</domain:contact></domain:add><domain:rem><domain:contact type="tech">mt24</domain:contact></domain:rem></domain:update></update><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:update><eurid:domain><eurid:add><eurid:nsgroup>nsgroup-eurid2</eurid:nsgroup></eurid:add><eurid:rem><eurid:nsgroup>nsgroup-eurid</eurid:nsgroup></eurid:rem></eurid:domain></eurid:update></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_update 1 build');
is($rc->is_success(),1,'domain_update 1 is_success');
is_deeply([$rc->info()],['OK'],'domain_update 1 info');


$R2=$E1.'<response>'.r(2308,'Data management policy violation').'<extension><eurid:ext><eurid:result><eurid:msg>Contact mt24 is not linked to domain ecom</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_update('ecom.eu',$toc);
is($rc->is_success(),0,'domain_update 2 is_success');
my @i=$rc->info();
is_deeply(\@i,['Contact mt24 is not linked to domain ecom'],'domain_update 2 info');


## p.61
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_delete_only('ecom.eu',{deleteDate=>DateTime->new(year=>2005,month=>9,day=>29,hour=>14,minute=>40,second=>51)});
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><delete><domain:delete xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>ecom.eu</domain:name></domain:delete></delete><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:delete><eurid:domain><eurid:deleteDate>2005-09-29T14:40:51.000000000Z</eurid:deleteDate></eurid:domain></eurid:delete></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_delete_only build');
is($rc->is_success(),1,'domain_delete_only is_success');


## p.63
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$ro=$dri->remote_object('domain');
$rc=$ro->undelete('ecom.eu');
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><undelete><domain:undelete xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>ecom.eu</domain:name></domain:undelete></undelete><clTRID>TRID-0001</clTRID></command></epp>','domain_undelete build');
is($rc->is_success(),1,'domain_undelete is_success');


## p.67
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
my %rd;
$rd{trDate}=DateTime->new(year=>2005,month=>9,day=>29,hour=>22);
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('jj1'),'billing');
$cs->set($dri->local_object('contact')->srid('ak4589'),'registrant');
$cs->set($dri->local_object('contact')->srid('mt24'),'tech');
$rd{contact}=$cs;
$rd{nsgroup}=$dri->local_object('hosts')->name('nsgroup-eurid');
$rc=$dri->domain_transfer_start('something.eu',\%rd);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><transfer op="request"><domain:transfer xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>something.eu</domain:name></domain:transfer></transfer><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:transfer><eurid:domain><eurid:registrant>ak4589</eurid:registrant><eurid:trDate>2005-09-29T22:00:00.000000000Z</eurid:trDate><eurid:billing>jj1</eurid:billing><eurid:tech>mt24</eurid:tech><eurid:nsgroup>nsgroup-eurid</eurid:nsgroup></eurid:domain></eurid:transfer></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_transfer_start build');
is($rc->is_success(),1,'domain_transfer_start is_success');


## p.70
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>Content check ok</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
%rd=();
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('jd1'),'billing');
$cs->set($dri->local_object('contact')->srid('js5'),'registrant');
$cs->set($dri->local_object('contact')->srid('jb1'),'tech');
$rd{contact}=$cs;
$rd{trDate}=DateTime->new(year=>2002,month=>2,day=>18,hour=>22);
$rd{ns}=$dri->local_object('hosts')->add('ns1.superdomain.eu',['1.2.3.4'])->add('ns.test.eu');
$rd{nsgroup}='mynsgroup1';
$rc=$ro->transferq_request('superdomain.eu',\%rd);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><transferq><domain:transferq xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>superdomain.eu</domain:name></domain:transferq></transferq><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:transferq><eurid:domain><eurid:registrant>js5</eurid:registrant><eurid:trDate>2002-02-18T22:00:00.000000000Z</eurid:trDate><eurid:billing>jd1</eurid:billing><eurid:tech>jb1</eurid:tech><eurid:ns xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:hostAttr><domain:hostName>ns1.superdomain.eu</domain:hostName><domain:hostAddr ip="v4">1.2.3.4</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns.test.eu</domain:hostName></domain:hostAttr></eurid:ns><eurid:nsgroup>mynsgroup1</eurid:nsgroup></eurid:domain></eurid:transferq></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_transferq build'); ## 3 corrections from EURid sample
is($rc->is_success(),1,'domain_transferq is_success');


## p.72
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
%rd=();
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('jj1'),'billing');
$cs->set($dri->local_object('contact')->srid('ak4589'),'registrant');
$cs->set($dri->local_object('contact')->srid('mt24'),'tech');
$rd{contact}=$cs;
$rd{trDate}=DateTime->new(year=>2005,month=>9,day=>29,hour=>22);
$rd{nsgroup}='nsgroup-eurid';
$rc=$ro->trade('fox.eu',\%rd);
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><trade><domain:trade xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>fox.eu</domain:name></domain:trade></trade><extension><eurid:ext xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd"><eurid:trade><eurid:domain><eurid:registrant>ak4589</eurid:registrant><eurid:trDate>2005-09-29T22:00:00.000000000Z</eurid:trDate><eurid:billing>jj1</eurid:billing><eurid:tech>mt24</eurid:tech><eurid:nsgroup>nsgroup-eurid</eurid:nsgroup></eurid:domain></eurid:trade></eurid:ext></extension><clTRID>TRID-0001</clTRID></command></epp>','domain_trade build'); ## corrected from EURid sample
is($rc->is_success(),1,'domain_trade build');


## p.74
$R2=$E1.'<response>'.r().'<extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$ro->reactivate('ecom.eu');
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><reactivate><domain:reactivate xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>ecom.eu</domain:name></domain:reactivate></reactivate><clTRID>TRID-0001</clTRID></command></epp>','domain_reactivate build');
is($rc->is_success(),1,'domain_reactivate is_success');


## p.76
$R2=$E1.'<response>'.r().'<resData><domain:chkData><domain:cd><domain:name avail="0">nothing.eu</domain:name></domain:cd><domain:cd><domain:name avail="1">anything.eu</domain:name></domain:cd><domain:cd><domain:name avail="0">ecom.eu</domain:name></domain:cd><domain:cd><domain:name avail="0">mykingdom.eu</domain:name></domain:cd><domain:cd><domain:name avail="0">everything.eu</domain:name></domain:cd><domain:cd><domain:name avail="1">something.eu</domain:name></domain:cd><domain:cd><domain:name avail="1">mything.eu</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$dri->cache_clear();
$rc=$dri->domain_check_multi('nothing.eu','anything.eu','ecom.eu','mykingdom.eu','everything.eu','something.eu','mything.eu');
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><check><domain:check xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>nothing.eu</domain:name><domain:name>anything.eu</domain:name><domain:name>ecom.eu</domain:name><domain:name>mykingdom.eu</domain:name><domain:name>everything.eu</domain:name><domain:name>something.eu</domain:name><domain:name>mything.eu</domain:name></domain:check></check><clTRID>TRID-0001</clTRID></command></epp>','domain_check_multi build');
is($rc->is_success(),1,'domain_check_multi is_success');
is($dri->get_info('exist','domain','nothing.eu'),1,'domain_check_multi get_info(exist) 1/7');
is($dri->get_info('exist','domain','anything.eu'),0,'domain_check_multi get_info(exist) 2/7');
is($dri->get_info('exist','domain','ecom.eu'),1,'domain_check_multi get_info(exist) 3/7');
is($dri->get_info('exist','domain','mykingdom.eu'),1,'domain_check_multi get_info(exist) 4/7');
is($dri->get_info('exist','domain','everything.eu'),1,'domain_check_multi get_info(exist) 5/7');
is($dri->get_info('exist','domain','something.eu'),0,'domain_check_multi get_info(exist) 6/7');
is($dri->get_info('exist','domain','mything.eu'),0,'domain_check_multi get_info(exist) 7/7');


## p.78
$R2=$E1.'<response>'.r().'<resData><domain:infData><domain:name>ecom.eu</domain:name><domain:roid>19204-EURID</domain:roid><domain:status s="ok"/><domain:registrant>mvw14</domain:registrant><domain:contact type="billing">jj1</domain:contact><domain:contact type="tech">mmai1</domain:contact><domain:ns><domain:hostAttr><domain:hostName>ns.anything.eu</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns.everything.eu</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns.unknown.eu</domain:hostName></domain:hostAttr></domain:ns><domain:clID>t000006</domain:clID><domain:crID>t000006</domain:crID><domain:crDate>2005-09-29T14:45:35.000Z</domain:crDate><domain:upID>t000006</domain:upID><domain:upDate>2005-09-29T14:45:35.000Z</domain:upDate><domain:exDate>2006-09-29T15:45:35.0Z</domain:exDate></domain:infData></resData><extension><eurid:ext><eurid:infData><eurid:domain><eurid:nsgroup>nsgroup-eurid2</eurid:nsgroup></eurid:domain></eurid:infData></eurid:ext></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('ecom.eu');
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name hosts="all">ecom.eu</domain:name></domain:info></info><clTRID>TRID-0001</clTRID></command></epp>','domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('roid'),'19204-EURID','domain_info get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($s->is_active(),1,'domain_info get_info(status) is_active');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['billing','registrant','tech'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'mvw14','domain_info get_info(contact) registrant srid');
is($s->get('billing')->srid(),'jj1','domain_info get_info(contact) registrant billing');
is($s->get('tech')->srid(),'mmai1','domain_info get_info(contact) registrant tech');
$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(ns)');
@c=$dh->get_names();
is_deeply(\@c,['ns.anything.eu','ns.everything.eu','ns.unknown.eu'],'domain_info get_info(ns) get_names');
is($dri->get_info('clID'),'t000006','domain_info get_info(clID)');
is($dri->get_info('crID'),'t000006','domain_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is(''.$d,'2005-09-29T14:45:35','domain_info get_info(crDate) value');
is($dri->get_info('upID'),'t000006','domain_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate)');
is(''.$d,'2005-09-29T14:45:35','domain_info get_info(upDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is(''.$d,'2006-09-29T15:45:35','domain_info get_info(exDate) value');
$d=$dri->get_info('nsgroup');
isa_ok($d,'ARRAY','domain_info get_info(nsgroup)');
is(@$d,1,'domain_info get_info(nsgroup) count');
$d=$d->[0];
isa_ok($d,'Net::DRI::Data::Hosts','domain_info get_info(nsgroup) [0]');
is($d->name(),'nsgroup-eurid2','domain_info get_info(nsgroup) [0] value');


################################################################################################################

## Examples from Registration_guidelines_v1_0F-appendix2-sunrise.pdf
$dri->target('EURid')->new_current_profile('p2','Net::DRI::Transport::Dummy',[{f_send=>\&mysend,f_recv=>\&myrecv}],'Net::DRI::Protocol::EPP::Extensions::EURid',['1.0',['Net::DRI::Protocol::EPP::Extensions::EURid::Sunrise']]);

## p.8
$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:contact="http://www.eurid.eu/xml/epp/contact-1.0" xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd http://www.eurid.eu/xml/epp/contact-1.0 contact-1.0.xsd http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><response><result code="1500"><msg>Command completed successfully; ending session</msg></result><resData><domain:appData><domain:name>c-and-a.eu</domain:name><domain:reference>c-and-a_1</domain:reference><domain:code>2565100006029999</domain:code><domain:crDate>2005-11-08T14:51:08.929Z</domain:crDate></domain:appData></resData><extension><eurid:ext><eurid:result><eurid:msg>OK</eurid:msg></eurid:result></eurid:ext></extension><trID><clTRID>clientref-12310026</clTRID><svTRID>eurid-1589</svTRID></trID></response></epp>';


$ro=$dri->remote_object('domain');
$h=$dri->local_object('hosts')->add('ns.c-and-a.eu',['81.2.4.4'],['2001:0:0:0:8:800:200C:417A'])->add('ns.isp.eu'); ## IPv6 changed
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('js5'),'registrant');
$cs->set($dri->local_object('contact')->srid('jd1'),'billing');
$cs->set($dri->local_object('contact')->srid('jd2'),'tech');
$rc=$ro->apply('c-and-a.eu',{reference=>'c-and-a_1',right=>'REG-TM-NAT','prior-right-on-name'=>'c&a','prior-right-country'=>'NL',documentaryevidence=>'applicant','evidence-lang'=>'nl',ns=>$h,contact=>$cs});

is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><apply><domain:apply xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:name>c-and-a.eu</domain:name><domain:reference>c-and-a_1</domain:reference><domain:right>REG-TM-NAT</domain:right><domain:prior-right-on-name>c&amp;a</domain:prior-right-on-name><domain:prior-right-country>NL</domain:prior-right-country><domain:documentaryevidence><domain:applicant/></domain:documentaryevidence><domain:evidence-lang>nl</domain:evidence-lang><domain:ns><domain:hostAttr><domain:hostName>ns.c-and-a.eu</domain:hostName><domain:hostAddr ip="v4">81.2.4.4</domain:hostAddr><domain:hostAddr ip="v6">2001:0:0:0:8:800:200C:417A</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns.isp.eu</domain:hostName></domain:hostAttr></domain:ns><domain:registrant>js5</domain:registrant><domain:contact type="billing">jd1</domain:contact><domain:contact type="tech">jd2</domain:contact></domain:apply></apply><clTRID>TRID-0001</clTRID></command></epp>','domain_apply build'); ## IPv6 changed from EURid example
is($rc->is_success(),1,'domain_apply is_success');
is($dri->get_info('reference'),'c-and-a_1','domain_apply get_info(reference)');
is($dri->get_info('code'),'2565100006029999','domain_apply get_info(code)');
is(''.$dri->get_info('crDate'),'2005-11-08T14:51:08','domain_apply get_info(crDate)');

## p.12
$R2='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:contact="http://www.eurid.eu/xml/epp/contact-1.0" xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xmlns:eurid="http://www.eurid.eu/xml/epp/eurid-1.0" xmlns:nsgroup="http://www.eurid.eu/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd http://www.eurid.eu/xml/epp/contact-1.0 contact-1.0.xsd http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd http://www.eurid.eu/xml/epp/eurid-1.0 eurid-1.0.xsd http://www.eurid.eu/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"><response><result code="1000"><msg>Command completed successfully</msg></result><resData><domain:appInfoData><domain:name>c-and-a.eu</domain:name><domain:reference>c-and-a_1</domain:reference><domain:code>2565100006029999</domain:code><domain:crDate>2005-11-08T14:51:08.929Z</domain:crDate><domain:status>INITIAL</domain:status><domain:registrant>js5</domain:registrant><domain:contact type="billing">jd1</domain:contact><domain:contact type="tech">jd2</domain:contact><domain:ns><domain:hostAttr><domain:hostName>ns.c-and-a.eu</domain:hostName><domain:hostAddr ip="v4">81.2.4.4</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns.isp.eu</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns.c-and-a.eu</domain:hostName><domain:hostAddr ip="v6">2001:0:0:0:8:800:200C:417A</domain:hostAddr></domain:hostAttr></domain:ns><domain:docsReceivedDate>2005-11-08T21:46:56.000Z</domain:docsReceivedDate><domain:adr>false</domain:adr></domain:appInfoData></resData><trID><clTRID>TRID-0001</clTRID><svTRID>eurid-0</svTRID></trID></response></epp>'; ## IPv6 changed from EURid example

$ro=$dri->remote_object('domain');
$rc=$ro->apply_info('c-and-a_1');
is($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="http://www.eurid.eu/xml/epp/epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eurid.eu/xml/epp/epp-1.0 epp-1.0.xsd"><command><apply-info><domain:apply-info xmlns:domain="http://www.eurid.eu/xml/epp/domain-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-1.0 domain-1.0.xsd"><domain:reference>c-and-a_1</domain:reference></domain:apply-info></apply-info><clTRID>TRID-0001</clTRID></command></epp>','domain_apply_info build');
is($rc->is_success(),1,'domain_apply_info is_success');
is($dri->get_info('reference'),'c-and-a_1','domain_apply get_info(reference)');
is($dri->get_info('code'),'2565100006029999','domain_apply get_info(code)');
is(''.$dri->get_info('crDate'),'2005-11-08T14:51:08','domain_apply get_info(crDate)');
is($dri->get_info('application_status'),'INITIAL','domain_apply get_info(application_status)');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_apply get_info(contact)');
is_deeply([$s->types()],['billing','registrant','tech'],'domain_apply get_info(contact) types');
is($s->get('billing')->srid(),'jd1','domain_apply get_info(contact) billing srid');
is($s->get('registrant')->srid(),'js5','domain_apply get_info(contact) registrant srid');
is($s->get('tech')->srid(),'jd2','domain_apply get_info(contact) tech srid');
$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_apply get_info(ns)');
@c=$dh->get_names();
is_deeply(\@c,['ns.c-and-a.eu','ns.isp.eu'],'domain_apply get_info(ns) get_names');
@c=$dh->get_details(1);
is($c[0],'ns.c-and-a.eu','domain_apply get_info(ns) get_details(1) 0');
is_deeply($c[1],['81.2.4.4'],'domain_apply get_info(ns) get_details(1) 1');
is_deeply($c[2],['2001:0:0:0:8:800:200C:417A'],'domain_apply get_info(ns) get_details(1) 2');
@c=$dh->get_details(2);
is($c[0],'ns.isp.eu','domain_apply get_info(ns) get_details(2) 0');
is_deeply($c[1],[],'domain_apply get_info(ns) get_details(2) 1');
is_deeply($c[2],[],'domain_apply get_info(ns) get_details(2) 2');
is(''.$dri->get_info('docsReceivedDate'),'2005-11-08T21:46:56','domain_apply get_info(docsReceivedDate)');
is($dri->get_info('adr'),0,'domain_apply get_info(adr)');

exit 0;
