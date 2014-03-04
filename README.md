# GrowthForecast Client [![Build Status](https://secure.travis-ci.org/sonots/growthforecast-client.png?branch=master)](http://travis-ci.org/sonots/growthforecast-client)

testing ruby: 1.9.2, 1.9.3, 2.0.0; GrowthForecast: >= 0.62 (Jun 27, 2013 released)

## About GrowthForecast Client

growthforecast-client is a ruby client library for GrowthForecast API where [GrowthForecast](http://kazeburo.github.com/GrowthForecast/) is a visualization graph tool.

With growthforecast-client, for example, you can edit properties of a graph such as `color`, and create a complex graph.

## USAGE

    gem install growthforecast-client

See [examples](examples) directory.

### CLI

GrowthForecast Client also provides a CLI named `growthforecast-client`.

Delete a graph or graphs under a path (copy and paste the URL from your GrowthForecast): 

```
$ growthforecast-client delete 'http://fqdn.to.growthforecast:5125/list/service_name'
```

Change the colors of graphs

```
$ growthforecast-client color 'http://fqdn.to.growthforecast:5125/list/service_name' -c 'graph_name:#1111cc' ...
```

See help for more:

```
$ growthforecast-client help
```

### Tips

#### Debug Print

Following codes prints the http requests and responses to STDOUT

```
client = GrowthForecast::Client.new('http://localhost:5125')
client.debug_dev = STDOUT # IO object
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new [Pull Request](../../pull/new/master)

## Copyright

Copyright (c) 2013 Naotoshi Seo. See [LICENSE](LICENSE) for details.
