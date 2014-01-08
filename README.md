# Plankton

Plankton deals with PDF files. It can read them. It understands all the basic
objects. And it can write them.

## Installation

Add this line to your application's Gemfile:

    gem 'plankton'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install plankton

## Usage

Read a file:

```ruby
reader = Plankton::Reader.new "document.pdf"
document = reader.document
```

Or create a document:

```ruby
document = Plankton::Document.new
```

Create a PDF object:

```ruby
object = Plankton::Object.new(42)
```

Add the object to the document:

```ruby
document.objects << object
```

Write the document to a file

```ruby
writer = Plankton::Writer.new(document)
File.binwrite "new-document.pdf", writer.serialize
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

[MIT](LICENSE)
