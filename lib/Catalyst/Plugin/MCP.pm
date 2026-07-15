package Catalyst::Plugin::MCP;
use v5.36;
use Catalyst::Plugin::MCP::Server;
use Catalyst::Plugin::JSONRPC::Server::Dispatcher;

our $VERSION = '0.002';

my $PROVIDER_SLOT = 'Catalyst::Plugin::MCP/providers';

sub mcp_register_provider ( $c, $obj ) {
    my $list = $c->stash->{$PROVIDER_SLOT} //= [];
    push @$list, $obj;
    return $c;
}

sub mcp_dispatch ( $c, $body = undef ) {
    my $providers = $c->stash->{$PROVIDER_SLOT} // [];
    my $cfg       = $c->config->{'Catalyst::Plugin::MCP'} // {};

    my %args;
    $args{protocol_versions} = $cfg->{protocol_versions}
        if $cfg->{protocol_versions};
    $args{server_info} = $cfg->{server_info} if $cfg->{server_info};

    my $engine = Catalyst::Plugin::MCP::Server->new(%args);
    $engine->register_provider($_) for @$providers;

    my $handlers = $engine->handlers;

    # Build a fresh per-request dispatcher so each request's verb set is
    # isolated: no stale verbs from prior requests leak across, and there
    # are no cross-thread races on the shared per-application dispatcher.
    my $dispatcher = Catalyst::Plugin::JSONRPC::Server::Dispatcher->new;
    $dispatcher->register( $_ => $handlers->{$_} ) for keys %$handlers;

    # MCP's Streamable HTTP transport requires HTTP 202 Accepted (not the
    # generic JSON-RPC 204) for a POST that carries only responses/notifications
    # — i.e. when the dispatcher has nothing to send back.
    return $c->jsonrpc_dispatch_with( $dispatcher, $body, 202 );
}

=head1 NAME

Catalyst::Plugin::MCP - Model Context Protocol server plugin for Catalyst

=head1 SYNOPSIS

    package MyApp;
    use Catalyst qw/
        +Catalyst::Plugin::JSONRPC::Server
        +Catalyst::Plugin::MCP
    /;
    __PACKAGE__->setup;

    # in a controller action mounted at your MCP endpoint
    sub mcp :Path('/mcp') :Args(0) {
        my ( $self, $c ) = @_;
        $c->mcp_register_provider( $c->model('MCP::Resources') );
        $c->mcp_register_provider( $c->model('MCP::Tools') );
        $c->mcp_dispatch;
    }

=head1 REQUIRED PLUGINS

This plugin builds on L<Catalyst::Plugin::JSONRPC::Server> and calls its
C<jsonrpc_dispatch_with> method. The consuming application B<must> load
C<Catalyst::Plugin::JSONRPC::Server> in its plugin list, B<before>
C<Catalyst::Plugin::MCP> (as in the SYNOPSIS). Declaring the distribution as a
prerequisite installs it but does not load it into the application class — a
Catalyst plugin is only mixed into C<$c> when listed in C<use Catalyst
qw/+.../>. Omitting it yields a runtime C<< Can't locate object method
"jsonrpc_dispatch_with" >> at the first MCP request.

=head1 DESCRIPTION

Adds a Model Context Protocol (revision 2025-06-18) server to a Catalyst
application, layered on L<Catalyst::Plugin::JSONRPC::Server>. The protocol
engine lives in L<Catalyst::Plugin::MCP::Server>; this module is the thin
Catalyst seam.

Each call to C<mcp_dispatch> builds a fresh
L<Catalyst::Plugin::JSONRPC::Server::Dispatcher> containing only the handlers
registered by the providers in the current request's stash. The shared
per-application dispatcher provided by C<Catalyst::Plugin::JSONRPC::Server>
is never written to by this plugin, so there is no cross-request verb leakage
and no concurrency hazard between simultaneous requests.

=head1 EXAMPLES

A runnable example lives in F<examples/>: a small Catalyst app loading
C<Catalyst::Plugin::JSONRPC::Server> then C<Catalyst::Plugin::MCP>, mounting
an C<echo> tool and a static resource at C</mcp>, plus a core-Perl client that
replays the C<initialize> / C<tools/list> / C<tools/call> / C<resources/read>
handshake. Start it with C<plackup examples/app.psgi> and run C<perl
examples/client.pl>. See F<examples/README.md>.

=cut

1;
