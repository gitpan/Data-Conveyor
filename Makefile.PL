use inc::Module::Install;
include 'Module::AutoInstall';

name 'Data-Conveyor';
all_from 'lib/Data/Conveyor.pm';
perl_version '5.006';

requires 'Class::Scaffold' => '0.03';
requires 'Class::Null';
requires 'Data::Container';
requires 'Data::Storage';
requires 'Data::Comparable';
requires 'Data::Inherited';
requires 'Data::Miscellany';
requires 'Date::Calc';
requires 'DBI';
requires 'Error::Hierarchy';
requires 'Hash::Flatten';
requires 'IO::Pager';
requires 'Pod::PlainText';
requires 'String::FlexMatch';
requires 'SOAP::Lite';
requires 'Term::Shell::Enhanced';
requires 'Test::Differences';
requires 'Test::More';
requires 'Test::utf8';
requires 'Text::Table';
requires 'Time::HiRes';
requires 'YAML';
requires 'YAML::Active';

build_requires 'Test::More' => '0.70';

process_templates(
    first_year    => 2004,
    rest_from     => "$ENV{HOME}/.mitlib/standard_pod",
    start_tag     => '{%',
    end_tag       => '%}',
    other_authors => [
        'Florian Helmberger C<< <fh@univie.ac.at> >>',
        'Achim Adam C<< <ac@univie.ac.at> >>',
        'Mark Hofstetter C<< <mh@univie.ac.at> >>',
        'Heinz Ekker C<< <ek@univie.ac.at> >>',
    ],
);

use_standard_tests(without => 'pod_coverage');
auto_install;
auto_include;
WriteAll;
