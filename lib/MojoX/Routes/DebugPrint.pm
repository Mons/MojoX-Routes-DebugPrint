package MojoX::Routes::DebugPrint;

use warnings;
use strict;

=head1 NAME

MojoX::Routes::DebugPrint - Create simple debug output of MojoX::Routes

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use MojoX::Routes::DebugPrint;
    use My::Mojolicious::App;
    
    my $app = My::Mojolicious::App->new;
    my $dp  = MojoX::Routes::DebugPrint->new($app->routes);
    
    $dp->print(); # by default, STDERR
    $dp->print( \*STDOUT );
    $dp->print( %args );
    $dp->print( $fh, %args );
    
=head1 METHODS

=head2 new ($r)

=head2 print ( [$fh], [%args])

Options

    color

=cut

sub new {
	my $self = bless {},shift;
	$self->{routes} = shift;
	$self;
}

sub _walk {
	my $self  = shift;
	my $node  = shift;
	my $depth = shift;
	#use uni::perl ':dumper';
	#warn dumper($node);exit;
	my $pattern = $node->pattern->pattern || '/';
	my $name    = $node->name;
	my $line = '';
	my @line;
	my %C;
	if ($self->{color}) {
		%C = (
			0 => "\e[0m",
			w => "\e[0;37m",
			bridge   => "\e[1;31m",
			waypoint => "\e[0;32m",
			route    => "\e[1;34m",
			c        => "\e[1;34m",
			cw       => "\e[1;31m",
			a        => "\e[0;32m",
			aw       => "\e[1;35m",
			f        => "\e[0;35m",
			
			u        => "\e[1;33m",
			e        => "\e[1;33m",
			fv       => "\e[1;37m",
			
			sl       => "\e[1;37m",
			tx       => "\e[1;34m",
			rx       => "\e[1;33m",
			sy       => "\e[1;31m",
			wc       => "\e[1;33m",
		);
	}
	else {
		%C = map { $_ => '' } qw(0 w bridge waypoint route c cw a aw f u e fv  sl tx rx sy wc);
	}
	my $type = $node->inline ? 'bridge' : $node->block ? 'waypoint' : 'route';
	push @line, $depth;
	push @line, $C{$type}.$type.$C{0};
	$line = sprintf "$C{$type}%-9s$C{0}| ",$type;
	$line .= ( ' ' x ($depth * 4) );
	
	$line .=  $pattern;
	$line .= ' 'x(50 - length $line);
	
	my %defs;
	if (exists $node->pattern->{defaults}) {
		%defs = %{ $node->pattern->{defaults} };
	}
	
	
	{
	my $p = $node->pattern;
	my $values ||= {};
	$values = {%{$p->defaults}, %$values};

	my $sclean = '';
	my $string   = '';
	for my $token (reverse @{$node->pattern->tree}) {
		my $op       = $token->[0];
		my $rendered = '';
		my $clean = '';

		# Slash
		if ($op eq 'slash') {
			$rendered = $C{sl}.($clean = '/');
		}

		# Text
		elsif ($op eq 'text') {
			$rendered = $C{tx}.( $clean = $token->[1] );
			#$optional = 0;
		}

		# Relaxed, symbol or wildcard
		elsif ($op eq 'relaxed' ) {
			$rendered = $C{rx}.( $clean = $p->relaxed_start.$token->[1] );
			
		}
		
		elsif( $op eq 'symbol' ) {
			$rendered = $C{sy} . ( $clean = $p->symbol_start.$token->[1] );
		
		}
		elsif ( $op eq 'wildcard') {
			$rendered = $C{wc} . ( $clean = $p->wildcard_start.$token->[1] );
		}

		$string = "$rendered$string";
		$sclean  = "$clean$sclean";
	}

	push @line, ( length $string ? $string : '/' ).$C{0};
	$line .= ' | '.( $string || '/').$C{0};
	
	}
	
	if (exists $node->pattern->{defaults}) {
		$line .= ' 'x(100 - length $line);
		my %defs = %{ $node->pattern->{defaults} };
		if (exists $defs{controller} or exists $defs{action}) {
			my $ca;
			$line .= " -> ";
			$line .= ( exists $defs{controller} ? $C{c}.$defs{controller} : $C{cw}."*" ).$C{w}."#";
			$line .= ( exists $defs{action} ? $C{a}.$defs{action} : $C{aw}."?").$C{0};
			$line .= " " if %defs;
			push @line,
				( exists $defs{controller} ? $C{c}.$defs{controller} : $C{cw}."*" ).$C{w}."#"
				.
				( exists $defs{action} ? $C{a}.$defs{action} : $C{aw}."?").$C{0};
			delete $defs{controller};
			delete $defs{action};
		} else {
			$line .= "    " if %defs;
			push @line, undef;
		}
		if (%defs) {
			my $defs = "{ ".join(", ",map {
				$C{f}.$_.$C{w}."=". (
					!defined $defs{$_} ? $C{u}."undef" :
					! length $defs{$_} ? $C{e}."''" :
					$C{fv}.$defs{$_}
				).$C{0}
			} keys %defs)." }";
			push @line, $defs;
			$line .= $defs;
		} else {
			push @line, undef;
		}
		
	}
	#$line .= '-> '.join '.', map { defined $_ ? $_ : 'undef' }  @{ $node->pattern->{defaults} }{qw( controller action )} if $node->pattern->{defaults};
	#use uni::perl ':dumper';
	#$line .= " {@{[ %{ $node->pattern->{defaults} } ]}}".du if $node->pattern->{defaults};
	#printf { $self->{fh} } "$line\n";
	push @{$self->{lines}}, \@line;
	++$depth;
	if ( exists $node->{children} ) {
		$self->_walk ( $_, $depth ) for @{$node->children};
	}
	--$depth;
}

sub print {
	my $self = shift;
	my $fh = @_ % 2 ? shift : \*STDERR;
	my %args = @_;
	$args{color} = -t $fh unless exists $args{color};
	local $self->{color} = $args{color};
	local $self->{lines} = [];
	$self->_walk( $_, 0 ) for @{ $self->{routes}->children };
	my $pad = $args{pad} || 4;
	my ($wt,$wp,$wc) = (0,0,0);
	no warnings;
	for my $line (@{$self->{lines}}) {
		my ($dep,$t,$p,$c) = @$line;
		for ($t,$p,$c) { s{\e\[.+?m}{}sg; $_ = length; }
		$p += $dep * $pad;
		$wt = $t if $t > $wt;
		$wp = $p if $p > $wp;
		$wc = $c if $c > $wc;
	}
	for my $line (@{$self->{lines}}) {
		my (undef,$ct,$cp,$cc,$cd) =
		my ($dep,$t,$p,$c,$d) = @$line;
		for ($ct,$cp,$cc) { s{\e\[.+?m}{}sg; $_ = length; }
		$cp += $dep * $pad;
		print { $fh }
			$t . ( ' ' x ( $wt - $ct ) ) .
			' | ' .
			( ' ' x ( $dep * $pad )).
			$p .
			( defined $c || defined $d
				? ( ' ' x ( $wp - $cp ) ) . (
					defined $c
						? '   -> ' . $c  :
						  '      '
				) . (
					defined $d
						? (' 'x($wc - $cc + 1)) . $d
						: ''
				) : ''
			)
		."\n"
		;
		#print {$fh} " | $c | $d\n";
	}
}


=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mons Anderson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

=cut

1; # End of MojoX::Routes::DebugPrint
