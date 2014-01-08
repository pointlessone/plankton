module Plankton
  class Object
    def initialize(value, number = nil, generation = nil)
      @value = value
      @number = number
      @generation = generation
      @free = false
    end

    attr_accessor :value, :stream

    def free!
      @free = true
    end

    def free?
      @free
    end
  end
end
