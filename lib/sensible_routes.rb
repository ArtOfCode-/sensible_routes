# frozen_string_literal: true

class SensibleRoute
  attr_reader :path, :url_details, :parameters, :verb

  def initialize(rt)
    @parameters = []

    formatter = rt.path.build_formatter
    parts = []
    matcher = []

    # Yes, this is a hack. Yes, it will probably break. No, it's not 'temporary'.
    internal = formatter.instance_variable_get :@parts
    internal.each do |part|
      if part.is_a? String
        parts << part
        matcher << part
      elsif part.is_a? ActionDispatch::Journey::Format::Parameter
        parts << ":#{part.name}"
        @parameters << part.name
        matcher << if rt.requirements[part.name.to_sym]
                     rt.requirements[part.name.to_sym]
                   else
                     '[^/]+'
                   end
      end
    end

    @path = parts.join
    @url_details = rt.requirements
    @verb = rt.verb
    @regex = Regexp.new "^#{matcher.join}$"
  end

  def match?(path)
    @regex.match?(path)
  end

  def self.hook_rails
    Rails.instance_eval <<EOF
      cache.delete :sensible_routes
    
      def self.sensible_routes
        Rails.cache.fetch :sensible_routes do
          routes = SensibleRouteCollection.new
          Rails.application.routes.routes.to_a.each { |r| routes.add(SensibleRoute.new(r)) }
          return routes
        end
      end
EOF
  end
end

class SensibleRouteCollection
  def initialize(**opts)
    @routes = if opts[:routes]
                opts[:routes]
              else
                []
              end
  end

  def add(new)
    @routes << new
  end

  def to_a
    @routes
  end

  def select(&block)
    self.class.new(routes: @routes.select(&block))
  end

  def map(&block)
    @routes.map(&block)
  end

  def each
    @routes.each do |rt|
      yield rt
    end
    self
  end

  def match_for(path)
    @routes.select { |rt| rt.match?(path) }.first
  end

  def route_for(**url_details)
    @routes.select { |rt| url_details <= rt.url_details }.first
  end

  def controller(controller)
    self.class.new(routes: @routes.select { |rt| rt.url_details[:controller] == controller.to_s })
  end

  def without(*paths)
    routes = paths.map { |p| match_for p }
    self.class.new(routes: @routes - routes)
  end
end
