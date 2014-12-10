require 'injectedlogger/errors'
require 'injectedlogger/delegator'

module InjectedLogger

  def self.logger
    @logger ||= Hash.new { |h, k| h[k] = Logger.new }
  end
  private_class_method :logger

  def self.injected?(on:)
    logger[on].injected?
  end

  def self.inject(*args, on:, **options)
    logger[on].inject(*args, **options)
  end

  def self.inject!(*args, on:, **options)
    logger[on].inject!(*args, **options)
  end

  def self.after_injection(on: nil, &blk)
    on = blk.binding.eval 'self' if on.nil?
    logger[on].after_hook = blk
  end

  class Logger
    UNKNOWN = :unknown
    LOGLEVELS = [:debug, :verbose, :notice, :info, :warn, :error, :critical, :fatal, :unknown]

    attr_reader :prefix, :levels, :level_info, :fallback
    attr_accessor :after_hook

    def injected?
      not logger.nil?
    end

    def inject(logger_obj, levels: LOGLEVELS, fallback: UNKNOWN, prefix: nil)
      if logger and logger != logger_obj
        raise InUse, "#{self} was already using logger #{logger}"
      end
      inject! logger_obj, levels: levels, fallback: fallback
    end

    def inject!(logger_obj, levels: LOGLEVELS, fallback: UNKNOWN, prefix: nil)
      self.logger = logger_obj
      set_prefix prefix
      set_levels levels
      set_fallback fallback
      add_methods
      self
    end

    def prefix=(prefix)
      set_prefix prefix
      add_methods
    end

    def levels=(levels)
      set_levels(levels)
      add_methods
    end

    def add_levels(*levels)
      lvls = self.levels + levels
      lvls.uniq!
      self.levels = lvls
    end

    def fallback=(level)
      set_fallback level
      add_methods
    end

    def method_missing(method, *args, &blk)
      logger.send method, *args, &blk
    rescue NoMethodError
      super
    end

    def respond_to_missing?(method, priv = false)
      logger.respond_to?(method, priv) || super
    end

    private

    attr_accessor :logger
    attr_writer :level_info

    def set_prefix(prefix)
      @prefix = prefix
    end

    def set_levels(levels)
      @levels = levels
    end

    def set_fallback(level)
      @fallback = level
    end

    def add_methods
      old_levels = level_info ? level_info[:supported] : []
      self.level_info = InjectedLogger::Delegator.delegate_levels(
        from: logger, on: self, prefix: prefix, extra_levels: self.levels,
        old_levels: old_levels, fallback: fallback)
      set_levels(level_info[:supported])
    end

    def ready
      level_info[:supported].tap do
        info_message(level_info) if level_info[:info]
      end
    end

    def info_message(level_info)
      message = if level_info[:fallback]
                  "non-native log levels #{level_info[:nonnative].join ', '} emulated" \
                    " using #{level_info[:fallback].upcase} severity"
                elsif level_info[:nonnative].any?
                  "unsupported log levels #{level_info[:nonnative].join ', '}"
                else
                  nil
                end
      send level_info[:info], message if message
    end

  end
end