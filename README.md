# Tabkv

Tab-seperated key value flatfile store internally used in chivi app

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  tabkv:
    github: chi-vi/tabkv
```

2. Run `shards install`

## Usage

```crystal
require "tabkv"

# modes:
# - `:normal`: load file if exists
# - `:clean`: load file if exists, resave file if there is overwritten entries.
# - `:force`: raise exception if file doesn't exists
# - `:reset`: ignore existed file, starting anew

map = Tabkv.new("demo.tsv", mode: :normal)

# update map without adding to buffer

map.set("a", ["a"]) # add/update an entry
map.set("b", "b") # value will be split by `\t`, newlines are replaced by two spaces
map.set("c", [1, 2, 3]) # array will be convert to Array(String)
map.set("d", 1) # => map.set("d", ["1"])

map.set("e", nil) # delete entry instead

# update map and add entries to buffer list to be saved in dirty mode later

map.set!("a", ["f"])
map.set!("b", "g")
# ...

# add/update entry and save buffer to disk if buffer size greater than provided value
map.add!("c", "c", flush: 4)

# delete entries
map.delete("a") # remove entry from entries and buffer
map.delete!("b") # remove entry and save delete mark to file

# save data:
map.save! # only save entries added/updated by calling `.set!`
map.save!(dirty: false) # save all data
```
