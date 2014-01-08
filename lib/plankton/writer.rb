module Plankton
  class Writer
    def initialize(document)
      @document = document
    end

    def serialize
      objects = @document.objects
      document_stream = "%PDF-#{@document.version}\n%\xff\xff\xff\xff\n".force_encoding(Encoding::ASCII_8BIT)
      xref_stream = ''.force_encoding(Encoding::ASCII_8BIT)

      xref_subsections = [[]]
      last_n = nil
      objects.each do |obj, n, _|
        if last_n && n != last_n + 1 && xref_subsections.last.any?
          xref_subsections << []
        end

        xref_subsections.last << n
        last_n = n
      end


      xref_subsections.each_with_index do |subsection, i|
        if i == 0
          if subsection.first == 1
            xref_stream << "0 #{subsection.length + 1}\n"
          else
            xref_stream << "0 1\n"
          end
          xref_stream << xref_entry(next_free_number(0), ObjectStore::MAX_GENERATION, true) << "\n"
        else
          xref_stream << "#{subsection.first} #{subsection.length}\n"
        end


        subsection.each do |n|
          ref = objects.ref(n)

          if ref.free?
            xref_stream << xref_entry(next_free_number(n), ref.generation, true) << "\n"
          else
            gen = ref.generation

            address = document_stream.length
            xref_stream << xref_entry(address, gen, false) << "\n"

            serialized_object = indirect_object(ref, n, gen)
            document_stream << serialized_object << "\n"
          end
        end
      end

      xref_location = document_stream.length

      document_stream << "xref\n" << xref_stream

      trailer = dictionary({
        Size: xref_subsections.map(&:length).inject(:+),
        Root: @document.root
      })

      document_stream << "trailer\n" << trailer << "\n"

      document_stream << "startxref\n#{xref_location}\n%%EOF\n"

      document_stream
    end

    private

    def next_free_number(start)
      number = nil
      @document.objects.each do |obj, n, gen|
        if n > start && obj.free?
          number = n
          break
        end
      end
      number
    end

    def xref_entry(address, generation, free)
      "#{address.to_s.rjust 10, '0'} #{generation.to_s.rjust 5, '0'} #{free ? 'f' : 'n'} "
    end

    def indirect_object(obj, number, generation)
      stream = if obj.stream
                 "stream\n#{obj.stream}\nendstream\n"
               else
                 ''
               end

      "#{number} #{generation} obj\n#{object obj.value}\n#{stream}endobj"
    end

    def object(obj)
      case obj
      when Hash
        dictionary(obj)
      when NilClass
        "null"
      when TrueClass
        "true"
      when FalseClass
        "false"
      when Fixnum
        obj.to_s
      when Float
        obj.to_s
      when String
        ls = literal_string(obj)
        hs = hex_string(obj)

        # take the shorter one
        ls.length < hs.length ? ls : hs
      when Symbol
        name(obj)
      when Array
        array(obj)
      when Reference
        reference(obj)
      else
        obj.class.name
      end
    end

    def literal_string(string)
      str = string.dup.force_encoding(Encoding::ASCII_8BIT)

      special_escapes = {9 => '\t', 10 => '\n', 12 => '\f', 13 => '\r'}
      literals = (0x20...0x7F).to_a - [0x28, 0x29] # printable charactes except for '(' and ')'

      opening_parentheses = str.gsub(/[^(]/, '').length
      closing_parentheses = str.gsub(/[^)]/, '').length
      unbalanced_parentheses = (opening_parentheses - closing_parentheses).abs
      balanced_parentheses = [opening_parentheses, closing_parentheses].max - unbalanced_parentheses
      opening_parentheses -= balanced_parentheses
      closing_parentheses -= balanced_parentheses

      "(#{str.bytes.map do |b|
        if literals.include? b
          b.chr
        elsif special_escapes.keys.include? b
          special_escapes[b]
        elsif b == 0x28 # '('
          if opening_parentheses > 0
            opening_parentheses -= 1
            '\('
          else
            '('
          end
        elsif b == 0x29 # ')'
          if closing_parentheses > 0
            closing_parentheses -= 1
            '\)'
          else
            ')'
          end
        else
          "\\#{b.to_s(8).rjust(3, '0')}"
        end
      end.join ''})"
    end

    def hex_string(string)
      hex = string.bytes.map do |b|
        b.to_s(16).rjust(2, '0')
      end.join('').gsub(/0\z/, '')

      "<#{hex}>"
    end

    def name(obj)
      str = obj.to_s.force_encoding(Encoding::ASCII_8BIT)

      literals = (33..126).to_a - [35, 40, 41, 60, 62] # printable chars except for #, (, ), <, >

      '/' + str.bytes.map do |b|
        if literals.include? b
          b.chr
        else
          "##{b.to_s(16).rjust(2, '0')}"
        end
      end.join('')
    end

    def array(obj)
      "[#{ obj.map { |o| object(o) }.join(' ') }]"
    end

    def dictionary(obj)
      "<<\n#{obj.map do |k, v|
        [
          name(k),
          object(v)
        ].join(' ')
      end.join("\n")}\n>>"
    end

    def reference(obj)
      "#{obj.number} #{obj.generation} R"
    end
  end
end
