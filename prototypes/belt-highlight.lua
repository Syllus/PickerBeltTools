--local merge = _G.util.merge

local base_entity = {
    type = 'simple-entity',
    name = 'fillerstuff',
    flags = {'placeable-neutral', 'not-on-map','placeable-off-grid'},
    subgroup = 'remnants',
    order = 'd[remnants]-c[wall]',
    icon = '__PickerBeltTools__/graphics/entity/markers/32x32highlightergood.png',
    icon_size = 32,
    --time_before_removed = 2000000000,
    collision_box = {{0, 0}, {0, 0}},
    selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
    collision_mask = {"layer-14"},
    selectable_in_game = false,
    --final_render_layer = 'selection-box',
    --[[animations = {{
        width = 64,
        height = 64,
        line_length = 8,
        frame_count = 16,
        direction_count = 1,
        animation_speed = 0.03125 * 16,
        scale = 0.5,
        filename = '__PickerBeltTools__/graphics/entity/markers/32x32highlightergood.png'
    }}]]--
}

local belt_pictures = {}
for i = 1,64 do
    local y = 0
    if i > 16 and i <= 32 then
        y = 32
    elseif i > 32 and i <= 48 then
        y = 64
    elseif i > 48 and i <= 64 then
        y = 96
    end
    belt_pictures[i] = {
        width = 32,
        height = 32,
        x = ((i-1)%16)*32,
        y = y,
        line_length = 16,
        frame_count = 1,
        direction_count = 1,
        --scale = 0.5,
        --shift = {-0.5,-0.5},
        filename = '__PickerBeltTools__/graphics/entity/markers/belt-arrow-set-full.png'
    }
end

local belt_marker = util.table.deepcopy(base_entity)
belt_marker.name = 'picker-belt-marker-full'
belt_marker.pictures = belt_pictures

local splitter_image_table = {
    ['splitter-north'] = {
        index_multiplier = 1,
        image_size = {
            x = 64,
            y = 32
        }
    },
    ['splitter-east'] = {
        index_multiplier = 2,
        image_size = {
            x = 32,
            y = 64
        }
    },
    ['splitter-south'] = {
        index_multiplier = 3,
        image_size = {
            x = 64,
            y = 32
        }
    },
    ['splitter-west'] = {
        index_multiplier = 4,
        image_size = {
            x = 32,
            y = 64
        }
    }
}

local splitter_pictures = {}
local counter = 1
for image, image_data in pairs(splitter_image_table) do
    for i = 1,16 do
        splitter_pictures[counter] = {
            width = image_data.image_size.x,
            height = image_data.image_size.y,
            x = ((i-1)%4)*image_data.image_size.x,
            y = ((i-1)%4)*image_data.image_size.y,
            line_length = 4,
            frame_count = 1,
            direction_count = 1,
            --scale = 0.5,
            --shift = {-0.5,-0.5},
            filename = '__PickerBeltTools__/graphics/entity/markers/' .. image .. '.png'
        }
        counter = counter + 1
    end
end

local splitter_marker = util.table.deepcopy(base_entity)
splitter_marker.name = 'picker-splitter-marker-full'
splitter_marker.pictures = splitter_pictures















data:extend({belt_marker,splitter_marker})












--[[local belt_marker_table = {
    ['picker-belt-marker-straight-both-lanes'] = 'belt-animated-both-lane',
    --['picker-pump-marker-good'] = 'pump-marker-good'
}
local belt_directions = {
    '-n',
    '-e',
    '-s',
    '-w'
}

local new_markers = {}
for belt_marker_name, images in pairs(belt_marker_table) do
    for _, directions in pairs(belt_directions) do
        local current_entity = util.table.deepcopy(base_entity)
        current_entity.type = 'simple-entity'
        current_entity.name = belt_marker_name .. directions
        --current_entity.animation.shift = {0, -0.1}
        current_entity.animations[1].filename = '__PickerBeltTools__/graphics/entity/markers/' .. images .. directions .. '.png'
        new_markers[#new_markers + 1] = current_entity
    end
end

for _, stuff in pairs(new_markers) do
    data:extend {
        merge {
            base_entity,
            stuff
        }
    }
end]]--


local base_beam = util.table.deepcopy(data.raw['beam']['electric-beam-no-sound'])
base_beam.name = 'picker-underground-belt-marker-beam'
base_beam.width = 1.0
base_beam.damage_interval = 2000000000
base_beam.action = nil
base_beam.start = {
    filename = '__core__/graphics/empty.png',
    line_length = 1,
    width = 0,
    height = 0,
    frame_count = 16,
    axially_symmetrical = false,
    direction_count = 1,
    hr_version = {
        filename = '__core__/graphics/empty.png',
        line_length = 1,
        width = 0,
        height = 0,
        frame_count = 16,
        axially_symmetrical = false,
        direction_count = 1
    }
}
base_beam.ending = {
    filename = '__core__/graphics/empty.png',
    line_length = 1,
    width = 0,
    height = 0,
    frame_count = 16,
    axially_symmetrical = false,
    direction_count = 1,
    hr_version = {
        filename = '__core__/graphics/empty.png',
        line_length = 1,
        width = 0,
        height = 0,
        frame_count = 16,
        axially_symmetrical = false,
        direction_count = 1
    }
}
 --
-- TODO 0.17 version
--[[base_beam.ending = {
    filename = "__PickerBeltTools__/graphics/entity/markers/" .. marker_name.box .. ".png",
    line_length = 1,
    width = 64,
    height = 64,
    frame_count = 1,
    axially_symmetrical = false,
    direction_count = 1,
    --shift = {-0.03125, 0},
    scale = 0.5,
    hr_version =
    {
        filename = "__PickerBeltTools__/graphics/entity/markers/" .. marker_name.box .. ".png",
        line_length = 1,
        width = 64,
        height = 64,
        frame_count = 1,
        axially_symmetrical = false,
        direction_count = 1,
        --shift = {0.53125, 0},
        scale = 0.5
    }
}]]
base_beam.head = {
    filename = '__PickerBeltTools__/graphics/entity/markers/underground-lines-animated.png',
    flags = {'no-crop'},
    line_length = 8,
    width = 64,
    height = 64,
    frame_count = 16,
    animation_speed = 0.03125 * 16,
    scale = 0.5
}
base_beam.tail = {
    filename = '__PickerBeltTools__/graphics/entity/markers/underground-lines-animated.png',
    flags = {'no-crop'},
    line_length = 8,
    width = 64,
    height = 64,
    frame_count = 16,
    animation_speed = 0.03125 * 16,
    scale = 0.5
}
base_beam.body = {
    {
        filename = '__PickerBeltTools__/graphics/entity/markers/underground-lines-animated.png',
        flags = {'no-crop'},
        line_length = 8,
        width = 64,
        height = 64,
        frame_count = 16,
        animation_speed = 0.03125 * 16,
        scale = 0.5
    }
}
--[[local underground_marker_beams = {}
for _,belt in pairs(data.raw['underground-belt']) do
    local current_beam = _G.util.table.deepcopy(base_beam)
    current_beam.name = belt.name .. "-underground-marker-beam"
    current_beam.head.animation_speed = belt.speed * belt.belt_horizontal.frame_count
    current_beam.tail.animation_speed = belt.speed * belt.belt_horizontal.frame_count
    current_beam.body[1].animation_speed = belt.speed * belt.belt_horizontal.frame_count
    underground_marker_beams[#underground_marker_beams + 1] = current_beam
end]]--
data:extend({base_beam})
