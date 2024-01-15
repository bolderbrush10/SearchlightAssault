local b = require("../bidirmap")

-- Allow testing from cmd line
if not game then
	game = {}
	game.print = print
end
if not serpent then
	-- You can just download the serpent .lua file from
	-- https://github.com/pkulchenko/serpent/blob/master/src/serpent.lua
	-- and shove it into your C:/programfiles/lua_install/ or wherever you're running from
	serpent = require("serpent")
end


function countLHS(bip)
	local count = 0
	for _, _ in pairs(bip.lKeys) do
		count = count + 1
	end
	return count
end

function countRHS(bip)
	local count = 0
	for _, _ in pairs(bip.rKeys) do
		count = count + 1
	end
	return count
end


local bip = b.new()

assert(bip ~= nil)
-- Make sure that trying to get a non-existing key gives an empty list
assert(b.giveLeftKey(bip, 4) ~= nil, serpent.block(b.giveLeftKey(bip, 4)))
assert(next(b.giveLeftKey(bip, 4)) == nil, serpent.block(b.giveLeftKey(bip, 4)))


--print("init bip")
b.add(bip, 2, 1111)
b.add(bip, 3, 1111)
b.add(bip, 3, 3333)
b.add(bip, 3, 5555)
b.add(bip, 4, 3333)
b.add(bip, 4, 5555)
b.add(bip, 5, 5555)
b.add(bip, 7, 8, "testmood")
b.add(bip, 8, 9, "testtest")
b.add(bip, 9, 8)
b.add(bip, 9, 9)
--b.print(bip)

assert(countLHS(bip) == 7, countLHS(bip))
assert(countRHS(bip) == 5, countRHS(bip))
assert(next(b.giveLeftKey(bip, 2)) == 1111)
assert(next(b.giveRightKey(bip, 9)) == 8)

assert(b.giveLeftMood(bip, 9) == true, 
			 tostring(b.giveLeftMood(bip, 9)))
assert(b.giveLeftMood(bip, 10) == nil, 
			  tostring(b.giveLeftMood(bip, 10)))
assert(b.giveLeftMood(bip, 7) == "testmood", 
			  tostring(b.giveLeftMood(bip, 7)))
assert(b.giveLeftMood(bip, 8) == "testtest", 
			  tostring(b.giveLeftMood(bip, 8)))

assert(b.giveRightMood(bip, 9) == "testtest", 
			 tostring(b.giveRightMood(bip, 9)))
assert(b.giveRightMood(bip, 11) == nil, 
			 tostring(b.giveRightMood(bip, 11)))
assert(b.giveRightMood(bip, 3333) == true, 
			 tostring(b.giveRightMood(bip, 3333)))


-- Give an LHS key, get the first mood listed by an associated RHS key
function BiDirMap.giveLeftMood(bip, lhs)
	if bip.lKeys[lhs] then
		return next(bip.lKeys[lhs])
	end
		
	return nil
end




--print("removeRHS for right value 5555")
b.removeRHS(bip, 5555)
--b.print(bip)

assert(countLHS(bip) == 6, countLHS(bip))
assert(countRHS(bip) == 4, countRHS(bip))


--print("removeLHS for left value 3")
b.removeLHS(bip, 3)
--b.print(bip)

assert(countLHS(bip) == 5, countLHS(bip))
assert(countRHS(bip) == 4, countRHS(bip))


--print("removeLHS for left value 8")
b.removeLHS(bip, 8)
--b.print(bip)

assert(countLHS(bip) == 4, countLHS(bip))
assert(countRHS(bip) == 4, countRHS(bip))



--print("removeLHS for right value 8")
b.removeRHS(bip, 8)
--b.print(bip)

assert(countLHS(bip) == 3, countLHS(bip))
assert(countRHS(bip) == 3, countRHS(bip))
