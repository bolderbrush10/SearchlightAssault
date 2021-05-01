require "sl-defines"
require "control-common"


local gridSize = searchlightRange
local gridSize = searchlightRange / 8

-- TODO Use this iteration pattern over here:
--      It's very tedious to modify/remove from a lua list while iterating.
--      So we'll just iterate on the copy so we can modify the real list hassle free.
-- Copy table to simply removal while iterating

-- Grid: {Force, Surface, Area, Searchlight Count, Searchlights[], Foes[]}
function MakeGrid(sl_parent, position)
  return {force = sl_parent.force,
          surface = sl_parent.surface,
          area = GridBaseToGridArea(PositionToGridBase(position)),
          searchlightCount = 0,
          searchlights = {},
          foes = nil}
end


function PosToStr(pos)
  return tostring(pos.x) .. "," .. tostring(pos.y)
end


function PositionToGridStr(position)
  return PosToStr(PositionToGridBase(position))
end


function PositionToGridBase(position)
  -- Flatten the given position to the top-left of the grid
  return {x = position.x - (position.x % gridSize),
          y = position.y - (position.y % gridSize)}
end

function GridBaseToGridArea(position)
  return {position, {x = position.x + gridSize, y = position.y + gridSize}}
end


function AppendSurroundingPositions(position)
  return {position,
     {x = position.x - gridSize, y = position.y           },
     {x = position.x + gridSize, y = position.y           },
     {x = position.x - gridSize, y = position.y - gridSize},
     {x = position.x + gridSize, y = position.y + gridSize},
     {x = position.x - gridSize, y = position.y + gridSize},
     {x = position.x + gridSize, y = position.y - gridSize},
     {x = position.x,            y = position.y - gridSize},
     {x = position.x,            y = position.y + gridSize},
   }
end


function Grid_UpdateFoeGrids(tick)
  -- Iterate through select grid locs based on current tick? Or all of them every tick?
  for forceIndex, positionToGrids in pairs(global.forceToPositionToGrid) do
    index = 0
    for positionIndex, grid in pairs(positionToGrids) do
      index = index + 1

      if (tick % ticksBetweenFoeSearches == index % ticksBetweenFoeSearches) then
          Grid_CheckForFoes(grid)
          rendering.draw_rectangle{color={r=0.9, g=0.9, b=0, a=0.5},
                                   width=6,
                                   filled=False,
                                   left_top=grid.area[1],
                                   right_bottom=grid.area[2],
                                   surface=grid.surface,
                                   time_to_live=3,
                                   draw_on_ground=False}
        else
          rendering.draw_rectangle{color={r=0.9, g=0.0, b=0, a=0.5},
                                   width=6,
                                   filled=False,
                                   left_top=grid.area[1],
                                   right_bottom=grid.area[2],
                                   surface=grid.surface,
                                   time_to_live=3,
                                   draw_on_ground=False}
        end
    end
  end
end


function Grid_CheckForFoes(grid)
  grid.foes = grid.surface.find_units({area = grid.area,
                                       force = grid.force,
                                       condition = "enemy"})
  if grid.foes then
    global.gridsWithFoes[grid] = grid
  else
    global.gridsWithFoes[grid] = nil
  end
end


function Grid_GetGrid(sl_parent, position)
  slGridStr = PositionToGridStr(position)
  findex = sl_parent.force.index

  positionToGrid = global.forceToPositionToGrid[findex]
  if positionToGrid == nil then
    global.forceToPositionToGrid[findex] = {}
    global.forceToPositionToGrid[findex][slGridStr] = MakeGrid(sl_parent, position)
  else
    grid = positionToGrid[slGridStr]
    if grid == nil then
      global.forceToPositionToGrid[findex][slGridStr] = MakeGrid(sl_parent, position)
    end
  end

  return global.forceToPositionToGrid[findex][slGridStr]
end


function Grid_LookupGridFromSL(sl)
  slGridStr = PositionToGridStr(sl.position)
  findex = sl.force.index

  if global.forceToPositionToGrid[findex] ~= nil then
    return global.forceToPositionToGrid[findex][slGridStr]
  end

  return nil
end


function Grid_LookupGrid(sl_parent, position)
  slGridStr = PositionToGridStr(position)
  findex = sl_parent.force.index

  if global.forceToPositionToGrid[findex] ~= nil then
    return global.forceToPositionToGrid[findex][slGridStr]
  end

  return nil
end


function Grid_AddSpotlight(sl)
  slGridPos = PositionToGridBase(sl.position)
  gridPositions = AppendSurroundingPositions(slGridPos)

  for index, gridPos in pairs(gridPositions) do
    Grid_GetGrid(sl, gridPos)
  end

  slGrid = Grid_LookupGrid(sl, slGridPos)
  slGrid.searchlightCount = slGrid.searchlightCount + 1
  slGrid.searchlights[sl.unit_number] = sl
end


function Grid_RemoveSpotlight(sl)
  slGridPos = PositionToGridBase(sl.position)
  slGridPosStr = PosToStr(slGridPos)
  forceInd = sl.force.index

  Grid_LookupGrid(sl, slGridPos).searchlights[sl.unit_number] = nil
  Grid_LookupGrid(sl, slGridPos).searchlightCount = Grid_LookupGrid(sl, slGridPos).searchlightCount - 1

  -- First, check if there are still other searchlights in this grid.
  -- If there are, we can exit early.
  if Grid_LookupGrid(sl, slGridPos).searchlightCount > 0 then
    return
  end

  neighbors = AppendSurroundingPositions(slGridPos)

  -- For each neighbor-grid of the searchlight being removed
  for index, neighborLoc in pairs(neighbors) do

    neighborGrid = Grid_LookupGrid(sl, neighborLoc)
    -- Skip nil grid neighbors, and then...
    if neighborGrid then

      -- Check if any of the neighbor-of-neighbors (2nd order neighbors) still have any searchlights
      nofns = AppendSurroundingPositions(neighborLoc)

      -- If no 2nd order neighbors have a searchlight, delete it
      if not doesListHaveSearchLight(nofns, sl) then
        global.gridsWithFoes[neighborGrid] = nil
        global.forceToPositionToGrid[forceInd][PosToStr(neighborLoc)] = nil
      end

    end
  end

  -- If all grids for a force have been cleared, remove the force entry
  -- Yes, you check if dicts are empty in lua by calling 'next'...
  if next(global.forceToPositionToGrid[forceInd]) == nil then
    global.forceToPositionToGrid[forceInd] = nil
  end
end


function doesListHaveSearchLight(listOfGridPositions, parent_sl)
  for index, pos in pairs(listOfGridPositions) do
    currGrid = Grid_LookupGrid(parent_sl, pos)
    if currGrid and currGrid.searchlightCount > 0 then
      return true
    end
  end

  return false
end
