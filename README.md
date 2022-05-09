<div align="center">

<img src="https://user-images.githubusercontent.com/194400/162528448-5df0e9e8-a132-4644-b216-5107e0df0204.png" alt="gogs elixir interface">

Interface with a **`Gogs`** instance from **`Elixir`**.

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/dwyl/gogs/Elixir%20CI?label=build&style=flat-square)](https://github.com/dwyl/gogs/actions/workflows/ci.yml)
[![codecov.io](https://img.shields.io/codecov/c/github/dwyl/gogs/main.svg?style=flat-square)](http://codecov.io/github/dwyl/gogs?branch=main)
[![Hex.pm](https://img.shields.io/hexpm/v/gogs?color=brightgreen&style=flat-square)](https://hex.pm/packages/gogs)
[![Libraries.io dependency status](https://img.shields.io/librariesio/release/hex/gogs?logoColor=brightgreen&style=flat-square)](https://libraries.io/hex/gogs)
[![docs](https://img.shields.io/badge/docs-maintained-brightgreen?style=flat-square)](https://hexdocs.pm/gogs/api-reference.html)
[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat-square)](https://github.com/dwyl/gogs/issues)
[![HitCount](http://hits.dwyl.com/dwyl/gogs.svg)](http://hits.dwyl.com/dwyl/gogs)
<!-- uncomment when service is working ...
[![Inline docs](http://inch-ci.org/github/dwyl/auth.svg?branch=master&style=flat-square)](http://inch-ci.org/github/dwyl/auth)
-->

</div>

# _Why?_ 💡

We needed an _easy_ way to interact 
with our **`Gogs`** (GitHub Backup) **Server**
from our **`Elixir/Phoenix`** App.
This package is that interface. 

> **Note**: We were _briefly_ tempted 
> to write this code _inside_ the Phoenix App 
> that uses it, 
> however we quickly realized
> that having it ***separate*** was better
> for ***testability/maintainability***.
> Having a _separate_ module enforces a
> [separation of concerns](https://en.wikipedia.org/wiki/Separation_of_concerns)
> with a strong "API contract".
> This way we know this package is well-tested,
> documented and maintained. 
> And can be used and _extended independently_ 
> of any `Elixir/Phoenix` app.
> The `Elixir/Phoenix` app can treat `gogs`
> as a logically separate/independent entity
> with a clear interface.

# _What_? 📦

A library for interacting with `gogs` (`git`)
from our `Elixir` apps. <br />

Hopefully this diagram explains 
how we are using the package:

<div align="center">

![Phoenix-Gogs-Infra-dagram](https://user-images.githubusercontent.com/194400/167098379-e06ee8ae-d652-4464-83d7-e209d442e9e2.png)

</div>

For the complete list of functions,
please see the docs: https://hexdocs.pm/gogs 📚 

# Who? 👤

This library is used by our (`Phoenix`) GitHub Backup App. <br />
If you find it helpful for your project,
please ⭐ on GitHub: 
[github.com/dwyl/gogs](https://github.com/dwyl/gogs)


## _How_? 💻

There are a couple of steps to get this working in your project.

<br />

## Install ⬇️

Install the package from [hex.pm](https://hex.pm/docs/publish), 
by adding `gogs` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gogs, "~> 0.7.0"}
  ]
end
```

Once you've saved your `mix.exs` file, 
run: 
```sh
mix deps.get
```

<br />

## _Setup_ 🔧

For `gogs` to work
in your `Elixir/Phoenix` App,
you will need to have 
a few environment variables defined.


### _Required_ Environment Variables

> See: [`.env_sample`](https://github.com/dwyl/gogs/blob/main/.env_sample)

There are **3 _required_** environment variables:

1. `GOGS_URL` - the domain where your Gogs Server is deployed,
   without the protocol, e.g: `gogs-server.fly.dev`

2. `GOGS_ACCESS_TOKEN` - the REST API Access Token 
See: https://github.com/dwyl/gogs-server#connect-via-rest-api-https

3. `GOGS_SSH_PRIVATE_KEY_PATH` - absolute path to the `id_rsa` file
  on your `localhost` or `Phoenix` server instance.

> @SIMON: this last env var currently not being picked up.
> So it will just use `~/simon/id_rsa` 
> You will need to add your `public` key 
> to the Gogs instance for this to work on your `localhost`
> see:
> https://github.com/dwyl/gogs-server#add-ssh-key


### _Optional_ Environment Variables

#### `GOGS_SSH_PORT`

If your **`Gogs` Server** is configured 
with a **_non-standard_ SSH port**, 
then you need to define it:
`GOGS_SSH_PORT` <br />
e.g: `10022` for our 
`Gogs` Server deployed to Fly.io

You can easily discover the port by either visiting your
Gogs Server Config page: <br />
`https://your-gogs-server.net/admin/config`

e.g:
https://gogs-server.fly.dev/admin/config

![gogs-ssh-port-config](https://user-images.githubusercontent.com/194400/167105374-ef36752f-80a7-4a77-8c78-2dda44a132f9.png)


Or if you don't have admin access to the config page,
simply view the `ssh` clone link on a repo page,
e.g: https://gogs-server.fly.dev/nelsonic/public-repo

![gogs-ssh-port-example](https://user-images.githubusercontent.com/194400/167104890-31b06fa0-bd23-4ecb-b680-91c92398b0a7.png)

In our case the `GOGS_SSH_PORT` e.g: `10022`. <br />
If you don't set it, then `gogs` will assume TCP port **`22`**.

#### `GIT_TEMP_DIR_PATH`

If you want to specify a directory where 
you want to clone `git` repos to,
create a `GIT_TEMP_DIR_PATH` environment variable.
e.g:

```sh
export GIT_TEMP_DIR_PATH=tmp
```

> **Note**: the directory **must _already_ exist**.
> (it won't be created if it's not there ...)

<br />

## Usage

Here's basic usage example:

### 1. Create Repo

```elixir
# Define the params for the remote repository:
org_name = "myorg"
repo_name = "pepsico-contract1234"
private = false # boolean
# Create the repo!
Gogs.remote_repo_create(org_name, repo_name, private)
```

> ⚠️ **WARNING**: there is currently no way 
> to create an Organisation on the `Gogs` Server
> via `REST API` so the `org_name` 
> _must_ already exists. 
> e.g: https://gogs-server.fly.dev/myorg
> We will be figuring out a workaround shortly ...
> https://github.com/dwyl/gogs/issues/17


### 2. Clone Repo

```elixir
git_repo_url = GogsHelpers.remote_url_ssh(org_name, repo_name)
Gogs.clone(git_repo_url)
```

### 3. Read Contents of File

TODO: https://github.com/dwyl/gogs/issues/21



### 3. Write to File



### 4. Commit Changes

### 5. Push to `Gogs` Remote



## Function Reference / Docs? 📖 

Rather than duplicate all the docs here, 
please read the complete function reference, 
on hexdocs: https://hexdocs.pm/gogs/Gogs.html

## I'm _Stuck!_ 🤷

As always, if anything is unclear
or you are stuck getting this working,
please open an issue!
[github.com/dwyl/gogs/issues](https://github.com/dwyl/gogs/issues/8)
We're here to help!

<br />

# ⚠️ Caution!

This package is provided "**as is**". 
We make ***no guarantee/warranty*** that it _works_.
We _cannot_ be held responsible
for any undesirable effects of it's usage.
e.g: if you use the [`Gogs.delete/1`](https://hexdocs.pm/gogs/Gogs.html#delete/1)
it will _permanently/irrecoverably_ **`delete`** the repo. 
Use it with caution!

That being said,
we are using this package in "production".
It works for _us_ an we _maintain_ it.
If you want to use it, go for it!
But we cannot "support" your usage
beyond answering questions on GitHub.

If you spot anything that can be improved,
please open an 
[issue](https://github.com/dwyl/gogs/issues),
we're very happy to discuss!