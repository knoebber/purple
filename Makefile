ifeq "$(MIX_ENV)" "prod"
    DEPS_FLAGS:= --only prod
    NPM_FLAGS:= --omit=dev
endif

all: deps create_db js compile assets migrate

deps:
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

.PHONY: all deps create_db js compile assets migrate
