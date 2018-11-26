-------------------------------------------------------------------------------
--[[Belt Highlighter]] --
-------------------------------------------------------------------------------
-- Concept designed and code written by TheStaplergun (staplergun on mod portal)
-- STDLib and code reviews provided by Nexela

local Player = require('lib/player')
local Event = require('lib/event')
local Position = require('lib/position')
local op_dir = Position.opposite_direction

local function get_ew(delta_x)
    return delta_x > 0 and defines.direction.west or defines.direction.east
end

local function get_ns(delta_y)
    return delta_y > 0 and defines.direction.north or defines.direction.south
end

local function get_direction(entity_position, neighbour_position)
    local abs = math.abs
    local delta_x = entity_position.x - neighbour_position.x
    local delta_y = entity_position.y - neighbour_position.y
    if delta_x ~= 0 then
        if delta_y == 0 then
            return get_ew(delta_x)
        else
            local adx, ady = abs(delta_x), abs(delta_y)
            if adx > ady then
                return get_ew(delta_x)
            else --? Exact diagonal relations get returned as a north/south relation.
                return get_ns(delta_y)
            end
        end
    else
        return get_ns(delta_y)
    end
end

local function show_underground_sprites(event)
    local player, pdata = Player.get(event.player_index)
    local create = player.surface.create_entity
    local read_entity_data = {}
    local all_entities_marked = {}
    local all_markers = {}
    local markers_made = 0
    --? Assign working table reference to global reference under player
    pdata.current_underground_marker_table = all_markers

    local max_distance = settings.global['picker-max-distance-checked'].value

    local filter = {
        area = {{player.position.x - max_distance, player.position.y - max_distance}, {player.position.x + max_distance, player.position.y + max_distance}},
        type = {'underground-belt'},
        force = player.force
    }
    for _, entity in pairs(player.surface.find_entities_filtered(filter)) do
        local entity_unit_number = entity.unit_number
        local entity_position = entity.position
        local entity_neighbours = entity.neighbours
        read_entity_data[entity_unit_number] = {
            entity_position,
            entity_neighbours,
        }
    end
    for unit_number, entity_data in pairs(read_entity_data) do
        if entity_data[2] then
            markers_made = markers_made + 1
            all_markers[markers_made] =
                create {
                name = 'picker-pipe-marker-box-good',
                position = entity_data[1]
            }
        else
            markers_made = markers_made + 1
            all_markers[markers_made] =
                create {
                name = 'picker-pipe-marker-box-bad',
                position = entity_data[1]
            }
        end
        local neighbour_unit_number = entity_data[2] and entity_data[2].unit_number
        local neighbour_data = read_entity_data[neighbour_unit_number]
        if neighbour_data then
            if not all_entities_marked[neighbour_unit_number] then
                local start_position = Position.translate(entity_data[1], get_direction(entity_data[1], neighbour_data[1]), 0.5)
                local end_position = Position.translate(neighbour_data[1], get_direction(neighbour_data[1], entity_data[1]), 0.5)
                markers_made = markers_made + 1
                all_markers[markers_made] =
                    create {
                    name = 'picker-underground-marker-beam',
                    position = entity_data[1],
                    source_position = {start_position.x, start_position.y + 1},
                    --TODO 0.17 source_position = {entity_position.x, entity_position.y - 0.1},
                    target_position = end_position,
                    duration = 2000000000
                }
            end
        end
        all_entities_marked[unit_number] = true
    end
end

local function destroy_markers(markers)
    if markers then
        for _, entity in pairs(markers) do
            entity.destroy()
        end
    end
end

local function highlight_underground(event)
    local _, pdata = Player.get(event.player_index)
    pdata.current_underground_marker_table = pdata.current_underground_marker_table or {}
    if next(pdata.current_underground_marker_table) then
        destroy_markers(pdata.current_underground_marker_table)
        pdata.current_underground_marker_table = nil
    else
        show_underground_sprites(event)
    end
end
Event.register('picker-show-underground-belt-paths', highlight_underground)



