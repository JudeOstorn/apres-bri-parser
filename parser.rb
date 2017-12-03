require 'mechanize'
require 'csv'
require_relative 'entity'
require_relative 'statistics'
require_relative 'config'

# class search and save catalog in file
class Sniffer
  include Info

  def initialize
    @page = Mechanize.new
    @results = []
    @post_result = []
    create_file
    @group_ids = {}
    @subgroup_ids = {}
    groups_lists
    @stats = Statistics.new(@group_ids.merge(@subgroup_ids))
  end

  def groups_lists
    @page.get(URL).search('.sc-desktop table').each do |page|
      page.css('.root').map { |link| @group_ids[group_id(link)] = link.text }
      page.css('.ch a').map { |link| @subgroup_ids[group_id(link)] = link.text }
    end
  end

  def parse
    stop = false
    (@group_ids.keys + @subgroup_ids.keys).sort.each do |id|
      @page.get(URL + id.to_s) do |page|
        stop = take_items(page, id)
        break if (stop == true)
        take_groups(page, id)
      end
        break if (stop == true)
    end
    save_to_file
  end

  def take_items(page, id)
    page.css('.goods .item a.img').map do |row|
      item = Item.new(row, id)
      @results << item.entity_info
      @page.get(item.image_url).save "./#{item.image_url}"
      continue = @stats.analyze(item.image_url, id, item.name)
      if continue == false
        return true
      end
    end
  end

  def take_groups(page, id)
    page.css('div.children a').map do |row|
      group = Group.new(row, id, data_type(id))
      @results << group.entity_info
      @page.get(group.image_url).save "./#{group.image_url}"
    end
  end

  def data_type(id)
    @group_ids.keys.include?(id) ? 'group' : 'subgroup'
  end

  def group_id(link)
    link['href'].sub('/catalog/', '').to_i
  end

  def save_to_file
    File.open(FILE_NAME, 'a+') { |f| f.puts(@results - @post_result) }
  end

  def create_file
    File.open(FILE_NAME).each_line { |line| @post_result << line }
  end
end
