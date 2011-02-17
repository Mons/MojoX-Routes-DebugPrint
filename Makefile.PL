use inc::Module::Install;

name     'MojoX-Routes-DebugPrint';
all_from 'lib/MojoX/Routes/DebugPrint.pm';
author   q{Mons Anderson <mons@cpan.org>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

