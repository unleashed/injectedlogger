require 'injectedlogger'

module L
  InjectedLogger.use(:info, :debug, :invented) {}
  InjectedLogger.after_injection do |l| l.prefix = '[ruby-logger]' end
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
