package Catalyst::Plugin::MCP;
use v5.36;

our $VERSION = '0.001';

=head1 NAME

Catalyst::Plugin::MCP - Model Context Protocol server plugin for Catalyst

=head1 DESCRIPTION

Adds a Model Context Protocol (revision 2025-06-18) server to a Catalyst
application, layered on L<Catalyst::Plugin::JSONRPC::Server>. The protocol
engine lives in L<Catalyst::Plugin::MCP::Server>; this module is the thin
Catalyst seam (added in a later task).

=cut

1;
