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

module IL2
  InjectedLogger.use :info, :debug, :invented, on: self
  raise unless IL2.respond_to? :inject
  InjectedLogger.after_injection do |l| l.prefix = '[injected-rubylogger-nodep]' end
end

class C < Messaging
  include IL
end

module NL
  InjectedLogger.use :info, :debug, :invented, as: 'core-log' do end
  InjectedLogger.after_injection on: 'core-log' do |l|
    l.info 'WORKS :)'
  end
end

class D < Messaging
  include NL
end

class E < Messaging
  include IL2
end

require 'logger'
l = Logger.new STDERR
InjectedLogger.inject l, prefix: '[prefix]', levels: [:invented], on: IL
InjectedLogger.inject l, prefix: '[prefix-as-name]', levels: [:invented], on: 'core-log'
IL2.inject l, prefix: '[prefix-nodep]', levels: [:invented]

test A
test B
test C
test A
test B
test C

test D
test E
