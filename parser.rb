require 'mechanize'

# 1) Тип сущности (группа, подгруппа, товар)
# 2) Наименование (группы, подгруппы, товара)
# 3) Группу товара (если данная строка предствляет товар)
# 4) Имя файла с изображением данного товара (при парсинге каталога, необходимо так же загружать изображения товара, давать файлам уникальные имена, и записывать имя файла в соответсвуюущую строчку в таблице-файле)
# 5) Условный идетификатор группы или товара (по которому вы сможете определить, были ли этот товар/группа загружены вашей программой)
# После того, как первую 1000 товаров ваша программа загрузила, необходимо рассчитать статистику и вывести ее в консоль:

# class search and save catalog in file
class Sniffer
  URL = 'http://www.a-yabloko.ru/catalog/'.freeze

  Statistics = Struct.new(:group_statistict,
                          :coef_image,
                          :min_image_size,
                          :max_image_size,
                          :avg_image_size)

  def initialize
    @results = []
    @page = Mechanize.new
    @page.history_added = proc { sleep 0.5 }
    create_catalog_map
  end

  def sniff(resourse: '')
    @page.get(URL + resourse.to_s) do |page|
      page.css('.goods .item a.img').map do |name|
        @results << ("item,#{name['title']},#{resourse},#{name['rel']}," + name['href'].gsub("/catalog/#{resourse}/goods/", '').to_i.to_s)
        @page.get(name['rel']).save "./#{name['rel']}"
      end
    end
  end

  def create_catalog_map
    @page.get(URL).search('.sc-desktop table').each do |page|
      #@group = page.css('.root').map do |link|
      #  @results << ("group, " link['href'].text "#{link['href'].gsub('/catalog/', '').to_i}")
      # end
      @group = page.css('.root').map { |link| link['href'].gsub('/catalog/', '').to_i }
      @subgroup = page.css('.ch a').map { |link| link['href'].gsub('/catalog/', '').to_i }
    end
    #p @group.sort
    #p @subgroup.sort
  end

  def parse
    @group.each { |group| sniff(resourse: group) }
    @subgroup.each { |group| sniff(resourse: group) }
    save
  end

  def save
    File.open('test.txt', 'w+') { |f| f.puts(@results) }
  end
end
Sniffer.new.parse
