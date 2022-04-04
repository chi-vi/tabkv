require "log"
require "colorize"
require "./tabkv/*"

class Tabkv(T)
  VERSION = "0.2.0"

  Log = ::Log.for("tabkv")
  # Log.setup_from_env(default_level: :error)

  enum Mode
    Normal; Clean; Force; Reset
  end

  getter file : String
  getter data = {} of String => T
  getter _buf = {} of String => T

  delegate :[], to: @data
  delegate :[]?, to: @data

  # forward_missing_to @data

  def initialize(@file, mode : Mode = :normal)
    return if mode.reset?
    return unless mode.force? || File.exists?(@file)

    count = load!(@file)
    save!(clean: true) if mode.clean? && @data.size != count
  end

  def load!(file : String = @file) : Int32
    start = Time.monotonic
    count = 0

    File.each_line(file) do |line|
      next if line.empty?
      count += 1

      rows = line.split('\t')
      key = rows.shift
      rows.empty? ? delete(key) : upsert(key, T.from_tsv(rows))
    rescue err
      Log.error { "#{file.colorize.red} error: #{err.colorize.red} on `#{line.colorize.red}`" }
    end

    Log.info {
      tspan = (Time.monotonic - start).total_milliseconds.round.to_i
      "# #{file.colorize.blue} loaded (lines: #{count.colorize.blue}, tspan: #{tspan.colorize.blue}ms)"
    }

    count
  end

  def upsert(key : String, value : T)
    @data[key] = value unless @data[key]? == value
  end

  def delete(key : String)
    _buf.delete(key)
    data.delete(key)
  end

  def delete!(key : String)
    File.open(@file, "a") { |io| io.puts(key) } if delete(key)
  end

  def append(key : String, value : T)
    upsert(key, value).try { |value| @_buf[key] = value }
  end

  def append!(key : String, value : T)
    upsert(key, value).try do
      File.open(@file, "a") { |io| to_tsv(io, key, value) }
    end
  end

  def save!(clean : Bool = false) : Nil
    output = clean ? @data : @_buf
    return if output.empty?

    Dir.mkdir_p(File.dirname(@file))
    File.open(@file, clean ? "w" : "a") do |io|
      io.puts unless clean # add blank line for safety
      output.each { |key, value| to_tsv(io, key, value) }
    end

    @_buf.clear

    Log.info {
      state = clean ? "saved" : "patched"
      color = clean ? :yellow : :light_yellow
      "- <#{@file}> #{state} (entries: #{output.size})".colorize(color)
    }
  rescue err
    Log.error { "# <#{@file}> saves error: #{err}".colorize.red }
  end

  def to_tsv(io : IO, key : String, value : T)
    io << key << '\t' << value.to_tsv << '\n'
  end

  def prune!
    @data.clear
    File.delete(@file) if File.exists?(@file)
  end
end
