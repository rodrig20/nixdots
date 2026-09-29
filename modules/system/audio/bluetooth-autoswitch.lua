-- Bluetooth auto-switch for WirePlumber.

-- Connected Bluetooth sinks by bound-id.
tracked_sinks = {}
-- Connected Bluetooth sources by bound-id.
tracked_sources = {}
-- All sinks by bound-id for fallback lookup.
all_sinks = {}
-- All sources by bound-id for fallback lookup.
all_sources = {}
-- Active playback streams to retarget on switch.
playback_streams = {}

-- Default metadata holding configured defaults.
metadata_om = ObjectManager {
  Interest {
    type = "metadata",
    Constraint { "metadata.name", "=", "default" },
  }
}

-- Bluetooth sinks only.
bt_sinks_om = ObjectManager {
  Interest {
    type = "node",
    Constraint { "media.class", "matches", "Audio/Sink", type = "pw-global" },
    Constraint { "device.api", "=", "bluez5", type = "pw-global" },
    Constraint { "wireplumber.is-virtual", "!", true, type = "pw" },
    Constraint { "wireplumber.is-fallback", "!", true, type = "pw" },
  }
}

-- Bluetooth sources only.
bt_sources_om = ObjectManager {
  Interest {
    type = "node",
    Constraint { "media.class", "matches", "Audio/Source", type = "pw-global" },
    Constraint { "device.api", "=", "bluez5", type = "pw-global" },
    Constraint { "wireplumber.is-virtual", "!", true, type = "pw" },
    Constraint { "wireplumber.is-fallback", "!", true, type = "pw" },
  }
}

-- All sinks for fallback selection.
all_sinks_om = ObjectManager {
  Interest {
    type = "node",
    Constraint { "media.class", "matches", "Audio/Sink", type = "pw-global" },
    Constraint { "wireplumber.is-virtual", "!", true, type = "pw" },
    Constraint { "wireplumber.is-fallback", "!", true, type = "pw" },
  }
}

-- All sources for fallback selection.
all_sources_om = ObjectManager {
  Interest {
    type = "node",
    Constraint { "media.class", "matches", "Audio/Source", type = "pw-global" },
    Constraint { "wireplumber.is-virtual", "!", true, type = "pw" },
    Constraint { "wireplumber.is-fallback", "!", true, type = "pw" },
  }
}

-- Playback streams to retarget on sink switch.
playback_om = ObjectManager {
  Interest {
    type = "node",
    Constraint { "media.class", "matches", "Stream/Output/Audio", type = "pw-global" },
    Constraint { "stream.monitor", "!", "true", type = "pw" },
  }
}

-- Extract id, name, serial, api and priority from a node.
function node_info (node)
  local props = node.properties
  return {
    id = node ["bound-id"],
    name = props ["node.name"],
    serial = props ["object.serial"],
    api = props ["device.api"],
    prio = tonumber (props ["priority.session"]) or 0,
  }
end

-- Lookup the default metadata object.
function get_default_metadata ()
  return metadata_om:lookup { Constraint { "metadata.name", "=", "default" } }
end

-- Run with default metadata, retrying once if not ready yet.
function with_metadata (fn)
  local md = get_default_metadata ()
  if md then
    fn (md)
  else
    Core.timeout_add (500, function ()
      local md_retry = get_default_metadata ()
      if md_retry then
        fn (md_retry)
      end
    end)
  end
end

-- Set default sink/source in metadata.
function set_configured (kind, name)
  with_metadata (function (md)
    Log.info ("bluetooth-autoswitch: default " .. kind .. " -> " .. tostring (name))
    md:set (0, "default.configured." .. kind, "Spa:String:JSON",
        Json.Object { name = name }:to_string ())
  end)
end

-- Move tracked playback streams to target.
function move_playback_streams (target_serial)
  with_metadata (function (md)
    for stream_id, _ in pairs (playback_streams) do
      md:set (tonumber (stream_id), "target.object", "Spa:Id", target_serial)
    end
  end)
end

-- Best non-Bluetooth node, or nil.
function find_fallback (nodes)
  local best = nil
  for _, info in pairs (nodes) do
    if info.api ~= "bluez5" and (best == nil or info.prio > best.prio) then
      best = info
    end
  end
  return best
end

-- Any still-connected Bluetooth node, or nil.
function find_remaining_bt (tracked)
  for _, info in pairs (tracked) do
    return info
  end
  return nil
end

-- Set default sink and move playback to it.
function switch_sink (info)
  set_configured ("audio.sink", info.name)
  move_playback_streams (info.serial)
end

-- Track new Bluetooth sink and switch to it.
function on_bt_sink_added (_, node)
  local info = node_info (node)
  if not info.id or not info.name or not info.serial then
    return
  end
  Log.info ("bluetooth-autoswitch: bluetooth sink connected: " .. info.name)
  tracked_sinks [info.id] = info
  switch_sink (info)
end

-- Forget removed sink, fall back if needed.
function on_bt_sink_removed (_, node)
  local id = node ["bound-id"]
  if not tracked_sinks [id] then
    return
  end
  Log.info ("bluetooth-autoswitch: bluetooth sink disconnected")
  tracked_sinks [id] = nil
  local next = find_remaining_bt (tracked_sinks) or find_fallback (all_sinks)
  if next then
    switch_sink (next)
  end
end

-- Track new Bluetooth source and set as default.
function on_bt_source_added (_, node)
  local info = node_info (node)
  if not info.id or not info.name or not info.serial then
    return
  end
  Log.info ("bluetooth-autoswitch: bluetooth source connected: " .. info.name)
  tracked_sources [info.id] = info
  set_configured ("audio.source", info.name)
end

-- Forget removed source, fall back if needed.
function on_bt_source_removed (_, node)
  local id = node ["bound-id"]
  if not tracked_sources [id] then
    return
  end
  Log.info ("bluetooth-autoswitch: bluetooth source disconnected")
  tracked_sources [id] = nil
  local next = find_remaining_bt (tracked_sources) or find_fallback (all_sources)
  if next then
    set_configured ("audio.source", next.name)
  end
end

-- React to Bluetooth sink/source connect and disconnect.
bt_sinks_om:connect ("object-added", on_bt_sink_added)
bt_sinks_om:connect ("object-removed", on_bt_sink_removed)
bt_sources_om:connect ("object-added", on_bt_source_added)
bt_sources_om:connect ("object-removed", on_bt_source_removed)

-- Keep fallback sink list up to date.
all_sinks_om:connect ("object-added", function (_, node)
  local info = node_info (node)
  if info.id then
    all_sinks [info.id] = info
  end
end)
all_sinks_om:connect ("object-removed", function (_, node)
  all_sinks [node ["bound-id"]] = nil
end)

-- Keep fallback source list up to date.
all_sources_om:connect ("object-added", function (_, node)
  local info = node_info (node)
  if info.id then
    all_sources [info.id] = info
  end
end)
all_sources_om:connect ("object-removed", function (_, node)
  all_sources [node ["bound-id"]] = nil
end)

-- Track playback streams without an explicit target.
playback_om:connect ("object-added", function (_, node)
  local id = node ["bound-id"]
  if id and not node.properties ["target.object"] and not node.properties ["node.target"] then
    playback_streams [id] = true
  end
end)
playback_om:connect ("object-removed", function (_, node)
  playback_streams [node ["bound-id"]] = nil
end)

-- Start watching PipeWire objects.
metadata_om:activate ()
bt_sinks_om:activate ()
bt_sources_om:activate ()
all_sinks_om:activate ()
all_sources_om:activate ()
playback_om:activate ()
