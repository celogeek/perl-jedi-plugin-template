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
		$jedi->get('/bla', sub {
			my ($jedi, $request, $response) = @_;
			$response->body($jedi->jedi_template('test.tt'), {hello => 'world'}, 'main.tt');
			return 1;
		})
	}

	1;

Here the structure of your app :

	.
	./bin/app.psgi
	./config.yml
	./environments
	./environments/prod.yml
	./views
	./view/test.tt
	./view/layouts/main.tt
	./public

The main.tt look like

	<html>
	<body>
	This will wrap your content :
	
	[% content %]
	</body>
	</html>

And your test.tt :

	<p>Hello [% hello %]</p>

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