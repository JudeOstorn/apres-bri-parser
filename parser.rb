require 'open-uri'
require 'nokogiri'

page = Nokogiri::HTML(open('http://www.a-yabloko.ru/catalog'), encoding = 'cp1251')
dock = File.open('test2.txt', 'w') { |f| f << page }
#page.parse_file('test.txt', encoding = 'UTF-8') {|f| f << page.text }
#если записывать текст то он автоматом меняет кодировку. page.text.to_s.encode("UTF-8")
#если записывать весь html то такого результат не выходит. и русские символы слетают в "������"
