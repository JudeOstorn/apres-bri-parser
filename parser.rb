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
    groups_list
    @counter = 0
  end

  def sniff(resourse: '')
    @page.get(URL + resourse.to_s) do |page|
      # группы и подгруппы
      page.css('div.children a').map do |row|
        @results << "#{data_type(group_id(row))},#{row.text},#{resourse},#{image_url(row)},#{resourse}"
        # @page.get(image_url(row)).save "./#{image_url(row)}"
        # analize()
      end
      # товары (не собираем товары с главной страницы)
      if resourse != ''
        page.css('.goods .item a.img').map do |row|
          @results << "item,#{row['title'].gsub(%r{/,|\d*$/}, '')},#{resourse},#{row['rel']},#{item_id(row, resourse)}"
          # @page.get(row['rel']).save "./#{row['rel']}"
          # analize()
        end
      end
    end
    p @results
  end

  def analize()
  end

  def groups_list
    @page.get(URL).search('.sc-desktop table').each do |page|
      @group = page.css('.root').map { |link| group_id(link) }.sort.unshift('')
      @subgroup = page.css('.ch a').map { |link| group_id(link) }.sort
    end
  end

  def parse
    @group.each { |group| sniff(resourse: group) }
    @subgroup.each { |subgroup| sniff(resourse: subgroup) }
    save
  end

  def save
    File.open('test.txt', 'w+') { |f| f.puts(@results) }
  end

  private

  def analize

  end

  def group_id(link)
    link['href'].gsub('/catalog/', '').to_i
  end

  def item_id(row, resourse)
    row['href'].gsub("/catalog/#{resourse}/goods/", '').to_i
  end

  def image_url(row)
    row['style'].gsub('background-image:url(', '').chop!
  end

  def data_type(resourse)
    if @group.include? resourse
      'group'
    else
      'subgroup'
    end
  end
end
Sniffer.new.sniff(resourse: '')
