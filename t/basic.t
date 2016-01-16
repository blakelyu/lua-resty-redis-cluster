# vim:set ft= ts=4 sw=4 et:

use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;/usr/local/openresty-dev/lualib/?.lua;";
    lua_package_cpath "/usr/local/openresty-dev/lualib/?.so;";
};

$ENV{TEST_NGINX_RESOLVER} = '8.8.8.8';
$ENV{TEST_NGINX_REDIS_PORT} ||= 6379;

no_long_string();
#no_diff();

run_tests();

__DATA__

=== TEST 1: module size of resty.redis
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local config = {
                name = "test",
                serv_list = {
                    {ip="127.0.0.1", port = 3100},
                    {ip="127.0.0.1", port = 3101},
                    {ip="127.0.0.1", port = 3102},
                    {ip="127.0.0.1", port = 3200},
                    {ip="127.0.0.1", port = 3201},
                    {ip="127.0.0.1", port = 3202},
                },
            }
            local redis_cluster = require "resty.rediscluster"
            local red_c = redis_cluster:new(config)
            local ok, err = red_c:set("a","b")
            ngx.say(ok)
        ';
    }
--- request
GET /t
--- response_body
OK
--- no_error_log
[error]

