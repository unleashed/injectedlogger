require 'injectedlogger/errors'
require 'injectedlogger/logger'
require 'injectedlogger/version'

module InjectedLogger
  # inject a default logger in case no one has set one for you:
  #
  # module MyLogger
  #   InjectedLogger.use :info, :debug, :invented do
  #     require 'logger'
  #     # parameters are inject() params, none is required, but if
  #     # logger is not present, a default one will be used.
  #     { logger: Logger.new(STDERR), prefix: '[mylogger]', ... }
  #   end
  # end
  #
  # class WantsLogging
  #   include MyLogger
  #
  #   def some_method_needing_logging
  #     logger.info 'some info'
  #   end
  #
  #   def some_method_with_invented_level_logging
  #     logger.invented do
  #       'some invented logging'
  #     end
  #   end
  # end
  #
  # This will only run the block passed to inject IFF there was no logger set
  # up to be used by InjectedLogger, and it will only happen the first time the
  # logger method is called, so that it does not 'require' anything if it is not
  # needed. :)

  def self.use(*required, on: nil, method_name: :logger, &blk)
    if on.nil?
      raise InjectedLogger::DefaultInjectionBlockMissing if blk.nil?
      on = blk.binding.eval 'self'
    else
      on = on.singleton_class unless on.is_a? Module
    end
    on.send :define_method, method_name do
      # avoid recursion if someone calls logger in the block
      on.send :remove_method, method_name
      unless InjectedLogger.injected? on: on
        args = blk ? blk.call : nil
        InjectedLogger.inject_logger args, required, on: on
      end
      thislogger = InjectedLogger.send(:logger).[](on)
      required.uniq!
      required -= thislogger.level_info[:supported]
      unless required.empty?
        thislogger.add_levels(*required)
        required -= thislogger.level_info[:supported]
        raise InjectedLogger::UnsupportedLevels.new(required) unless required.empty?
      end
      on.send :define_method, method_name do
        thislogger
      end
      thislogger.after_hook.call(thislogger) if thislogger.after_hook
      thislogger.send :ready
      thislogger
    end
  end

  private

  def self.default_logger
    require 'logger'
    { logger: ::Logger.new(STDERR) }
  end

  def self.inject_logger(args, required, on:)
    args ||= {}
    args = default_logger.merge(args) unless args.has_key? :logger
    logger = args.delete :logger
    unless required.empty?
      args[:levels] ||= []
      args[:levels].push(required).flatten!
      args[:levels].uniq!
    end
    args[:on] = on
    InjectedLogger.inject(logger, **args)
  end
end
