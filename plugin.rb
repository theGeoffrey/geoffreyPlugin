# name: theGeoffrey
# about: integrate theGeoffrey.co – your friendly discourse bot
# version: 0.1
# authors: Benjamin Kampmann


register_asset "javascripts/geoffrey.js"

after_initialize do
  require_dependency File.expand_path('../integrate.rb', __FILE__)
end