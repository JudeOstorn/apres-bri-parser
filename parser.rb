require 'mechanize'
require 'csv'

# 1. max/min размер картинки и ИМЯ товара
# 2. выход из цикла если @counter == 1000
# 3. запись в файл без перезаписи, а лишь дополнением

# class item, group and subgroup
class Entity
  def entity_info
    [self.type, self.name, self.group_id, self.image_url, self.id].to_csv
  end
end

# class group
class Group < Entity
  attr_accessor(:type, :name, :group_id, :image_url, :id)
  def initialize (row, id, data_type)
    @type = data_type
    @name = row.text
    @group_id = row['href'].sub('/catalog/', '').to_i
    @image_url = row['style'].sub('background-image:url(', '').chop!
    @id = row['href'].sub("/catalog/#{id}/goods/", '').to_i
  end
end

# class item
class Item < Entity
  attr_accessor(:type, :name, :group_id, :image_url, :id)
  def initialize (row, id)
    @type = 'item'
    @name = row['title']
    @group_id = id
    @image_url = row['rel']
    @id = row['href'].sub("/catalog/#{id}/goods/", '').to_i
  end
end

# class search and save catalog in file
class Sniffer
  URL = 'http://www.a-yabloko.ru/catalog/'.freeze
  STATS_AMOUNT = 10

  def initialize
    @results = []
    @page = Mechanize.new
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
    (@group_ids + @subgroup_ids).each do |id|
      break if @counter > STATS_AMOUNT

      @page.get(URL + id.to_s) do |page|
        take_groups(page, id)
        take_items(page, id) if id != ''
      end

      save_info
    end
  end

  def take_groups(page, id)
    page.css('div.children a').map do |row|
      group = Group.new(row, id, data_type(id))
      @results << group.entity_info
      @page.get(group.image_url).save "./#{group.image_url}"
    end
  end

  def take_items(page, id)
    # не собираем товары с главной страницы
    page.css('.goods .item a.img').map do |row|
      item = Item.new(row, id)
      @results << item.entity_info
      @page.get(item.image_url).save "./#{item.image_url}"
      analyze(item.image_url, id)
    end
  end

  def analyze(image, id)
    @counter += 1
    @no_image_items += 1 if image == ''
    @images_sizes << File.size(image.sub('/', '')).to_f / 1000 if image != ''
    @group_info[id].nil? ? @group_info[id] = 1 : @group_info[id] += 1
    print_stats if (@counter % STATS_AMOUNT) == 0
  end

  def print_stats
    p "#{@counter} товаров обработано"
    p @group_info
    p "#{100.0 - @no_image_items.to_f / @counter.to_f * 100.0}% товаров имеют изображение"
    p "#{@images_sizes.min}KB минимальный размер картинки"
    p "#{@images_sizes.max}KB максимальный размер картинки"
    p "#{@images_sizes.reduce(:+) / @images_sizes.size.to_f}KB средний размер картинки"
  end

  def data_type(id)
    @group_ids.include?(id) ? 'group' : 'subgroup'
  end

  def group_id(link)
    link['href'].sub('/catalog/', '').to_i
  end

  def save_info
    File.open('catalog.txt', 'w+') do |f|
      if f != @results
        f.puts(@results)
      end
    end
  end
end
Sniffer.new.parse
