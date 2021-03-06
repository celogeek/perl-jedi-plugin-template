package t::TestTemplate::App;
use Jedi::App;
use Jedi::Plugin::Template;

sub jedi_app {
	my ($jedi) = @_;

	$jedi->get('/', $jedi->can('handle_index'));
	$jedi->get('/mainlayout', $jedi->can('handle_main_layout'));
	$jedi->get('/error', $jedi->can('handle_error'));

	return;
}

sub handle_index {
	my ($jedi, $request, $response) = @_;
	$response->status(200);
	$response->body($jedi->jedi_template('index.tt', {}, $request->params->{layout}));
	return;
}

sub handle_main_layout {
	my ($jedi, $request, $response) = @_;
	$response->status(200);
	$jedi->jedi_template_default_layout('main.tt');
	$response->body($jedi->jedi_template('index.tt', {}));
	return;
}

sub handle_error {
	my ($jedi, $request, $response) = @_;
	$response->status(200);
	$response->body($jedi->jedi_template('error.tt', {}, $request->params->{layout}));
	return;
}

1;