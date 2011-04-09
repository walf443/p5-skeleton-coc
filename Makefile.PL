use inc::Module::Install;
use Module::Install::ReadmeFromPod;
use Module::Install::Repository;
name 'Skeleton-CoC';
all_from 'lib/Skeleton/CoC.pm';
readme_from 'lib/Skeleton/CoC.pm';

# requires '';

tests_recursive 't';
author_tests 'xt';

build_requires 'Test::More';
build_requires 'Test::LoadAllModules';
build_requires 'Module::Install::ReadmeFromPod';

requires 'Data::Section::Simple';
requires 'Text::MicroTemplate';
requires 'Log::Minimal';
requires 'Path::Class';

auto_include;
auto_set_repository;
WriteAll;
