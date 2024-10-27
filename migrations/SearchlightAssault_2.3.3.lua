local t = {}
for tick, listitem in pairs(storage.spotter_timeouts) do
	if not t[tick] then
		t[tick] = {}
	end
	t[tick][listitem] = true
end

storage.spotter_timeouts = t