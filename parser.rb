require 'mechanize'

# class search and save catalog in file
class Sniffer
  URL = 'http://www.a-yabloko.ru/catalog/'.freeze

  def initialize
    @results = []
    @page = Mechanize.new
    @page.history_added = proc { sleep 0.5 }
    groups_list

    # statistics
    @counter = 0
    @group_info = {}
    @coef_image = 0.0
    @images = []
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

  def sniff(resourse: '')
    @page.get(URL + resourse.to_s) do |page|
      # группы и подгруппы
      page.css('div.children a').map do |row|
        @results << "#{data_type(group_id(row))},#{row.text},#{resourse},#{image_url(row)},#{resourse}"
        @page.get(image_url(row)).save "./#{image_url(row)}"
        analyze(image_url(row), resourse)
      end
      # товары (не собираем товары с главной страницы)
      if resourse != ''
        page.css('.goods .item a.img').map do |row|
          @results << "item,#{row['title']},#{resourse},#{row['rel']},#{item_id(row, resourse)}"
          @page.get(row['rel']).save "./#{row['rel']}"
          analyze(row['rel'], resourse)
        end
      end
    end
  end

  protected

  def analyze(image, resourse)
    @counter += 1
    print '.'
    @coef_image += 1 if image == ''
    image_size = @page.get(image).response['content-length'].to_i if image != ''
    @images << image_size

    if @group_info[resourse].nil?
      @group_info[resourse] = 1
    else
      @group_info[resourse] += 1
    end

    if (@counter % 1000) == 0
      p "#{@counter} сущностей обработано"
      p @group_info
      p "#{1.00 * 100.0 - @coef_image.to_f / @counter.to_f * 100.0}% товаров у которых присутствовало изображение"
      p "#{@images.min}KB минимальный размер картинки"
      p "#{@images.max}KB максимальный размер картинки"
      p "#{@images.reduce(:+) / @images.size.to_f}KB средний размер картинки"
    end
  rescue
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
    @group.include?(resourse) ? 'group' : 'subgroup'
  end

  def save
    File.open('test.txt', 'w+') { |f| f.puts(@results) }
  end
end
Sniffer.new.parse