local function highlight_belts(player)
    local player, pdata = Player.get(event.player_index)
    local belt_table = {}
    local read_entity_data = {}
    local all_entities_marked = {}
    local find_belt = player.surface.find_entities_filtered
    local position_translate = Position.translate

    local function read_forward_belt(entity_position, entity_direction)
        local forward_position = position_translate(entity_position, entity_direction, 1)
        local forward_entity = find_belt({
            position = forward_position,
            type = {'transport-belt', 'underground-belt', 'splitter'},
        })
        if forward_entity then
            local forward_entity_direction = forward_entity.direction
            if not (forward_entity_direction == op_dir(entity_direction)) then
                local forward_entity_type = forward_entity.type
                if forward_entity_type == 'underground-belt' and forward_entity_direction ~= entity_direction then
                    return {forward_entity, forward_entity_direction, forward_position, forward_entity_type}
                else
                    return {false,false,false,false}
                end
            else
                return {false,false,false,false}
            end
        end
    end

    local function read_forward_splitter()
        local forward_entity = find_belt({
            area = Position(entity_position):copy():translate(entity_direction, 1):expand_to_area(1),
            type = {'transport-belt', 'underground-belt', 'splitter'},
        })
        if forward_entity then
            local forward_entity_direction = forward_entity.direction
            if not (forward_entity_direction == op_dir(entity_direction)) then
                return {forward_entity,forward_entity_direction}
            end
        end
    end

    local function read_belts(entity, entity_unit_number, entity_position, entity_type, entity_direction)

        local function step_forward(entity, entity_unit_number, entity_position, entity_type, entity_direction, previous_entity_un)
            local entity_neighbours = {}
            if previous_entity_un then
                entity_neighbours[#entity_neighbours + 1] = previous_entity_un
            end
            --? Cache current entity
            read_entity_data[entity_unit_number] = {
                entity_position,
                entity_neighbours,
                entity_type,
                entity_direction,
                entity
            }
            --? Underground belt handling
            if entity_type == 'underground-belt' then
                local ug_neighbour = entity.neighbours
                --? UG Belts always return an entity reference as the neighbour
                if ug_neighbour then
                    local ug_neighbour_type = 'underground-belt'
                    local ug_neighbour_direction = entity_direction
                    local ug_neighbour_position = neighbour.position
                    --? Make sure we don't get stuck in a recursive belt loop and only step forward.
                    if entity.belt_to_ground_type == 'input' then
                        local ug_neighbour_unit_number = neighbour.unit_number
                        entity_neighbours[#entity_neighbours + 1] = ug_neighbour_unit_number
                        if not read_entity_data[neighbour_unit_number] then
                            if belts_read < max_belts then
                                step_forward(ug_neighbour, ug_neighbour_unit_number, ug_neighbour_position, ug_neighbour_type, ug_neighbour_direction, entity_unit_number)
                            end
                        end
                    end
                else
                    local forward_entity, forward_entity_direction, forward_entity_position, forward_entity_type = read_forward_belt(entity_position, entity_direction)
                    if forward_entity then
                        local forward_entity_unit_number = forward_entity.unit_number
                        entity_neighbours[#entity_neighbours + 1] = forward_entity_unit_number
                        if not read_entity_data[forward_entity_unit_number] then
                            if belts_read < max_belts then
                                step_forward(forward_entity, forward_entity_unit_number, forward_entity_position, forward_entity_type, forward_entity_direction, entity_unit_number)
                            end
                        end
                    end
                end
            end


        end
        if forward_entity then
            local forward_entity_direction = forward_entity.direction
            if not (forward_entity_direction == op_dir(entity_direction) then
                step_forward()
    end

    local starter_unit_number = starter_entity.unit_number
    local starter_entity_direction = starter_entity.direction
    local starter_entity_type = starter_entity.type
    local starter_entity_position = starter_entity.position
    read_belts(starter_entity, starter_unit_number, starter_entity_position, starter_entity_type, starter_entity_direction)
