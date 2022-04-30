server: deps create_db migrate
	mix phx.server

deps:
	mix deps.get

test:
	mix test

create_db:
	mix ecto.create

migrate:
	mix ecto.migrate


.PHONY: server deps test migrate create_db
