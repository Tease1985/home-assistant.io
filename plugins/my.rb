require 'uri'

module Jekyll
  module HomeAssistant
    class My < Liquid::Tag
      def initialize(tag_name, args, tokens)
        super
        raise SyntaxError, <<~MSG unless args.strip =~ SYNTAX
          Syntax error in tag 'my' while parsing the following options:

          #{args}

          Valid syntax:
            {% my <redirect> [title="Link name"] [badge] [icon[="icon-puzzle-piece"]] [addon="core_ssh"] [blueprint_url="http://example.com/blueprint.yaml"] [domain="hue"] [brand="philips"] [service="light.turn_on"] %}
        MSG

        @redirect = Regexp.last_match(1).downcase
        @options = Regexp.last_match(2)
      end

      def render(context)
        # We parse on render, as we now have context
        options = parse_options(@options, context)

        # Base URI
        uri = URI.join("https://my.home-assistant.io/redirect/", @redirect)

        # Build query string
        query = []
        query += [["addon", options[:addon]]] if options.include? :addon
        query += [["blueprint_url", options[:blueprint_url]]] if options.include? :blueprint_url
        query += [["domain", options[:domain]]] if options.include? :domain
        query += [["brand", options[:brand]]] if options.include? :brand
        query += [["repository_url", options[:repository_url]]] if options.include? :repository_url
        query += [["service", options[:service]]] if options.include? :service
        uri.query = URI.encode_www_form(query) unless query.empty?

        if options[:badge]
          raise ArgumentError, "Badges cannot have custom titles" if options[:title]

          "<a href='#{uri}' class='my badge' target='_blank'>" \
            "<img src='https://my.home-assistant.io/badges/#{@redirect}.svg' />" \
            "</a>"
        else
          title = @redirect.gsub("_", ' ').titlecase
          icon = ""

          if options[:title]
            # Custom title
            title = options[:title]
          elsif @redirect == "developer_call_service"
            # Developer service call
            title = "Call Service"
            title = "`#{options[:service]}`" if options.include? :service
          elsif DEFAULT_TITLES.include?(@redirect)
            # Lookup defaults
            title = DEFAULT_TITLES[@redirect]
          end

          if options[:icon]
            raise ArgumentError, "No default icon for redirect #{@redirect}" \
            if (!options[:icon].nil? == options[:icon]) && !DEFAULT_ICONS.include?(@redirect)

            icon = !options[:icon].nil? == options[:icon] ? DEFAULT_ICONS[@redirect] : @options[:icon]
            icon = "<i class='#{icon}' /> "
          end

          "#{icon}<a href='#{uri}' class='my' target='_blank'>#{title}</a>"
        end
      end

      private

      SYNTAX = /^([a-z_]+)((\s+\w+(=([\w\.]+?|".+?"))?)*)$/
      OPTIONS_REGEX = /(?:\w="[^"]*"|\w=[\w\.]+|\w)+/

      # Default icons when used in in-line text
      DEFAULT_ICONS = {
        "config_flow_start" => "icon-plus-sign",
        "config" => "icon-cog"
      }.freeze

      # Default title used for in-line text
      DEFAULT_TITLES = {
        "automations" => "Automations & Scenes",
        "blueprint_import" => "Import Blueprint",
        "cloud" => "Home Assistant Cloud",
        "config_energy" => "Energy Configuration",
        "config_flow_start" => "Add Integration",
        "config_mqtt" => "MQTT Configuration",
        "config_zha" => "ZHA Configuration",
        "config_zwave_js" => "Z-Wave JS Configuration",
        "config" => "Settings",
        "developer_events" => "Events",
        "developer_services" => "Services",
        "developer_states" => "States",
        "developer_template" => "Templates",
        "energy" => "Energy",
        "general" => "General Settings",
        "info" => "Information",
        "supervisor_info" => "Supervisor Information",
        "supervisor_backups" => "Backups",
        "integrations" => "Devices & Services"
      }.freeze

      def parse_options(input, context)
        options = {}
        return options if input.empty?

        # Split along 3 possible forms: key="value", key=value, or just key
        input.scan(OPTIONS_REGEX) do |opt|
          key, value = opt.split("=")
          unless value.nil?
            if value&.include?('"')
              value.delete!('"')
            else
              value = context[value]
            end
          end
          options[key.to_sym] = value || true
        end
        options
      end
    end
  end
end

Liquid::Template.register_tag('my', Jekyll::HomeAssistant::My)
