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
requires 'Hook::Modular';
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

recommends 'Test::Pod';
recommends 'Test::Pod::Coverage';

test_requires 'Test::More' => '0.70';
test_requires 'Test::Compile';

auto_install;
auto_include;
WriteAll;
