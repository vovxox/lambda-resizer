top_level=$(shell pwd)

up:
	rm ./deploy.zip
	# cd ./api/venv/lib/python3.7/site-packages; zip -r9 -D $(top_level)/deploy.zip *
	cd $(top_level);zip -g -j -D ./deploy.zip ./api/main.py
	./scripts/bootstrap.sh up
.PHONY: up


down:
	./scripts/bootstrap.sh down 
.PHONY: down

