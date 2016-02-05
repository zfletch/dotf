require 'shellwords'
require 'set'

class DotFiles
  def initialize(path)
    @path = path
  end

  def init
    if File.exists?(path)
      puts "Already initialized: #{path}"
    else
      begin
        Dir.mkdir(path)
        Dir.mkdir(dotfiles_dir)
        Dir.mkdir(compiled_dir)
        File.write(tag_file, default_tags.join("\n") + "\n")
        File.write(key_file, default_key + "\n")
      rescue => exception
        quit "Initialization failed: #{exception}"
      end

      puts "Initialized dotf in #{path}"
    end
  end

  def tags
    begin
      File.open(tag_file, "r") { |file| file.each_line.map(&:chomp) }.to_set
    rescue => exception
      quit "Could not get tags: #{exception}"
    end
  end

  def write_tags(new_tags)
    new_tags = (new_tags + tags.to_a).uniq.sort

    begin
      File.open(tag_file, "w") do |file|
        new_tags.each { |tag| file.puts(tag) }
      end
    rescue => exception
      quit "Could not write tags: #{exception}"
    end
  end

  def key
    begin
      File.read(key_file).chomp
    rescue => exception
      quit "Could not get key: #{exception}"
    end
  end

  def write_key(key)
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
    warn "Clearing out old files ..."
    compiled_dotfiles.each { |file| File.unlink(file) }

    dotfiles.each do |file|
      begin
        warn "Compiling #{File.basename(file)} ..."
        File.open(compiled_file_path(file), "w") do |compiled|
          filtered_lines(file) { |line| compiled.print(line) }
        end
      rescue => exception
        quit "Compilation failed: #{exception}"
      end
    end

    warn "Finished compilation"
  end

  def link
    compiled_dotfiles.each do |file|
      begin
        case file_status(file)
        when :unlinked
          warn "Linking: #{File.basename(file)} ..."
          File.symlink(file, location(file))
        when :linked
          warn "Already linked: #{File.basename(file)}"
        when :problem
          warn "Cannot link: #{File.basename(file)}"
        end
      rescue => exception
        quit "Linking failed: #{exception}"
      end
    end

    warn "Finished linking"
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
    begin
      Dir.entries(dotfiles_dir)
        .reject { |entry| entry.start_with?(".") }
        .map { |entry| File.join(dotfiles_dir, entry) }
    rescue => exception
      quit "Could not get dotfiles: #{exception}"
    end.sort
  end

  def compiled_dotfiles
    begin
      Dir.entries(compiled_dir)
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
    filtered_lines(filepath)
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
