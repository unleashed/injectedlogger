module InjectedLogger
  module Delegator
    class << self
      # creates methods in klass according to the supported levels in the
      # object specified. (levels are supposed to be methods)
      #
      # Arguments:
      #
      # on: class which we'll create methods on
      # from: underlying logger object, which responds to some levels
      # prefix: prefix log messages with this string
      # extra_levels: extra levels we want to use from klass delegating to logger
      # old_levels: the old levels that the class was delegating previously
      # fallback: not required, suggested fallback level for non-native lvls
      # info: not required, suggested level usable for information
      #
      # Returns a hash with information about supported and fallback levels:
      #
      # native: levels natively supported by the underlying object
      # nonnative: non-native levels, callable only if there is fallback
      # fallback: (if existing) native level used as fallback for others
      # supported: supported levels, some maybe via fallback to native ones
      # info: level the caller can use to give info (can be nil)
      #
      def delegate_levels(on:, from:, prefix:, extra_levels: [],
                          old_levels: [], fallback: UNKNOWN, info: INFO)
        self.logger = from
        self.klass = on
        self.prefix = prefix
        supp, unsupp = add_level_methods(extra_levels)
        { native: supp,
          nonnative: unsupp,
          info: preferred_lvl(supp, info) }.
        tap do |level_info|
          level_info.merge!(
            if fallback and unsupp.any?
              flvl = preferred_lvl(supp, fallback)
              add_as_fallback(unsupp, flvl)
              { fallback: flvl, supported: supp + unsupp }
            else
              { supported: supp }
            end)
          (old_levels - level_info[:supported]).each { |lvl| remove_level lvl }
        end
      end

      private

      UNKNOWN = :unk
      INFO = :info

      attr_accessor :klass, :logger, :prefix

      def remove_level(lvl)
        klass.singleton_class.send :undef_method, lvl rescue nil
      end

      def add_level(lvl, &blk)
        klass.define_singleton_method lvl, &blk
      end

      def add_as_fallback(nonnative, fallback)
        nonnative.each do |lvl|
          remove_level lvl
          add_level lvl do |*msg, &blk|
            if blk
              public_send fallback, *msg do
                str = blk.call
                "[#{lvl.upcase}] #{str}"
              end
            else
              public_send fallback, "[#{lvl.upcase}] #{msg.join ' '}"
            end
          end
        end
      end

      def remove_unsupported(unsupported)
        unsupported.each do |lvl|
          remove_level lvl
        end
      end

      def add_level_methods(extra_levels)
        get_all_levels_with(extra_levels).partition do |lvl|
          remove_level lvl
          if logger.respond_to? lvl
            add_level_method lvl
          elsif logger.respond_to? :log
            add_log_method lvl
          end
        end
      end

      def get_all_levels_with(extra_levels)
        (extra_levels + (logger.respond_to?(:levels) ?
                         logger.levels.map { |l| l.downcase.to_sym } : [])).uniq
      end

      def add_level_method(lvl)
        if prefix.nil? or prefix.empty?
          add_level lvl do |*msg, &blk|
            logger.send lvl, *msg, &blk
          end
        else
          add_level lvl do |*msg, &blk|
            if blk
              logger.send lvl, *msg do
                str = blk.call
                "#{prefix} #{str}"
              end
            else
              logger.send lvl, "#{prefix} #{msg.join ' '}"
            end
          end
        end
      end

      # Useful for Ruby 'logger' from stdlib and compatible interfaces
      # called when logger.log exists only
      def add_log_method(lvl)
        arity = logger.method(:log).arity
        if arity.abs == 1
          # one single mandatory parameter, the string logged
          prefix_s = "[#{lvl.upcase}]"
          if prefix and not prefix.empty?
            prefix_s += " " + prefix
          end
          klass.define_singleton_method lvl do |msg|
            logger.send :log, "#{prefix_s} #{msg}"
          end
        else
          # assume two or more params, best effort with 1st being level
          if lvl_s = ruby_logger_severity(lvl)
            klass.define_singleton_method lvl do |msg|
              logger.send :log, lvl_s, msg
            end
          end
        end
      end

      # try to map a severity level with one compatible with Ruby's Logger
      def ruby_logger_severity(level)
        lvl_s = level.upcase
        l = logger
        begin
          l.const_get(lvl_s)
        rescue NoMethodError
          l = l.class
          retry
        rescue NameError
        end
      end

      # return the preferred level if matched in levels, else first one
      def preferred_lvl(levels, preference)
        preference_r = Regexp.new("^#{Regexp.escape(preference.to_s)}")
        levels.find { |l| preference_r.match l } || levels.first
      end
    end
  end

end
