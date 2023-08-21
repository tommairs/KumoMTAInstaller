--[[
########################################################
KumoMTA Sink policy (Renamed init.lua for systemd automation)
This config policy defines KumoMTA as a pure sink.
It will consume and discard all incoming messages
########################################################
]]--

local kumo = require 'kumo'

-- This config acts as a sink that will discard all received mail

kumo.on('init', function()
  -- Define a listener.
  -- Can be used multiple times with different parameters to
  -- define multiple listeners!
  for _, port in ipairs { 25, 2026 } do
    kumo.start_esmtp_listener {
      listen = '0:' .. tostring(port),
    }
  end

  kumo.start_http_listener {
    listen = '0.0.0.0:8000',
  }

  -- Define the default "data" spool location.
  -- This is unused by this config, but we are required to
  -- define a default spool location.
  kumo.define_spool {
    name = 'data',
    path = '/var/spool/kumomta/data',
  }

  -- Define the default "meta" spool location.
  -- This is unused by this config, but we are required to
  -- define a default spool location.
  kumo.define_spool {
    name = 'meta',
    path = '/var/spool/kumomta/meta',
  }

  kumo.configure_local_logs {
    log_dir = '/var/log/kumomta',
    headers = { 'Subject' },
    max_segment_duration = '1 minute',
    per_record = {
      Reception = {
        suffix = '_recv',
      },
    Delivery = {
        suffix = '_deliv',
    },
    TransientFailure = {
        suffix = '_trans',
    },
    Bounce = {
        suffix = '_bounce',
    },
    -- For any record type not explicitly listed, apply these settings.
    -- This effectively turns off all other log records
    Any = {
        suffix = '_any',
    },
  },
}

end)

kumo.on('smtp_server_message_received', function(msg)
  -- Accept and discard all messages
     msg:set_meta('queue', 'null')
end)

kumo.on('http_message_generated', function(msg)
  -- Accept and discard all messages
     msg:set_meta('queue', 'null')
end)


