# Dirty Tracking Support in AttrJson

In ordinary ActiveRecord, there is dirty/change-tracking support for attributes,
that lets you see what changes currently exist in the model compared to what
was fetched from the db, as well as what changed on the most recent save operation.

```ruby
model = SomeModel.new
model.str_value = "some value"
model.changes_to_save
  # => { 'str_value' => 'some_value'}
model.will_save_change_to_str_value?
  # => true
model.save
model.saved_changes
  # => { 'str_value' => 'some_value'}
model.str_value_before_last_save
  # => nil
# and more
```

You may be used to an older style of AR change-tracking methods,
involving `changes` and `previous_changes`. These older-style methods were
deprecated in Rails 5.1 and removed in Rails 5.2.  It's a bit confusing and not
fully documented in AR, see more at
[these](https://www.levups.com/en/blog/2017/undocumented-dirty-attributes-activerecord-changes-rails51.html)
blog [posts](https://www.ombulabs.com/blog/rails/upgrades/active-record-5-1-api-changes.html),
and the initial [AR pull request](https://github.com/rails/rails/pull/25337).

AttrJson supports all of these new-style dirty-tracking methods, only
in Rails 5.1+. (*Sorry, our dirty tracking support does not work with Rails 5.0,
or old-style dirty API in Rails 5.1. Only new-style API in Rails 5.1+*). I wasn't
able to find a good way to get changes in the default Rails dirty tracking methods,
so instead **they are available off a separate `attr_json_changes` method**,
which also allows customization of if host record changes are also included.

To include the AttrJson dirty-tracking features, include the
`AttrJson::Record::Dirty` module in your active record model already including
`AttrJson::Record`:

```ruby
class MyEmbeddedModel
  include AttrJson::Model

  attr_json :str, :string
end

class MyModel < ActiveRecord::Base
  include AttrJson::Record
  include AttrJson::Record::Dirty

  attr_json :str, :string
  attr_json :str_array, :string, array: true
  attr_json :array_of_models, MyEmbeddedModel.to_type, array: true
end
```

Now dirty changes are available off a `attr_json_changes` method.
The full suite of (new, Rails 5.1+) ActiveRecord dirty methods are supported,
both ones that take the attribute-name as an argument, and synthetic attribute-specific
methods. All top-level `attr_json`s are supported, including those that
include arrays and/or complex/nested/compound models.

```ruby
model = MyModel.new
model.str = "some value"
model.attr_json_changes.will_save_change_to_str? #=> true
model.str_array = ["original1", "original2"]
model.array_of_models = [MyEmbeddedModel.new(str: "value")]
model.save

model.attr_json_changes.saved_changes
  # => {"str"=>[nil, "some value"], "str_array"=>[nil, ["original1", "original2"]], "array_of_models"=>[nil, [#<MyEmbeddedModel:0x00007fb285d12330 @attributes={"str"=>"value"}, @validation_context=nil, @errors=#<ActiveModel::Errors:0x00007fb285d00400 @base=#<MyEmbeddedModel:0x00007fb285d12330 ...>, @messages={}, @details={}>>]]

model.str_array << "new1"

model.attr_json_changes.will_save_change_to_str_array? # => true
model.attr_json_changes.str_array_change_to_be_saved
  # => [["original1", "original2"], ["original1", "original2", "new1"]]
```

## Cast representation vs Json representation

If you ask to see changes, you are going to see the changes reported as _cast_ values,
not _json_ values. For instance, you'll see your actual `AttrJson::Model`
objects instead of the hashes they serialize to, and ruby DateTime objects instead
of the ISO 8601 strings they serialize to.

If you'd like to see the the JSON-compat data structures instead, just tag
on the `as_json` modifier. For simple strings and ints and similar primitives,
it won't make a difference, for some types it will:

```ruby
model.attr_json_changes.changes_to_save
#=> {
#  json_str: [nil, "some value"]
#  embedded_model: [nil, #<TestModel:0x00007fee25a04bf8 @attributes={"str"=>"foo"}>]
#  json_date: [nil, {{ruby Date object}}]
# }

model.attr_json_changes.as_json.changes_to_save
#=> {
#  json_str: [nil, "some_value"]
#  embedded_model: [nil, {'str' => 'foo'}]
#  json_date: [nil, "2018-03-23"]
# }

```

All existing values are serialized every time you call this, since they are stored
in cast form internally. So there _could_ be perf implications, but generally it is looking fine.

## Merge in ordinary AR attribute dirty tracking

Now you have one place to track 'ordinary' AR attribute "dirtyness"
(`model.some_attribute_will_change?`), and another place to track attr_json
dirty-ness (`my_model.attr_json_changes.some_json_attr_will_change?`).

You may wish you could have one place that tracked both, so your calling code
doesn't need to care if a given attribute is jsonb-backed or ordinary-column, and
is resilient if an attribute switches from one to another.

While we couldn't get this on the built-in dirty attributes, you *can* optionally
tell the `attr_json_changes` to include 'ordinary' changes from model too,
all in one place, by adding on the method `merged`.

```ruby
model.attr_json_changes.merged.ordinary_attribute_will_change?
model.attr_json_changes.merged.attr_json_will_change?
model.attr_json_changes.merged.attr_json_will_change?
model.attr_json_changes.merged.changes_to_save
# => includes a hash with keys that are both ordinary AR attributes
#    and attr_jsons, as applicable for changes.
```

This will ordinarily include your json container attributes (eg `json_attributes`)
too, as they will show up in ordinary AR dirty tracking since they are just AR
columns.

If you'd like to exclude these from the merged dirty tracking, pretend the json
container attributes don't exist and just focus on the individual `attr_json`s,
we got you covered:

```ruby
model.attr_json_changes.merged(containers: false).attr_jsons_will_change?
  # => always returns `nil`, the 'real' `attr_jsons` attribute is dead to us.
```

## Combine both of these modifiers at once no problem

```ruby
model.attr_json_changes.as_json.merged.saved_changes
model.attr_json_changes.as_json.merged(containers: false).saved_changes
model.attr_json_changes.merged(containers: true).as_json.saved_changes
```
