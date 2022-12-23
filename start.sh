# Initial setup
mix deps.get --only prod
MIX_ENV=prod mix compile

# Compile assets
MIX_ENV=prod mix assets.deploy

# Finally run the server
PORT=4001 MIX_ENV=prod mix phx.server
