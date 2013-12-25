
require 'muack/test'

describe Muack::AnyInstanceOf do
  klass = Class.new{ def f; 0; end; private; def g; 1; end }

  should 'mock any_instance_of' do
    any_instance_of(klass){ |inst| mock(inst).say{ true } }
    obj = klass.new
    obj.say              .should.eq true
    obj.respond_to?(:say).should.eq true
    Muack.verify         .should.eq true
    obj.respond_to?(:say).should.eq false
  end

  should 'mock any_instance_of with instance_exec' do
    any_instance_of(klass){ |inst|
      mock(inst).say.returns(:instance_exec => true){ f } }
    obj = klass.new
    obj.say              .should.eq obj.f
    Muack.verify         .should.eq true
    obj.respond_to?(:say).should.eq false
  end

  should 'proxy any_instance_of' do
    any_instance_of(klass){ |inst| mock(inst).f }
    obj = klass.new
    obj.f       .should.eq 0
    Muack.verify.should.eq true
    obj.f       .should.eq 0
  end

  should 'proxy any_instance_of for private methods' do
    any_instance_of(klass){ |inst| mock(inst).g.peek_return{|i|i+1} }
    obj = klass.new
    obj.__send__(:g).should.eq 2
    Muack.verify    .should.eq true
    obj.__send__(:g).should.eq 1
  end

  should 'proxy any_instance_of with peek_return' do
    any_instance_of(klass){ |inst| mock(inst).f.peek_return{|i|i+1} }
    obj = klass.new
    obj.f       .should.eq 1
    Muack.verify.should.eq true
    obj.f       .should.eq 0
  end

  should 'proxy with multiple any_instance_of call' do
    any_instance_of(klass){ |inst| mock(inst).f.peek_return{ |i| i+1 } }
    any_instance_of(klass){ |inst| mock(inst).f.peek_return{ |i| i+2 } }
    obj = klass.new
    obj.f.should.eq 1
    obj.f.should.eq 2
    Muack.verify.should.eq true
    obj.f.should.eq 0
  end

  should 'mock with multiple any_instance_of call' do
    any_instance_of(klass){ |inst| mock(inst).f(is_a(Fixnum)){ |i| i+1 } }
    any_instance_of(klass){ |inst| mock(inst).f(is_a(Fixnum)){ |i| i+2 } }
    obj = klass.new
    obj.f(2).should.eq 3
    obj.f(2).should.eq 4
    Muack.verify.should.eq true
    obj.f.should.eq 0
  end

  should 'stub proxy with any_instance_of and spy' do
    any_instance_of(klass){ |inst| stub(inst).f.peek_return{ |i| i+3 } }
    obj = klass.new
    obj.f.should.eq 3
    obj.f.should.eq 3
    spy(any_instance_of(klass)).f.times(2)
    Muack.verify.should.eq true
    obj.f.should.eq 0
  end

  should 'stub with any_instance_of and spy under satisfied' do
    any_instance_of(klass){ |inst| stub(inst).f{ 5 } }
    obj = klass.new
    obj.f.should.eq 5
    spy(any_instance_of(klass)).f.times(2)
    begin
      Muack.verify
    rescue Muack::Expected => e
      expected = /Muack::API\.any_instance_of\(.+?\)\.f\(\)/
      e.expected      .should =~ expected
      e.expected_times.should.eq 2
      e.actual_times  .should.eq 1
    end
    obj.f.should.eq 0
  end

  should 'stub with any_instance_of and spy over satisfied' do
    any_instance_of(klass){ |inst| stub(inst).f{ 2 } }
    obj = klass.new
    2.times{ obj.f.should.eq 2 }
    spy(any_instance_of(klass)).f
    begin
      Muack.verify
    rescue Muack::Expected => e
      expected = /Muack::API\.any_instance_of\(.+?\)\.f\(\)/
      e.expected      .should =~ expected
      e.expected_times.should.eq 1
      e.actual_times  .should.eq 2
    end
    obj.f.should.eq 0
  end
end
