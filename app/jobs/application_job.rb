class ApplicationJob < ActiveJob::Base
  EMAIL_MAPPING = {
    '2015': {
      '1': 'ovaisinamullah@gmail.com',
      '2': 'brandon.tricou@gmail.com',
      '3': 'stewart.hackler@gmail.com',
      '4': 'sccrrckstr@gmail.com',
      '5': 'goblue101@gmail.com',
      '6': 'john.rosensweig@gmail.com',
      '7': 'jstatham3@gmail.com',
      '8': 'stephen.weil@gmail.com',
      '9': 'captrf@gmail.com',
      '10': 'seidmangar@gmail.com'
    },
    '2016': {
      '1': 'ovaisinamullah@gmail.com',
      '2': 'brandon.tricou@gmail.com',
      '3': 'stewart.hackler@gmail.com',
      '4': 'sccrrckstr@gmail.com',
      '5': 'goblue101@gmail.com',
      '6': 'john.rosensweig@gmail.com',
      '7': 'jstatham3@gmail.com',
      '8': 'stephen.weil@gmail.com',
      '9': 'captrf@gmail.com',
      '10': 'seidmangar@gmail.com'
    },
    '2017': {
      '1': 'ovaisinamullah@gmail.com',
      '2': 'mikelacy3@gmail.com',
      '3': 'stewart.hackler@gmail.com',
      '4': 'tonypelli@gmail.com',
      '5': 'goblue101@gmail.com',
      '6': 'pkaushish@gmail.com',
      '7': 'adamkos101@gmail.com',
      '8': 'stephen.weil@gmail.com',
      '9': 'captrf@gmail.com',
      '10': 'seidmangar@gmail.com'
    },
    '2018': {
      '1': 'ovaisinamullah@gmail.com',
      '2': 'mikelacy3@gmail.com',
      '4': 'tonypelli@gmail.com',
      '5': 'goblue101@gmail.com',
      '6': 'pkaushish@gmail.com',
      '7': 'adamkos101@gmail.com',
      '8': 'stephen.weil@gmail.com',
      '9': 'captrf@gmail.com',
      '10': 'seidmangar@gmail.com',
      '11': 'mattforetich4@gmail.com'
    },
    '2019': {
      '1': 'ovaisinamullah@gmail.com',
      '2': 'mikelacy3@gmail.com',
      '4': 'tonypelli@gmail.com',
      '5': 'goblue101@gmail.com',
      '6': 'pkaushish@gmail.com',
      '7': 'adamkos101@gmail.com',
      '8': 'stephen.weil@gmail.com',
      '9': 'captrf@gmail.com',
      '10': 'seidmangar@gmail.com',
      '11': 'sccrrckstr@gmail.com'
    },
    '2020': {
      '1': 'ovaisinamullah@gmail.com',
      '2': 'mikelacy3@gmail.com',
      '4': 'tonypelli@gmail.com',
      '5': 'goblue101@gmail.com',
      '6': 'pkaushish@gmail.com',
      '7': 'adamkos101@gmail.com',
      '8': 'stephen.weil@gmail.com',
      '9': 'captrf@gmail.com',
      '10': 'seidmangar@gmail.com',
      '11': 'sccrrckstr@gmail.com'
    },
    '2021': {
      '1': 'ovaisinamullah@gmail.com',
      '2': 'mikelacy3@gmail.com',
      '4': 'tonypelli@gmail.com',
      '5': 'goblue101@gmail.com',
      '6': 'pkaushish@gmail.com',
      '7': 'adamkos101@gmail.com',
      '8': 'stephen.weil@gmail.com',
      '9': 'captrf@gmail.com',
      '10': 'seidmangar@gmail.com',
      '11': 'sccrrckstr@gmail.com',
      '12': 'michael.i.zack@gmail.com',
      '13': 'john.rosensweig@gmail.com'
    },
    '2022': {
      '1': 'ovaisinamullah@gmail.com',
      '2': 'mikelacy3@gmail.com',
      '4': 'tonypelli@gmail.com',
      '5': 'goblue101@gmail.com',
      '6': 'pkaushish@gmail.com',
      '7': 'adamkos101@gmail.com',
      '8': 'stephen.weil@gmail.com',
      '9': 'captrf@gmail.com',
      '10': 'seidmangar@gmail.com',
      '11': 'sccrrckstr@gmail.com',
      '12': 'michael.i.zack@gmail.com',
      '13': 'john.rosensweig@gmail.com'
    },
    '2023': {
      '1': 'ovaisinamullah@gmail.com',
      '2': 'mikelacy3@gmail.com',
      '4': 'tonypelli@gmail.com',
      '5': 'goblue101@gmail.com',
      '6': 'pkaushish@gmail.com',
      '7': 'adamkos101@gmail.com',
      '8': 'stephen.weil@gmail.com',
      '9': 'captrf@gmail.com',
      '10': 'seidmangar@gmail.com',
      '11': 'sccrrckstr@gmail.com',
      '12': 'michael.i.zack@gmail.com',
      '13': 'austinlayton6@gmail.com'
    },
    '2024': {
      '1': 'ovaisinamullah@gmail.com',
      '2': 'mikelacy3@gmail.com',
      '4': 'tonypelli@gmail.com',
      '5': 'goblue101@gmail.com',
      '6': 'pkaushish@gmail.com',
      '7': 'adamkos101@gmail.com',
      '8': 'stephen.weil@gmail.com',
      '9': 'captrf@gmail.com',
      '10': 'seidmangar@gmail.com',
      '11': 'sccrrckstr@gmail.com',
      '12': 'michael.i.zack@gmail.com',
      '13': 'austinlayton6@gmail.com'
    },
    '2025': {
      '1': 'ovaisinamullah@gmail.com',
      '2': 'mikelacy3@gmail.com',
      '4': 'tonypelli@gmail.com',
      '5': 'goblue101@gmail.com',
      '6': 'pkaushish@gmail.com',
      '7': 'adamkos101@gmail.com',
      '8': 'stephen.weil@gmail.com',
      '9': 'captrf@gmail.com',
      '10': 'seidmangar@gmail.com',
      '11': 'sccrrckstr@gmail.com',
      '12': 'michael.i.zack@gmail.com',
      '13': 'austinlayton6@gmail.com'
    }
  }.with_indifferent_access

  private

  def sleeper_client
    @sleeper_client ||= SleeperRb::Client.new
  end

  def espn_cookies
    { SWID:"{#{Rails.application.credentials.espn_swid}}", espn_s2:Rails.application.credentials.espn_s2 }
  end
end
