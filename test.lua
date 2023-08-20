--[[ *************************************** ]]--
--    TEST.LUA
--    A version of config used for speed testing
--[[ *************************************** ]]--

local kumo = require 'kumo'

kumo.on('init', function()
  kumo.define_spool {
    name = 'data',
    path = '/var/spool/kumomta/data',
    kind = 'RocksDB',
  }

  kumo.define_spool {
    name = 'meta',
    path = '/var/spool/kumomta/meta',
    kind = 'RocksDB',
  }

  kumo.configure_local_logs {
    log_dir = '/var/log/kumomta',
    headers = { 'Subject', 'X-Customer-ID' },
  }

  kumo.configure_bounce_classifier {
    files = {
      '/opt/kumomta/share/bounce_classifier/iana.toml',
    },
  }

  kumo.start_http_listener {
    listen = '0.0.0.0:8000',
    -- allowed to access any http endpoint without additional auth
    trusted_hosts = { '127.0.0.1', '::1' },
  }

  kumo.start_esmtp_listener {
    listen = '0.0.0.0:25',
    -- override the default set of relay hosts
    relay_hosts = { '127.0.0.1', '192.168.1.0/24' },
    tls_private_key = '/opt/kumomta/etc/tls/ca.key',
    tls_certificate = '/opt/kumomta/etc/tls/ca.crt',
  }

  kumo.define_egress_source {
    name = 'ip-1',
    source_address = '172.31.30.241',
    ehlo_domain = 'mta1.examplecorp.com',
  }

  kumo.define_egress_pool {
    name = 'TenantOne',
    entries = {
      { name = 'ip-1' },
    },
  }

end) -- END OF THE INIT EVENT

-- Helper function that merges the values from `src` into `dest`
function merge_into(src, dest)
  for k, v in pairs(src) do
    dest[k] = v
  end
end

kumo.on('get_egress_path_config', function(domain, egress_source, site_name)
  return kumo.make_egress_path {
    connection_limit = 32,
    smtp_port = 587,
    enable_tls = "OpportunisticInsecure",
  }


end)

local TENANT_PARAMS = {
  TenantOne = {
    max_age = '5 minutes',
  },
}

kumo.on('get_queue_config', function(domain, tenant, campaign)
  local params = {
    egress_pool = tenant,
  }
  merge_into(TENANT_PARAMS[tenant] or {}, params)
  return kumo.make_queue_config(params)
end)

kumo.on('smtp_server_message_received', function(msg)
  -- Assign tenant based on X-Tenant header.
  msg:set_meta('queue', '[20.83.209.56]')
end)

