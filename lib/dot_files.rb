require 'shellwords'
require 'set'

class DotFiles
  def initialize(path)
    @path = path
  end

  def init
    if File.exists?(path)
      warn "Already initialized: #{path}"
    else
      begin
        Dir.mkdir(path)
        Dir.mkdir(dotfiles_dir)
        Dir.mkdir(compiled_dir)
        File.open(tag_file, 'w') { |file| default_tags.each { |tag| file.puts(tag) } }
        File.open(key_file, 'w') { |file| file.puts default_key }
      rescue => exception
        quit "Initialization failed: #{exception}"
      end
    end
  end

  def tags
    return @tags if @tags

    begin
      @tags = File.open(tag_file, "r") { |file| file.each_line.map(&:chomp) }.to_set
    rescue => exception
      quit "Could not get tags: #{exception}"
    end
  end

  def write_tags(new_tags)
    new_tags = (new_tags + tags.to_a).uniq.sort
    @tags = nil

    begin
      File.open(tag_file, "w") do |file|
        new_tags.each { |tag| file.puts(tag) }
      end
    rescue => exception
      quit "Could not write tags: #{exception}"
    end
  end

  def key
    return @key if @key

    begin
      @key = File.read(key_file).chomp
    rescue => exception
      quit "Could not get key: #{exception}"
    end
  end

  def write_key(key)
    @key = nil

    begin
      File.write(key_file, key)
    rescue => exception
      quit "Could not write key: #{exception}"
    end
  end

  def status
    dotfiles.map do |file|
      linked_file = location(file)

      case file_status(file)
      when :unlinked
        "[ ] #{File.basename(file)} -> #{linked_file}"
      when :linked
        "[y] #{File.basename(file)} -> #{linked_file}"
      when :problem
        "[!] #{File.basename(file)} -> #{linked_file}"
      end
    end
  end

  def compile
    compiled_dotfiles.each { |file| File.unlink(file) }
    @compiled_dotfiles = nil

    dotfiles.each do |file|
      begin
        File.open(compiled_file_path(file), "w") do |compiled|
          filtered_lines(file) { |line| compiled.print(line) }
        end
      rescue => exception
        quit "Compilation failed: #{exception}"
      end
    end
  end

  def link
    compiled_dotfiles.each do |file|
      begin
        case file_status(file)
        when :unlinked
          File.symlink(file, location(file))
        when :linked
        when :problem
          warn "Cannot link: #{File.basename(file)}"
        end
      rescue => exception
        quit "Linking failed: #{exception}"
      end
    end
  end

  private

  attr_reader :path

  def dotfiles_dir
    File.join(path, "dotfiles")
  end

  def compiled_dir
    File.join(path, ".compiled")
  end

  def tag_file
    File.join(path, "tags")
  end

  def key_file
    File.join(path, "key")
  end

  def default_key
    '~~~'
  end

  def default_tags
    ['all']
  end

  def quit(message)
    warn message
    exit 1
  end

  def tag_matches?(tags)
    tags.empty? || tags.any? { |tag| self.tags.member?(tag) }
  end

  def smart_path(filepath)
    basename = File.basename(filepath)
    basename = ".#{basename}" unless basename.start_with?(".")

    File.join(File.expand_path("~"), basename)
  end

  def dotfiles
    return @dotfiles if @dotfiles

    begin
      @dotfiles = Dir.entries(dotfiles_dir)
        .reject { |entry| entry.start_with?(".") }
        .map { |entry| File.join(dotfiles_dir, entry) }
    rescue => exception
      quit "Could not get dotfiles: #{exception}"
    end.sort
  end

  def compiled_dotfiles
    return @compiled_dotfiles if @compiled_dotfiles

    begin
      @compiled_dotfiles = Dir.entries(compiled_dir)
        .reject { |entry| entry.start_with?(".") }
        .map { |entry| File.join(compiled_dir, entry) }
    rescue => exception
      quit "Could not get compiled dotfiles: #{exception}"
    end.sort
  end

  def filtered_lines(filepath)
    begin
      location = smart_path(filepath)
      status = tags.member?("all") ? :go : :stop

      File.open(filepath, 'r') do |file|
        line_count = 0

        file.each_line do |line|
          line_count += 1

          match = line[/(?<=#{Regexp.escape(key)}).*(?=#{Regexp.escape(key)})/]

          if match
            command, *tags = *Shellwords.split(match)

            case command
            when "exclude"
              status = tag_matches?(tags) ? :stop : status
            when "include"
              status = tag_matches?(tags) ? :go : status
            when "only"
              status = tag_matches?(tags) ? :go : :stop
            when "location"
              possible_location, *tags = *tags
              location = tag_matches?(tags) ? possible_location : location
            else
              warn "Unrecognized command: #{command} @ #{filepath}:#{line_count}"
            end
          end

          case status
          when :go
            yield(line) if block_given?
          when :stop
          end
        end
      end

      return location
    rescue => exception
      quit "Error opening file: #{exception}"
    end
  end

  def location(filepath)
    return @location[filepath] if @location && @location[filepath]

    @location ||= {}

    @location[filepath] = filtered_lines(filepath)
  end

  def compiled_file_path(filepath)
    File.join(compiled_dir, File.basename(filepath))
  end

  def file_status(filepath)
    linked_file = location(filepath)

    if !File.exists?(linked_file)
      :unlinked
    elsif File.realdirpath(linked_file) == File.realdirpath(compiled_file_path(filepath))
      :linked
    else
      :problem
    end
  end
end
