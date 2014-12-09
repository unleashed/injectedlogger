require 'injectedlogger'

class Messaging
  def msg(m)
    logger.info m
    logger.debug do m end
    logger.info 'arg' do 'block' end
    logger.invented 'invented arg'
    logger.invented do 'invented block' end
    logger.invented 'invented arg in arg and block' do 'invented block in arg and block' end
  end
end

module R4L
  InjectedLogger.use :info, :debug, :invented do
    require 'log4r'
    { logger: Log4r::Logger.new('test_log4r').tap { |l| l.outputters = Log4r::Outputter.stdout } }
  end
  InjectedLogger.after_injection do |l| l.prefix = '[log4r]' end
end

class A < Messaging
  include R4L
end

def test(klass)
  a = klass.new
  a.msg 'hola'
end

module L
  InjectedLogger.use(:info, :debug, :invented) {}
  InjectedLogger.after_injection do |l| l.prefix = '[ruby-logger]' end
end

class B < Messaging
  include L
end

module IL
  InjectedLogger.use :info, :debug, :invented, on: self
  InjectedLogger.after_injection do |l| l.prefix = '[injected-rubylogger]' end
end

class C < Messaging
  include IL
end

require 'logger'
InjectedLogger.inject Logger.new(STDERR), prefix: '[prefix]', levels: [:invented], on: IL

test A
test B
test C
test A
test B
test C

