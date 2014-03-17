require 'uri'
require 'hocon/impl'
require 'hocon/impl/origin_type'

class Hocon::Impl::SimpleConfigOrigin

  MERGE_OF_PREFIX = "merge of "

  def self.new_file(file_path)
    url = URI.join('file:///', file_path)
    self.new(file_path, -1, -1,
             Hocon::Impl::OriginType::FILE,
             url, nil)
  end

  def self.new_simple(description)
    self.new(description, -1, -1,
             Hocon::Impl::OriginType::GENERIC,
             nil, nil)
  end

  def self.remove_merge_of_prefix(desc)
    if desc.start_with?(MERGE_OF_PREFIX)
      desc = desc[MERGE_OF_PREFIX.length, desc.length - 1]
    end
    desc
  end

  def self.merge_two(a, b)
    merged_desc = nil
    merged_start_line = nil
    merged_end_line = nil
    merged_comments = nil

    merged_type =
        if a.origin_type == b.origin_type
          a.origin_type
        else
          Hocon::Impl::OriginType.GENERIC
        end

    # first use the "description" field which has no line numbers
    # cluttering it.
    a_desc = remove_merge_of_prefix(a.description)
    b_desc = remove_merge_of_prefix(b.description)

    if a_desc == b_desc
      merged_desc = a_desc
      if a.line_number < 0
        merged_start_line = b.line_number
      elsif b.line_number < 0
        merged_start_line = a.line_number
      else
        merged_start_line = [a.line_number, b.line_number].min
      end

      merged_end_line = [a.end_line_number, b.end_line_number].max
    else
      # this whole merge song-and-dance was intended to avoid this case
      # whenever possible, but we've lost. Now we have to lose some
      # structured information and cram into a string.
      #
      # description() method includes line numbers, so use it instead
      # of description field.
      a_full = remove_merge_of_prefix(a.description)
      b_full = remove_merge_of_prefix(b.description)

      merged_desc = "#{MERGE_OF_PREFIX}#{a_full},#{b_full}"
      merged_start_line = -1
      merged_end_line = -1
    end

    merged_url =
        if Hocon::Impl::ConfigImplUtil.equals_handling_nil?(a.url_or_nil, b.url_or_nil)
          a.url_or_nil
        else
          nil
        end

    if Hocon::Impl::ConfigImplUtil.equals_handling_nil?(a.comments_or_nil, b.comments_or_nil)
      merged_comments = a.comments_or_nil
    else
      merged_comments = []
      if a.comments_or_nil
        merged_comments.concat(a.comments_or_nil)
      end
      if b.comments_or_nil
        merged_comments.concat(b.comments_or_nil)
      end
    end

    Hocon::Impl::SimpleConfigOrigin.new(
        merged_desc, merged_start_line, merged_end_line,
        merged_type, merged_url, merged_comments)
  end

  def self.merge_origins(stack)
    if stack.empty?
      raise ConfigBugError, "can't merge empty list of origins"
    elsif stack.length == 1
      stack[0]
    elsif stack.length == 2
      merge_two(stack[0], stack[1])
    else
      remaining = stack.clone
      while remaining.length > 2
        merged = merge_three(remaining[0], remaining[1], remaining[2])
        remaining.pop
        remaining.pop
        remaining.pop
      end

      # should be down to either 1 or 2
      merge_origins(remaining)
    end
  end


  def initialize(description, line_number, end_line_number,
                  origin_type, url, comments)
    if !description
      raise ArgumentError, "description may not be nil"
    end

    @description = description
    @line_number = line_number
    @end_line_number = end_line_number
    @origin_type = origin_type
    @url_or_nil = url
    @comments_or_nil = comments
  end

  attr_reader :description, :line_number, :end_line_number, :origin_type,
              :url_or_nil, :comments_or_nil

  def set_line_number(line_number)
    if (line_number == @line_number) and
        (line_number == @end_line_number)
      self
    else
      Hocon::Impl::SimpleConfigOrigin.new(
          @description, line_number, line_number,
          @origin_type, @url_or_nil, @comments_or_nil)
    end
  end

  def set_comments(comments)
    if Hocon::Impl::ConfigImplUtil.equals_handling_nil?(comments, @comments_or_nil)
      self
    else
      Hocon::Impl::SimpleConfigOrigin.new(
          @description, @line_number, @end_line_number,
          @origin_type, @url_or_nil, comments)
    end
  end

  def prepend_comments(comments)
    if Hocon::Impl::ConfigImplUtil.equals_handling_nil?(comments, @comments_or_nil)
      self
    elsif @comments_or_nil.nil?
      set_comments(comments)
    else
      merged = []
      merged.concat(comments)
      merged.concat(@comments_or_nil)
      set_comments(merged)
    end
  end

  def comments
    @comments_or_nil || []
  end

end