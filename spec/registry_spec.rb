require 'spec_helper'

class Pinguin
  describe Registry do
    subject(:registry) { Class.new.extend(Registry) }

    it "stores registered entries" do
      registry.register(:a, "hello")
      registry.register(:b, "goodbye")

      registry.get(:a).should == "hello"
      registry.get(:b).should == "goodbye"
    end

    it "raises KeyError if an entry can't be found" do
      expect do
        registry.get(:a)
      end.to raise_error(KeyError)
    end

    it "raises ArgumentError if registering an already taken name" do
      registry.register(:a, "hello")
      expect do
        registry.register(:a, "goodbye")
      end.to raise_error(ArgumentError)
      registry.get(:a).should == "hello"
    end

    it "coerces keys to strings" do
      registry.register(:a, "hello")
      registry.get("a").should == "hello"
      expect do
        registry.register("a")
      end.to raise_error(ArgumentError)
    end
  end
end
