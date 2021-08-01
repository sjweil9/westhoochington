require Rails.root.join("app/lib/discord/channels/base")
Dir[Rails.root.join("app/lib/discord/channel") + "/**.rb"].each { |file| require file unless file =~ 'lib/discord/channels/base.rb' }