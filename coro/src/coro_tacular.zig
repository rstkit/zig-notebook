const std = @import("std");
const c = @import("c_defs.zig").c;
const Bunny = @import("bunny.zig").Bunny;

// This is the maximum amount of elements (quads) per batch
// NOTE: This value is defined in [rlgl] module and can be changed there
const MAX_BATCH_ELEMENTS = 8192;
var gameOver = false;
var coroutineCount: usize = 0;

var deltaAdded: usize = 0;

pub fn bunnymark(texBunny: c.Texture) void {
    // Kick off the main coroutine which will run the Raylib event loop.
    _ = c.neco_start(bunnymark_game_coro, 1, &texBunny);
}

fn bunny_mover_coro(_: c_int, argv: [*c]?*anyopaque) callconv(.C) void {
    coroutineCount += 1;

    const pBunny: *Bunny = @alignCast(@ptrCast(argv[0]));
    const pTexBunny: *c.Texture = @alignCast(@ptrCast(argv[1]));

    const SCREEN_WIDTH = c.GetScreenWidth();
    const SCREEN_HEIGHT = c.GetScreenHeight();

    const sw: f32 = @floatFromInt(SCREEN_WIDTH);
    const sh: f32 = @floatFromInt(SCREEN_HEIGHT);
    const texW = @as(f32, @floatFromInt(pTexBunny.width >> 2));
    const texH = @as(f32, @floatFromInt(pTexBunny.height >> 2));

    // This loop is now dedicated to updating a single bunny.
    while (true) {
        if (deltaAdded == 0) {
            pBunny.pos.x += pBunny.speed.x;
            pBunny.pos.y += pBunny.speed.y;

            if (((pBunny.pos.x + texW) > sw) or
                ((pBunny.pos.x + texW) < 0))
            {
                pBunny.speed.x *= -1;
            }
            if (((pBunny.pos.y + texH) > sh) or
                ((pBunny.pos.y + texH - 40) < 0))
            {
                pBunny.speed.y *= -1;
            }
        }
        _ = c.neco_yield();
    }
}

fn bunnymark_game_coro(_: c_int, argv: [*c]?*anyopaque) callconv(.C) void {
    const SCREEN_WIDTH = c.GetScreenWidth();
    const maxBunnies = 100_000;

    const pTexBunny: *c.Texture = @alignCast(@ptrCast(argv[0]));

    // Stack alloc'd bunnies array.
    var bunnies: [maxBunnies]Bunny = undefined;
    var bunniesCount: usize = 0;

    while (!c.WindowShouldClose() and !gameOver) {
        //----------------------------------------------------------------------------------
        // Update
        //----------------------------------------------------------------------------------
        if (c.IsKeyReleased(c.KEY_ESCAPE)) {
            gameOver = true;
        }

        deltaAdded = 0;

        if (c.IsMouseButtonDown(c.MOUSE_BUTTON_LEFT)) {
            defer deltaAdded = 0;
            // Barf more bunnies
            for (0..5) |_| {
                if (bunniesCount < maxBunnies) {
                    bunnies[bunniesCount].pos = c.GetMousePosition();
                    bunnies[bunniesCount].speed.x = @as(f32, @floatFromInt(c.GetRandomValue(-250, 250))) / 60.0;
                    bunnies[bunniesCount].speed.y = @as(f32, @floatFromInt(c.GetRandomValue(-250, 250))) / 60.0;
                    bunnies[bunniesCount].color = .{
                        .r = @intCast(c.GetRandomValue(50, 240)),
                        .g = @intCast(c.GetRandomValue(80, 240)),
                        .b = @intCast(c.GetRandomValue(100, 240)),
                        .a = 255,
                    };

                    deltaAdded += 1;
                    // Grab a pointer to a single bunny.
                    const pBunny = &bunnies[bunniesCount];
                    // Spawn a coroutine responsible for moving this bunny, passing the bunny
                    // and texture by reference.
                    _ = c.neco_start(bunny_mover_coro, 2, pBunny, pTexBunny);

                    bunniesCount += 1;
                }
            }
        }

        // Don't forget to yield the game loop to give all alive coroutines a chance to run.
        // After all, this is a truly concurrent demo - no pesky native OS threads here.
        _ = c.neco_yield();

        //----------------------------------------------------------------------------------
        // Draw
        //----------------------------------------------------------------------------------
        c.BeginDrawing();
        defer c.EndDrawing();

        c.ClearBackground(c.RAYWHITE);

        for (0..bunniesCount) |i| {
            const x: c_int = @intFromFloat(bunnies[i].pos.x);
            const y: c_int = @intFromFloat(bunnies[i].pos.y);
            c.DrawTexture(pTexBunny.*, x, y, bunnies[i].color);
        }

        c.DrawRectangle(0, 0, SCREEN_WIDTH, 40, c.BLACK);
        c.DrawText(c.TextFormat("bunnies: %i", bunniesCount), 120, 10, 20, c.GREEN);
        c.DrawText(c.TextFormat("batched draw calls: %i, coroutines: %i", 1 + bunniesCount / MAX_BATCH_ELEMENTS, coroutineCount), 320, 10, 20, c.MAROON);

        c.DrawFPS(10, 10);
    }
}
