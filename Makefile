console:
	@bundle exec pry -r ./bin/console.rb

test:
	@bundle exec rake test

.PHONY: test console