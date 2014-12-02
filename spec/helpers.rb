module Helpers
  module LevelsMethod
    def levels
      if self.singleton_class.const_defined? :LEVELS
        self.singleton_class.const_get(:LEVELS).map(&:downcase)
      else
        @levels || []
      end
    end
  end

  module RubyLoggerCompat
    LEVELS = [:DEBUG, :VERBOSE, :INFO, :NOTICE, :WARN, :ERROR, :CRITICAL, :FATAL]

    include LevelsMethod

    def self.included(base)
      define_constant_levels_on base
    end

    def self.define_constant_levels_on(base)
      num = rand(LEVELS.size) + 1
      num -= 1 if num == LEVELS.size # always leave out at least one level
      # so that we can spec non-native levels
      LEVELS.sample(rand(LEVELS.size) + 1).each_with_index do |lvl, i|
        base.const_set(lvl, i)
      end.tap do |levels|
        base.const_set(:LEVELS, levels)
        #base.define_singleton_method :levels do
        #  levels
        #end
      end
    end

    def log(level, msg)
      out.puts "#{level} #{msg}"
    end
  end

  class Outputter
    attr_reader :msgs

    def initialize
      @msgs = []
    end

    def puts(msg)
      msgs << msg
    end

    def match(re)
      re = Regexp.new("#{Regexp.escape(re)}$") unless re.is_a? Regexp
      msgs.any? do |m|
        re.match m
      end
    end
    alias_method :<<, :puts
  end

  class SpecLogger
    attr_accessor :out, :called

    def initialize(levels, out = Outputter.new)
      @levels = if self.singleton_class.const_defined? :LEVELS
                  self.singleton_class.const_get :LEVELS
                else
                  levels
                end
      self.out = out
      self.called = Hash.new do |h, k|
        h[k] = 0
      end
      @levels.each do |lvl|
        self.singleton_class.send :define_method, lvl.downcase do |msg|
          out.puts "#{lvl.upcase} #{msg}"
        end
      end
    end
  end

  class RubyLikeLogger < SpecLogger
    include RubyLoggerCompat
  end
end
