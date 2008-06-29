require 'hpricot'
require 'open-uri'
require 'timeout'

class <%= class_name %> < ActiveRecord::Base
  TARGET = {:asin => "asin", :isbn13 => "isbn13"}
  # your AWS associate tag
  ASSOCIATE_TAG = '<%= associate_tag %>'
  # your AWS access key ID
  ACCESS_KEY_ID = '<%= access_key %>'

  def self.find_by_asin(asin)
    find_by_asin_or_isbn13(TARGET[:asin], asin)
  end

  def self.find_by_isbn13(isbn13)
    isbn13.gsub!('-', '') if isbn13.is_a?(String)
    find_by_asin_or_isbn13(TARGET[:isbn13], isbn13)
  end

  class << self
    alias :find_by_isbn :find_by_asin
  end

  private

  def self.find_by_asin_or_isbn13(target, key)
    item = self.find(:first, :conditions => ["#{target} = ?", key])
    if !item || (item.updated_at < 1.week.ago)
      item = self.new(target.to_sym => key) unless item

      doc = timeout(5) do
        eval("get_by_#{target}(key)")
      end
      return nil unless (doc/:request/:errors).blank?

      item = copy_from_doc(item, doc)
      item.save!
    end
    item
  rescue ActiveRecord::RecordInvalid, Timeout::Error
    nil
  end

  def self.get_by_asin(asin)
    Hpricot(open(%Q|http://ecs.amazonaws.jp/onca/xml?Service=AWSECommerceService&AWSAccessKeyId=#{ACCESS_KEY_ID}&AssociateTag=#{ASSOCIATE_TAG}&Operation=ItemLookup&ItemId=#{asin}&ResponseGroup=Images,ItemAttributes|))
  end

  def self.get_by_isbn13(isbn13)
    Hpricot(open(%Q|http://ecs.amazonaws.jp/onca/xml?Service=AWSECommerceService&AWSAccessKeyId=#{ACCESS_KEY_ID}&AssociateTag=#{ASSOCIATE_TAG}&Operation=ItemLookup&IdType=ISBN&ItemId=#{isbn13}&ResponseGroup=Images,ItemAttributes&SearchIndex=Books|))
  end

  def self.copy_from_doc(item, doc)
    item.medium_image_url = (doc/:mediumimage/:url).first.inner_html unless
      (doc/:mediumimage/:url).blank?
    item.small_image_url = (doc/:smallimage/:url).first.inner_html unless
      (doc/:smallimage/:url).blank?
    item.isbn13 = (doc/:itemattributes/:ean).inner_html unless
      (doc/:itemattributes/:ean).blank?

    item.asin = (doc/:asin).inner_html
    item.url = (doc/:detailpageurl).inner_html
    item.product_name = (doc/:itemattributes/:title).inner_html
    item.creator = (doc/:itemattributes/:creator).map{|i| i.inner_html}.join(",")
    item.manufacturer = (doc/:manufacturer).inner_html
    item.media = (doc/:itemattributes/:binding).inner_html
    item.release_date = (doc/:publicationdate).inner_html
    item.release_date = (doc/:releasedate).inner_html if item.release_date.blank?
    item.price = (doc/:listprice/:formattedprice).inner_html
    item
  end
end
