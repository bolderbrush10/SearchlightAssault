-- Tiny optimization, reduces calls to global table
local pairs = pairs
local next  = next


-- We'll represent the existence of a relationship using a 2D matrix.
-- For now, to make up for inefficiencies with this implementation,
-- we'll just try to construct these such that the LHS is more sparse.
-- In the future, maybe we'll look at making a proper bidirectional map.

-- Since the game engine wipes out metatables across save/load,
-- we'll have to use primitive methods to emulate a class


Relation = {}


function Relation.empty(rel)
  return next(rel.matrix) == nil
end


function Relation.setRelation(rel, lhs, rhs, mood)
  if not lhs or not rhs then
    return
  end

  if not mood then
    mood = true
  end

  if not rel.matrix[lhs] then
    rel.matrix[lhs] = {}
  end

  rel.matrix[lhs][rhs] = mood
end


function Relation.hasRelation(rel, lhs, rhs)
  return rel.matrix[lhs] and rel.matrix[lhs][rhs]
end


function Relation.getRelation(rel, lhs, rhs)
  if rel.matrix[lhs] then
    return rel.matrix[lhs][rhs]
  end

  return nil
end


function Relation.getRelationLHS(rel, lhs)
  return rel.matrix[lhs] or {}
end


function Relation.getRelationRHS(rel, rhs)
  local results = {}
  for lhsInd, lhs in pairs(rel.matrix) do
    if lhs[rhs] then
    results[lhsInd] = true
    end
  end
  return results
end


function Relation.getRelationMatrix(rel)
  return rel.matrix
end


function Relation.removeRelation(rel, lhs, rhs)
  if not rel.matrix[lhs] then
    return
  end

  rel.matrix[lhs][rhs] = nil

  -- Clear {} (empty tables)
  if next(rel.matrix[lhs]) == nil then
    rel.matrix[lhs] = nil
  end
end


function Relation.removeRelationLHS(rel, lhs)
  rel.matrix[lhs] = nil
end


function Relation.removeRelationRHS(rel, rhs)
  for _, lhs in pairs(rel.matrix) do
    lhs[rhs] = nil

    -- Clear {} (empty tables)
    if rel.matrix[lhs] and next(rel.matrix[lhs]) == nil then
      rel.matrix[lhs] = nil
    end
  end
end


-- Returns dict: {rhs, mood}
function Relation.popRelationLHS(rel, lhs)
  if not rel.matrix[lhs] then
    return {}
  end

  local results = {}

  for rhs, val in pairs(rel.matrix[lhs]) do
    results[rhs] = val
  end

  rel.matrix[lhs] = nil
  return results
end


-- Returns dict: {lhs, mood}
function Relation.popRelationRHS(rel, rhs)
  local results = {}

  for _, lhs in pairs(rel.matrix) do
    results[lhs] = lhs[rhs]
    lhs[rhs] = nil

    -- Clear {} (empty tables)
    if next(rel.matrix[lhs]) == nil then
      rel.matrix[lhs] = nil
    end
  end

  return results
end


function Relation.print(rel)
  game.print("Start-----")
  for lhsInd, lhs in pairs(rel.matrix) do
    for rhsInd, rhs in pairs(lhs) do
      game.print(lhsInd .. ", " .. rhsInd .. ": " .. tostring(rhs))
    end
  end
  game.print("------End\n")
end


function Relation.newRelation()
  local rel = {}
  rel.matrix = {}
  return rel
end


return Relation