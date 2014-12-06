# A logger injection gem

This gem can be used to inject a logger in your Ruby code.

It will try to support as many methods and levels as the underlying object supports, and fall back to a supported level in case some levels are not available

## Usage

```ruby
logger = InjectedLogger::Logger.use somelogger
raise 'No info :(' unless logger.level_info[:supported].include? :info
logger.info 'You now have a logger!'
```

or you can set-up a default injection for your logger in case no one else sets it up before you need to log something:

```ruby
module MyLogger
  InjectedLogger.inject self, required: [:debug, :info] do
    require 'logger'
    { logger: Logger.new(STDERR), prefix: '[mylogger]' }
  end
end

class WantsLogging
  include MyLogger

  def some_method_needing_logging
    logger.info 'some_info'
  end
end

class ThisAlsoWantsIt
  include MyLogger
  ...
end
```

## Generating the gem

Both bundler and rspec are required to build the gem:

    $ gem install bundler rspec

Run rake -T to see available tasks. The gem can be built with:

    $ rake build

Or, if you want to make sure everything works correctly:

    $ bundle exec rake build

## Installation

After generating the gem, install it using:

    $ gem install pkg/injectedlogger-*.gem
