shared_examples "a check" do |name|
  it "is frozen" do
    check.should be_frozen
  end

  it "is registered" do
    Pinguin::Checks.get(name).should == check.class
  end
end
