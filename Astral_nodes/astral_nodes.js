import { createInfiniteBackground } from './background.js';

// This example is the based on basic/container, but using OffscreenCanvas.

const canvas = document.createElement('canvas');    //Создаёт обычный HTML-элемент <canvas> в памяти (но не добавляет его на страницу). Чтобы получить доступ к API Canvas 2D или WebGL. Пока canvas не добавлен в DOM (document.body.appendChild(canvas)), он не отображается. Это стандартный способ работы с Canvas.
const view = canvas.transferControlToOffscreen();   //Преобразует обычный <canvas> в OffscreenCanvas — специальный объект, который можно передать в Web Worker. Вынести тяжёлые вычисления (рендеринг, анимации) в фоновый поток.


(async () => {
    // Create a new application
    const app = new PIXI.Application(view);

    // Initialize the application
    await app.init({ view, background: '#1099bb', resizeTo: window });

    // Append the application canvas to the document body
    document.body.appendChild(canvas);

    // 1. Основной контейнер (будет двигаться как "камера")
    const world = new PIXI.Container();
    app.stage.addChild(world);

    // 2. Контейнер для статичных элементов (не двигается)
    const ui = new PIXI.Container();
    app.stage.addChild(ui); // Добавляем НЕ в world, а в app.stage

    // 3. Какой-нибудь контейнер для объектов находящийся в world
    const container = new PIXI.Container();
    world.addChild(container);



    createInfiniteBackground(app, world); // Вызываем здесь



    // Перетаскивание
    let isDragging = false;
    let lastPosition = { x: 0, y: 0 };
    // Начало перетаскивания
    canvas.addEventListener('pointerdown', (e) => {
        isDragging = true;
        lastPosition = { x: e.clientX, y: e.clientY };
    });
    // Движение мыши
    canvas.addEventListener('pointermove', (e) => {
        if (!isDragging)  return;

        const dx = e.clientX - lastPosition.x;
        const dy = e.clientY - lastPosition.y;

        // Перемещаем "мир" в противоположном направлении
        world.x += dx;
        world.y += dy;

        lastPosition = { x: e.clientX, y: e.clientY };
    });
    // Конец перетаскивания
    canvas.addEventListener('pointerup', () => {
        isDragging = false;
    });



    // Load the bunny texture
    const texture = await PIXI.Assets.load('possum.png');

    // Create a 5x5 grid of bunnies
    for (let i = 0; i < 25; i++) {
    const bunny = new PIXI.Sprite(texture);

    bunny.anchor.set(0.5);
    bunny.x = (i % 5) * 40;
    bunny.y = Math.floor(i / 5) * 40;
    container.addChild(bunny);
    }

    // Move container to the center
    container.x = app.screen.width / 2;
    container.y = app.screen.height / 2;

    // Center bunny sprite in local container coordinates
    container.pivot.x = container.width / 2;
    container.pivot.y = container.height / 2;

    // Listen for animate update
    app.ticker.add((time) => {
    // Rotate the container!
    // * use delta to create frame-independent transform *
    container.rotation -= 0.01 * time.deltaTime;
    });
})();




