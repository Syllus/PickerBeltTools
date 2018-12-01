local merge = _G.util.merge

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
    animations = {{
        width = 64,
        height = 64,
        line_length = 8,
        frame_count = 16,
        direction_count = 1,
        animation_speed = 0.03125 * 32,
        scale = 0.5,
        filename = '__PickerBeltTools__/graphics/entity/markers/32x32highlightergood.png'
    }}
}

local belt_marker_table = {
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
end


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
