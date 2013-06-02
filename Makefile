MOCHA_OPTS= --compilers coffee:coffee-script --check-leaks
REPORTER = dot

test:
	./node_modules/.bin/mocha \
	  --reporter $(REPORTER) \
	  $(MOCHA_OPTS)

.PHONY: test
