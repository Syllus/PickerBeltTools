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

local map_direction = {
    [0] = '-n',
    [2] = '-e',
    [4] = '-s',
    [6] = '-w'
}
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
        local entity_belt_direction = entity.belt_to_ground_type
        local entity_direction = entity.direction
        --local entity_name = entity.name
        read_entity_data[entity_unit_number] = {
            entity_position,
            entity_neighbours,
            entity_belt_direction,
            entity_direction
            --entity_name
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
                local start_position = Position.translate(entity_data[1], entity_data[4], 0.5)
                local end_position = Position.translate(neighbour_data[1], op_dir(entity_data[4]), 0.5)
                if entity_data[3] == 'input' then
                    markers_made = markers_made + 1
                    all_markers[markers_made] =
                        create {
                        name = 'picker-underground-belt-marker-beam',
                        position = entity_data[1],
                        source_position = {start_position.x, start_position.y + 1},
                        --TODO 0.17 source_position = {entity_position.x, entity_position.y - 0.1},
                        target_position = end_position,
                        duration = 2000000000
                    }
                    all_entities_marked[unit_number] = true

                end
            end
        end

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

local allowed_types = {
    ['underground-belt'] = true,
    ['transport-belt'] = true,
    ['splitter'] = true
}

local splitter_check_table = {
    [defines.direction.north] = {
        left = Position.new({x = -0.5, y = -1}),
        right = Position.new({x = 0.5, y = -1})
    },
    [defines.direction.east] = {
        left = Position.new({x = 1, y = -0.5}),
        right = Position.new({x = 1, y = 0.5})
    },
    [defines.direction.south] = {
        left = Position.new({x = 0.5, y = 1}),
        right = Position.new({x = -0.5, y = 1})
    },
    [defines.direction.west] = {
        left = Position.new({x = -1, y = 0.5}),
        right = Position.new({x = -1, y = -0.5})
    },
}

--[[local function copy_position(position)
    return {x=position.x,y=position.y}
end]]--

local function highlight_belts(selected_entity, player_index)
    local player, pdata = Player.get(player_index)
    --local belt_table = {}
    local read_entity_data = {}
    local all_entities_marked = {}
    local all_markers = {}

    local markers_made = 0

    --? Assign working table references to global reference under player
    pdata.current_marker_table = all_markers
    pdata.current_beltnet_table = all_entities_marked

    --? Cache functions used more than once
    local find_belt = player.surface.find_entities_filtered
    local create = player.surface.create_entity

    local function read_forward_belt(forward_position)
        return find_belt({
            position = forward_position,
            type = {'transport-belt', 'underground-belt', 'splitter'},
        })[1]
    end

    -- TODO Make two individual point checks and return two entry table
    local function read_forward_splitter(entity_position, entity_direction)
        local shift_directions = splitter_check_table[entity_direction]
        --local left_pos = Position(entity_position):copy():add(shift_directions.left):copy()
        --local right_pos = Position(entity_position):copy():add(shift_directions.right):copy()
        local left_pos = entity_position + shift_directions.left
        local right_pos = entity_position + shift_directions.right
        return {
            left_entity = {
                entity = find_belt({
                    position = left_pos,
                    type = {'transport-belt', 'underground-belt', 'splitter'},
                })[1],
                position = left_pos
            },
            right_entity = {
                entity = find_belt({
                    position = right_pos,
                    type = {'transport-belt', 'underground-belt', 'splitter'},
                })[1],
                position = right_pos
            }
        }
    end

    local function read_belts(starter_entity)
        local starter_unit_number = starter_entity.unit_number
        local starter_entity_direction = starter_entity.direction
        local starter_entity_type = starter_entity.type
        local starter_entity_position = starter_entity.position

        local function step_forward(entity, entity_unit_number, entity_position, entity_type, entity_direction, belt_to_ground_direction, previous_entity_unit_number)
            local entity_neighbours = {}
            if previous_entity_unit_number then
                entity_neighbours.input = previous_entity_unit_number
            end
            --? Cache current entity
            read_entity_data[entity_unit_number] =
            {
                entity_position,
                entity_neighbours,
                entity_type,
                entity_direction,
                entity,
                belt_to_ground_direction
            }
            --? Underground belt handling
            if entity_type == 'underground-belt' then
                local ug_neighbour = entity.neighbours
                local ug_belt_to_ground_type = entity.belt_to_ground_type
                --? UG Belts always return an entity reference as the neighbour
                if ug_belt_to_ground_type == 'input' then
                    read_entity_data[entity_unit_number][6] = ug_belt_to_ground_type
                    if ug_neighbour then
                        local ug_neighbour_type = 'underground-belt'
                        local ug_neighbour_direction = entity_direction
                        local ug_neighbour_position = ug_neighbour.position
                        --? Make sure we don't get stuck in a recursive belt loop and only step forward.
                        --if entity.belt_to_ground_type == 'input' then
                            local ug_neighbour_unit_number = ug_neighbour.unit_number
                            entity_neighbours.underground_neighbour = ug_neighbour_unit_number
                            if not read_entity_data[ug_neighbour_unit_number] then
                                --if belts_read < max_belts then
                                    step_forward(ug_neighbour, ug_neighbour_unit_number, ug_neighbour_position, ug_neighbour_type, ug_neighbour_direction, 'output', entity_unit_number)
                                --end
                            end
                        --end
                    end
                else
                    local forward_position = Position.new(entity_position):copy():translate(entity_direction, 1)
                    local forward_entity = read_forward_belt(forward_position)
                    if forward_entity then
                        local forward_entity_direction = forward_entity.direction
                        local forward_entity_type = forward_entity.type
                        if not (forward_entity_direction == op_dir(entity_direction))
                            and not (forward_entity_type == 'underground-belt' and forward_entity_direction == entity_direction and forward_entity.belt_to_ground_type == 'output')
                            and not (forward_entity_type == 'splitter' and forward_entity_direction ~= entity_direction)
                        then
                            local forward_entity_unit_number = forward_entity.unit_number
                            entity_neighbours.output_target = forward_entity_unit_number
                            if not read_entity_data[forward_entity_unit_number] then
                                --if belts_read < max_belts then
                                    step_forward(forward_entity, forward_entity_unit_number, forward_entity_type == 'splitter' and forward_entity.position or forward_position, forward_entity_type, forward_entity_direction, nil, entity_unit_number)
                                --end
                            end
                        end
                    end
                end
            --? Transport belt stepping
            elseif entity_type == 'transport-belt' then
                local forward_position = Position.new(entity_position):copy():translate(entity_direction, 1)
                local forward_entity = read_forward_belt(forward_position)
                if forward_entity then
                    local forward_entity_direction = forward_entity.direction
                    local forward_entity_type = forward_entity.type
                    if not (forward_entity_direction == op_dir(entity_direction))
                        and not (forward_entity_type == 'underground-belt' and forward_entity_direction == entity_direction and forward_entity.belt_to_ground_type == 'output')
                        and not (forward_entity_type == 'splitter' and forward_entity_direction ~= entity_direction)
                    then
                        local forward_entity_unit_number = forward_entity.unit_number
                        entity_neighbours.output_target = forward_entity_unit_number
                        if not read_entity_data[forward_entity_unit_number] then
                            --if belts_read < max_belts then
                                step_forward(forward_entity, forward_entity_unit_number, forward_entity_type == 'splitter' and forward_entity.position or forward_position, forward_entity_type, forward_entity_direction, entity_unit_number)
                            --end
                        end
                    end
                end
            --? Splitter handling
            elseif entity_type == 'splitter' then
                local forward_entities = read_forward_splitter(entity_position, entity_direction)
                if forward_entities.left_entity.entity then
                    game.print("Left entity found!" )
                    local left_entity_direction = forward_entities.left_entity.entity.direction
                    local left_entity_type = forward_entities.left_entity.entity.type
                    local left_entity_position = forward_entities.left_entity.position
                    if not (left_entity_direction == op_dir(entity_direction))
                        and not (left_entity_type == 'underground-belt' and left_entity_direction == entity_direction and forward_entities.left_entity.entity.belt_to_ground_type == 'output')
                        and not (left_entity_type == 'splitter' and left_entity_direction ~= entity_direction)
                    then
                        local left_entity_unit_number = forward_entities.left_entity.entity.unit_number
                        entity_neighbours.left_output_target = left_entity_unit_number
                        if not read_entity_data[left_entity_unit_number] then
                            --if belts_read < max_belts then
                                step_forward(forward_entities.left_entity.entity, left_entity_unit_number, left_entity_type == 'splitter' and forward_entities.left_entity.entity.position or left_entity_position, left_entity_type, left_entity_direction, nil, entity_unit_number)
                            --end
                        end
                    end
                end
                if forward_entities.right_entity.entity then
                    game.print("Right entity found!" )
                    local right_entity_direction = forward_entities.right_entity.entity.direction
                    local right_entity_type = forward_entities.right_entity.entity.type
                    local right_entity_position = forward_entities.right_entity.position
                    if not (right_entity_direction == op_dir(entity_direction))
                        and not (right_entity_type == 'underground-belt' and right_entity_direction == entity_direction and forward_entities.right_entity.entity.belt_to_ground_type == 'output')
                        and not (right_entity_type == 'splitter' and right_entity_direction ~= entity_direction)
                    then
                        local right_entity_unit_number = forward_entities.right_entity.entity.unit_number
                        entity_neighbours.right_output_target = right_entity_unit_number
                        if not read_entity_data[right_entity_unit_number] then
                            --if belts_read < max_belts then
                                step_forward(forward_entities.right_entity.entity, right_entity_unit_number, right_entity_type == 'splitter' and forward_entities.right_entity.entity.position or right_entity_position, right_entity_type, right_entity_direction, nil, entity_unit_number)
                            --end
                        end
                    end
                end
            end
        end
        step_forward(starter_entity, starter_unit_number, starter_entity_position, starter_entity_type, starter_entity_direction, starter_entity_type == "underground-belt" and starter_entity.belt_to_ground_type or nil)
    end
    read_belts(selected_entity)

    for unit_number, current_entity in pairs(read_entity_data) do
        if not all_entities_marked[unit_number] then
            if current_entity[3] == 'underground-belt' and current_entity[6] == 'input' and current_entity[2].underground_neighbour then
                local start_position = Position(current_entity[1]):copy():translate(current_entity[4], 0.5)
                local neighbour_entity_data = read_entity_data[current_entity[2].underground_neighbour]
                local end_position = Position(neighbour_entity_data[1]):copy():translate(op_dir(current_entity[4]), 0.5)
                markers_made = markers_made + 1
                all_markers[markers_made] =
                    create {
                    name = 'picker-pipe-dot-bad',
                    position = current_entity[1]
                }
                markers_made = markers_made + 1
                all_markers[markers_made] =
                    create {
                    name = 'picker-underground-belt-marker-beam',
                    position = current_entity[1],
                    source_position = {start_position.x, start_position.y + 1},
                    --TODO 0.17 source_position = {entity_position.x, entity_position.y - 0.1},
                    target_position = end_position,
                    duration = 2000000000
                }
                all_entities_marked[unit_number] = true
            elseif current_entity[3] == 'transport-belt' then
                markers_made = markers_made + 1
                all_markers[markers_made] =
                    create {
                    name = 'picker-belt-marker-straight-both-lanes' .. map_direction[current_entity[4]],
                    position = current_entity[1]
                }
                all_entities_marked[unit_number] = true
            else
                markers_made = markers_made + 1
                all_markers[markers_made] =
                    create {
                    name = 'picker-pipe-dot-bad',
                    position = current_entity[1]
                }
                all_entities_marked[unit_number] = true
            end
        end
    end
end


local function get_beltline(event)
    local player, pdata = Player.get(event.player_index)
    pdata.current_beltnet_table = pdata.current_beltnet_table or {}
    pdata.current_marker_table = pdata.current_marker_table or {}
    if not pdata.disable_auto_highlight then
        local selection = player.selected
        -- TODO Faster check if table method possibly
        if selection and allowed_types[selection.type] then
            if not pdata.current_beltnet_table[selection.unit_number] then
                if next(pdata.current_beltnet_table) then
                    destroy_markers(pdata.current_marker_table)
                    pdata.current_beltnet_table = nil
                    pdata.current_marker_table = nil
                end
                highlight_belts(selection, event.player_index)
            end
        else
            if next(pdata.current_beltnet_table) then
                destroy_markers(pdata.current_marker_table)
                pdata.current_beltnet_table = nil
                pdata.current_marker_table = nil
            end
        end
    end
end
Event.register(defines.events.on_selected_entity_changed, get_beltline)
