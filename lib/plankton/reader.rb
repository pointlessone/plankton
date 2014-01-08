require 'strscan'

module Plankton
  class Reader

    def initialize(path_or_io)
      read_data(path_or_io)

      @scanner = StringScanner.new(@string)
      @document = Document.new


      @end_of_document = false

      parse
    end

    attr_reader :document


    private

    def read_data(path_or_io)
      if path_or_io.is_a?(IO) || (defined?(IO::Readable) && path_or_io.is_a?(IO::Readable))
        path_or_io.rewind
        path_or_io.binmode
        @string = path_or_io.read
      else
        #File.open(path_or_io, 'rb') do |f|
        #  @string = f.read
        #end
        @string = File.binread(path_or_io)
      end
      @string.force_encoding Encoding::ASCII_8BIT
    end

    def parse
      check_for_pdf

      parse_document_section(find_entry_xref)
    end

    def check_for_pdf
      unless @string =~ /\A%PDF-\d+\.\d+/
        raise "Not a PDF file or file is damaged"
      else
        version = @string.match(/\A%PDF-(\d+\.\d+)/)[1]
        @document.version = version
      end
    end

    def parse_document_section(xref_location)
      trailer = parse_trailer(find_trailer(xref_location))

      if trailer[:Prev]
        parse_document_section(trailer[:Prev])
      end
      if trailer[:Root]
        @document.root = trailer[:Root]
      end

      parse_xref(xref_location)
    end


    def find_entry_xref
      doc_end = @string.rindex("\n%%EOF")
      s = scanner(@string.rindex('startxref', doc_end))
      s.scan(/startxref/)
      eat_whitespaces(s)
      s.scan(/\d+/).to_i
    end

    def parse_xref(location)
      s = scanner(location)
      s.scan(/xref/)
      eat_whitespaces(s)

      subsection_re = /\d+ \d+#{EOL_MARKER}*/
      entry_re = /\d{10} \d{5} [nf][ \n\r]{2}/
      loop do
        subsection_header = s.scan(subsection_re)
        eat_whitespaces(s)
        if subsection_header
          base, n = subsection_header.split(' ').map{ |i| i.strip.to_i }
          n.times do |i|
            if s.scan(entry_re)
              entry = s.matched.strip.split(' ')
            else
              raise "Malformed PDF: invalid xref entry @ #{s.pos}: #{@string[s.pos..(s.pos + 20)].inspect}"
            end

            generation = entry[1].to_i
            if entry[2] == 'n'
              address = entry[0].to_i
              @scanner.pos = address
              obj = indirect_object
              @document.objects[base + i, generation] = obj
            else
              unless @document.objects[base + i, generation]
                obj = Plankton::Object.new(nil)
                @document.objects[base + i, generation] = obj
              end
              @document.objects[base + i, generation].free! unless base + i == 0
            end
          end
        else
          break
        end
      end
    end

    def find_trailer(xref_location)
      trailer_location = @string.index('trailer', xref_location)
      raise "Malformed PDF: no triler found after xref table @ #{xref_location}" unless trailer_location

      s = scanner(trailer_location)
      s.scan(/trailer/)
      eat_whitespaces(s)
      s.pos
    end

    def parse_trailer(location)
      pos = @scanner.pos
      @scanner.pos = location
      dictionary
    ensure
      @scanner.pos = pos
    end

    def scanner(location = 0)
      StringScanner.new(@string).tap { |s| s.pos = location }
    end

    def ruby_value(value)
      if value == TrueClass
        true
      elsif value == FalseClass
        false
      elsif value == NilClass
        nil
      else
        value
      end
    end


    ################################################

    # Character classes

    WHITE_SPACE = /[\000\011\012\014\015\040]/

    EOL_MARKER = /\r|\n|\r\n/

    # Tokens

    def boolean
      if @scanner.scan(/true|false/)
        if @scanner.matched == 'true'
          TrueClass
        else
          FalseClass
        end
      end
    end

    def integer
      if @scanner.scan(/[+-]?\d+/)
        @scanner.matched.to_i
      end
    end

    def real
      if @scanner.scan(/[+-]?(\d+\.\d*|\.\d+)/)
        @scanner.matched.to_f
      end
    end

    def number
      real || integer
    end

    def literal_string
      if @scanner.check(/\(/)
        paren_level = 0
        str = ''.force_encoding(Encoding::ASCII_8BIT)
        loop do
          byte = @scanner.get_byte
          case byte
          when '('
            str << byte
            paren_level += 1
          when ')'
            str << byte
            paren_level -= 1
            break if paren_level == 0
          when '\\'
            if char = @scanner.scan(/[nrtbf()\\]/)
            #if char = @scanner.scan(/[nrtbf\\]/)
              str << {'n' => "\n", 'r' => "\r", 't' => "\t", 'b' => "\b", 'f' => "\f", '\\' => '\\', '(' => '(', ')' => ')'}[char]
            elsif oct = @scanner.scan(/[0-7]{1,3}/)
              str << oct.to_i(8)
            elsif @scanner.scan(EOL_MARKER)
              # eat EOL marker
            else
              # ignore \
            end
          else
            str << byte
          end
        end
        # Get rid of surrounding parentheses
        str[1...-1].force_encoding(Encoding::UTF_8)
      end
    end

    def hex_string
      if @scanner.scan(/<([0-9a-fA-F]+)>/)
        hex = @scanner.matched[1...-1]
        if hex.length.odd?
          hex << '0'
        end
        hex.scan(/../).map{ |h| h.to_i(16).chr }.join('').force_encoding(Encoding::UTF_8)
      end
    end

    def string
      literal_string || hex_string
    end

    def name
      if @scanner.scan(/\/[^\000\011\012\014\015\040()<>\[\]{}\/%]*/)
        str = @scanner.matched[1..-1]
        str.gsub(/#[0-9a-fA-F]{2}/) { |s| s[1..-1].to_i(16).chr }.force_encoding(Encoding::UTF_8).to_sym
      end
    end

    def null
      if @scanner.scan(/null/)
        NilClass
      end
    end

    def object
      boolean || number || string || name || array || dictionary || null or raise "Malformed PDF at #{@scanner.pos}: #{@string[@scanner.pos..(@scanner.pos + 30)].inspect}"
    end

    def reference
      if @scanner.scan(/\d+ \d+ R/)
        parts = @scanner.matched.split(' ', 2)
        n = parts[0].to_i
        gen = parts[1].to_i
        @document.objects.ref(n, gen)
      end
    end

    def array
      if @scanner.scan(/\[/)
        array = []
        loop do
          eat_whitespaces
          if @scanner.scan(/]/)
            break
          else
            array << ruby_value(reference || object)
          end
        end
        array
      end
    end

    def dictionary
      if @scanner.scan(/<</)
        dictionary = {}
        loop do
          eat_whitespaces
          if @scanner.scan(/#{WHITE_SPACE}*>>/)
            break
          else
            key = name
            eat_whitespaces
            value = reference || object
            dictionary[key] = ruby_value(value)
          end
        end
        dictionary
      end
    end

    def indirect_object
      if obj_header = @scanner.scan(/\d+ \d+ obj#{WHITE_SPACE}*/)
        obj_number, generation = obj_header.split(' ')
        obj = Plankton::Object.new(ruby_value(object))
        @document.objects[obj_number.to_i, generation.to_i] = obj

        if obj.value.is_a? Hash
          stream_length = obj.value[:Length]
          if stream_length
            eat_whitespaces
            obj.stream = stream(stream_length)
          end
        end

        eat_whitespaces
        @scanner.scan(/endobj#{EOL_MARKER}/)

        obj
      end
    end


    def stream(length)
      if @scanner.scan(/stream(\r?\n)/)
        data = @string[@scanner.pos...(@scanner.pos + length)]
        @scanner.pos += length
        @scanner.scan(/#{EOL_MARKER}?endstream/)
        eat_whitespaces
        data
      end
    end


    # Untility methods

    def eat_whitespaces(scanner = nil)
      (scanner || @scanner).scan(/(#{WHITE_SPACE}*(%.*#{EOL_MARKER})?)*/)
    end

  end
end
