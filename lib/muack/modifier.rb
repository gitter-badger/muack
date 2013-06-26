
require 'muack/error'

module Muack
  class Modifier < Struct.new(:mock, :defi)
    # Public API
    def with_any_args
      defi.args = [WithAnyArgs]
      self
    end

    # Public API
    def returns val=nil, &block
      defi.block = block || lambda{ val }
    end

    # Public API
    def proxy
      defi.proxy = true
    end

    # Public API
    def times number
      if mock.__mock_class == Stub
        raise StubHasNoTimes.new(object, defi, number)
      end

      if number >= 1
        (number - 1).times{ mock.__mock_defis_push(defi) }
      elsif number == 0
        mock.__mock_defis_pop(defi)
      else
        raise "What would you expect from calling a method #{number} times?"
      end
      self
    end

    # Public API
    def object
      mock.object
    end
  end
end
