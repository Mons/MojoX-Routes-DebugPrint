#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MojoX::Routes::DebugPrint' ) or print "Bail out!\n";
}

diag( "Testing MojoX::Routes::DebugPrint $MojoX::Routes::DebugPrint::VERSION, Perl $], $^X" );
