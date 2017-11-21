require 'mechanize'

#1) Тип сущности (группа, подгруппа, товар)
#2) Наименование (группы, подгруппы, товара)
#3) Группу товара (если данная строка предствляет товар)
#4) Имя файла с изображением данного товара (при парсинге каталога, необходимо так же загружать изображения товара, давать файлам уникальные имена, и записывать имя файла в соответсвуюущую строчку в таблице-файле)
#5) Условный идетификатор группы или товара (по которому вы сможете определить, были ли этот товар/группа загружены вашей программой)
#После того, как первую 1000 товаров ваша программа загрузила, необходимо рассчитать статистику и вывести ее в консоль:

class Sniffer

  URL = 'http://www.a-yabloko.ru'

  def initialize
    @results = [['Тип сущности', 'Наименование', 'Группа товара', 'Имя файла с изображением данного товара', 'Условный идетификатор группы или товара']]
    @page = Mechanize.new
    @page.history_added = Proc.new { sleep 0.5 }
    create_catalog_map
  end

  def sniff(resourse: '/catalog/')
    @page.get(URL+resourse).search('.goods').each do |page|
    p a = page.css('.item a.img').map { |name| name['title'] }
    end
  end

  def create_catalog_map
    @page.get(URL+'/catalog/').search('.sc-desktop table').each do |page|
      @group = page.css('.root').map { |link| link['href'] }
      @subgroup = page.css('.ch a').map { |link| link['href'] }
    end
  end

  def save
  end
end

class Statistics
  def initialize
    @group_statistict = {}
    @coef_image = 0.0 # %persent image have
    @min_image_size = {name: '', size: 0.0}
    @max_image_size = {name: '', size: 0.0}
    @avg_image_size = 0.0
  end
end


Sniffer.new.sniff(resourse: '/catalog/45/')






#page.css('.sc-desktop table').each
#page.search('.goods').each do |a|
 #p a.text
#end

#File.open('test2.txt', 'w+') do |csv_file|
#  results.each do |row|
#    csv_file << row
#  end
#end
#dock = File.open('test2.txt', 'w+') { |f| f << page }
