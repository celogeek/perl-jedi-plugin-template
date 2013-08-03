package Jedi::Plugin::Template;

# ABSTRACT: Jedi Plugin for Template Toolkit

=head1 DESCRIPTION

This will add missing route to catch public file if exists.

This will also give a "jedi_template" method to display your template.

To use it in your Jedi app :

	package MyApps;
	use Jedi::App;
	use Jedi::Plugin::Template;

	sub jedi_app {
		...
		$response->body($jedi->jedi_template('test.tt'));
	}

	1;

Take a look here : L<Jedi::Plugin::Template::Role>

=cut

use strict;
use warnings;

# VERSION

use Import::Into;
use Module::Runtime qw/use_module/;

use B::Hooks::EndOfScope;

=method import

This module is equivalent into your package to :

	package MyApps;
	with "Jedi::Plugin::Template::Role";

=cut
sub import {
	my $target = caller;
	on_scope_end {
		$target->can('with')->('Jedi::Plugin::Template::Role');
	};
	return;
}

1;