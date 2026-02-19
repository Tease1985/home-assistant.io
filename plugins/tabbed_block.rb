require 'securerandom'

module Jekyll
  class TabbedBlock < Liquid::Block
    def slug(key)
      key.downcase.strip.gsub(' ', '-').gsub(/[^\w\-]/, '')
    end

    def render_tabbed_block(vars:, converter:, _classes: nil, _parent_type: nil)
      block = []
      tabs = []
      tab_content = []
      uuid = "id#{SecureRandom.hex(10)}"

      tabs << "<div class='tabbed-content-block-tabs'>"
      vars.map do |entry|
        tabs << "<label onclick='openTab(this)'><input type='radio' name='#{uuid}'>" \
                "<div id='#{uuid}-#{slug(entry['title'])}'>#{entry['title']}</div></label>"
        tab_content << "<div id='#{uuid}-#{slug(entry['title'])}' " \
                       "class='tabbed-content-block-content'>#{converter.convert(entry['content'].to_s)}</div>"
      end
      tabs << "</div>"
      block << tabs.join
      block << tab_content.join
      block.join
    end

    def render(context)
      contents = super(context)
      begin
        vars = SafeYAML.load(contents)
      rescue Psych::SyntaxError => e
        raise ArgumentError, "Failed to parse tabbed_block YAML: #{e.message}"
      end

      site = context.registers[:site]
      converter = site.find_converter_instance(::Jekyll::Converters::Markdown)

      <<~MARKUP
        <script>
        function openTab(tab){
          const tabKey = tab.querySelector("div").id;
          const targetTabContent = tab.parentElement.parentElement.querySelector(`#${tabKey}.tabbed-content-block-content`);
          const tabContents = tab.parentElement.parentElement.querySelectorAll(".tabbed-content-block-content")

          tabContents.forEach((content) => {
            content.style.display = "none"
          });
          targetTabContent.style.display = "block";
        }
        window.addEventListener('DOMContentLoaded', (event) => {
          const tabbedBlocks = document.querySelectorAll(".tabbed-content-block");
          tabbedBlocks.forEach((block) => {
              block.querySelector("input").checked = true;
              block.querySelector(".tabbed-content-block-content").style.display = "block";
          });

        });
        </script>
        <div class="tabbed-content-block">
          #{render_tabbed_block(vars:, converter:)}
        </div>
      MARKUP
    end
  end
end

Liquid::Template.register_tag('tabbed_block', Jekyll::TabbedBlock)
