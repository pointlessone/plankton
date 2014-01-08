require 'spec_helper'

describe Plankton::Writer do #, focus: true do
  it "serializes objects document" do
    reader = Plankton::Reader.new File.expand_path('../data/objects.pdf', __FILE__)
    doc = reader.document

    Plankton::Writer.new(doc).serialize
  end

  it "must successfully serialize updated pdf" do
    reader = Plankton::Reader.new File.expand_path('../data/minimal-compliant-update.pdf', __FILE__)
    doc = reader.document

    Plankton::Writer.new(doc).serialize
  end

  it "must successfully serialize PDF 1.7 spec", slow: true do
    reader = Plankton::Reader.new File.expand_path('../data/pdf_reference_1-7.pdf', __FILE__)
    doc = reader.document

    Plankton::Writer.new(doc).serialize
  end
end
