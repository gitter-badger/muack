
require 'muack/test'

describe Muack::Mock do
  describe 'Muack.verify==true' do
    after do
      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    would 'inspect' do
      mock(Obj).inspect.should.eq "Muack::API.mock(obj)"
    end

    would 'mock with regular method' do
      mock(Obj).say(true){ 'boo' }
      Obj.say(true).should.eq 'boo'
    end

    would 'mock existing method' do
      mock(Obj).to_s{ 'zoo' }
      Obj.to_s.should.eq 'zoo'
    end

    would 'pass the actual block' do
      mock(Obj).say{ |&block| block.call('Hi') }
      Obj.say{ |msg| msg }.should.eq 'Hi'
    end

    would 'pass multiple arguments' do
      mock(Obj).say{ |*args| args.reverse }.with_any_args
      Obj.say(0, 1).should.eq [1, 0]
    end

    would 'mock private method and preserve privacy' do
      mock(Obj).private{ 'sai' }
      Obj.respond_to?(:private      ).should.eq false
      Obj.respond_to?(:private, true).should.eq true
      Obj.__send__(:private).should.eq 'sai'
      Muack.verify.should.eq true
      Obj.respond_to?(:private      ).should.eq false
      Obj.__send__(:private).should.eq 'pri'
    end

    would 'mock twice' do
      mock(Obj).say(true){ Obj.saya }
      mock(Obj).saya{ 'coo' }
      Obj.say(true).should.eq 'coo'
    end

    would 'also mock with with' do
      mock(Str).method_missing(:say, 0){ 0 }
      Str.say(0).should.eq 0
      Muack.verify.should.eq true
      mock(Str).method_missing(:say, 1){ 1 }
      lambda{ Str.say(2) }.should.raise(Muack::Unexpected)
      Muack.reset
    end

    would 'mix mock and stub' do
      mock(Obj).say { 0 }
      stub(Obj).saya{ 1 }
      3.times{ Obj.saya.should.eq 1 }
               Obj.say .should.eq 0
    end

    would 'mix mock and stub with conflicting method, latter wins' do
      stub(Obj).say{0}
      mock(Obj).say{1}
      Obj.say.should.eq 1
    end

    would 'mix mock and stub with conflicting method, try to hit stub' do
      stub(Obj).say{0}
      mock(Obj).say{1}
      Obj.say.should.eq 1
      lambda{ Obj.say }.should.raise(Muack::Expected)
    end

    would 'mix mock and stub with conflicting method, mock never called' do
      mock(Obj).say{0}
      stub(Obj).say{1}
      Obj.say.should.eq 1
      lambda{ Muack.verify }.should.raise(Muack::Expected)
    end

    would 'unnamed mock' do
      mock.say{1}.object.say.should.eq 1
    end

    would 'mock and call, mock and call' do
      mock(Obj).say{0}
      Obj.say.should.eq 0
      mock(Obj).say{1}
      Obj.say.should.eq 1
    end

    would 'not remove original singleton method' do
      obj = Class.new{ def self.f; 0; end }
      2.times{ mock(obj).f{ 1 }  }
      2.times{ obj.f.should.eq 1 }
      Muack.verify.should.eq true
      obj.f       .should.eq 0
    end
  end

  describe 'Muack.verify==false' do
    after do
      Muack.reset
      Muack::EnsureReset.call
    end

    would 'raise Unexpected error if passing unexpected argument' do
      mock(Obj).say(true){ 'boo' }
      e = should.raise(Muack::Unexpected){ Obj.say(false) }
      e.expected.should.eq 'obj.say(true)'
      e.was     .should.eq 'obj.say(false)'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end

    would 'have correct message for multiple mocks with the same name' do
      2.times{ mock(Obj).say{} }
      e = should.raise(Muack::Expected){ 3.times{ Obj.say } }
      e.expected.should.eq 'obj.say()'
      e.expected_times.should.eq 2
      e.actual_times  .should.eq 3
      e.message       .should.eq "\nExpected: obj.say()\n  " \
                                 "called 2 times\n but was 3 times."
    end

    would 'have correct message for mocks with special satisfier' do
      mock(Obj).say(anything){}
      e = should.raise(Muack::Expected) do
        Obj.say(1)
        Obj.say(2)
      end
      expected = 'obj.say(Muack::API.anything())'
      e.expected.should.eq expected
      e.expected_times.should.eq 1
      e.actual_times  .should.eq 2
      e.message       .should.eq "\nExpected: #{expected}\n  " \
                                 "called 1 times\n but was 2 times."
    end

    would 'raise if a mock with times(0) gets called' do
      mock(Obj).say.times(0)
      e = should.raise(Muack::Unexpected){ Obj.say }
      e.expected.should.eq nil
      e.was     .should.eq 'obj.say()'
      e.message .should.eq "\nUnexpected call: #{e.was}"
    end

    would 'raise if a mock with times(0) gets called with diff sig' do
      mock(Obj).say.times(0)
      e = should.raise(Muack::Unexpected){ Obj.say(true) }
      e.expected.should.eq nil
      e.was     .should.eq 'obj.say(true)'
      e.message .should.eq "\nUnexpected call: #{e.was}"
    end

    would 'raise Unexpected when calling with diff sig' do
      mock(Obj).say(true){1}
      Obj.say(true).should.eq 1
      e = should.raise(Muack::Unexpected){ Obj.say }
      e.expected.should.eq 'obj.say(true)'
      e.was     .should.eq 'obj.say()'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end

    would 'raise Expected error if mock methods not called' do
      mock(Obj).say(true){ 'boo' }
      e = should.raise(Muack::Expected){ Muack.verify }
      e.expected      .should.eq 'obj.say(true)'
      e.expected_times.should.eq 1
      e.actual_times  .should.eq 0
      e.message       .should.eq "\nExpected: obj.say(true)\n  " \
                                 "called 1 times\n but was 0 times."
    end

    would 'show first not enough calls' do
      mock(Obj).say{ 'boo' }.times(2)
      mock(Obj).saya{}      .times(2)
      e = should.raise(Muack::Expected) do
        Obj.say
        Muack.verify
      end
      e.expected      .should.eq 'obj.say()'
      e.expected_times.should.eq 2
      e.actual_times  .should.eq 1
      e.message       .should.eq "\nExpected: obj.say()\n  " \
                                 "called 2 times\n but was 1 times."
    end
  end
end
