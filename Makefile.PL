use inc::Module::Install;
name 'Data-Conveyor';
all_from 'lib/Data/Conveyor.pm';
perl_version '5.006';

requires 'Class::Scaffold';
requires 'Class::Null';
requires 'Data::Container';
requires 'Data::Storage';
requires 'Data::Comparable';
requires 'Data::Inherited';
requires 'Data::Miscellany';
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

use_standard_tests(without => 'pod_coverage');
auto_include;
WriteAll;
