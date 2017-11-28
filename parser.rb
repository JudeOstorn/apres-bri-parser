require 'mechanize'

# class search and save catalog in file
class Sniffer
  URL = 'http://www.a-yabloko.ru/catalog/'.freeze
  Stats_amount = 1000.freeze

  def initialize
    @results = []
    @page = Mechanize.new
    #@page.history_added = proc { sleep 0.5 }
    groups_lists

    # statistics
    @counter = 0
    @group_info = {}
    @no_image_items = 0.0
    @images_sizes = []
  end

  def groups_lists
    @page.get(URL).search('.sc-desktop table').each do |page|
      @group_ids = page.css('.root').map { |link| group_id(link) }.sort.unshift('')
      @subgroup_ids = page.css('.ch a').map { |link| group_id(link) }.sort
    end
  end

  def parse
    (@group_ids + @subgroup_ids).each do |page_id|
      break if @counter > Stats_amount
      sniff(id: page_id)
    end
    save_info
  end

  def sniff(id: '')
    @page.get(URL + id.to_s) do |page|
      # группы и подгруппы
      page.css('div.children a').map do |row|
        image = image_url(row)
        @results << "#{data_type(group_id(row))},#{row.text},#{id},#{image},#{id}"
        @page.get(image).save "./#{image}"
      end
      # товары (не собираем товары с главной страницы)
      if id != ''
        page.css('.goods .item a.img').map do |row|
          image = row['rel']
          @results << "item,#{row['title']},#{id},#{image},#{item_id(row, id)}"
          @page.get(image).save "./#{image}"
          analyze(image, id)
        end
      end
    end
  end

  protected

  def analyze(image, id)
    @counter += 1
    @no_image_items += 1 if image == ''
    @images_sizes << File.size(image.sub('/', '')).to_f / 1000 if image != ''
    @group_info[id].nil? ? @group_info[id] = 1 : @group_info[id] += 1
    print_stats if (@counter % Stats_amount) == 0
  end

  def print_stats
    p "#{@counter} товаров обработано"
    p @group_info
    p "#{100.0 - @no_image_items.to_f / @counter.to_f * 100.0}% товаров имеют изображение"
    p "#{@images_sizes.min}KB минимальный размер картинки"
    p "#{@images_sizes.max}KB максимальный размер картинки"
    p "#{@images_sizes.reduce(:+) / @images_sizes.size.to_f}KB средний размер картинки"
  end

  def group_id(link)
    link['href'].sub('/catalog/', '').to_i
  end

  def item_id(row, id)
    row['href'].sub("/catalog/#{id}/goods/", '').to_i
  end

  def image_url(row)
    row['style'].sub('background-image:url(', '').chop!
  end

  def data_type(id)
    @group_ids.include?(id) ? 'group' : 'subgroup'
  end

  def save_info
    File.open('catalog.txt', 'w+') { |f| f.puts(@results) }
  end
end
a = Sniffer.new
a.parse
