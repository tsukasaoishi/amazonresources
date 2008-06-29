class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    create_table "<%= table_name %>", :force => true do |t|
      t.column :asin, :string, :limit => 20, :null => false
      t.column :isbn13, :string, :limit => 20
      t.column :url, :string, :limit => 2100, :null => false
      t.column :product_name, :string
      t.column :creator, :string
      t.column :manufacturer, :string
      t.column :media, :string
      t.column :release_date, :string
      t.column :price, :string
      t.column :medium_image_url, :string, :limit => 2100
      t.column :small_image_url, :string, :limit => 2100
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
    add_index "<%= table_name %>", :asin, :unique => true
    add_index "<%= table_name %>", :isbn13, :unique => true
  end

  def self.down
    drop_table "<%= table_name %>"
  end
end
