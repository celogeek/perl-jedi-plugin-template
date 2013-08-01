package Jedi::Plugin::Template;

# ABSTRACT: Jedi Plugin for Template Toolkit

=head1 DESCRIPTION

This will add missing route to catch public file if exists.

This will also give a "template" keep to display your template.

To use it in your Jedi app :

	package MyApps;
	use Jedi::App;
	use Jedi::Plugin::Template;

	sub jedi_app { ... }

	1;

=cut

use Moo::Role;
# VERSION
use Template;
use Path::Class;
use feature 'state';
use MIME::Types qw/by_suffix/;

# This part is for handle the public subdir
# It catch all files from path info and send it if the file exists
# It stop the road trip if a file is found to avoid any other routes to be executed
# They is no cache here, use an engine like nginx to speed up that process.

before 'jedi_app' => sub {
	my ($jedi) = @_;

	$jedi->get(qr{.*}x, $jedi->can('_jedi_dispatch_public_files'));

	return;
};

sub _jedi_dispatch_public_files {
	my ($jedi, $request, $response) = @_;
	my $file = file($jedi->jedi_app_root, 'public', $request->env->{PATH_INFO});
	return 1 if ! -f $file;

	my ($mime_type, $encoding) = by_suffix($file);
	my $type = $mime_type . '; charset=' . $encoding;
	my $content = $file->slurp();

	$response->status(200);
	$response->set_header('Content-Type', $type);
	$response->body($content);

	return;
}

has '_template_views' => (is => 'lazy');
sub _build__template_views {
	my ($jedi) = @_;
	return dir($jedi->jedi_app_root, 'views');
}

has 'template_default_layout' => (is => 'rw');

sub template {
	my ($jedi, $file, $vars, $layout) = @_;
	$layout //= $jedi->template_default_layout;
	
	my @tpl_options = (
		INCLUDE_PATH => [ $jedi->_template_views ]
	);

	if (defined $layout && $layout ne 'none') {
		push @tpl_options, WRAPPER => file($jedi->_template_views, 'layouts', $layout);
	}

	my $tpl_engine = Template->new(@tpl_options);
	my $view_file = file($jedi->_template_views, $file);

	my $ret = '';
	$tpl_engine->process($view_file, $vars, \$ret) or croak $tpl_engine->errors();

	return $ret;
}

1;