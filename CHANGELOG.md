# Changelog

## v1.4.0

* Added support for connection pooling that is configurable via the `:pool_size` option.

## v1.3.0

* Added the `c:Statix.connect/1` callback to support runtime configuration.
* Dropped support for Elixir v1.2.

## v1.2.1

* Fixed port command for OTP versions that support ancillary data sending.
* Fixed ArgumentError raising when port gets closed.

## v1.2.0

* Added support for global tags.

## v1.1.0

* Made Statix functions overridable.
