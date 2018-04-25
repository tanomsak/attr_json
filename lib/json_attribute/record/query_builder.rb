module JsonAttribute
  module Record
    # Implementation class called by #jsonb_contains scope method. Ordinarily
    # you don't need to use it yourself, but you can.
    class QueryBuilder
      attr_reader :relation, :input_attributes
      def initialize(relation, input_attributes)
        @relation = relation
        @input_attributes = input_attributes
      end

      def contains_relation
        result_relation = relation

        group_attributes_by_container.each do |container_attribute, attributes|
          param_hash = {}

          attributes.each do |key, value|
            add_to_param_hash!(param_hash, key, value)
          end
          result_relation = result_relation.where("#{relation.table_name}.#{container_attribute} @> (?)::jsonb", param_hash.to_json)
        end

        result_relation
      end

      protected

      def merge_param_hash!(original, new)
        original.deep_merge!(new) do |key, old_val, new_val|
          if old_val.is_a?(Array) && old_val.first.is_a?(Hash) && new_val.is_a?(Array) && new_val.first.is_a?(Hash)
            [merge_param_hash!(old_val.first, new_val.first)]
          elsif old_val.is_a?(Hash) && new_val.is_a?(Hash)
            merge_param_hash!(old_val, new_val)
          else
            new_val
          end
        end
      end


      def add_to_param_hash!(param_hash, key_path_str, value)
        key_path = key_path_str.to_s.split(".")
        first_key, rest_keys = key_path.first, key_path[1..-1]
        attr_def = relation.json_attributes_registry.fetch(first_key)

        value = if rest_keys.present?
          attr_def.type.value_for_contains_query(rest_keys, value)
        else
          attr_def.serialize(attr_def.cast value)
        end

        if value.kind_of?(Hash)
          param_hash[attr_def.store_key] ||= {}
          merge_param_hash!(param_hash[attr_def.store_key], value)
        else
          param_hash[attr_def.store_key] = value
        end

        # it's a mutator not functional don't you forget it.
        return nil
      end

      # returns a hash with keys container attributes, values hashes of attributes
      # belonging to that container attribute.
      def group_attributes_by_container
        @group_attributes_by_container ||= begin
          hash_by_container_attribute = {}

          input_attributes.each do |key_path, value|
            key = key_path.to_s.split(".").first
            attr_def = relation.json_attributes_registry.fetch(key)
            container_attribute = attr_def.container_attribute

            hash_by_container_attribute[container_attribute] ||= {}
            hash_by_container_attribute[container_attribute][key_path] = value
          end

          hash_by_container_attribute
        end
      end
    end
  end
end
