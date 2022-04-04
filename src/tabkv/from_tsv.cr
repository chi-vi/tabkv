class Object
  def self.from_tsv(rows : Array(String))
    from_tsv(rows.first)
  end
end

class String
  def self.from_tsv(value : String)
    value
  end
end

struct Bool
  def self.from_tsv(value : String)
    value == "t" || value == "true"
  end
end

struct Int32
  def self.from_tsv(value : String)
    value.to_i
  end
end

struct Int64
  def self.from_tsv(value : String)
    value.to_i64
  end
end

class Array(T)
  def self.from_tsv(rows : Array(String))
    rows.map { |x| T.from_tsv(x) }
  end
end
