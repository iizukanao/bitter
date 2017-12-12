MOCHA_OPTS= --require coffee-script/register --check-leaks
REPORTER = dot

test:
	./node_modules/.bin/mocha \
	  --reporter $(REPORTER) \
	  $(MOCHA_OPTS) "test/*.coffee"

.PHONY: test
