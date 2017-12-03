# class item, group and subgroup
class Entity
    attr_accessor(:type, :name, :group_id, :image_url, :id)
  def entity_info
    [type, name, group_id, image_url, id].to_csv
  end
end

# class group
class Group < Entity
  def initialize(row, id, data_type)
    @type = data_type
    @name = row.text
    @group_id = row['href'].sub('/catalog/', '').to_i
    @image_url = row['style'].sub('background-image:url(', '').chop!
    @id = row['href'].sub("/catalog/#{id}/goods/", '').to_i
  end
end

# class item
class Item < Entity
  def initialize(row, id)
    @type = 'item'
    @name = row['title']
    @group_id = id
    @image_url = row['rel']
    @id = row['href'].sub("/catalog/#{id}/goods/", '').to_i
  end
end
