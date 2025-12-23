rule = {
	matches = {
		{
			-- Match any USB audio device
			{ "device.bus", "equals", "usb" },
			{ "media.class", "starts-with", "Audio/" },
		},
	},
	apply_properties = {
		["priority.session"] = 10000,
	},
}

table.insert(alsa_monitor.rules, rule)
