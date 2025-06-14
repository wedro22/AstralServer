// background.js
export function createInfiniteBackground(app, world) {
    // Параметры текстуры фона
    const bgTextureSize = 512; // Размер одной текстуры фона
    const bgTextures = []; // Массив для хранения текстур фона

    // Создаем текстуру для фона
    function createBackgroundTexture() {
        const graphic = new PIXI.Graphics();

        // Рисуем простой узор (замените на свой дизайн)
        graphic.beginFill(0x2a3042); // Основной цвет
        graphic.drawRect(0, 0, bgTextureSize, bgTextureSize);
        graphic.endFill();

        graphic.beginFill(0x3a4055); // Вторичный цвет
        for (let i = 0; i < 5; i++) {
            graphic.drawCircle(
                Math.random() * bgTextureSize,
                Math.random() * bgTextureSize,
                Math.random() * 20 + 5
            );
        }
        graphic.endFill();

        return app.renderer.generateTexture(graphic);
    }

    // Создаем несколько текстур для разнообразия
    for (let i = 0; i < 3; i++) {
        bgTextures.push(createBackgroundTexture());
    }

    // Контейнер для фона
    const bgContainer = new PIXI.Container();
    world.addChildAt(bgContainer, 0); // Помещаем фон в самый низ

    // Массив для хранения спрайтов фона
    const bgSprites = [];

    // Переменные для отслеживания изменений
    let lastX = world.position.x;
    let lastY = world.position.y;
    let lastScale = world.scale.x;

    // Функция для обновления фона
    function updateBackground() {
        // Получаем видимую область мира с учетом масштаба
        const screenWidth = app.screen.width / world.scale.x;
        const screenHeight = app.screen.height / world.scale.y;
        const worldX = -world.position.x / world.scale.x;
        const worldY = -world.position.y / world.scale.y;

        // Определяем границы видимой области с запасом
        const padding = bgTextureSize * 1.5; // Запас вокруг экрана
        const left = worldX - padding;
        const right = worldX + screenWidth + padding;
        const top = worldY - padding;
        const bottom = worldY + screenHeight + padding;

        // Вычисляем необходимые тайлы фона
        const startX = Math.floor(left / bgTextureSize) * bgTextureSize;
        const startY = Math.floor(top / bgTextureSize) * bgTextureSize;
        const endX = Math.ceil(right / bgTextureSize) * bgTextureSize;
        const endY = Math.ceil(bottom / bgTextureSize) * bgTextureSize;

        // Удаляем спрайты, которые больше не видны
        for (let i = bgSprites.length - 1; i >= 0; i--) {
            const sprite = bgSprites[i];
            if (sprite.x + bgTextureSize < startX ||
                sprite.x > endX ||
                sprite.y + bgTextureSize < startY ||
                sprite.y > endY) {
                bgContainer.removeChild(sprite);
                bgSprites.splice(i, 1);
            }
        }

        // Добавляем новые спрайты, если они нужны
        for (let x = startX; x < endX; x += bgTextureSize) {
            for (let y = startY; y < endY; y += bgTextureSize) {
                const exists = bgSprites.some(s => s.x === x && s.y === y);
                if (!exists) {
                    const texture = bgTextures[Math.floor(Math.random() * bgTextures.length)];
                    const sprite = new PIXI.Sprite(texture);
                    sprite.position.set(x, y);
                    bgContainer.addChild(sprite);
                    bgSprites.push(sprite);
                }
            }
        }
    }

    // Первоначальное создание фона
    updateBackground();

    // Функция для проверки изменений
    function checkForChanges() {
        if (world.position.x !== lastX ||
            world.position.y !== lastY ||
            world.scale.x !== lastScale) {

            lastX = world.position.x;
            lastY = world.position.y;
            lastScale = world.scale.x;
            updateBackground();
        }
        requestAnimationFrame(checkForChanges);
    }

    // Запускаем проверку изменений
    checkForChanges();

    // Также обновляем при изменении размера экрана
    app.renderer.on('resize', updateBackground);

    // Возвращаем функцию для ручного обновления, если нужно
    return {
        update: updateBackground
    };
}