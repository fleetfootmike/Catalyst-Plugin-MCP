# Catalyst::Plugin::MCP

Generic, app-agnostic Model Context Protocol (revision 2025-06-18) server plugin
for Catalyst, layered on `Catalyst::Plugin::JSONRPC::Server`. It owns the MCP
lifecycle, capability advertisement, and verb routing, and knows nothing about
your domain — you supply providers.

## Synopsis

```perl
package MyApp;
use Catalyst qw/
    +Catalyst::Plugin::JSONRPC::Server
    +Catalyst::Plugin::MCP
/;
__PACKAGE__->setup;

# in a controller action:
sub mcp :Path('/mcp') :Args(0) {
    my ( $self, $c ) = @_;
    $c->mcp_register_provider( $c->model('MCP::Tools') );      # ToolProvider
    $c->mcp_register_provider( $c->model('MCP::Resources') );  # ResourceProvider
    $c->mcp_dispatch;   # reads the body, runs the MCP lifecycle, writes the reply
}
```

## Providers

Implement one of the shipped Moo::Roles per provider object:

- `Catalyst::Plugin::MCP::Role::ResourceProvider` — `list($cursor)`,
  `templates`, `read($uri)`.
- `Catalyst::Plugin::MCP::Role::PromptProvider` — `list($cursor)`,
  `get($name, $args)`.
- `Catalyst::Plugin::MCP::Role::ToolProvider` — `list($cursor)`,
  `call($name, $args)`.

Capabilities advertised in `initialize` are derived from which roles your
registered providers consume. Pagination is pass-through: the cursor flows to
`list($cursor)` and your `nextCursor` flows back out. Tool execution failures
return a normal result with `isError => 1`; unknown tools/prompts/resources and
bad params become JSON-RPC errors (`-32602`, `-32002`).

## Configuration

```perl
__PACKAGE__->config(
    'Catalyst::Plugin::MCP' => {
        protocol_versions => ['2025-06-18'],          # newest-first
        server_info       => { name => 'myapp', version => '1.0' },
    },
);
```

## Author

Mike Whitaker <mike@altrion.org>

## License

This library is free software; you can redistribute it and/or modify it
under the terms of the Artistic License, as distributed with Perl.
