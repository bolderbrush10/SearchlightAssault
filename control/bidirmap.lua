-- Tiny optimization, reduces calls to global table
local pairs = pairs
local next  = next


BiDirMap = {}


-- Supports a many-to-many mapping of keys and values
function BiDirMap.new()
  local bip = {}
  bip.lKeys = {}
  bip.rKeys = {}
  return bip
end


function BiDirMap.print(bip)
  game.print("Start-----")
  for lhsKey, lhsTable  in pairs(bip.lKeys) do
  	for rhsKey, mood in pairs(lhsTable) do
      game.print(lhsKey .. ", " .. rhsKey .. " : " .. tostring(mood))
    end
  end
  game.print("------End\n")
end


-- Associate a left-hand-side (LHS) key and a right-hand-side (RHS) key together
function BiDirMap.add(bip, lhs, rhs, mood)
	if mood == nil then
		mood = true
	end

  if not bip.lKeys[lhs] then
    bip.lKeys[lhs] = {}
  end

  if not bip.rKeys[rhs] then
    bip.rKeys[rhs] = {}
  end

	bip.lKeys[lhs][rhs] = mood
	bip.rKeys[rhs][lhs] = mood
end


-- Give an LHS key, get a list of any RHS keys
function BiDirMap.giveLeftKey(bip, lhs)
	return bip.lKeys[lhs] or {}
end


-- Give an LHS key, get the first mood listed by an associated RHS key
function BiDirMap.giveLeftMood(bip, lhs)
	if bip.lKeys[lhs] and next(bip.lKeys[lhs]) ~= nil then
		return select(2, next(bip.lKeys[lhs]))
	end
		
	return nil
end


-- Give an RHS key, get the first mood listed by an associated LHS key
function BiDirMap.giveRightMood(bip, rhs)
	if bip.rKeys[rhs] and next(bip.rKeys[rhs]) ~= nil then
		return select(2, next(bip.rKeys[rhs]))
	end
		
	return nil
end


-- Give an RHS key, get a list of any LHS keys
function BiDirMap.giveRightKey(bip, rhs)
	return bip.rKeys[rhs] or {}
end


function BiDirMap.removeLHS(bip, lhs)
	if not bip.lKeys[lhs] then
		return
	end

	for rKey, _ in pairs(bip.lKeys[lhs]) do
		bip.rKeys[rKey][lhs] = nil
		if next(bip.rKeys[rKey]) == nil then
			-- Clear empty tables
			bip.rKeys[rKey] = nil
		end
	end

	bip.lKeys[lhs] = nil
end


function BiDirMap.removeRHS(bip, rhs)
	if not bip.rKeys[rhs] then
		return
	end

	for lKey, _ in pairs(bip.rKeys[rhs]) do
		bip.lKeys[lKey][rhs] = nil
		if next(bip.lKeys[lKey]) == nil then
			-- Clear empty tables
			bip.lKeys[lKey] = nil
		end
	end

	bip.rKeys[rhs] = nil
end


function BiDirMap.empty(bip, bip)
  return next(bip.lKeys) == nil
end


return BiDirMap
