require "./spec_helper"

# This should not cause compilation errors
class NoAttributes < ActiveModel::Model
end

# Inheritance should be supported
class BaseKlass < NoAttributes
  attribute string : String = "hello"
  attribute integer : Int32 = 45
  attribute no_default : String
end

class AttributeOptions < ActiveModel::Model
  attribute time : Time, converter: Time::EpochConverter
  attribute bob : String = "Bobby", mass_assignment: false

  attribute weird : String | Int32
end

class Inheritance < BaseKlass
  attribute boolean : Bool = true

  macro __customize_orm__
    {% for name, type in FIELDS %}
      def {{name}}_custom
        @{{name}}
      end
    {% end %}
  end
end

class Changes < BaseKlass
  attribute arr : Array(Int32) = [1, 2, 3]
end

describe ActiveModel::Model do
  describe "class definitions" do
    it "should provide the list of attributes" do
      NoAttributes.attributes.should eq [] of Nil
      BaseKlass.attributes.should eq [:string, :integer, :no_default]
      Inheritance.attributes.should eq [:boolean, :string, :integer, :no_default]
    end
  end

  describe "initialization" do
    it "creates a new model with defaults" do
      bk = BaseKlass.new
      bk.attributes.should eq({
        :string     => "hello",
        :integer    => 45,
        :no_default => nil,
      })
    end

    it "creates a new inherited model with defaults" do
      i = Inheritance.new
      i.attributes.should eq({
        :boolean    => true,
        :string     => "hello",
        :integer    => 45,
        :no_default => nil,
      })
    end

    it "creates a new model from JSON" do
      bk = BaseKlass.from_json("{\"boolean\": false, \"integer\": 67}")
      bk.attributes.should eq({
        :string     => "hello",
        :integer    => 67,
        :no_default => nil,
      })

      i = Inheritance.from_json("{\"boolean\": false, \"integer\": 67}")
      i.attributes.should eq({
        :boolean    => false,
        :string     => "hello",
        :integer    => 67,
        :no_default => nil,
      })
    end

    it "uses named params for initialization" do
      bk = BaseKlass.new string: "bob", no_default: "jane"
      bk.attributes.should eq({
        :string     => "bob",
        :integer    => 45,
        :no_default => "jane",
      })

      i = Inheritance.new string: "bob", boolean: false, integer: 2
      i.attributes.should eq({
        :boolean    => false,
        :string     => "bob",
        :integer    => 2,
        :no_default => nil,
      })
    end

    it "uses HTTP Params for initialization" do
      params = HTTP::Params.new({"string" => ["bob"], "no_default" => ["jane"]})
      bk = BaseKlass.new params

      bk.attributes.should eq({
        :string     => "bob",
        :integer    => 45,
        :no_default => "jane",
      })

      i = Inheritance.new({"string" => "bob", "no_default" => "jane", "boolean" => "True"})
      i.attributes.should eq({
        :boolean    => true,
        :string     => "bob",
        :integer    => 45,
        :no_default => "jane",
      })

      i = Inheritance.new({"string" => "bob", "integer" => "123", "boolean" => "false"})
      i.attributes.should eq({
        :boolean    => false,
        :string     => "bob",
        :integer    => 123,
        :no_default => nil,
      })
    end
  end

  describe "attribute accessors" do
    it "should return attribute values" do
      bk = BaseKlass.new
      bk.string.should eq "hello"
      bk.integer.should eq 45
      bk.no_default.should eq nil

      i = Inheritance.new
      i.boolean.should eq true
      i.string.should eq "hello"
      i.integer.should eq 45
      i.no_default.should eq nil
    end

    it "should allow attribute assignment" do
      bk = BaseKlass.new
      bk.string.should eq "hello"
      bk.string = "what"
      bk.string.should eq "what"

      bk.attributes.should eq({
        :string     => "what",
        :integer    => 45,
        :no_default => nil,
      })

      i = Inheritance.new
      i.boolean.should eq true
      i.boolean = false
      i.boolean.should eq false

      i.attributes.should eq({
        :boolean    => false,
        :string     => "hello",
        :integer    => 45,
        :no_default => nil,
      })
    end
  end

  describe "serialization" do
    it "should support to_json" do
      i = Inheritance.new
      i.to_json.should eq "{\"boolean\":true,\"string\":\"hello\",\"integer\":45}"

      i.no_default = "test"
      i.to_json.should eq "{\"boolean\":true,\"string\":\"hello\",\"integer\":45,\"no_default\":\"test\"}"
    end
  end

  describe "change tracking" do
    it "should track changes" do
      BaseKlass.new.changed_attributes.should eq({:string => "hello", :integer => 45})
      klass = Inheritance.new
      klass.changed_attributes.should eq({:boolean => true, :string => "hello", :integer => 45})
      klass.string_change.should eq ({nil, "hello"})
    end

    it "should allow changes information to be cleared" do
      klass = Inheritance.new
      klass.changed_attributes.should eq({:boolean => true, :string => "hello", :integer => 45})
      klass.clear_changes_information
      klass.changed_attributes.should eq({} of Nil => Nil)
      klass.changed?.should eq false
      klass.no_default_changed?.should eq false
      klass.no_default = "bob"
      klass.no_default_changed?.should eq true
      klass.no_default_change.should eq ({nil, "bob"})
      klass.changed?.should eq true
      klass.changed_attributes.should eq({:no_default => "bob"})

      klass.string_change.should eq nil
      klass.string = "else"
      klass.string_change.should eq ({"hello", "else"})
    end

    it "should be able to mark attributes as changed" do
      klass = Changes.new
      klass.clear_changes_information
      klass.arr.should eq [1, 2, 3]
      arr = klass.arr
      raise "no array" unless arr
      arr << 123
      klass.arr.should eq [1, 2, 3, 123]
      klass.arr_changed?.should eq false
      klass.changed_attributes.should eq({} of Nil => Nil)
      klass.arr_will_change!
      klass.arr_changed?.should eq true
      klass.changed_attributes.should eq({:arr => [1, 2, 3, 123]})

      arr << 456
      klass.changed_attributes.should eq({:arr => [1, 2, 3, 123, 456]})
      klass.arr_change.should eq({[1, 2, 3, 123], [1, 2, 3, 123, 456]})
    end

    it "should restore changes" do
      klass = Inheritance.new
      klass.clear_changes_information
      klass.changed_attributes.should eq({} of Nil => Nil)

      klass.string = "bob"
      klass.string_changed?.should eq true
      klass.string_change.should eq({"hello", "bob"})

      klass.restore_attributes
      klass.string_changed?.should eq false
      klass.string.should eq "hello"
    end
  end

  describe "attribute options" do
    it "should convert values using converters" do
      AttributeOptions.attributes.should eq [:time, :bob, :weird]
      opts = AttributeOptions.from_json(%({"time": 1459859781, "bob": "Angus", "weird": 34}))
      opts.time.should eq Time.epoch(1459859781)
      opts.to_json.should eq %({"time":1459859781,"bob":"Bobby","weird":34})
    end

    it "should not assign attributes protected from mass assignment" do
      opts = AttributeOptions.from_json(%({"time": 1459859781, "bob": "Steve"}))
      opts.time.should eq Time.epoch(1459859781)
      opts.bob.should eq "Bobby"
    end

    it "should assign attributes protected from mass assignment where data source is trusted" do
      opts = AttributeOptions.from_trusted_json(%({"time": 1459859781, "bob": "Steve"}))
      opts.time.should eq Time.epoch(1459859781)
      opts.bob.should eq "Steve"
    end
  end
end
