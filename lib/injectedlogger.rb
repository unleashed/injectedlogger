require 'injectedlogger/errors'
require 'injectedlogger/logger'
require 'injectedlogger/version'

module InjectedLogger
  # inject a default logger in case no one has set one for you:
  #
  # module MyLogger
  #   InjectedLogger.inject do
  #     require 'logger'
  #     # logger is required, the rest are other inject() params
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
  # end
  #
  # This will only run the block passed to inject IFF there was no logger set
  # up to be used by InjectedLogger, and it will only happen the first time the
  # logger method is called, so that it does not 'require' anything if it is not
  # needed. :)

  def self.declare(on: nil, required: [], method_name: :logger, &blk)
    if on.nil?
      raise InjectedLogger::DefaultInjectionBlockMissing if blk.nil?
      on = blk.binding.eval 'self'
    else
      on = on.singleton_class unless on.is_a? Module
    end
    on.send :define_method, method_name do
      # avoid recursion if someone calls logger in the block
      on.send :remove_method, method_name
      unless InjectedLogger::Logger.injected?
        args = blk ? blk.call : nil
        args = InjectedLogger.default_logger if args.nil? or args == :default
        InjectedLogger.inject_logger args, required
      end
      required.uniq!
      required -= InjectedLogger::Logger.level_info[:supported]
      raise InjectedLogger::UnsupportedLevels.new(required) if not required.empty?
      on.send :define_method, method_name do
        InjectedLogger::Logger
      end
      InjectedLogger::Logger
    end
  end

  private

  def self.default_logger
    require 'logger'
    { logger: ::Logger.new(STDERR) }
  end

  def self.inject_logger(args, required)
    logger = args.delete :logger
    unless required.empty?
      args[:levels] ||= []
      args[:levels].push(required).flatten!
      args[:levels].uniq!
    end
    InjectedLogger::Logger.inject(logger, args)
  end
end
