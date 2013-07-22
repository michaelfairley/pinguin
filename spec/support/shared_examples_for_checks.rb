shared_examples "a check" do
  it "is frozen" do
    check.should be_frozen
  end
end
