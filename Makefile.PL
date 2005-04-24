use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::DRI',
    AUTHOR              => 'Patrick Mevzek <netdri@dotandco.com>',
    VERSION_FROM        => 'lib/Net/DRI.pm',
    ABSTRACT            => 'Interface to Domain Name Registries/Registrars/Resellers',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DateTime' => 0,
        'DateTime::Duration' => 0,
        'DateTime::Format::Strptime' => 0,
        'DateTime::TimeZone' => 0,
        'Class::Accessor' => 0,
        'Class::Accessor::Chained' => 0,
        'Time::HiRes' => 0,
        'IO::Socket::INET' => 0,
        'IO::Socket::SSL' => '0.90',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-DRI-*' },
);
