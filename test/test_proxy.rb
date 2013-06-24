
require 'muack/test'

describe Muack::Proxy do
  describe 'Muack.verify==true' do
    after do
      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    should 'proxy with regular method' do
      proxy(Str).reverse
      Str.reverse.should.eq 'ooM'
    end

    should 'proxy multiple times' do
      2.times{ proxy(Str).reverse }
      2.times{ Str.reverse.should.eq 'ooM' }
    end

    should 'proxy multiple times with super method' do
      2.times{ proxy(Str).class }
      2.times{ Str.class.should.eq String }
    end

    should 'proxy and call the block' do
      proxy(Obj).with(:inspect){ |str| str.reverse }
      Obj.inspect.should.eq 'jbo'
    end

    should 'proxy and call the block with super' do
      proxy(Str).class{ |klass| klass.name.reverse  }
      Str.class.should.eq 'gnirtS'
    end

    should 'proxy and call, proxy and call' do
      proxy(Obj).inspect
      Obj.inspect.should.eq 'obj'
      proxy(Obj).inspect
      Obj.inspect.should.eq 'obj'
    end
  end

  describe 'Muack.verify==false' do
    after do
      Muack.reset
      Muack::EnsureReset.call
    end

    should 'raise Muack::Expected error if passing unexpected argument' do
      proxy(Str).reverse
      Str.reverse.should.eq 'ooM'
      begin
        Str.reverse
        'never'.should.eq 'reach'
      rescue Muack::Expected => e
        e.expected      .should.eq '"Moo".reverse()'
        e.expected_times.should.eq 1
        e.actual_times  .should.eq 2
        e.message       .should.eq "\nExpected: \"Moo\".reverse()\n  " \
                                   "called 1 times\n but was 2 times."
      end
    end
  end
end
