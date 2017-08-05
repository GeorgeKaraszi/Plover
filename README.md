# Starting Up

## Setting up Environmental Variables
` $: cp .env.example .env.dev`

Assign the proper key values to the `.env.dev` file

## To start The Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `cd /assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

# Project Prerequisite's

* Postgres v9.6

# Heroku Prerequisite's

## Build packs

```
heroku buildpacks:set https://github.com/gjaldon/heroku-buildpack-phoenix-static.git
heroku buildpacks:add --index 1 https://github.com/HashNuke/heroku-buildpack-elixir
```