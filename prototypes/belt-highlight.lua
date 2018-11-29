
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
