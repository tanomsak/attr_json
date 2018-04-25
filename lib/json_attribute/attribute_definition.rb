 require 'json_attribute/type/array'

 module JsonAttribute

  # Represents a `json_attribute` definition, on either a JsonAttribute::Record
  # or JsonAttribute::Model.
  class AttributeDefinition
    DEFAULT_CONTAINER_ATTRIBUTE = :json_attributes
    NO_DEFAULT_PROVIDED = Object.new.freeze

    attr_reader :name, :type, :original_args, :container_attribute

    # TODO doc keyword args please.
    def initialize(name, type, options = {})
      # reflection useful for debugging, maybe other things.
      @original_args = [name, type, options]

      @name = name.to_sym

      @container_attribute = options[:container_attribute] && options[:container_attribute].to_s

      @store_key = options[:store_key] && options[:store_key].to_s

      @default = if options.has_key?(:default)
        options[:default]
      else
        NO_DEFAULT_PROVIDED
      end

      if type.is_a? Symbol
        # should we be using ActiveRecord::Type instead for db-specific
        # types? I think maybe not, we just want to serialize
        # to a json primitive type that'll go in the json hash.

        if ["geography","geometry"].include?(type.to_s)
          type = ActiveModel::Type.lookup(type,nil, "#{type.to_s}(#{options[:geo_type]},#{options[:srid]})")                    
        else
          type = ActiveModel::Type.lookup(type)          
        end

      elsif ! type.is_a? ActiveModel::Type::Value
        raise ArgumentError, "Second argument (#{type}) must be a symbol or instance of an ActiveModel::Type::Value subclass"
      end
      @type = (options[:array] == true ? JsonAttribute::Type::Array.new(type) : type)
    end

    def cast(value)
      type.cast(value)
    end

    def serialize(value)
      type.serialize(value)
    end

    def deserialize(value)
      type.deserialize(value)
    end

    def has_custom_store_key?
      !!@store_key
    end

    def store_key
      (@store_key || name).to_s
    end

    def has_default?
      @default != NO_DEFAULT_PROVIDED
    end

    def provide_default!
      unless has_default?
        raise ArgumentError.new("This #{self.class.name} does not have a default defined!")
      end

      # Seems weird to assume a Proc can't be the default itself, but I guess
      # Proc's aren't serializable, so fine assumption. Modeled after:
      # https://github.com/rails/rails/blob/f2dfd5c6fdffdf65e6f07aae8e855ac802f9302f/activerecord/lib/active_record/attribute/user_provided_default.rb#L12-L16
      if @default.is_a?(Proc)
        cast(@default.call)
      else
        cast(@default)
      end
    end
  end
end
