require 'plankton/object'
require 'plankton/reference'

module Plankton
  class ObjectStore
    include Enumerable

    MAX_GENERATION = 0xFFFF

    def initialize
      @objects = {}
    end

    def [](number, generation = nil)
      h = @objects[number] || {}
      if generation
        h[generation]
      else
        h[h.keys.last]
      end
    end

    def []=(number, object_or_generation, object = nil)
      return nil if number == 0 # 0 is reserved

      h = @objects[number] || {}

      if object
        generation = object_or_generation
      else
        generation = if h.empty?
                       0
                       else
                         if h[h.keys.last].free?
                           h.keys.last
                         else
                           h.keys.last + 1
                         end
                       end
        object = object_or_generation
      end

      if generation > MAX_GENERATION
        raise ArgumentError.new("Object generation can not be greater than #{MAX_GENERATION}: #{generation}")
      end

      # Free all younger generations objects
      h.each_pair do |g, obj|
        if g < generation
          obj.free!
        end
      end

      h[generation] = object
      @objects[number] = Hash[h.sort]

      object
    end

    def add(object)
      self[first_free_number] = object
    end
    alias_method :<<, :add


    def each
      @objects.each do |number, hash|
        generation = hash.keys.last
        object = hash[generation]
        yield object, number, generation
      end
    end

    def length
      @objects.length
    end

    def ref(number_or_object, generation = nil)
      if number_or_object.is_a? Plankton::Object
        @objects.each do |n, hash|
          hash.each do |gen, obj|
            if obj == number_or_object
              return Reference.new(self, n, gen)
            end
          end
        end
      else
        if number_or_object <= 0
          raise ArgumentError.new("Object number must greater than 0")
        end
        if generation.nil?
          #raise ArgumentError.new("You must supply generation if you pass in object number")
          generation = @objects[number_or_object].keys.last
        else
          if generation < 0
            raise ArgumentError.new("Generation must not be negative")
          end
          if generation > MAX_GENERATION
            raise ArgumentError.new("Generation must not be greater than #{MAX_GENERATION}")
          end
        end

        Reference.new(self, number_or_object, generation)
      end
    end

    private

    def first_free_number
      n = nil
      @objects.each do |k, v|
        if v.values.last.free? && v.keys.last < MAX_GENERATION
          n = k
          break
        end
      end
      n || (@objects.keys.max || 0) + 1
    end
  end
end
