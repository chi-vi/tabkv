require "log"
require "colorize"
require "file_utils"

class Tabkv
  Log = ::Log.for("tabkv")

  enum Mode
    Normal; Clean; Force; Reset
  end

  alias Value = Array(String)

  getter file : String
  getter data = {} of String => Value
  getter upds = {} of String => Value

  delegate size, to: @data
  delegate has_key?, to: @data
  delegate each, to: @data
  delegate reverse_each, to: @data
  delegate clear, to: @data
  delegate empty?, to: @data
  delegate values?, to: @data

  def initialize(@file, mode : Mode = Mode::Normal)
    return if mode.reset?
    return unless mode.force? || File.exists?(@file)

    count = load!(@file)
    save!(dirty: false) if mode.clean? && @data.size != count
  end

  def load!(file : String = @file) : Int32
    start = Time.monotonic
    count = 0

    File.each_line(file) do |line|
      # next if line.empty?
      ary = line.split('\t', 2)
      key = ary[0]

      set(key, ary[1]?.try(&.split('\t')))
      count += 1
    rescue err
      Log.error { "#{file.colorize.red} error: #{err.colorize.red} on `#{line.colorize.red}`" }
    end

    tspan = (Time.monotonic - start).total_milliseconds.round.to_i
    Log.info { "- #{file.colorize.blue} loaded (lines: #{count.colorize.blue}, tspan: #{tspan.colorize.blue}ms)" }

    count
  end

  def unsaved
    @upds.size
  end

  def get(key : String) : Value?
    @data[key]?
  end

  def get(key : String) : Value
    unless value = @data[key]?
      value = yield
      set(value)
    end

    value
  end

  def get!(key : String) : Value
    unless value = @data[key]?
      value = yield
      set!(key, value)
    end

    value
  end

  def add!(key : String, value, flush = 10) : Nil
    return unless set!(key, value)
    save!(dirty: true) if @upds.size >= flush
  end

  def set!(key : String, value) : Bool
    return false unless value = set(key, value)
    @upds[key] = value
    true
  end

  def set(key : String, value : Array(String)) : Value?
    return nil if @data[key]? == value
    @data[key] = value
  end

  def set(key : String, value : Nil) : Value?
    @data.delete(key)
  end

  def set(key : String, value : String) : Value?
    set(key, value.gsub('\n', "  ").split('\t'))
  end

  def set(key : String, value : Enumerable) : Value?
    set(key, value.map(&.to_s))
  end

  def set(key : String, value : Object) : Value?
    set(key, [value.to_s])
  end

  def delete(key : String) : Value?
    @data.delete(key) || @upds.delete(key)
  end

  def delete!(key : String) : Nil
    return unless delete(key)
    File.open(@file, "a") { |io| io.puts(key) }
  end

  def fval(key : String)
    get(key).try(&.first?)
  end

  def fval_alt(key : String, alt : String)
    fval(key) || fval(alt)
  end

  def ival(key : String, df = 0)
    ival(key) { df }
  end

  def ival(key : String)
    fval(key).try(&.to_i?) || yield
  end

  def ival_64(key : String, df = 0_i64)
    ival_64(key) { df }
  end

  def ival_64(key : String)
    fval(key).try(&.to_i64?) || yield
  end

  def reset!
    @data.clear
    @upds.clear
  end

  def save!(dirty : Bool = true) : Nil
    if @data.empty?
      File.delete(@file) if File.exists?(@file)
      return
    else
      FileUtils.mkdir_p(File.dirname(@file))
    end

    output = dirty ? @upds : @data

    File.open(@file, dirty ? "a" : "w") do |io|
      output.each_with_index do |(key, value), idx|
        io << '\n' if idx > 0 || dirty
        io << key << '\t'
        value.join(io, '\t')
      end
    end

    state, color = dirty ? {"updated", :light_yellow} : {"saved", :yellow}
    Log.info { "- <#{@file}> #{state} (entries: #{output.size})".colorize(color) }

    @upds.clear
  rescue err
    Log.error { "- <#{@file}> saves error: #{err}".colorize.red }
  end
end
