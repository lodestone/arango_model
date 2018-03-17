require "./spec_helper"

class Ninja < ArangoModel::Base
end

describe ArangoModel do
  it "should be an instance of ActiveModel" do
    Ninja.new.should_not be_nil
  end
end
