require 'injectedlogger/errors'
require 'injectedlogger/logger'
require 'injectedlogger/version'

module InjectedLogger
  # inject a default logger in case no one has set one for you:
  #
  # module MyLogger
  #   InjectedLogger.inject self do
  #     require 'logger'
  #     # logger is required, the rest are other use() params
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

  def self.inject(klass, required: [], method_name: :logger, &blk)
    klass.send :remove_method, method_name rescue nil
    klass.send :define_method, method_name do
      unless InjectedLogger::Logger.in_use?
        args = blk.call
        logger = args.delete :logger
        unless required.empty?
          args[:levels] ||= []
          args[:levels].push(required).flatten!.uniq!
        end
        InjectedLogger::Logger.use(logger, args)
      end
      required.uniq!
      required -= InjectedLogger::Logger.level_info[:supported]
      raise InjectedLogger::UnsupportedLevels.new(required) if not required.empty?
      klass.send :remove_method, method_name
      klass.send :define_method, method_name do
        InjectedLogger::Logger
      end
      InjectedLogger::Logger
    end
  end
end
