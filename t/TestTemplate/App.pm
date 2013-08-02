package t::TestTemplate::App;
use Jedi::App;
with 'Jedi::Plugin::Template';

sub jedi_app {
	my ($jedi) = @_;

	$jedi->get('/', $jedi->can('handle_index'));

	return;
}

sub handle_index {
	my ($jedi, $request, $response) = @_;
	$response->status(200);
	$response->body($jedi->jedi_template('index.tt', {}, $request->params->{layout}));
	return;
}

1;