require 'injectedlogger'

module MyLogger
  InjectedLogger.inject on: self, required: [:randomlevel] do
    require 'logger'
    { logger: Logger.new(STDERR), prefix: '[test]' }
  end
end
