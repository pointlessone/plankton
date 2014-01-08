require 'spec_helper'

describe Plankton::Reference do
  let(:objects) { Plankton::ObjectStore.new }
  describe "ObjectStore#ref" do
    it "returns Reference instance" do
      ref = objects.ref 1, 0
      expect(ref).to be_an_instance_of(Plankton::Reference)
      expect(ref.number).to eq(1)
      expect(ref.generation).to eq(0)
    end

    it "returns refernce to an object given number and generation" do
      obj = Plankton::Object.new(true)
      objects[2, 0] = obj

      ref = objects.ref(2, 0)
      expect(ref.number).to eq(2)
      expect(ref.generation).to eq(0)
      expect(ref.object).to eq(obj)
    end

    it "returns refernce to an object given the object" do
      obj = Plankton::Object.new(true)
      objects[2, 0] = obj

      ref = objects.ref(obj)
      expect(ref.number).to eq(2)
      expect(ref.generation).to eq(0)
    end
  end

  context "construction" do
    it "can be constructed with an object store, number and generation" do
      ref = Plankton::Reference.new(objects, 1, 0)

      expect(ref.number).to eq(1)
      expect(ref.generation).to eq(0)
    end
  end

  context "delegation" do
    let(:obj) { Plankton::Object.new(1).tap { |o| o.stream = "stream" } }
    let(:ref) { objects.ref(1, 0) }
    before(:each) { objects[1, 0] = obj }

    example "#value must delegate to the object" do
      expect(ref.value).to eq(obj.value)
    end

    example "#value= must delegate to the object" do
      ref.value = 2

      expect(ref.value).to eq(obj.value)
      expect(obj.value).to eq(2)
    end

    example "#stream must delegate to the object" do
      expect(ref.stream).to eq(obj.stream)
    end

    example "#stream= must delegate to the object" do
      ref.stream = "another stream"

      expect(ref.stream).to eq(obj.stream)
      expect(obj.stream).to eq("another stream")
    end

    example "#free? must delegate to the object" do
      expect(ref.free?).to be_false
      obj.free!
      expect(ref.free?).to be_true
    end

    example "#free! must delegate to the object" do
      expect(obj.free?).to be_false
      ref.free!
      expect(obj.free?).to be_true
    end
  end
end
