
require 'muack/definition'
require 'muack/modifier'
require 'muack/failure'

module Muack
  class Mock < BasicObject
    attr_reader :object
    def initialize object
      @object = object
      @__mock_ignore = []
      [:__mock_defis=, :__mock_disps=].each do |m|
        __send__(m, ::Hash.new{ |h, k| h[k] = [] })
      end
    end

    # Public API: Bacon needs this, or we often ended up with stack overflow
    def inspect
      "#<#{class << self; self; end.superclass} object=#{object.inspect}>"
    end

    # Public API: Define mocked method
    def with msg, *args, &block
      defi = Definition.new(msg, args, block)
      __mock_inject_method(defi) if __mock_pure?(defi)
      __mock_defis_push(defi)
      Modifier.new(self, defi)
    end

    # Public API: Define mocked method, the convenient way
    alias_method :method_missing, :with

    # used for Muack::Modifier#times
    def __mock_defis_push defi
      __mock_defis[defi.msg] << defi
    end

    # used for Muack::Modifier#times
    def __mock_defis_pop defi
      __mock_defis[defi.msg].pop
    end

    # used for Muack::Modifier#times
    def __mock_ignore defi
      @__mock_ignore << defi
    end

    # used for mocked object to dispatch mocked method
    def __mock_dispatch msg, actual_args, actual_block
      if defi = __mock_defis[msg].shift
        __mock_disps_push(defi)
        if __mock_check_args(defi.args, actual_args)
          __mock_block_call(defi, actual_args)
        else
          Mock.__send__(:raise, # Wrong argument
            Unexpected.new(object, [defi], msg, actual_args))
        end
      else
        defis = __mock_disps[msg]
        if expected_defi = defis.find{ |d| d.args == actual_args }
          Mock.__send__(:raise, # Too many times
            Expected.new(object, expected_defi, defis.size, defis.size+1))
        else
          Mock.__send__(:raise, # Wrong argument
            Unexpected.new(object, defis, msg, actual_args))
        end
      end
    end

    # used for Muack::Session#verify
    def __mock_verify
      __mock_defis.values.all?(&:empty?) || begin
        msg, defis_with_same_msg = __mock_defis.find{ |_, v| v.size > 0 }
        args, defis = defis_with_same_msg.group_by(&:args).first
        dsize = __mock_disps[msg].select{ |d| d.args == args }.size
        Mock.__send__(:raise,   # Too little times
          Expected.new(object, defis.first, defis.size + dsize, dsize))
      end
    end

    # used for Muack::Session#reset
    def __mock_reset
      [__mock_defis.values, __mock_disps.values, @__mock_ignore].
      flatten.compact.each do |defi|
        object.singleton_class.module_eval do
          methods = instance_methods(false)
          if methods.include?(defi.msg) # removed mocked method
            remove_method(defi.msg)     # could be removed by other defi
          end
          if methods.include?(defi.original_method) # restore original method
            alias_method defi.msg, defi.original_method
            remove_method defi.original_method
          end
        end
      end
    end

    protected # get warnings for private attributes
    attr_accessor :__mock_defis, :__mock_disps

    private
    def __mock_pure? defi
      __mock_defis[defi.msg].empty? && __mock_disps[defi.msg].empty?
    end

    def __mock_inject_method defi
      mock = self # remember the context

      object.singleton_class.module_eval do
        if instance_methods(false).include?(defi.msg)
          # store original method
          original_method = Mock.find_new_name(self, defi.msg)
          alias_method original_method, defi.msg
          defi.original_method = original_method
        end

        # define mocked method
        define_method defi.msg do |*actual_args, &actual_block|
          mock.__mock_dispatch(defi.msg, actual_args, actual_block)
        end
      end
    end

    def self.find_new_name klass, message, level=0
      raise "Cannot find a suitable method name, tried #{level+1} times." if
        level >= 9

      new_name = "__muack_mock_#{level}_#{message}".to_sym
      if klass.instance_methods(false).include?(new_name)
        find_new_name(klass, message, level+1)
      else
        new_name
      end
    end

    def __mock_block_call defi, actual_args
      if block = defi.block
        arity = block.arity
        if arity < 0
          block.call(*actual_args)
        else
          block.call(*actual_args.first(arity))
        end
      end
    end

    def __mock_check_args expected_args, actual_args
      if expected_args == [WithAnyArgs]
        true
      elsif expected_args.none?{ |arg| arg.kind_of?(Satisfy) }
        expected_args == actual_args

      elsif expected_args.size == actual_args.size
        expected_args.zip(actual_args).all?{ |(e, a)|
          if e.kind_of?(Satisfy) then e.match(a) else e == a end
        }
      else
        false
      end
    end

    # used for Muack::Mock#__mock_dispatch
    def __mock_disps_push defi
      __mock_disps[defi.msg] << defi
    end
  end
end
