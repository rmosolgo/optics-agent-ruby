# optics-agent-ruby
Optics Agent for GraphQL Monitoring in Ruby.

This is an alpha release, suitable for use in development contexts. There are still some outstanding improvements to make it ready for production contexts; see the [known limitations](#known-limitations) section below.

[![Gem Version](https://badge.fury.io/rb/optics-agent.svg)](https://badge.fury.io/rb/optics-agent) [![Build Status](https://travis-ci.org/apollostack/optics-agent-ruby.svg?branch=master)](https://travis-ci.org/apollostack/optics-agent-ruby)


## Installing

Add

```ruby
gem 'optics-agent'
```

To your `Gemfile`

## Setup

### API key

You'll need to run your app with the `OPTICS_API_KEY` environment variable set to the API key of your Apollo Optics service; at the moment Optics is in early access alpha--[get in touch](http://www.apollostack.com/optics) if you want to be part of our early access program.

### Basic Rack/Sinatra

Create an agent

```ruby
# we expect one day there'll be some options
agent = OpticsAgent::Agent.instance
```

Register the Rack middleware (say in a `config.ru`):

```ruby
use agent.rack_middleware
```

Register the Graphql middleware:

```ruby
agent.instrument_schema(YourSchema)
```

Add something like this to your route:

```ruby
post '/graphql' do
  request.body.rewind
  params = JSON.parse request.body.read
  document = params['query']
  variables = params['variables']

  result = Schema.execute(
    document,
    variables: variables,
    context: { optics_agent: env[:optics_agent].with_document(document) }
  )

  JSON.generate(result)
end
```

## Rails

The equivalent of the above for Rails is:

Create an agent in `config/apllication.rb`, and register the rack middleware:

```ruby
module YourApplicationRails
  class Application < Rails::Application
    # ...

    config.optics_agent = OpticsAgent::Agent.instance
    config.middleware.use config.optics_agent.rack_middleware
  end
end

```

Register the Graphql middleware when you create your schema:

```ruby
Rails.application.config.optics_agent.instrument_schema(YourSchema)
```

Register Optics Agent on the GraphQL context within your `graphql` action as below:

```ruby
def create
  query_string = params[:query]
  query_variables = ensure_hash(params[:variables])

  result = YourSchema.execute(
    query_string,
    variables: query_variables,
    context: {
      optics_agent: env[:optics_agent].with_document(query_string)
    }
  )

  render json: result
end
```

You can check out the GitHunt Rails API server example here: https://github.com/apollostack/githunt-api-rails

## Known limitations

Currently the agent is in alpha state; it is intended for early access use in development or basic (non-performance oriented) staging testing.

We are working on resolving a [list of issues](https://github.com/apollostack/optics-agent-ruby/projects/1) to put together a production-ready beta launch. The headline issues as things stand are:

- The agent is overly chatty and uses a naive threading mechanism that may lose reporting data when threads exit/etc.
- Instrumentation timings may not be correct in all uses cases, and query times include the full rack request time.

You can follow along with our [Beta Release Project](https://github.com/apollostack/optics-agent-ruby/projects/1), or even get in touch if you want to help out getting there!

## Development

### Running tests

```
bundle install
bundle exec rspec
```

### Building protobuf definitions

Ensure you've installed `protobuf` and development dependencies.

```bash
# this works on OSX
brew install protobuf

# ensure it's version 3
protoc --version

bundle install
````

Compile the `.proto` definitions with

```bash
bundle exec rake protobuf:compile
```
