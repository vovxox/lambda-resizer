up:
	zip -r deploy.zip ./api/*
	./scripts/bootstrap.sh up
.PHONY: up


down:
	./scripts/bootstrap.sh down 
.PHONY: down

