require 'injectedlogger'

module L
  InjectedLogger.use :info, :debug, :invented do
    require 'log4r'
    { logger: Log4r::Logger.new('test_log4r').tap { |l| l.outputters = Log4r::Outputter.stdout } }
  end
  InjectedLogger.after_injection do |l| l.prefix = '[log4r]' end
end

class A
  include L

  def msg(m)
    logger.info m
    logger.debug do m end
    logger.info 'arg' do 'block' end
    logger.invented 'invented arg'
    logger.invented do 'invented block' end
    logger.invented 'invented arg in arg and block' do 'invented block in arg and block' end
  end
end

def test
  a = A.new
  a.msg 'hola'
end

test
