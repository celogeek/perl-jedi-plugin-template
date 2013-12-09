package Jedi::Plugin::Template::Role;

# ABSTRACT: Jedi Plugin for Template Toolkit (Role)

use strict;
use warnings;

# VERSION
use Template;
use Path::Class;
use feature 'state';
use MIME::Types qw/by_suffix/;
use Carp;
use IO::Compress::Gzip qw(gzip);
use HTTP::Date qw/time2str/;
use Digest::SHA qw/sha1_base64/;
use File::ShareDir ':ALL';

sub _jedi_template_check_path {
  my ($path) = @_;

  return if !defined $path;

  return if (! -d dir($path, 'views')) || (! -d dir($path, 'public'));

  return dir($path);
}

sub _jedi_template_setup_path {
  my ($jedi_app) = @_;

  my $class = ref $jedi_app;
  my $dist = $class; $dist =~ s/::/-/gx;

  my $template_dir = 
      # config dir
      _jedi_template_check_path($jedi_app->jedi_config->{$class}{template_dir})
      //
      # local share dir
      _jedi_template_check_path(dir(file($0)->dir, 'share'))
      //
      # parent share dir (launch from bin)
      _jedi_template_check_path(dir(file($0)->dir->parent, 'share'))
      //
      # dist_dir
      _jedi_template_check_path(eval{dist_dir($dist)})
  ;

  croak "No template dir found, please setup one !" if ! defined $template_dir;

  $jedi_app->jedi_config->{$class}{template_dir} = dir($template_dir);

  return;
}

sub _jedi_dispatch_public_files {
  my ($jedi_app, $request, $response) = @_;
  my $class = ref $jedi_app;
  my $file = file($jedi_app->jedi_config->{$class}{template_dir}, 'public', $request->env->{PATH_INFO});
  return 1 if ! -f $file;

  my ($mime_type, $encoding) = by_suffix($file);
  my $type = $mime_type . '; charset=' . $encoding;
  my $content = $file->slurp();

  my $accept_encoding = $request->env->{HTTP_ACCEPT_ENCODING} // '';
  if ($accept_encoding =~ /gzip/) {
    my $content_unpack = $content;
    gzip \$content_unpack => \$content;
    $response->set_header('Content-Encoding', 'gzip');
    $response->set_header('Vary', 'Accept-Encoding');
  }

  my $now = time;
  my $last_change = $file->stat()->mtime;
  $response->set_header('Last-Modified', time2str($last_change));
  $response->set_header('Expires', time2str($now + 86400));
  $response->set_header('Cache-Control', 'max-age=86400');
  $response->set_header('ETag', sha1_base64($content));

  $response->status(200);
  $response->set_header('Content-Type', $type);
  $response->set_header('Content-Length' => length($content));
  $response->body($content);

  return;
}

use Moo::Role;

before 'jedi_app' => sub {
	my ($jedi_app) = @_;

  _jedi_template_setup_path($jedi_app);

	$jedi_app->get(qr{.*}x, \&_jedi_dispatch_public_files);

	return;
};


=attr jedi_template_default_layout

if you want to set a default layout, use this attribute.

	$jedi_app->jedi_template_default_layout('main.tt');

=cut
has 'jedi_template_default_layout' => (is => 'rw');

=method jedi_template

This method will use L<Template> to process your template.

	$jedi_app->jedi_template($file, $vars);
	$jedi_app->jedi_template($file, $vars, $layout);

The layout use the jedi_template_default_layout by default.
You can also remove any layout, using the value "none".

The file is a file inside the subdir "views". The subdir "views" is located on the root of your apps, in
the same directory than the "config.*".

=cut
sub jedi_template {
	my ($jedi_app, $file, $vars, $layout) = @_;
	$layout //= $jedi_app->jedi_template_default_layout;
	$layout = 'none' if !defined $layout;
  my $class = ref $jedi_app;
  my $template_views = dir($jedi_app->jedi_config->{$class}{template_dir}, 'views');

	my $layout_file;
	if ($layout ne 'none') {
		$layout_file = file($template_views, 'layouts', $layout);
		if (! -f $layout_file) {
			$layout = 'none';
			$layout_file = undef;
		}
	};


	state $cache = {};
	if (!exists $cache->{$layout}) {
		my @tpl_options = (
			INCLUDE_PATH => [ $template_views->absolute->stringify ],
			ABSOLUTE => 1,
		);
	
		if ($layout ne 'none') {
			push @tpl_options, WRAPPER => $layout_file->absolute->stringify;
		}

		$cache->{$layout} = Template->new(@tpl_options);
	}
	
	my $tpl_engine = $cache->{$layout};
	my $view_file = file($template_views, $file);

	my $ret = "";
	$tpl_engine->process($view_file->absolute->stringify, $vars, \$ret) or croak $tpl_engine->error();

	return $ret;
}

1;
