#!/usr/bin/env perl

use strict;
use warnings;
use lib::abs '../lib';
use Test::More tests => 2;
use Test::NoWarnings;
BEGIN {
	eval {
		require Test::Differences::Color;
		Test::Differences::Color->import('eq_or_diff');
	1} or eval {
		require Test::Differences;
		Test::Differences->import('eq_or_diff');
	1} or do {
		*eq_or_diff = \&is;
	};
}

use MojoX::Routes;
use MojoX::Routes::DSL;
use MojoX::Routes::DebugPrint;

my $r = routing {
	route { path '/clean'; call clean => 1; };
	route { path '/clean/too'; call something => 1; };
	route {
		path '/:controller/test';
		call action => 'test';
		route {
			path '/edit';
			call action => 'edit';
			name 'test_edit';
		};
		route{
			path '/delete/(id)', id => qr/\d+/;
			call action => 'delete', id => 23;
		};
	};
	bridge {
		path '/test2';
		call controller => 'test2';
		bridge {
			call controller => 'index';
			route {
				path '/foo';
				call controller => 'baz';
			};
			route {
				path '/bar';
				call controller => 'lalala';
			};
		};
		route {
			path '/baz';
			call 'just#works';
		};
	};
	waypoint {
		path '/test3';
		call controller => 's', action => 'l';
		route {
			path '/edit';
			call action => 'edit';
		};
	};
	route {
		path '/';
		call controller => 'hello', action => 'world';
	};
	route {
		path '/wildcards/1/(*wildcard)', wildcard => qr/(.*)/;
		call controller => 'wild', action => 'card';
	};
	route {
		path '/wildcards/2/(*wildcard)';
		call controller => 'card', action => 'wild';
	};
	route {
		path '/wildcards/3/(*wildcard)/foo';
		call controller => 'very', action => 'dangerous';
	};
	route {
		path '/format';
		call controller => 'hello', action => 'you', format => 'html';
	};
	route {
		path '/format2.html';
		call controller => 'you', action => 'hello';
	};
	route {
		path '/format2.json';
		call controller => 'you', action => 'hello_json';
	};
	route {
		path '/format3/:foo.html';
		call controller => 'me', action => 'bye';
	};
	route {
		path '/format3/:foo.json';
		call controller => 'me', action => 'bye_json';
	};
	waypoint {
		path '/articles';
		call (
			controller => 'articles',
			action     => 'index',
			format     => 'html'
		);
		waypoint{
			path '/:id';
			call (
				controller => 'articles',
				action     => 'load',
				format     => 'html'
			);
			bridge {
				call (
					controller => 'articles',
					action     => 'load',
					format     => 'html'
				);
				route {
					path '/edit';
					call controller => 'articles', action => 'edit';
				};
				route {
					path '/delete';
					call (
						controller => 'articles',
						action     => 'delete',
						format     => undef
					);
					name 'articles_delete';
				};
			};
		};
	};
	route {
		path '/method/get';
		via 'GET';
		call controller => 'method', action => 'get';
	};
	route {
		path '/method/post';
		via 'post';
		call controller => 'method', action => 'post';
	};
	route {
		path '/method/post_get';
		via qw/POST get/;
		call controller => 'method', action => 'post_get';
	};
	route {
		path '/simple/form';
		call 'test-test#test';
	};
	route {
		path '/edge';
		bridge {
			path '/auth';
			call 'auth#check';
			route {
				path '/about/';
				call 'pref#about';
			};
			bridge {
				call 'album#allow';
				route {
					path '/album/create/';
					call 'album#create';
				};
			};
			route {
				path '/gift/';
				call 'gift#index';
			};
		};
	};
} MojoX::Routes->new;

#use MojoX::Routes::AsGraph;
#my $graph = MojoX::Routes::AsGraph->graph($r);
#diag $graph->as_ascii;exit;

my $dp = MojoX::Routes::DebugPrint->new($r);
open my $f,'>',\my $data;
$dp->print($f);


eq_or_diff $data, 'route    | /clean                                          { clean=1 }
route    | /clean/too                                      { something=1 }
route    | /:controller/test            -> *#test
route    |     /edit                    -> *#edit
route    |     /delete/:id              -> *#delete        { id=23 }
bridge   | /test2                       -> test2#?
bridge   |     /                        -> index#?
route    |         /foo                 -> baz#?
route    |         /bar                 -> lalala#?
route    |     /baz                     -> just#works
waypoint | /test3                       -> s#l
route    |     /edit                    -> *#edit
route    | /                            -> hello#world
route    | /wildcards/1/*wildcard       -> wild#card
route    | /wildcards/2/*wildcard       -> card#wild
route    | /wildcards/3/*wildcard/foo   -> very#dangerous
route    | /format                      -> hello#you       { format=html }
route    | /format2.html                -> you#hello
route    | /format2.json                -> you#hello_json
route    | /format3/:foo.html           -> me#bye
route    | /format3/:foo.json           -> me#bye_json
waypoint | /articles                    -> articles#index  { format=html }
waypoint |     /:id                     -> articles#load   { format=html }
bridge   |         /                    -> articles#load   { format=html }
route    |             /edit            -> articles#edit
route    |             /delete          -> articles#delete { format=undef }
route    | /method/get                  -> method#get
route    | /method/post                 -> method#post
route    | /method/post_get             -> method#post_get
route    | /simple/form                 -> test-test#test
route    | /edge
bridge   |     /auth                    -> auth#check
route    |         /about/              -> pref#about
bridge   |         /                    -> album#allow
route    |             /album/create/   -> album#create
route    |         /gift/               -> gift#index
';

seek $f,0,0;
$data = '';
$dp->print($f, color => -t STDOUT);
diag $data;
