
require 'muack/test'

describe Muack::AnyInstanceOf do
  should 'mock any_instance_of' do
    klass = Class.new
    any_instance_of(klass){ |instance| mock(instance).say{ true } }
    obj = klass.new
    obj.say              .should.eq true
    obj.respond_to?(:say).should.eq true
    Muack.verify         .should.eq true
    obj.respond_to?(:say).should.eq false
  end

  should 'proxy any_instance_of' do
    klass = Class.new{ def f; true; end }
    any_instance_of(klass){ |instance| mock(instance).f.proxy }
    obj = klass.new
    obj.f       .should.eq true
    Muack.verify.should.eq true
    obj.f       .should.eq true
  end

  should 'proxy any_instance_of with a block' do
    klass = Class.new{ def f; 0; end }
    any_instance_of(klass){ |instance| mock(instance).f{ |i| i+1 }.proxy }
    obj = klass.new
    obj.f       .should.eq 1
    Muack.verify.should.eq true
    obj.f       .should.eq 0
  end

  should 'proxy with multiple any_instance_of call' do
    klass = Class.new{ def f; 0; end }
    any_instance_of(klass){ |instance| mock(instance).f{ |i| i+1 }.proxy }
    any_instance_of(klass){ |instance| mock(instance).f{ |i| i+2 }.proxy }
    obj = klass.new
    obj.f.should.eq 1
    obj.f.should.eq 2
    Muack.verify.should.eq true
    obj.f.should.eq 0
  end

  should 'mock with multiple any_instance_of call' do
    klass = Class.new{ def f; 0; end }
    any_instance_of(klass){ |inst| mock(inst).f(is_a(Fixnum)){ |i| i+1 } }
    any_instance_of(klass){ |inst| mock(inst).f(is_a(Fixnum)){ |i| i+2 } }
    obj = klass.new
    obj.f(0).should.eq 1
    obj.f(0).should.eq 2
    Muack.verify.should.eq true
    obj.f.should.eq 0
  end
end
