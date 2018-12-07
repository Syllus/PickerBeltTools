-------------------------------------------------------------------------------
--[[Belt Highlighter]] --
-------------------------------------------------------------------------------
-- Concept designed and code written by TheStaplergun (staplergun on mod portal)
-- STDLib and code reviews provided by Nexela

local Player = require('lib/player')
local Event = require('lib/event')
local Position = require('lib/position')
local op_dir = Position.opposite_direction

local map_direction = {
    [0] = 'picker-splitter-marker-north',
    [2] = 'picker-splitter-marker-east',
    [4] = 'picker-splitter-marker-south',
    [6] = 'picker-splitter-marker-west'
}

local marker_entry = {
    [0] = 1,
    [1] = 2,
    [4] = 3,
    [5] = 4,
    [16] = 5,
    [17] = 6,
    [20] = 7,
    [21] = 8,
    [64] = 9,
    [65] = 10,
    [68] = 11,
    [69] = 12,
    [80] = 13,
    [81] = 14,
    [84] = 15,
    [85] = 16
}


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

    local function get_splitter_input_side(entity_position, entity_direction, splitter_position)
        local delta_x = entity_position.x - splitter_position.x
        local delta_y = entity_position.y - splitter_position.y
        if entity_direction == defines.direction.north then
            return delta_x < 0 and 'left' or 'right'
        elseif entity_direction == defines.direction.east then
            return delta_y < 0 and 'left' or 'right'
        elseif entity_direction == defines.direction.south then
            return delta_x < 0 and 'right' or 'left'
        elseif entity_direction == defines.direction.west then
            return delta_y < 0 and 'right' or 'left'
        end
    end

    local function get_directions_ug_belt(current_entity)
        local table_entry = 0
        local entity_neighbours = current_entity[2]
        table_entry = current_entity[2].output_target and (table_entry + (2^current_entity[4])) or table_entry
        if entity_neighbours.input then
            for _, direction_data in pairs(entity_neighbours.input) do
                table_entry = table_entry + (2 ^ op_dir(direction_data[2]))
            end
        end
        return table_entry
    end

    local function mark_ug_belt(unit_number, current_entity)
        markers_made = markers_made + 1
        local new_marker  = create {
            name = 'picker-ug-belt-marker-full',
            position = current_entity[1]
        }
        local map_dir = current_entity[4]/2
        local graphics_change = (16*map_dir) + marker_entry[get_directions_ug_belt(current_entity)]
        new_marker.graphics_variation = graphics_change
        all_markers[markers_made] = new_marker
        all_entities_marked[unit_number] = true
    end

    local function get_directions_belt(current_entity)
        local table_entry = 0
        local entity_neighbours = current_entity[2]
        if entity_neighbours.input then
            for _, direction_data in pairs(entity_neighbours.input) do
                table_entry = table_entry + (2 ^ op_dir(direction_data[2]))
            end
        end
        if current_entity[2].output_target then
            table_entry = table_entry + (2 ^ current_entity[4])
        end
        return table_entry
    end

    local function mark_belt(unit_number, current_entity)
        markers_made = markers_made + 1
        local new_marker  = create {
            name = 'picker-belt-marker-full',
            position = current_entity[1]
        }
        local map_dir = current_entity[4]/2
        local graphics_change = (16*map_dir) + marker_entry[get_directions_belt(current_entity)]
        new_marker.graphics_variation = graphics_change
        all_markers[markers_made] = new_marker
        all_entities_marked[unit_number] = true
    end

    local function get_directions_splitter(current_entity)
        local neighbours = current_entity[2]
        local directions_map = 0
        directions_map = neighbours.left_output_target and (directions_map + (2 ^ 0)) or directions_map
        directions_map = neighbours.right_output_target and (directions_map + (2 ^ 2)) or directions_map
        directions_map = neighbours.right and (directions_map + (2 ^ 4)) or directions_map
        directions_map = neighbours.left and (directions_map + (2 ^ 6)) or directions_map
        return directions_map
    end

    local function mark_splitter(unit_number, current_entity)
        markers_made = markers_made + 1
        local new_marker  = create {
            name = map_direction[current_entity[4]],
            position = current_entity[1]
        }
        local graphics_change = marker_entry[get_directions_splitter(current_entity)]
        new_marker.graphics_variation = graphics_change
        all_markers[markers_made] = new_marker
        all_entities_marked[unit_number] = true
    end

    local function read_belts(starter_entity)
        local starter_unit_number = starter_entity.unit_number
        local starter_entity_direction = starter_entity.direction
        local starter_entity_type = starter_entity.type
        local starter_entity_position = starter_entity.position

        local function step_forward(entity, entity_unit_number, entity_position, entity_type, entity_direction, belt_to_ground_direction, previous_entity_unit_number, previous_entity_direction, previous_entity_input_side)
            local entity_neighbours = {}
            if previous_entity_input_side then
                entity_neighbours[previous_entity_input_side] = previous_entity_unit_number
            else
                entity_neighbours.input = previous_entity_unit_number and {{previous_entity_unit_number,previous_entity_direction}} or {}
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
                        local ug_neighbour_unit_number = ug_neighbour.unit_number
                        entity_neighbours.ug_output_target = ug_neighbour_unit_number
                        if not read_entity_data[ug_neighbour_unit_number] then
                            --if belts_read < max_belts then
                            return step_forward(ug_neighbour, ug_neighbour_unit_number, ug_neighbour_position, ug_neighbour_type, ug_neighbour_direction, 'output', entity_unit_number, entity_direction, nil)
                            --end
                        else
                            local input = read_entity_data[ug_neighbour_unit_number][2].input
                            input[#input + 1] = {entity_unit_number,entity_direction}
                        end
                    end
                else
                    local forward_position = Position.new(entity_position):copy():translate(entity_direction, 1)
                    local forward_entity = read_forward_belt(forward_position)
                    if forward_entity then
                        local forward_entity_direction = forward_entity.direction
                        local forward_entity_type = forward_entity.type
                        if not (forward_entity_direction == op_dir(entity_direction))
                            and not (forward_entity_type == 'underground-belt' and forward_entity_direction == entity_direction and forward_entity.belt_to_ground_type == 'output')
                            and not (forward_entity_type == 'splitter' and forward_entity_direction ~= entity_direction) then
                            local forward_entity_unit_number = forward_entity.unit_number
                            entity_neighbours.output_target = forward_entity_unit_number
                            local splitter_input_side
                            if forward_entity_type == 'splitter' then
                                forward_position = forward_entity.position
                                splitter_input_side = get_splitter_input_side(entity_position, entity_direction, forward_position)
                            end
                            if not read_entity_data[forward_entity_unit_number] then
                                --if belts_read < max_belts then
                                return step_forward(forward_entity, forward_entity_unit_number, forward_position, forward_entity_type, forward_entity_direction, nil, entity_unit_number, entity_direction, splitter_input_side)
                                --end
                            else
                                if forward_entity_type ~= 'splitter' then
                                    local input = read_entity_data[forward_entity_unit_number][2].input
                                    input[#input + 1] = {entity_unit_number,entity_direction}
                                else
                                    local neighbours = read_entity_data[forward_entity_unit_number][2]
                                    neighbours[splitter_input_side] = entity_unit_number
                                end
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
                        and not (forward_entity_type == 'splitter' and forward_entity_direction ~= entity_direction) then
                        local forward_entity_unit_number = forward_entity.unit_number
                        entity_neighbours.output_target = forward_entity_unit_number
                        local splitter_input_side
                        if forward_entity_type == 'splitter' then
                            forward_position = forward_entity.position
                            splitter_input_side = get_splitter_input_side(entity_position, entity_direction, forward_position)
                        end
                        if not read_entity_data[forward_entity_unit_number] then
                            --if belts_read < max_belts then
                                return step_forward(forward_entity, forward_entity_unit_number, forward_position, forward_entity_type, forward_entity_direction, nil, entity_unit_number, entity_direction, splitter_input_side)
                            --end
                        else
                            if forward_entity_type ~= 'splitter' then
                                local input = read_entity_data[forward_entity_unit_number][2].input
                                input[#input + 1] = {entity_unit_number,entity_direction}
                            else
                                local neighbours = read_entity_data[forward_entity_unit_number][2]
                                neighbours[splitter_input_side] = entity_unit_number
                            end
                        end
                    end
                end
            --? Splitter handling
            elseif entity_type == 'splitter' then
                local forward_entities = read_forward_splitter(entity_position, entity_direction)
                if forward_entities.left_entity.entity then
                    local left_entity_direction = forward_entities.left_entity.entity.direction
                    local left_entity_type = forward_entities.left_entity.entity.type
                    local left_entity_position = forward_entities.left_entity.position
                    if not (left_entity_direction == op_dir(entity_direction))
                        and not (left_entity_type == 'underground-belt' and left_entity_direction == entity_direction and forward_entities.left_entity.entity.belt_to_ground_type == 'output')
                        and not (left_entity_type == 'splitter' and left_entity_direction ~= entity_direction) then
                        local left_entity_unit_number = forward_entities.left_entity.entity.unit_number
                        entity_neighbours.left_output_target = left_entity_unit_number
                        local splitter_input_side
                        if left_entity_type == 'splitter' then
                            left_entity_position = forward_entities.left_entity.entity.position
                            splitter_input_side = get_splitter_input_side(entity_position, entity_direction, left_entity_position)
                        end
                        if not read_entity_data[left_entity_unit_number] then
                            --if belts_read < max_belts then
                                step_forward(forward_entities.left_entity.entity, left_entity_unit_number, left_entity_position, left_entity_type, left_entity_direction, nil, entity_unit_number, entity_direction, splitter_input_side)
                            --end
                        else
                            if left_entity_type ~= 'splitter' then
                                local input = read_entity_data[left_entity_unit_number][2].input
                                input[#input + 1] = {entity_unit_number,entity_direction}
                            else
                                local neighbours = read_entity_data[left_entity_unit_number][2]
                                neighbours[splitter_input_side] = entity_unit_number
                            end
                        end
                    end
                end
                if forward_entities.right_entity.entity then
                    local right_entity_direction = forward_entities.right_entity.entity.direction
                    local right_entity_type = forward_entities.right_entity.entity.type
                    local right_entity_position = forward_entities.right_entity.position
                    if not (right_entity_direction == op_dir(entity_direction))
                        and not (right_entity_type == 'underground-belt' and right_entity_direction == entity_direction and forward_entities.right_entity.entity.belt_to_ground_type == 'output')
                        and not (right_entity_type == 'splitter' and right_entity_direction ~= entity_direction) then
                        local right_entity_unit_number = forward_entities.right_entity.entity.unit_number
                        entity_neighbours.right_output_target = right_entity_unit_number
                        local splitter_input_side
                        if right_entity_type == 'splitter' then
                            right_entity_position = forward_entities.right_entity.entity.position
                            splitter_input_side = get_splitter_input_side(entity_position, entity_direction, right_entity_position)
                        end
                        if not read_entity_data[right_entity_unit_number] then
                            --if belts_read < max_belts then
                                step_forward(forward_entities.right_entity.entity, right_entity_unit_number, right_entity_position, right_entity_type, right_entity_direction, nil, entity_unit_number, entity_direction, splitter_input_side)
                            --end
                        else
                            if right_entity_type ~= 'splitter' then
                                local input = read_entity_data[right_entity_unit_number][2].input
                                input[#input + 1] = {entity_unit_number,entity_direction}
                            else
                                local neighbours = read_entity_data[right_entity_unit_number][2]
                                neighbours[splitter_input_side] = entity_unit_number
                            end
                        end
                    end
                end
            end
        end
        step_forward(starter_entity, starter_unit_number, starter_entity_position, starter_entity_type, starter_entity_direction, starter_entity_type == "underground-belt" and starter_entity.belt_to_ground_type or nil)


        local function read_backward_belt(current_entity)
            local left_feed_direction_check = (current_entity[4] + 6) % 8
            local rear_feed_direction_check = op_dir(current_entity[4])
            local right_feed_direction_check = (current_entity[4] + 2) % 8
            local left_feed_position = Position.new(current_entity[1]):copy():translate(left_feed_direction_check, 1)
            local rear_feed_position = Position.new(current_entity[1]):copy():translate(rear_feed_direction_check, 1)
            local right_feed_position = Position.new(current_entity[1]):copy():translate(right_feed_direction_check, 1)
            local left_feed_entity = find_belt({
                position = left_feed_position,
                type = {'transport-belt', 'underground-belt', 'splitter'},
            })[1]
            local rear_feed_entity = find_belt({
                position = rear_feed_position,
                type = {'transport-belt', 'underground-belt', 'splitter'},
            })[1]
            local right_feed_entity = find_belt({
                position = right_feed_position,
                type = {'transport-belt', 'underground-belt', 'splitter'},
            })[1]
            local backstep_data = {}
            local left_feed_direction = left_feed_entity and left_feed_entity.direction or nil
            local rear_feed_direction = rear_feed_entity and rear_feed_entity.direction or nil
            local right_feed_direction = right_feed_entity and right_feed_entity.direction or nil
            if left_feed_direction and left_feed_direction == op_dir(left_feed_direction_check) then
                local left_feed_type = left_feed_entity.type
                local belt_to_ground_direction = left_feed_type == 'underground-belt' and left_feed_entity.belt_to_ground_type
                if belt_to_ground_direction ~= 'input' then
                    backstep_data.left_feed_entity_data = {
                        left_feed_position,
                        true,
                        left_feed_type,
                        left_feed_direction,
                        left_feed_entity,
                        belt_to_ground_direction
                    }
                end
            end
            if rear_feed_direction and rear_feed_direction == op_dir(rear_feed_direction_check) then
                local rear_feed_type = rear_feed_entity.type
                local belt_to_ground_direction = rear_feed_type == 'underground-belt' and rear_feed_entity.belt_to_ground_type
                if belt_to_ground_direction ~= 'input' then
                    backstep_data.rear_feed_entity_data = {
                        rear_feed_position,
                        true,
                        rear_feed_type,
                        rear_feed_direction,
                        rear_feed_entity,
                        belt_to_ground_direction
                    }
                end
            end
            if right_feed_direction and right_feed_direction == op_dir(right_feed_direction_check) then
                local right_feed_type = right_feed_entity.type
                local belt_to_ground_direction = right_feed_type == 'underground-belt' and right_feed_entity.belt_to_ground_type
                if belt_to_ground_direction ~= 'input' then
                    backstep_data.right_feed_entity_data = {
                        right_feed_position,
                        true,
                        right_feed_type,
                        right_feed_direction,
                        right_feed_entity,
                        belt_to_ground_direction
                    }
                end
            end
            return backstep_data
        end

        local function read_sideload_ug_belt(current_entity)
            local left_feed_direction_check = (current_entity[4] + 6) % 8
            local right_feed_direction_check = (current_entity[4] + 2) % 8
            local left_feed_position = Position.new(current_entity[1]):copy():translate(left_feed_direction_check, 1)
            local right_feed_position = Position.new(current_entity[1]):copy():translate(right_feed_direction_check, 1)
            local left_feed_entity = find_belt({
                position = left_feed_position,
                type = {'transport-belt', 'underground-belt', 'splitter'},
            })[1]
            local right_feed_entity = find_belt({
                position = right_feed_position,
                type = {'transport-belt', 'underground-belt', 'splitter'},
            })[1]
            local backstep_data = {}
            local left_feed_direction = left_feed_entity and left_feed_entity.direction or nil
            local right_feed_direction = right_feed_entity and right_feed_entity.direction or nil
            if left_feed_direction and left_feed_direction == op_dir(left_feed_direction_check) then
                local left_feed_type = left_feed_entity.type
                local belt_to_ground_direction = left_feed_type == 'underground-belt' and left_feed_entity.belt_to_ground_type
                if belt_to_ground_direction ~= 'input' then
                    backstep_data.left_feed_entity_data = {
                        left_feed_position,
                        true,
                        left_feed_type,
                        left_feed_direction,
                        left_feed_entity,
                        belt_to_ground_direction
                    }
                end
            end
            if right_feed_direction and right_feed_direction == op_dir(right_feed_direction_check) then
                local right_feed_type = right_feed_entity.type
                local belt_to_ground_direction = right_feed_type == 'underground-belt' and right_feed_entity.belt_to_ground_type
                if belt_to_ground_direction ~= 'input' then
                    backstep_data.right_feed_entity_data = {
                        right_feed_position,
                        true,
                        right_feed_type,
                        right_feed_direction,
                        right_feed_entity,
                        belt_to_ground_direction
                    }
                end
            end
            return backstep_data
        end

        local function read_backward_splitter(current_entity)
            local shift_directions = splitter_check_table[op_dir(current_entity[4])]
            local left_feed_position = current_entity[1] + shift_directions.right
            local right_feed_position = current_entity[1] + shift_directions.left
            local left_feed_entity = find_belt({
                position = left_feed_position,
                type = {'transport-belt', 'underground-belt', 'splitter'},
            })[1]
            local right_feed_entity = find_belt({
                position = right_feed_position,
                type = {'transport-belt', 'underground-belt', 'splitter'},
            })[1]
            local backstep_data = {}
            local left_feed_direction = left_feed_entity and left_feed_entity.direction or nil
            local right_feed_direction = right_feed_entity and right_feed_entity.direction or nil
            if left_feed_direction and left_feed_direction == current_entity[4] then
                local left_feed_type = left_feed_entity.type
                local belt_to_ground_direction = left_feed_type == 'underground-belt' and left_feed_entity.belt_to_ground_type
                if belt_to_ground_direction ~= 'input' then
                    backstep_data.left_feed_entity_data = {
                        left_feed_position,
                        true,
                        left_feed_type,
                        left_feed_direction,
                        left_feed_entity,
                        belt_to_ground_direction
                    }
                end
            end
            if right_feed_direction and right_feed_direction == current_entity[4] then
                local right_feed_type = right_feed_entity.type
                local belt_to_ground_direction = right_feed_type == 'underground-belt' and right_feed_entity.belt_to_ground_type
                if belt_to_ground_direction ~= 'input' then
                    backstep_data.right_feed_entity_data = {
                        right_feed_position,
                        true,
                        right_feed_type,
                        right_feed_direction,
                        right_feed_entity,
                        belt_to_ground_direction
                    }
                end
            end
            return backstep_data
        end

        local function step_backward(entity, entity_unit_number, entity_position, entity_type, entity_direction, belt_to_ground_direction, previous_entity_unit_number, previous_entity_output_side)

            local function check_backward(current_entity, neighbour)
                local entity_neighbours = current_entity[2]
                local neighbour_type = neighbour[3]
                local neighbour_position = neighbour_type == 'splitter' and neighbour[5].position or neighbour[1]
                local neighbour_direction = neighbour[4]
                local neighbour_unit_number = neighbour[5].unit_number
                entity_neighbours.input = entity_neighbours.input and entity_neighbours.input or {}
                entity_neighbours.input[#entity_neighbours.input + 1] = {neighbour_unit_number,neighbour_direction}
                local splitter_output_side
                if neighbour_type == 'splitter' then
                    splitter_output_side = get_splitter_input_side(neighbour_position, neighbour_direction, current_entity[1]) == 'right' and 'left_output_target' or 'right_output_target'
                end
                if not read_entity_data[neighbour_unit_number] then
                    step_backward(neighbour[5], neighbour_unit_number, neighbour_position, neighbour_type, neighbour_direction, neighbour.belt_to_ground_direction, entity_unit_number, splitter_output_side)
                else
                    if neighbour_type ~= 'splitter' then
                        read_entity_data[neighbour_unit_number][2].output_target = entity_unit_number
                    else
                        read_entity_data[neighbour_unit_number][2][splitter_output_side] = entity_unit_number
                    end
                end
            end

            local entity_neighbours = read_entity_data[entity_unit_number] and read_entity_data[entity_unit_number][2] or {}
            if previous_entity_output_side then
                entity_neighbours[previous_entity_output_side] = previous_entity_unit_number
            else
                if previous_entity_unit_number then
                    if belt_to_ground_direction ~= 'input' and not entity_neighbours.output_target then
                        entity_neighbours.output_target = previous_entity_unit_number
                    elseif belt_to_ground_direction == 'input' and not entity_neighbours.ug_output_target then
                        entity_neighbours.ug_output_target = previous_entity_unit_number
                    end
                end
            end
            --? Cache current entity
            local current_entity = read_entity_data[entity_unit_number] or {
                entity_position,
                entity_neighbours,
                entity_type,
                entity_direction,
                entity,
                belt_to_ground_direction
            }
            read_entity_data[entity_unit_number] = current_entity
            if entity_type == 'underground-belt' then
                local ug_neighbour = entity.neighbours
                local ug_belt_to_ground_type = entity.belt_to_ground_type
                if ug_belt_to_ground_type == 'output' then
                    read_entity_data[entity_unit_number][6] = ug_belt_to_ground_type
                    if ug_neighbour then
                        local ug_neighbour_type = 'underground-belt'
                        local ug_neighbour_direction = entity_direction
                        local ug_neighbour_position = ug_neighbour.position
                        local ug_neighbour_unit_number = ug_neighbour.unit_number
                        entity_neighbours.ug_input = ug_neighbour_unit_number
                        if not read_entity_data[ug_neighbour_unit_number] then
                            --if belts_read < max_belts then
                            step_backward(ug_neighbour, ug_neighbour_unit_number, ug_neighbour_position, ug_neighbour_type, ug_neighbour_direction, 'input', entity_unit_number)
                            --end
                        else
                            read_entity_data[ug_neighbour_unit_number][2].output_target = {entity_unit_number, entity_direction}
                        end
                    end
                    local neighbours = read_sideload_ug_belt(current_entity)
                    if neighbours.left_feed_entity_data then
                        local neighbour = neighbours.left_feed_entity_data
                        check_backward(current_entity, neighbour)
                    end
                    if neighbours.right_feed_entity_data then
                        local neighbour = neighbours.right_feed_entity_data
                        check_backward(current_entity, neighbour)
                    end
                else
                    local neighbours = read_backward_belt(current_entity)
                    if neighbours.left_feed_entity_data then
                        local neighbour = neighbours.left_feed_entity_data
                        check_backward(current_entity, neighbour)
                    end
                    if neighbours.rear_feed_entity_data then
                        local neighbour = neighbours.rear_feed_entity_data
                        check_backward(current_entity, neighbour)
                    end
                    if neighbours.right_feed_entity_data then
                        local neighbour = neighbours.right_feed_entity_data
                        check_backward(current_entity, neighbour)
                    end
                end
            elseif entity_type == 'transport-belt' then
                local neighbours = read_backward_belt(current_entity)
                if neighbours.left_feed_entity_data then
                    local neighbour = neighbours.left_feed_entity_data
                    check_backward(current_entity, neighbour)
                end
                if neighbours.rear_feed_entity_data then
                    local neighbour = neighbours.rear_feed_entity_data
                    check_backward(current_entity, neighbour)
                end
                if neighbours.right_feed_entity_data then
                    local neighbour = neighbours.right_feed_entity_data
                    check_backward(current_entity, neighbour)
                end
            elseif entity_type == 'splitter' then
                local neighbours = read_backward_splitter(current_entity)
                if neighbours.left_feed_entity_data then
                    local neighbour = neighbours.left_feed_entity_data
                    local neighbour_type = neighbour[3]
                    local neighbour_position = neighbour_type == 'splitter' and neighbour[5].position or neighbour[1]
                    local neighbour_direction = neighbour[4]
                    local neighbour_unit_number = neighbour[5].unit_number
                    entity_neighbours.left = neighbour_unit_number
                    local splitter_output_side
                    if neighbour_type == 'splitter' then
                        splitter_output_side = get_splitter_input_side(neighbour_position, neighbour_direction, entity_position) == 'right' and 'left_output_target' or 'right_output_target'
                    end
                    if not read_entity_data[neighbour_unit_number] then
                        step_backward(neighbour[5], neighbour_unit_number, neighbour_position, neighbour_type, neighbour_direction, neighbour.belt_to_ground_direction, entity_unit_number, splitter_output_side)
                    else
                        if neighbour_type ~= 'splitter' then
                            read_entity_data[neighbour_unit_number][2].output_target = entity_unit_number
                        else
                            read_entity_data[neighbour_unit_number][2][splitter_output_side] = entity_unit_number
                        end
                    end
                end
                if neighbours.right_feed_entity_data then
                    local neighbour = neighbours.right_feed_entity_data
                    local neighbour_type = neighbour[3]
                    local neighbour_position = neighbour_type == 'splitter' and neighbour[5].position or neighbour[1]
                    local neighbour_direction = neighbour[4]
                    local neighbour_unit_number = neighbour[5].unit_number
                    entity_neighbours.right = neighbour_unit_number
                    local splitter_output_side
                    if neighbour_type == 'splitter' then
                        splitter_output_side = get_splitter_input_side(neighbour_position, neighbour_direction, entity_position) == 'right' and 'left_output_target' or 'right_output_target'
                    end
                    if not read_entity_data[neighbour_unit_number] then
                        step_backward(neighbour[5], neighbour_unit_number, neighbour_position, neighbour_type, neighbour_direction, neighbour.belt_to_ground_direction, entity_unit_number, splitter_output_side)
                    else
                        if neighbour_type ~= 'splitter' then
                            read_entity_data[neighbour_unit_number][2].output_target = entity_unit_number
                        else
                            read_entity_data[neighbour_unit_number][2][splitter_output_side] = entity_unit_number
                        end
                    end
                end
            end
        end

        step_backward(starter_entity, starter_unit_number, starter_entity_position, starter_entity_type, starter_entity_direction, starter_entity_type == "underground-belt" and starter_entity.belt_to_ground_type or nil)
    end
    read_belts(selected_entity)

    for unit_number, current_entity in pairs(read_entity_data) do
        if not all_entities_marked[unit_number] then
            if current_entity[3] == 'underground-belt' and current_entity[6] == 'input' and current_entity[2].ug_output_target then
                local start_position = Position(current_entity[1]):copy():translate(current_entity[4], 0.5)
                local neighbour_entity_data = read_entity_data[current_entity[2].ug_output_target]
                local end_position = Position(neighbour_entity_data[1]):copy():translate(op_dir(current_entity[4]), 0.5)
                mark_ug_belt(unit_number, current_entity)
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
                mark_belt(unit_number, current_entity)
            elseif current_entity[3] == 'splitter' then
                mark_splitter(unit_number, current_entity)
            else
                mark_ug_belt(unit_number, current_entity)
            end
            --[[else
                markers_made = markers_made + 1
                all_markers[markers_made] =
                    create {
                    name = 'picker-pipe-dot-bad',
                    position = current_entity[1]
                }
                all_entities_marked[unit_number] = true
            end]]--
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
