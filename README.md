<div align="center">

# `gogs`

Interface with ***`gogs`*** from **`Elixir`**.

![GitHub Workflow Status](https://img.shields.io/github/workflow/status/dwyl/gogs/Elixir%20CI?label=build&style=flat-square)
[![codecov.io](https://img.shields.io/codecov/c/github/dwyl/gogs/master.svg?style=flat-square)](http://codecov.io/github/dwyl/auth?branch=main)
[![Hex.pm](https://img.shields.io/hexpm/v/gogs?color=brightgreen&style=flat-square)](https://hex.pm/packages/auth)
[![Libraries.io dependency status](https://img.shields.io/librariesio/release/hex/gogs?logoColor=brightgreen&style=flat-square)](https://libraries.io/hex/gogs)
[![docs](https://img.shields.io/badge/docs-maintained-brightgreen?style=flat-square)](https://hexdocs.pm/gogs/api-reference.html)
[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat-square)](https://github.com/dwyl/gogs/issues)
[![HitCount](http://hits.dwyl.com/dwyl/gogs.svg)](http://hits.dwyl.com/dwyl/gogs)
<!-- uncomment when service is working ...
[![Inline docs](http://inch-ci.org/github/dwyl/auth.svg?branch=master&style=flat-square)](http://inch-ci.org/github/dwyl/auth)
-->

</div>

## Installation

If [available in Hex](https://hex.pm/docs/publish), 
the package can be installed
by adding `gogs` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gogs, "~> 0.1.0"}
  ]
end
```

<!--
Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/gogs>.
-->

## Function Roadmap

+ [ ] Connect to Git Endpoint - perhaps a proxy for this is having access to a know repository.
+ [ ] Create or `Org` this might only be done via the API.


Continue: 
+ [ ] New Access token: https://gogs-server.fly.dev/user/settings/applications
+ [ ] New terminal: `cd /Users/n/code/gogs-server && codium .`
+ [ ] New terminal: `cd /Users/n/code/elixir-auth-github && atom .`
+ [ ] Publish: https://hex.pm/packages/gogs