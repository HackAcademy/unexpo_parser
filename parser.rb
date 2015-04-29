#! /usr/local/bin/ruby
# encoding: utf-8

class String
  def string_between_markers marker1, marker2
    self[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
  end

  def string_from_marker marker
    if self.index(marker).nil?
      self[0,self.length]
    else
      self[self.index(marker)+2, self.length]
    end
  end

  def splitparse_by_markers *markers
    regexpstring = '\^['
    markers.each do |m|
      regexpstring << "#{Regexp.escape(m)}" 
    end
    regexpstring << ']{1}'
    self.split(/#{regexpstring}/)
  end
end

class Category
  attr_accessor :name

  def parse_category hash_category
    @name = hash_category.string_from_marker '^a'
  end
end

class Book
  attr_accessor :title, :subtitle, :categories, :authors, :editorial, :callnumber, :isbn, :pubtype, :dimensions

  def parse_title hash_title
    @title = hash_title.string_between_markers '^a','^b'
    @subtitle = hash_title.string_from_marker '^b'
  end

  def parse_isbn hash_isbn
    @isbn = hash_isbn.string_from_marker '^a'
  end

  def parse_pubtype hash_pubtype
    @pubtype = hash_pubtype.string_from_marker '^a'
  end

  def parse_editorial hash_editorial
    @editorial = hash_editorial.splitparse_by_markers 'a', 'b', 'c'
    @editorial.shift
    @editorial = @editorial.join(', ')
  end

  def parse_call hash_call
    @callnumber = hash_call.splitparse_by_markers 'a', 'b'
    @callnumber.shift
    @callnumber = @callnumber.join(', ')
  end

  def parse_dimensions hash_dimensions
    @dimensions = hash_dimensions.splitparse_by_markers('a', 'b', 'c')
    @dimensions.shift
    @dimensions = @dimensions.join(', ')
  end
end

class Author
  attr_accessor :name

  def parse_author hash_author
    @name = hash_author.string_from_marker '^a'
  end
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
    book.authors = []
    book.categories= []
    hash_book.each do |key,value|
      case key
        when '650'
          category = Category.new
          category.parse_category value
          book.categories.push category
        when '100'
          author = Author.new
          author.parse_author value
          book.authors.insert(0,author)
        when '700'
          author = Author.new
          author.parse_author value
          book.authors.push author
        when '245'
          book.parse_title value
        when '260'
          book.parse_editorial value
        when '82'
          book.parse_call value
        when '20'
          book.parse_isbn value
        when '842'
          book.parse_pubtype value 
        when '300'
          book.parse_dimensions value
      end
    end
    library.books.push book
  end

  # puts parser.library_hash[0].inspect
  
  puts library.books[0].inspect
  #library.save
end

main()
