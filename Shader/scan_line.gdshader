shader_type canvas_item;

// 雷达基础设置
uniform vec4 fill_color : source_color = vec4(0.0, 0.1, 0.0, 0.3);
uniform vec4 line_color : source_color = vec4(0.0, 1.0, 0.0, 0.8);
uniform float line_thickness : hint_range(0.0, 0.1) = 0.02;
uniform float speed : hint_range(0.1, 10.0) = 2.0;
uniform float radar_radius = 0.4;
uniform vec2 center = vec2(0.5, 0.5);

// 敌人1属性
uniform vec2 enemy1_pos = vec2(0.3, 0.3);
uniform float enemy1_size = 0.005;
uniform vec4 enemy1_color = vec4(1.0, 0.0, 0.0, 1.0); // 红色

uniform sampler2D detect_data;  // 每个纹素包含一个敌人的数据 (RGBA: 位置x,位置y,大小,类型)
uniform int detect_count = 1;

void fragment() {
    vec2 relative_pos = UV - center;
    float distance_from_center = length(relative_pos);

    COLOR = vec4(0.0);

    if (distance_from_center <= radar_radius) {
        // 扫描线计算
        float scan_angle = TIME * speed;
        scan_angle = fract(scan_angle) * 2.0 * 3.141592;

        float pixel_angle = atan(relative_pos.y, relative_pos.x);
        pixel_angle = (pixel_angle < 0.0) ? pixel_angle + 2.0 * 3.141592 : pixel_angle;

        float angle_diff = abs(mod(pixel_angle - scan_angle, 2.0 * 3.141592));
        angle_diff = min(angle_diff, 2.0 * 3.141592 - angle_diff);

        float scan_line = smoothstep(line_thickness, 0.0, angle_diff) *
                         smoothstep(radar_radius * 0.1, radar_radius, distance_from_center);

        // 初始化敌人混合颜色和透明度
        vec4 enemy_blend = vec4(0.0);
        float total_enemy_alpha = 0.0;

        // 敌人1
        //float enemy1_strength = smoothstep(enemy1_size * 1.5, enemy1_size, length(UV - enemy1_pos));
        //enemy_blend = mix(enemy_blend, enemy1_color, enemy1_strength);
        //total_enemy_alpha = max(total_enemy_alpha, enemy1_strength * enemy1_color.a);
		
		// 然后在代码中:
		for (int i = 0; i < detect_count; i++) {
		    vec4 data = texelFetch(detect_data, ivec2(i, 0), 0);
		    vec2 pos = data.xy;
		    float size = data.z;
			
			float enemy_strength = smoothstep(size * 1.5, size, length(UV - pos));
		    enemy_blend = mix(enemy_blend, enemy1_color, enemy_strength);
			//total_enemy_alpha = max(total_enemy_alpha, enemy_strength * enemy1_color.a);
		}

        // 组合所有效果
        COLOR = fill_color;
        COLOR.rgb += line_color.rgb * scan_line * line_color.a;

        // 混合敌人颜色（保持最上层敌人的颜色）
        if (total_enemy_alpha > 0.0) {
            COLOR.rgb = mix(COLOR.rgb, enemy_blend.rgb, total_enemy_alpha);
        }

        // 雷达网格线
        float grid = 0.0;
        float grid_width = 0.005;
        for (float r = 0.1; r < radar_radius; r += 0.1) {
            grid += smoothstep(r + grid_width, r, distance_from_center) *
                    smoothstep(r - grid_width, r, distance_from_center);
        }
        grid += smoothstep(grid_width, 0.0, abs(relative_pos.x));
        grid += smoothstep(grid_width, 0.0, abs(relative_pos.y));
        COLOR.rgb += vec3(0.0, 0.3, 0.0) * grid * 0.5;
    }
}