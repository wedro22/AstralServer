//подключает типы из node_modules
/// <reference types="pixi.js" /> 
/**
 * @type {typeof import("pixi.js")}
 */
const PIXI = window.PIXI;  // Явно связываем глобальный PIXI с типами

import { createUI } from './ui.js';
import { World } from './world.js';

document.body.style.margin = '0';   // Убираем стандартные отступы у body
document.body.style.overflow = 'hidden'; // Отключаем скроллбары

(async () => {
    // Create a new application
    const app = new PIXI.Application();
    await app.init({ antialias: true,background: '#2a2a3a', resizeTo: window });

    document.body.appendChild(app.canvas);
    
    // 1. Основной контейнер мира (будет масштабироваться и таскаться)
    const world = new World(app);
    app.stage.addChild(world);


    // 2. UI контейнер
    const ui = new PIXI.Container();
    app.stage.addChild(ui);

    // 3. Какой-нибудь контейнер для объектов находящийся в world
    const container = new PIXI.Container();
    world.addChild(container);



    //createInfiniteBackground(app, world); // Бесконечный фон с эффектом параллакса (не работает)
    //const inputController = new InputController(canvas, world); // Создаём контроллер ввода



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



    createUI(app, ui);  // Создаём интерфейс
})();




