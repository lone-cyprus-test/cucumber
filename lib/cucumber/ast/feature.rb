require 'cucumber/ast/names'

module Cucumber
  module Ast
    # Represents the root node of a parsed feature.
    class Feature #:nodoc:
      include Names

      attr_accessor :language
      attr_writer :features, :background
      attr_reader :file

      def initialize(background, comment, tags, keyword, title, description, feature_elements)
        @background, @comment, @tags, @keyword, @title, @description, @feature_elements = background, comment, tags, keyword, title, description, feature_elements
      end

      attr_reader :gherkin_statement
      def gherkin_statement(statement=nil)
        @gherkin_statement ||= statement
      end

      def init
        @background.feature = self if @background
        @background.init if @background
        @feature_elements.each do |feature_element|
          feature_element.init
          feature_element.feature = self
        end
      end

      def add_feature_element(feature_element)
        @feature_elements << feature_element
      end

      def accept(visitor)
        return if Cucumber.wants_to_quit
        init
        visitor.visit_comment(@comment) unless @comment.empty?
        visitor.visit_tags(@tags)
        visitor.visit_feature_name(@keyword, indented_name)
        visitor.visit_background(@background) if @background
        @feature_elements.each do |feature_element|
          visitor.visit_feature_element(feature_element)
        end
      end

      def indented_name
        indent = ""
        name.split("\n").map do |l|
          s = "#{indent}#{l}"
          indent = "  "
          s
        end.join("\n")
      end

      def source_tag_names
        (@tags ? @tags.tag_names.to_a : [] + (@feature ? @feature.source_tag_names.to_a : [])).uniq
      end

      def accept_hook?(hook)
        @tags.accept_hook?(hook)
      end

      def next_feature_element(feature_element, &proc)
        init
        index = @feature_elements.index(feature_element)
        next_one = @feature_elements[index+1]
        proc.call(next_one) if next_one
      end

      def backtrace_line(step_name, line)
        "#{file_colon_line(line)}:in `#{step_name}'"
      end

      def file=(file)
        file = file.gsub(/\//, '\\') if Cucumber::WINDOWS && file && !ENV['CUCUMBER_FORWARD_SLASH_PATHS']
        @file = file
      end

      def file_colon_line(line)
        "#{@file}:#{line}"
      end

      def short_name
        first_line = name.split(/\n/)[0]
        if first_line =~ /#{language.keywords('feature')}:(.*)/
          $1.strip
        else
          first_line
        end
      end

      def to_sexp
        init
        sexp = [:feature, @file, name]
        comment = @comment.to_sexp
        sexp += [comment] if comment
        tags = @tags.to_sexp
        sexp += tags if tags.any?
        sexp += [@background.to_sexp] if @background
        sexp += @feature_elements.map{|fe| fe.to_sexp}
        sexp
      end
    end
  end
end
