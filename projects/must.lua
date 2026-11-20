-- Returns `value`, or fails the action with `err` when there is none. Wrap a
-- call that returns nil and a message, as Rex's own calls do.

return function(value, err)
  if value == nil then error(err or "unknown error", 0) end
  return value
end
