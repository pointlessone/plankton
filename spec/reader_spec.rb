require 'spec_helper'

describe Plankton::Reader do
  it "Should parse minimal PDF file" do
    reader = Plankton::Reader.new File.expand_path('../data/minimal.pdf', __FILE__)
    doc = reader.document

    expect(doc.objects.length).to eq(4)
  end

  it "Should parse minimal compliant PDF file" do
    reader = Plankton::Reader.new File.expand_path('../data/minimal-compliant.pdf', __FILE__)
    doc = reader.document

    expect(doc.objects.length).to eq(4)
  end

  it "Should parse minimal compliant PDF file with updates" do
    reader = Plankton::Reader.new File.expand_path('../data/minimal-compliant-update.pdf', __FILE__)
    doc = reader.document

    expect(doc.objects.length).to eq(5)
  end

  it "Should parse PDF 1.7 refernce file", :slow do
    reader = Plankton::Reader.new File.expand_path('../data/pdf_reference_1-7.pdf', __FILE__)
    doc = reader.document

    # FIXME this should also include objects in object streams
    expect(doc.objects.length).to eq(334092)
  end

  context 'values' do
    let(:objects) { Plankton::Reader.new(File.expand_path('../data/objects.pdf', __FILE__)).document.objects }

    example "There should be 49 of them" do
      expect(objects.length).to eq(49)
    end

    [
      true,
      false,
      123,
      43445,
      17,
      -98,
      0,
      34.5,
      -3.62,
      123.6,
      4.0,
      -0.002,
      0.0,
      "This is a string",
      "Strings may contain newlines\nand such.",
      "Strings may contain balanced parentheses ( ) and special characters (*!&}^% and so on).",
      "Unbalanced parentheses must be escaped ( ",
      "The following is an empty string.",
      "",
      "It has zero (0) length.",
      "These two strings are the same.",
      "These two strings are the same.",
      "This string has an end−of−line at the end of it.\n",
      "So does this one.\n",
      "This string contains \xA5two octal characters\xC7.",
      "\x053",
      "+",
      "+",
      "Nov shmoz ka pop.",
      "\x90\x1F\xA3",
      "\x90\x1F\xA0",
      :Name1,
      :ASomewhatLongerName,
      :"A;Name_With−Various***Characters?",
      :"1.2",
      :$$,
      :@pattern,
      :".notdef",
      :"",
      :"Adobe Green",
      :"PANTONE 5757 CV",
      :"paired()parentheses",
      :"The_Key_of_F#_Minor",
      :AB,
      [549, 3.14, false, "Ralph", :SomeName],
      [[1], 2, [3, [4]]],
      {
        Type: :Example,
        Subtype: :DictionaryExample,
        Version: 0.01,
        IntegerItem: 12,
        StringItem: "a string",
        Subdictionary: {
          Item1: 0.4,
          Item2: true,
          LastItem: 'not!',
          VeryLastItem: 'OK',
        }
      },
      [Plankton::Reference.new(nil, 46, 0)]
    ].each_with_index do |object, n|
      example "Object #{n} must be #{object.inspect}" do
        expect(objects[n + 1].value).to eq(object)
      end
    end

    example "Object 49 must be a stream of '1234567890'" do
      expect(objects[49].value).to eq({Length: 10})
      expect(objects[49].stream).to eq('1234567890')
    end
  end

  describe '#object' do
    def object(value)
      io = StringIO.new <<-PDF.strip
%PDF-1.0
1 0 obj
#{value}
endobj
xref
0 2
0000000000 65535 f 
0000000009 00000 n 
trailer
<<
  /Size 4
  /Root 1 0 R
>>
startxref
#{25 + value.length}
%%EOF
PDF

      objects = Plankton::Reader.new(io).document.objects
      objects[1, 0]
    end

    it "returns true for true" do
      expect(object('true').value).to eq(true)
    end

    it "returns empty hash for <<>>" do
      expect(object('<<>>').value).to eq({})
    end
  end
end
