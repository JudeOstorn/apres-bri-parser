require_relative 'config'

# parser statistics
class Statistics# < Sniffer
  include Info

  def initialize(groups)
    @groups = groups  #@group_ids.merge(@subgroup_ids)
    @counter = 0
    @group_info = {}
    @no_image_items = 0.0
    @images_sizes = []
    @max_image_size = [0, '']
    @min_image_size = [0, '']
  end

  def analyze(image, id, item_name)
    @counter += 1
    if image != ''
      @no_image_items += 1
      image_sizes(image, item_name)
    end
    @group_info[id].nil? ? @group_info[id] = 1 : @group_info[id] += 1
    if (@counter % STATS_AMOUNT).zero?
      print_stats
      return false
    end
  end

  def image_sizes(image, item_name)
    @images_sizes << img_size = File.size(image.sub('/', '')).to_f / 1000 # byte : 1000 = kb
    @max_image_size = [img_size, item_name] if img_size >= @images_sizes.max
    @min_image_size = [img_size, item_name] if img_size <= @images_sizes.min
  end

  def groups_info
    b = @group_info.values.reduce(:+)
    @group_info.keys.sort.map { |k| p "#{@groups[k]} - #{@group_info[k]} товаров, это - #{@group_info[k] / b.to_f * 100.0}%" }
  end

  def print_stats
    p "#{@counter} товаров обработано"
    groups_info
    p "#{@no_image_items.to_f / @counter.to_f * 100.0}% товаров имеют изображение"
    p "#{@min_image_size[0]}KB минимальный размер картинки #{@min_image_size[1]}"
    p "#{@max_image_size[0]}KB максимальный размер картинки #{@max_image_size[1]}"
    p "#{@images_sizes.reduce(:+) / @images_sizes.size.to_f}KB средний размер картинки"
  end
end
