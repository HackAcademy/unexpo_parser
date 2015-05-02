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
    @name = hash_category.splitparse_by_markers 'a', 'n', 'x'
    @name.shift
    @name = @name.join(', ')
  end
end

class Publication
  attr_accessor :title, :categories, :authors, :editorial, :callnumber, :isbn, :pubtype, :dimensions

  def parse_title hash_title
    @title = hash_title.splitparse_by_markers 'a', 'b'
    @title.shift
    @title = @title.join(', ')
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
  attr_accessor :publications
end

class Parser
  attr_accessor :library_hash

  def initialize
    @library_hash = []
  end

  def populate_hash line, hash_publication
    key = line.string_between_markers('<','>')
    value = line.string_between_markers('>','<')
    if hash_publication[key].nil?
      hash_publication[key] = value
    else
      unless hash_publication[key].kind_of?(Array)
        temp = hash_publication[key]
        hash_publication[key] = Array.new
        hash_publication[key].push temp
      end
      hash_publication[key].push value
    end


    hash_publication
  end

  def start
    hash_publication = {}

    File.open('library.bak', 'r', :encoding => "UTF-8") do |file|
      while line = file.gets
        line = line.chomp
        unless line == '##' || line[0..2] == 'Mfn'
          unless line == ''
            hash_publication = populate_hash line, hash_publication
          else
            @library_hash.push hash_publication
            hash_publication = {}
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
  library.publications = []
  # puts parser.library_hash[23].inspect
  parser.library_hash.each do |hash_publication|
    publication = Publication.new
    publication.authors = Array.new
    publication.categories = Array.new
    hash_publication.each do |key,value|
      case key
        when '650'
          if value.kind_of?(Array)
            value.each do |cat|
              category = Category.new
              category.parse_category cat
              publication.categories.push category
            end
          else
            category = Category.new
            category.parse_category value
            publication.categories.push category
          end
        when '100'
          author = Author.new
          author.parse_author value
          publication.authors.insert(0,author)
        when '700'
          if value.kind_of?(Array)
            value.each do |auth|
              author = Author.new
              author.parse_author auth
              publication.authors.push author
            end
          else
            author = Author.new
            author.parse_author value
            publication.authors.push author
          end
        when '245'
          publication.parse_title value
        when '260'
          publication.parse_editorial value
        when '82'
          publication.parse_call value
        when '20'
          if value.kind_of?(Array)
            publication.parse_isbn value[0]
          else
            publication.parse_isbn value
          end
        when '842'
          publication.parse_pubtype value 
        when '300'
          publication.parse_dimensions value
      end
    end
    # puts publication.categories.inspect
    library.publications.push publication
  end

  # puts parser.library_hash[0].inspect
  
  puts library.publications[0].inspect
  #library.save
end

main()
