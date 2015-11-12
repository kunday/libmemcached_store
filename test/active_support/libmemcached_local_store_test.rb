require_relative '../test_helper'
require 'memcached'
require 'active_support'
require 'active_support/core_ext/module/aliasing'
require 'active_support/core_ext/object/duplicable'
require 'active_support/cache/libmemcached_local_store'

describe ActiveSupport::Cache::LibmemcachedLocalStore do
  # it with and without local cache
  def self.it_wawo(description, &block)
    it "#{description} with local cache" do
      @cache.with_local_cache do
        instance_eval(&block)
      end
    end

    it "#{description} without locale cache" do
      instance_eval(&block)
    end
  end

  before do
    @cache = ActiveSupport::Cache.lookup_store(:libmemcached_local_store, expires_in: 60)
    @cache.clear
    @cache.silence!
  end

  it_wawo "can read and write" do
    @cache.write 'x', 1
    @cache.read('x').must_equal 1
  end

  it_wawo "can read raw" do
    @cache.write 'x', 1, raw: true
    @cache.read('x').must_equal "1"
  end

  it_wawo "can read raw when written with raw" do
    @cache.write 'x', 1, raw: true
    @cache.read('x', raw: true).must_equal "1"
  end

  it_wawo "can read normal as raw" do
    @cache.write 'x', 1
    @cache.read('x', raw: true).must_equal "\x04\bi\x06"
  end

  it_wawo "can increment" do
    @cache.write 'x', 0, raw: true
    @cache.increment 'x', 1
    @cache.increment 'x', 1
    @cache.read('x').must_equal "2"
  end

  it_wawo "can decrement" do
    @cache.write 'x', 3, raw: true
    @cache.decrement 'x', 1
    @cache.decrement 'x', 1
    @cache.read('x').must_equal "1"
  end
end
