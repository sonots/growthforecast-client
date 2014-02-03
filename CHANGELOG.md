# 0.80.0 (2014/02/03)

Changes:

  - Use `net/http` instead of `httpclient` because we met difficulties in multi-thread environments

# 0.62.4 (2014/02/01)

Features:

  - Add `keepalive` option
  - Proxy httpclient parameters

# 0.62.3 (2013/09/20)

Features:

  - Add -g and -s options to `delete` command

# 0.62.2 (2013/09/19)

Changes:

  - Change option -u to an argument of `color`, `create_complex` command

# 0.62.1 (2013/09/19)

Features:

  - Add `growthforecast-client color` command
  - Add `growthforecast-client create_complex` command

Changes:

  - Change `growthforecast-client delete_graph` to `delete` command

# 0.62.0 (2013/07/02)

Changes:

  - Version up!

# 0.0.6 (2013/05/17)

Features:

  - Add `#base_uri` method

# 0.0.5 (2013/05/16)

Features:

  - Add `#last_response` method to get HTTPClient response directory
  - Add `#client=` method to replace HTTPClient object

# 0.0.3
Add bin/growthforecast-client delete_graph
