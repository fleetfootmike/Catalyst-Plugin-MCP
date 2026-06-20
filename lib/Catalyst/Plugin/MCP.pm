package Catalyst::Plugin::MCP;
use v5.36;
use Catalyst::Plugin::MCP::Server;

our $VERSION = '0.001';

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
    $c->jsonrpc_register( $_ => $handlers->{$_} ) for keys %$handlers;

    return $c->jsonrpc_dispatch($body);
}

=head1 NAME

Catalyst::Plugin::MCP - Model Context Protocol server plugin for Catalyst

=head1 DESCRIPTION

Adds a Model Context Protocol (revision 2025-06-18) server to a Catalyst
application, layered on L<Catalyst::Plugin::JSONRPC::Server>. The protocol
engine lives in L<Catalyst::Plugin::MCP::Server>; this module is the thin
Catalyst seam.

=cut

1;
