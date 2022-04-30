ifeq "$(MIX_ENV)" "prod"
    DEPS_FLAGS:= --only prod
endif

server: deps create_db compile assets migrate
	mix phx.server

deps:
	mix deps.get $(DEPS_FLAGS)

create_db:
	mix ecto.create

compile:
	mix compile

assets:
	mix assets.deploy

migrate:
	mix ecto.migrate

test:
	mix test

.PHONY: compile assets server deps test migrate create_db
