-- Dokurwiony Watermark for Gamesense CS:GO - Fioletowy Gradient Góra
-- Toggleable in LUA > A tab

local client_set_event_callback = client.set_event_callback
local client_screen_size = client.screen_size
local client_latency = client.latency
local client_timestamp = client.timestamp
local client_system_time = client.system_time
local entity_get_local_player = entity.get_local_player
local entity_get_player_name = entity.get_player_name
local globals_tickinterval = globals.tickinterval
local ui_new_checkbox = ui.new_checkbox
local ui_get = ui.get
local renderer_measure_text = renderer.measure_text
local renderer_rectangle = renderer.rectangle
local renderer_text = renderer.text
local renderer_circle = renderer.circle
local renderer_circle_outline = renderer.circle_outline
local math_floor = math.floor
local math_sqrt = math.sqrt
local string_format = string.format
local string_sub = string.sub

local enable_watermark = ui_new_checkbox("LUA", "A", "Enable Watermark")

-- FPS vars
local fps = 0
local fps_frames = 0
local last_fps_update = 0

-- Fioletowe kolory
local purple_r, purple_g, purple_b = 138, 43, 226
local purple_light_r, purple_light_g, purple_light_b = 180, 100, 255

-- Tło - pixel perfect zaokrąglenie przez rysowanie linia po linii
local function draw_rounded_rect_perfect(x, y, w, h, radius, r, g, b, a)
    for i = 0, h - 1 do
        local current_y = y + i
        local line_x = x
        local line_w = w
        
        -- Górne zaokrąglenie
        if i < radius then
            local dy = radius - i
            local offset = radius - math_sqrt(radius * radius - dy * dy)
            offset = math_floor(offset + 0.5)
            line_x = x + offset
            line_w = w - 2 * offset
        end
        
        -- Dolne zaokrąglenie
        if i > h - 1 - radius then
            local dy = i - (h - 1 - radius)
            local offset = radius - math_sqrt(radius * radius - dy * dy)
            offset = math_floor(offset + 0.5)
            line_x = x + offset
            line_w = w - 2 * offset
        end
        
        if line_w > 0 then
            renderer_rectangle(line_x, current_y, line_w, 1, r, g, b, a)
        end
    end
end

-- Fioletowy gradient na górze z pełnym zaokrągleniem
local function draw_purple_top_gradient(x, y, w, h, radius, alpha_top)
    local gradient_height = math_floor(h * 0.65)
    
    for i = 0, gradient_height - 1 do
        local progress = i / gradient_height
        local current_alpha = math_floor(alpha_top * (1 - progress))
        local current_y = y + i
        
        if current_alpha > 0 then
            local line_x = x
            local line_w = w
            
            -- Górne zaokrąglenie
            if i < radius then
                local dy = radius - i
                local offset = radius - math_sqrt(radius * radius - dy * dy)
                offset = math_floor(offset + 0.5)
                line_x = x + offset
                line_w = w - 2 * offset
            end
            
            if line_w > 0 then
                renderer_rectangle(line_x, current_y, line_w, 1, purple_r, purple_g, purple_b, current_alpha)
            end
        end
    end
end

-- Outline z pełnym zaokrągleniem
local function draw_rounded_outline_perfect(x, y, w, h, radius, r, g, b, a, thickness)
    -- Góra
    renderer_circle_outline(x + radius, y + radius, r, g, b, a, radius, 180, 0.25, thickness)
    renderer_circle_outline(x + w - radius, y + radius, r, g, b, a, radius, 270, 0.25, thickness)
    renderer_rectangle(x + radius, y, w - 2 * radius, thickness, r, g, b, a)
    
    -- Dół
    renderer_circle_outline(x + radius, y + h - radius, r, g, b, a, radius, 90, 0.25, thickness)
    renderer_circle_outline(x + w - radius, y + h - radius, r, g, b, a, radius, 0, 0.25, thickness)
    renderer_rectangle(x + radius, y + h - thickness, w - 2 * radius, thickness, r, g, b, a)
    
    -- Boki
    renderer_rectangle(x, y + radius, thickness, h - 2 * radius, r, g, b, a)
    renderer_rectangle(x + w - thickness, y + radius, thickness, h - 2 * radius, r, g, b, a)
