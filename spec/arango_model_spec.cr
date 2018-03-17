require "./spec_helper"

class Ninja < ArangoModel::Base
  attribute name : String
  attribute epithet : String
  attribute age : Int32
  attribute weapons : Array(String) = [] of String
  attribute enemies : JSON::Any
end

describe ArangoModel do
  it "should be generally okay" do
    Ninja.new.should_not be_nil
  end

  it "should support a string attribute" do
    ninja = Ninja.new name: "Hiro"
    ninja.name.should eq("Hiro")
  end

  it "should support an integer attribute" do
    ninja = Ninja.new age: 25
    ninja.age.should eq(25)
  end

  it "should support an array attribute" do
    nothing = [] of String
    ninja = Ninja.new
    ninja.weapons = %w[ katana shuriken ]
    # Have to do this or it gives me a Nil error!
    (ninja.weapons || nothing).first.should eq("katana")
    (ninja.weapons || nothing).last.should eq("shuriken")
  end

  it "should support a json attribute" do
    ninja = Ninja.new
    ninja.enemies = JSON::Any.new([{"name" => "Hiro"}, {"name" => "Shane"}].to_json)
    ninja.enemies.should eq("[{\"name\":\"Hiro\"},{\"name\":\"Shane\"}]")
  end
end
