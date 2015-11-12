require 'active_support/cache/libmemcached_store'

module ActiveSupport
  module Cache
    class LibmemcachedLocalStore < LibmemcachedStore
      include ActiveSupport::Cache::Strategy::LocalCache

      # if we read from local_cache then the return value from read_entry will be an Entry,
      # so convert it to it's value
      def read(*args)
        result = super
        result = result.value if result.is_a?(ActiveSupport::Cache::Entry)
        result
      end

      # make read multi hit local cache
      def read_multi(*names)
        return super unless cache = local_cache

        options = names.extract_options!

        missing_names = []

        # We write raw values to the local cache, unlike rails MemcachedStore, so we cannot use local_cache.read_multi.
        # Once read_multi_entry is available we can switch to that.
        results = names.each_with_object({}) do |name, results|
          value = local_cache_fetch_entry(name) do
            missing_names << name
            nil
          end
          results[name] = value unless value.nil?
        end

        if missing_names.any?
          missing_names << options
          missing = super(*missing_names)
          missing.each { |k,v| cache.write_entry(k, v, nil) }
          results.merge!(missing)
        end

        results
      end

      # memcached returns a fixnum on increment, but the value that is stored is raw / a string
      def increment(key, amount, options={})
        result = super
        if result && (cache = local_cache)
          cache.write(key, result.to_s)
        end
        result
      end

      # memcached returns a fixnum on decrement, but the value that is stored is raw / a string
      def decrement(key, amount, options={})
        result = super
        if result && (cache = local_cache)
          cache.write(key, result.to_s)
        end
        result
      end

      private

      # when trying to do a raw read we want the marshaled value to behave the same as memcached
      def read_entry(key, options)
        entry = super
        if options && options[:raw] && local_cache && entry && !entry.is_a?(Entry)
          entry = Marshal.dump(entry)
        end
        entry
      end

      def local_cache_fetch_entry(key)
        data = local_cache.instance_variable_get(:@data)
        data.fetch(key) { data[key] = yield }
      end

      # for memcached writing raw means writing a string and not the actual value
      def write_entry(key, entry, options) # :nodoc:
        written = super
        if options && options[:raw] && local_cache && written
          local_cache.write_entry(key, Entry.new(entry.to_s), options)
        end
        written
      end
    end
  end
end
