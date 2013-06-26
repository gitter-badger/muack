
require 'muack/mock'

module Muack
  class Stub < Mock
    # used for Muack::Session#verify
    def __mock_verify; true; end

    # used for mocked object to dispatch mocked method
    def __mock_dispatch msg, actual_args
      __mock_defis[msg].find{ |d| __mock_check_args(d.args, actual_args) } ||
        Mock.__send__(:raise, # Wrong argument
          Unexpected.new(object, __mock_defis[msg], msg, actual_args))
    end
  end
end
