module Plankton
  class Reference
    attr_reader :number, :generation

    def initialize(object_store, number, generation)
      @object_store = object_store
      @number = number
      @generation = generation
    end

    def object
      @object_store[number, generation]
    end

    def ==(other)
      other.is_a?(self.class) && other.number == self.number && other.generation == self.generation
    end

    # Deleage some basic methods to the object.
    # This allows using references wherever objects can be used.

    def value
      object.value
    end

    def value=(val)
      object.value = val
    end

    def stream
      object.stream
    end

    def stream=(val)
      object.stream = val
    end

    def free?
      object.free?
    end

    def free!
      object.free!
    end
  end
end
