require 'mechanize'

#1) Тип сущности (группа, подгруппа, товар)
#2) Наименование (группы, подгруппы, товара)
#3) Группу товара (если данная строка предствляет товар)
#4) Имя файла с изображением данного товара (при парсинге каталога, необходимо так же загружать изображения товара, давать файлам уникальные имена, и записывать имя файла в соответсвуюущую строчку в таблице-файле)
#5) Условный идетификатор группы или товара (по которому вы сможете определить, были ли этот товар/группа загружены вашей программой)
#После того, как первую 1000 товаров ваша программа загрузила, необходимо рассчитать статистику и вывести ее в консоль:

class Sniffer

  URL = 'http://www.a-yabloko.ru/catalog/'

  Statistics = Struct.new( :group_statistict,
                           :coef_image,
                           :min_image_size,
                           :max_image_size,
                           :avg_image_size)

  def initialize
    @results = []
    @page = Mechanize.new
    @page.history_added = Proc.new { sleep 0.5 }
    create_catalog_map
  end

  def sniff(resourse: '')
    @page.get(URL+resourse) do |page|
      @results << page.css('.goods .item a.img').map { |name| "item" + "," + name['title'] + "," + name['rel'] + "," + "#{resourse[0..-2].to_i}" + "," + item_id(name, resourse) }
    end
  end

  def create_catalog_map
    @page.get(URL).search('.sc-desktop table').each do |page|
      @group = page.css('.root').map { |link| link['href'].gsub("/catalog/",'') }
      @subgroup = page.css('.ch a').map { |link| link['href'].gsub("/catalog/",'') }
    end
  end

  def parse
    @group.each { |group| sniff(resourse: group) }
    @subgroup.each { |group| sniff(resourse: group) }
    save
  end

  def save
    File.open('test.txt', 'w+') { |f| f << @results }
  end
private
  def item_id(name, resourse)
    name["href"].gsub("/catalog/#{resourse}goods/",'').to_i.to_s
  end
end

Sniffer.new.parse

#File.open('test2.txt', 'w+') do |csv_file|
#  results.each do |row|
#    csv_file << row
#  end
#end
#dock = File.open('test2.txt', 'w+') { |f| f << page }
