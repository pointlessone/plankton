require 'plankton/object_store'

module Plankton
  class Document
    attr_accessor :version
    attr_reader :objects
    attr_accessor :root

    def initialize
      @version = '1.0'
      @objects = ObjectStore.new
    end
  end
end
