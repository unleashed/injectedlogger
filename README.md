# A logger injection gem

This gem can be used to inject several loggers in different parts of your Ruby project.

It will try to support as many methods and levels as the underlying object supports, and fall back to a supported level in case some levels are not available

## Usage examples

### On your code, which receives a logger from some foreign caller:

```ruby
module MyLogger
  InjectedLogger.use :debug, :info, :invented do
    # this gets executed if no logger has been injected at use time
    require 'logger'
    { logger: Logger.new(STDERR) }
  end
  InjectedLogger.after_injection do |logger|
    logger.prefix = '[myproject]'
  end
end

class WantsLogging
  include MyLogger

  def some_method_needing_logging
    logger.info 'some info'
  end
end

class ThisAlsoWantsIt
  include MyLogger

  def some_other_method_with_invented_logging
    logger.invented 'some invented info'
  end
end
```

### On the code injecting a logger:

```ruby
InjectedLogger.inject somelogger, on: MyLogger
```

### In case some other dependency needs a logger:

```ruby
InjectedLogger.inject somelogger, prefix: '[other]', on: Other::Logger
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
