# frozen_string_literal: true

# Representation of a single route. Readers:
# @path: the normalized, parameterized path for the route (i.e. /labels/12/edit)
# @url_details: controller and action, plus any non-default parameter formats as regexes
# @parameters: an array of parameter names
# @verb: HTTP verb (GET, POST, etc)
# @request_line: minus the protocol, the HTTP request line (i.e. GET /labels/12/edit).
class SensibleRoute
  attr_reader :path, :url_details, :parameters, :verb, :request_line

  # Initialize a new SensibleRoute.
  # @param rt  a Journey route, as used internally by Rails
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
      elsif part.is_a? ActionDispatch::Journey::Format
        matcher << '(?:\.[^/]+)?'
      end
    end

    @path = parts.join
    @url_details = rt.requirements
    @verb = rt.verb
    @request_line = "#{@verb} #{@path}"
    @regex = Regexp.new "^#{matcher.join}$"
  end

  # Given a path (such as /labels/12/edit), detect whether that path is a match for this route
  # (i.e. the route is actually /labels/:id/edit, but /labels/12/edit is a match for that).
  # @param path  the path string to test
  # @return boolean
  def match?(path)
    @regex.match?(path)
  end

  # For use in gem initialization - call this once Rails is fully loaded so that Rails.sensible_routes
  # can be set up.
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

# An array-like collection of SensibleRoutes.
class SensibleRouteCollection
  # Initialize a new route collection. For an empty collection, call with no arguments; for a
  # collection built from an existing array of routes, call with the routes: option.
  def initialize(**opts)
    @routes = if opts[:routes]
                opts[:routes]
              else
                []
              end
  end

  # Add a route to the collection.
  # @param new  the route to add
  def add(new)
    @routes << new
  end

  # Get an array representation of the collection.
  # @return Array
  def to_a
    @routes
  end

  # Get a route at a particular index from the collection.
  # @param idx  the index from which to return an element
  # @return SensibleRoute
  def [](idx)
    @routes[idx]
  end

  # Get the first route in the collection.
  # @return SensibleRoute
  def first
    @routes[0]
  end

  # Get the last route in the collection.
  # @return SensibleRoute
  def last
    @routes[-1]
  end

  # Filter the collection to only those entries that match the given block.
  # @param &block  a block that returns true to retain an element, or false to reject it
  # @return SensibleRouteCollection
  def select(&block)
    self.class.new(routes: @routes.select(&block))
  end

  # Map over the collection, applying the given block as a transformation to each element.
  # @param &block  a block to apply to each element; the return value will be included in the returned array
  # @return Array
  def map(&block)
    @routes.map(&block)
  end

  # Iterate through the collection, performing the specified operation with each element.
  # @param &block  a block is required; it will be passed the current element as an argument
  # @return self
  def each
    @routes.each do |rt|
      yield rt
    end
    self
  end

  # Find a match from the current route collection for a given path string. Useful for finding the current
  # route being executed.
  # @param path  the path string to find a matching route for
  # @return SensibleRoute
  def match_for(path)
    @routes.select { |rt| rt.match?(path) }.first
  end

  # Find the route that responds to the provided url_details (action and controller names).
  # @param url_details  the name of a controller and action to find the route for
  # @return SensibleRoute
  def route_for(**url_details)
    @routes.select { |rt| url_details <= rt.url_details }.first
  end

  # Filter the collection down to only the routes served by the specified controller.
  # @param controller  the controller name whose routes should be returned
  # @return SensibleRouteCollection
  def controller(controller)
    self.class.new(routes: @routes.select { |rt| rt.url_details[:controller] == controller.to_s })
  end

  # Given a list of path strings, return a new collection with their corresponding routes removed.
  # @param paths  a list of path strings to find routes for and remove
  # @return SensibleRouteCollection
  def without(*paths)
    routes = paths.map { |p| match_for p }
    self.class.new(routes: @routes - routes)
  end
end
