# `sensible_routes`
Simple and comprehensible route introspection library for Rails.

## Huh?
In a stock Rails app, `rake routes` is essentially the only way to get any introspection of routes. There's no programmatic access to them in detail,
beyond basic route helpers. This gem aims to make detailed programmatic introspection possible.

## Installation
Add the following line to your Gemfile and run `bundle install`:

    gem 'sensible_routes'
    
Then, create a new initializer (say `config/initializers/sensible_routes.rb`), with this as its only content:

    SensibleRoute.hook_rails
    
## Usage
At a basic level, you can get a list of your application's routes in a useful form with this:

    Rails.sensible_routes
    
That returns a SensibleRouteCollection, which is array-like in that it responds to many of the same methods. You can also filter the collection down
further - see the API documentation for full details.

## Contributions
Welcome. Ping me a PR. For large changes you should probably open an issue first to discuss.

## License
Available under the terms of the MIT license.