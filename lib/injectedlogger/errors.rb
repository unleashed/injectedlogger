module InjectedLogger
  Error = Class.new StandardError
  InUse = Class.new Error
  DefaultInjectionBlockMissing = Class.new Error
  UnsupportedLevels = Class.new Error do
    def initalize(levels)
      super("logger does not support required levels #{levels.join ', '}")
    end
  end
end

