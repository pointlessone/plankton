require 'spec_helper'

def pdf_object(value)
  Plankton::Object.new(value)
end

describe Plankton::ObjectStore do #, focus: true do
  let(:store) { Plankton::ObjectStore.new }

  it "add new objects" do
    store.add pdf_object(1)

    expect(store[1].value).to eq(1)
  end

  it "sets objects when assigned by number" do
    store[1] = pdf_object(1)

    expect(store[1].value).to eq(1)
  end

  it "sets objects when assigned by number without filling in lower free numbers" do
    store[10] = pdf_object(1)

    1.upto(9) do |n|
      expect(store[n]).to be_nil
    end

    expect(store[10].value).to eq(1)
  end

  it "return latest genertion of the object when accessed by number only" do
    store[1] = pdf_object(1)
    store[1] = o2 = pdf_object(2)

    expect(store[1]).to eq(o2)
  end

  it "return the right object when accessed by number and generation" do
    store[1] = o1 = pdf_object(1)
    store[1] = o2 = pdf_object(2)

    expect(store[1, 0]).to eq(o1)
    expect(store[1, 1]).to eq(o2)
  end

  it "frees previous generation object when assigned by number" do
    store[1] = pdf_object(1)
    store[1] = pdf_object(2)

    expect(store[1, 0]).to be_free
  end

  describe '#each' do
    it "yields object, number and generation" do
      o = pdf_object(1)
      store << o

      store.each do |obj, n, gen|
        expect(obj).to eq(o)
        expect(n).to eq(1)
        expect(gen).to eq(0)
      end
    end

    it "yields only for existing objects" do
      store[3, 0] = pdf_object(1)
      store[10, 0] = pdf_object(2)

      numbers = []
      store.each do |obj, n, gen|
        numbers << n
      end

      expect(numbers).to eq([3, 10])
    end
  end
end
