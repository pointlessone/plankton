source 'https://rubygems.org'

# Specify your gem's dependencies in ..gemspec
gemspec

platforms :rbx do
  gem 'rubysl-strscan'
end

gem 'mutant'
gem 'ruby-lint'

group :development do
  platforms :rbx do
    gem 'racc'
    gem 'rubysl-singleton'
    gem 'rubysl-benchmark'
    gem 'rubysl-readline'
    gem 'rubinius-compiler'
    gem 'rubinius-debugger'
  end
end
