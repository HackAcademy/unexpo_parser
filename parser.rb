#! /usr/local/bin/ruby
# encoding: utf-8

class String
  def string_between_markers marker1, marker2
    self[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
  end

  def string_from_marker marker1
    self[/#{Regexp.escape(marker1)}(.*?)/m, 1]
  end
end

class Category
  attr_accessor :name
end

class Book
  attr_accessor :title, :subtitle, :category, :author, :editorial

  def parse_title hash_title
    @title = hash_title.string_between_markers '^a','^b'
    @subtitle = hash_title.string_from_marker '^b'
  end
end

class Author
  attr_accessor :name, :last_name
end

class Library
  attr_accessor :books
end

class Parser
  attr_accessor :library_hash

  def initialize
    @library_hash = []
  end

  def populate_hash line, hash_book
    key = line.string_between_markers('<','>')
    value = line.string_between_markers('>','<')
    hash_book[key] = value

    hash_book
  end

  def start
    hash_book = {}

    File.open('library.bak', 'r', :encoding => "UTF-8") do |file|
      while line = file.gets
        line = line.chomp
        unless line == '##' || line[0..2] == 'Mfn'
          unless line == ''
            hash_book = populate_hash line, hash_book
          else
            @library_hash.push hash_book
            hash_book = {}
          end
        end
      end
    end
  end
end

def main
  parser = Parser.new
  parser.start

  library = Library.new
  library.books = []

  parser.library_hash.each do |hash_book|
    book = Book.new
    hash_book.each do |key,value|
      case key
        when '650'
          category = Category.new
          category.name = value
          book.category = category
        when '100'
          author = Author.new
          author.name = value
          book.author = author
        when '245'
          book.parse_title value
        when '260'
          book.editorial = value
      end
    end
    library.books.push book
  end

  puts library.books[0].subtitle
  #library.save
end

main()
