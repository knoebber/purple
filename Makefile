ifeq "$(MIX_ENV)" "prod"
    DEPS_FLAGS:= --only prod
    NPM_FLAGS:= --omit=dev
endif

all: deps create_db js compile assets migrate

test:
	mix test

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

compile:
	mix compile

assets:
	mix assets.deploy

migrate:
	mix ecto.migrate

.PHONY: all test hex rebar deps create_db js compile assets migrate
