require "./spec_helper"

DIR = "spec/fixtures"

describe Tabkv do
  # TODO: Write tests

  it "load file correctly" do
    t = Tabkv(String).new("#{DIR}/string.tsv", :force)
    t["a"].should eq "b"
  end

  it "load array string" do
    t = Tabkv(Array(String)).new("#{DIR}/array-string.tsv", :force)
    t["a"].should eq ["a", "b", "c"]
  end

  it "load int32 store" do
    t = Tabkv(Int32).new("#{DIR}/integer.tsv", :force)
    t["a"].should eq 1
  end

  it "append to file" do
    file = "#{DIR}/append.tsv"
    File.delete(file) if File.exists?(file)

    t = Tabkv(Int64).new(file, :reset)

    t["a"]?.should eq nil
    t.append!("a", 1)

    t["a"].should eq 1
    File.read(file).should eq "a\t1\n"
  end
end