end

-- Fioletowy outline tylko na górze z gradientowym zanikaniem
local function draw_purple_top_outline(x, y, w, h, radius, thickness)
    local a = 255
    
    -- Górne rogi i linia
    renderer_circle_outline(x + radius, y + radius, purple_light_r, purple_light_g, purple_light_b, a, radius, 180, 0.25, thickness)
    renderer_circle_outline(x + w - radius, y + radius, purple_light_r, purple_light_g, purple_light_b, a, radius, 270, 0.25, thickness)
    renderer_rectangle(x + radius, y, w - 2 * radius, thickness, purple_light_r, purple_light_g, purple_light_b, a)
    
    -- Boki z gradientowym zanikaniem
    local side_gradient_height = math_floor(h * 0.4)
    for i = 0, side_gradient_height - 1 do
        local progress = i / side_gradient_height
        local current_alpha = math_floor(a * (1 - progress))
        local current_y = y + radius + i
        if current_alpha > 0 and current_y < (y + h - radius) then
            renderer_rectangle(x, current_y, thickness, 1, purple_light_r, purple_light_g, purple_light_b, current_alpha)
            renderer_rectangle(x + w - thickness, current_y, thickness, 1, purple_light_r, purple_light_g, purple_light_b, current_alpha)
        end
    end
end

local function draw_watermark()
    if not ui_get(enable_watermark) then
        return
    end

    local screen_w, screen_h = client_screen_size()
    local lp = entity_get_local_player()
    if not lp then
        return
    end

    fps_frames = fps_frames + 1
    local ctime = client_timestamp()
    if ctime >= last_fps_update + 1000 then
        fps = math_floor(fps_frames * 1000 / (ctime - last_fps_update) + 0.5)
        fps_frames = 0
        last_fps_update = ctime
    end

    local name = string_sub(entity_get_player_name(lp), 1, 14)
    local latency = math_floor(client_latency() * 1000 + 0.5)
    local tickrate = math_floor(1 / globals_tickinterval() + 0.5)
    local h, m, s = client_system_time()
    local time_str = string_format("%02d:%02d:%02d", h, m, s)

    local watermark_text = string_format("gamesense | %s | %dms | %dfps | %dtick | %s", name, latency, fps, tickrate, time_str)

    local text_flags = "cb"
    local text_width, text_height = renderer_measure_text(text_flags, watermark_text)

    local padding = 5
    local margin = 10
    local radius = 5
    local box_x = screen_w - text_width - margin - padding * 2
    local box_y = margin
    local box_width = text_width + padding * 2
    local box_height = text_height + padding * 2

    -- 1. Tło - pixel perfect zaokrąglenie
    draw_rounded_rect_perfect(box_x, box_y, box_width, box_height, radius, 15, 15, 15, 240)

    -- 2. Fioletowy gradient na górze
    draw_purple_top_gradient(box_x, box_y, box_width, box_height, radius, 80)

    -- 3. Ciemny outline dookoła
    draw_rounded_outline_perfect(box_x, box_y, box_width, box_height, radius, 40, 40, 40, 180, 1)
    
    -- 4. Fioletowy outline na górze (nadpisuje ciemny)
    draw_purple_top_outline(box_x, box_y, box_width, box_height, radius, 1)

    -- 5. Tekst
    local tx = box_x + padding + text_width / 2
    local ty = box_y + padding + text_height / 2
    
    renderer_text(tx + 1, ty + 1, 0, 0, 0, 255, text_flags, 0, watermark_text)
    renderer_text(tx, ty, 245, 245, 245, 255, text_flags, 0, watermark_text)
end

client_set_event_callback("paint", draw_watermark)