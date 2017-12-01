require 'mechanize'
require 'csv'

# 1. запись в файл без перезаписи, а лишь дополнением
# 2. выход из цикла если @counter == 1000 (логика приложения)

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
  FILE_NAME = 'catalog.txt'.freeze

  def initialize
    @page = Mechanize.new
    @results = []
    @post_result = []
    create_file

    #groups map
    @group_ids = {}
    @subgroup_ids = {}
    groups_lists

    # statistics
    @counter = 0
    @group_info = {}
    @no_image_items = 0.0

    #размеры изображений
    @images_sizes = []
    @max_image_size = [0, '']
    @min_image_size = [0, '']
  end

  def groups_lists
    @page.get(URL).search('.sc-desktop table').each do |page|
      page.css('.root').map { |link| @group_ids[group_id(link)] = link.text }
      page.css('.ch a').map { |link| @subgroup_ids[group_id(link)] = link.text }
    end
  end

  def parse
    create_file
    (@group_ids.keys + @subgroup_ids.keys).sort.each do |id|
      break if @counter > STATS_AMOUNT   # а вот это до сих пор не работает Т_Т

      @page.get(URL + id.to_s) do |page|
        take_items(page, id)
        take_groups(page, id)
      end
      save_to_file
    end
  end

  def take_items(page, id)
    page.css('.goods .item a.img').map do |row|
      item = Item.new(row, id)
      @results << item.entity_info
      @page.get(item.image_url).save "./#{item.image_url}"
      analyze(item.image_url, id, item.name)
    end
  end

  def take_groups(page, id)
    page.css('div.children a').map do |row|
      group = Group.new(row, id, data_type(id))
      @results << group.entity_info
      @page.get(group.image_url).save "./#{group.image_url}"
    end
  end

  def analyze(image, id, item_name)
    @counter += 1
    if image != ''
      @no_image_items += 1
      image_sizes(image, item_name)
    end
    @group_info[id].nil? ? @group_info[id] = 1 : @group_info[id] += 1
    print_stats if (@counter % STATS_AMOUNT) == 0
  end

  def image_sizes(image, item_name)
    @images_sizes << img_size = File.size(image.sub('/', '')).to_f / 1000 # byte : 1000 = kb
    @max_image_size = [img_size, item_name] if img_size >= @images_sizes.max
    @min_image_size = [img_size, item_name] if img_size <= @images_sizes.min
  end

  def print_stats
    p "#{@counter} товаров обработано"
    groups_info
    p "#{@no_image_items.to_f / @counter.to_f * 100.0}% товаров имеют изображение"
    p "#{@min_image_size[0]}KB минимальный размер картинки #{@min_image_size[1]}"
    p "#{@max_image_size[0]}KB максимальный размер картинки #{@max_image_size[1]}"
    p "#{@images_sizes.reduce(:+) / @images_sizes.size.to_f}KB средний размер картинки"
  end

  def groups_info
    ids = @group_ids.merge(@subgroup_ids)
    b = 0
    @group_info.values.map {|a| b += a}
    @group_info.keys.sort.map { |k| p "#{ids[k]} - #{@group_info[k]} товаров, это - #{@group_info[k] / b.to_f * 100.0 }%"  }
  end

  def data_type(id)
    @group_ids.keys.include?(id) ? 'group' : 'subgroup'
  end

  def group_id(link)
    link['href'].sub('/catalog/', '').to_i
  end

  def save_to_file
    File.open(FILE_NAME, 'a+') do |f|
      f.puts (@results - @post_result)
     end
  end

  def create_file
    if !File.file? FILE_NAME
      @file = File.open(FILE_NAME)
        @file.each_line {|line| @post_result << line}
    end
  end
end
Sniffer.new.parse
