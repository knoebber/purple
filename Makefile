ifeq "$(MIX_ENV)" "prod"
    DEPS_FLAGS:= --only prod
    NPM_FLAGS:= --omit=dev
endif

all: deps create_db js compile assets migrate

clean:
	rm -rf build/

warnings:
	mix compile --all-warnings --warnings-as-errors

compile:
	mix compile

format:
	mix format mix.exs "lib/**/*.{ex,exs}" "test/**/*.{ex,exs}"

server:
	mix phx.server

test: warnings
	mix test

reset_test:
	MIX_ENV=test mix ecto.reset

hex:
	mix local.hex --force

rebar:
	mix local.rebar --force

deps: hex rebar
	mix deps.get $(DEPS_FLAGS)

create_db:
	mix ecto.create

js:
	cd assets/; npm i $(NPM_FLAGS)


assets:
	mix assets.deploy

migrate:
	mix ecto.migrate

deploy: clean test
	fly deploy

.PHONY: all format test hex rebar deps create_db js compile assets migrate deploy warnings
