[![Gem Version](https://badge.fury.io/rb/injectedlogger.svg)](http://badge.fury.io/rb/injectedlogger)

# A logger injection gem

This gem can be used to inject several loggers in different parts of your Ruby project.

It will try to support as many methods and levels as the underlying object supports, and fall back to a supported level in case some levels are not available

## How to use it

You have to declare the log levels that your code will be using, and
InjectedLogger will make sure that the underlying object supports them.

The user of your code will just pass the logger and refer to either a module of
yours or a symbolic name or string.

Suppose we have two projects, one of which has the other as dependency, and has
a logger available. The other project wants to log whatever it does using a
logger injected (provided) by the first project.

### On the code injecting the logger:

Inject our logger on `Dependency::Logger`, which is the module used by Dependency
for logging:
```ruby
InjectedLogger.inject mylogger, on: Dependency::Logger
```

Inject our logger on whatever is identified by `'dependency-logger'`:
```ruby
InjectedLogger.inject mylogger, on: 'dependency-logger'
```

Inject our logger on `'dependency-logger'`, and have it provide `:debug`, `:info`
and `:invented` log levels, with whatever of those being actually unsupported by
`mylogger` emulated with `:info`:
```ruby
InjectedLogger.inject mylogger, levels: [:debug, :info, :invented], fallback: :info, on: 'dependency-logger'
```

Inject our logger on `Dependency::Logger` and prefix the messages with `'[logger-for-dep]'`:
```ruby
InjectedLogger.inject mylogger, prefix: '[logger-for-dep]', on: Dependency::Logger
```

### On the code where you want a logger injected:

This sets up a module with a `logger` method identified as `'dependency-logger'`
and declaring requirements of `:debug`, `:info`, and `:invented` log levels. In
case no logger gets injected by the time `logger` is needed, the standard Ruby
logger with output on `STDERR` will be used. After a logger is finally available,
this also makes sure the prefix for each message is `'[dependency]'` (overriding
what the injector set up):
```ruby
module Dependency
  module Logger
    InjectedLogger.use :debug, :info, :invented, as: 'dependency-logger' do
      # this gets executed if no logger has been injected at use time
      require 'logger'
      { logger: Logger.new(STDERR) } # optionally add parameters for `inject`
    end
    InjectedLogger.after_injection on: 'dependency-logger' do |logger|
      logger.prefix = '[dependency]'
    end
  end
end
```

Now you can use your module elsewhere in your project:
```ruby
class WantsLogging
  include Dependency::Logger

  def some_method_needing_logging
    logger.info 'some info'
    # logger blocks are also supported
    logger.invented do
      find_answer_to_ultimate_question_of life, universe and ObjectSpace.each_object
      'using the invented log level is computationally expensive so ' \
      'I pass this computation as a block to avoid computing it in ' \
      'case the logger filters this level'
    end
  end
end
```

If you write this inside `Dependency::Logger`, you will get a `mylogger` method in
`Dependency::Logger` requiring the `:debug` and `:info` levels and falling back
to the Ruby logger, identified for injection with `Dependency::Logger`:
```ruby
InjectedLogger.use :debug, :info, method_name: :mylogger do
  require 'logger'
  { logger: Logger.new(STDERR)
end
```

You can also force the definition of the method elsewhere:
```ruby
InjectedLogger.use :debug, :info, method_name: :mylogger, on: Dependency::OtherLogger do
  [...]
end
```

If you omit the block, InjectedLogger will provide a default logger (note that
we are forced to use the `:on` parameter if we have no block).
```ruby
InjectedLogger.use :debug, :info, on: self
```

Note that you do not need to specify the `:on` parameter for `InjectedLogger.use`
nor `InjectedLogger.after_injection` IFF you provide a block to those methods
and want to imply `on: self`.

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
