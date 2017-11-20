require 'mechanize'

mechanize = Mechanize.new

page = mechanize.get('http://www.a-yabloko.ru/catalog')

#p page.class
puts page.at('.goods').text# { |it| p it }
