module InjectedLogger
  class Introspector
    attr_reader :level_methods, :has_levels_constant,
                :has_levels_method, :has_log_method

    COMMON_LEVELS = [:debug, :verbose, :notice, :info, :warn,
                     :error, :fatal, :critical, :unknown]

    def initialize(object, search_levels = COMMON_LEVELS)
      self.obj = object
      self.klass = get_class_context_of object
      discover_capabilities
      self.level_methods = get_level_methods search_levels
    end

    private

    attr_accessor :obj, :klass
    attr_writer :level_methods, :has_levels_constant, :has_levels_method, :has_log_with_parms

    def get_class_context_of(object)
      if object.respond_to? :singleton_class?
        # an object which responds to that is class-like already
        # so we'll operate on that
        object
      else
        object.singleton_class
      end
    end

    def find_responding_levels(levels)
      methods = levels.map do |m|
        lvl = m.to_sym
        if obj.respond_to? lvl
          lvl
        elsif obj.respond_to? lvl.downcase
          lvl.downcase
        end
      end
      methods.compact!
      methods
    end

    def value_if_enumerable(val)
      val.map { |key, _| key } if val.is_a? Enumerable
    end

    def discover_capabilities
      if lvlk = klass.const_get(:LEVELS) rescue nil
        self.has_levels_constant = value_if_enumerable(lvlk)
      end
      if obj.respond_to? :levels
        self.has_levels_method = value_if_enumerable(obj.levels)
      end
      self.has_log_with_parms = obj.method(:log).parameters if obj.respond_to? :log
    end

    def get_level_methods(search_levels)
      methods = []
      methods += has_levels_constant if has_levels_constant
      methods += has_levels_method if has_levels_method
      methods += search_levels # adding last bc we want to respect ordering
      methods.uniq!
      methods = find_responding_levels(methods)
      methods.uniq! # we might have :WARN and :warn mapping both to :warn
      methods
    end

  end

end
