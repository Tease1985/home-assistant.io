module Jekyll
  module HomeAssistant
    class TerminologyTooltip < Liquid::Tag
      def initialize(tag_name, args, tokens)
        super
        raise SyntaxError, <<~MSG unless args.strip =~ SYNTAX
          Syntax error in tag 'term' while parsing the following options:

          #{args}

          Valid syntax:
            {% term <term> [<text>] %}
        MSG

        @term = Regexp.last_match(1)
        @text = Regexp.last_match(2)
      end

      def render(context)
        @term.gsub!('\"', "")
        entries = context.registers[:site].data["glossary"].select do |entry|
          entry.key?("term") and (@term.casecmp(entry["term"]).zero? or (entry.key?("aliases") and entry["aliases"].any? do |s|
                                                                           s.casecmp(@term).zero?
                                                                         end))
        end

        raise ArgumentError, "Term #{@term} was not found in the glossary" if entries.empty?
        raise ArgumentError, "Term #{@term} is in the glossary multiple times" if entries.length > 1
        raise ArgumentError, "Term #{@term} is missing a definition" unless entries[0].key?("definition")

        glossary = entries[0]

        definition = glossary["excerpt"] || glossary["definition"]

        if glossary.key?("link")
          rendered_link = Liquid::Template.parse(glossary["link"]).render(context).strip
          link = "<br><a class='terminology-link' href='#{rendered_link}' target='_blank'>[Learn more]</a>"
        end

        tooltip = "<span class='terminology-tooltip'>#{definition}#{link || ''}</span>"

        "<span class='terminology'>#{@text || @term}#{tooltip}</span>"
      end

      SYNTAX = /^(\w+?|".+?")(?:\s+(\w+|".+"))?$/
    end
  end
end

Liquid::Template.register_tag('term', Jekyll::HomeAssistant::TerminologyTooltip)
