// background.js
export function createInfiniteBackground(app, world) {
    const bg = new PIXI.Graphics();
    world.addChildAt(bg, 0);

    const gridSize = 100;
    const colors = [0x1a1a2e, 0x16213e, 0x0f3460];

    function drawBackground() {
        bg.clear();

        const visibleLeft = -world.x;
        const visibleTop = -world.y;
        const visibleRight = visibleLeft + app.screen.width;
        const visibleBottom = visibleTop + app.screen.height;

        const startX = Math.floor(visibleLeft / gridSize) * gridSize - gridSize;
        const startY = Math.floor(visibleTop / gridSize) * gridSize - gridSize;
        const endX = Math.ceil(visibleRight / gridSize) * gridSize + gridSize;
        const endY = Math.ceil(visibleBottom / gridSize) * gridSize + gridSize;

        for (let x = startX; x <= endX; x += gridSize) {
            for (let y = startY; y <= endY; y += gridSize) {
                const colorIndex = Math.floor(
                    (Math.sin(x * 0.01) + Math.cos(y * 0.01) + 2)
                ) % colors.length;

                bg.beginFill(colors[colorIndex])
                  .drawRect(x, y, gridSize, gridSize)
                  .endFill();
            }
        }
    }

    drawBackground();
    app.ticker.add(drawBackground);
    return bg;
}