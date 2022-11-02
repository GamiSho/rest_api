import Config

config :rest_api, port: 80
config :rest_api, mongo_url: "mongodb://root:example@localhost:27017/rest_api_db"
config :rest_api, pool_size: 3
config :rest_api, :basic_auth, username: "WDpCRC9z", password: "ZOnrvJoP"
