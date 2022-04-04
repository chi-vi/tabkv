class Object
  def to_tsv
    to_s
  end
end

struct Bool
  def to_tsv
    self ? 't' : 'f'
  end
end

module Enumerable(T)
  def to_tsv
    self.join('\t')
  end
end
