//import { createInfiniteBackground } from './background2.js';    //(не работает)
import { InputController } from './inputController.js';

// This example is the based on basic/container, but using OffscreenCanvas.

document.body.style.margin = '0';   // Убираем стандартные отступы у body
document.body.style.overflow = 'hidden'; // Отключаем скроллбары
const canvas = document.createElement('canvas');    //Создаёт обычный HTML-элемент <canvas> в памяти (но не добавляет его на страницу). Чтобы получить доступ к API Canvas 2D или WebGL. Пока canvas не добавлен в DOM (document.body.appendChild(canvas)), он не отображается. Это стандартный способ работы с Canvas.
const view = canvas.transferControlToOffscreen();   //Преобразует обычный <canvas> в OffscreenCanvas — специальный объект, который можно передать в Web Worker. Вынести тяжёлые вычисления (рендеринг, анимации) в фоновый поток.


(async () => {
    // Create a new application
    const app = new PIXI.Application(view);

    // Initialize the application
    await app.init({ view, background: '#2a2a3a', resizeTo: window });

    // Append the application canvas to the document body
    document.body.appendChild(canvas);

    // 1. Основной контейнер мира (будет масштабироваться)
    const world = new PIXI.Container();
    app.stage.addChild(world);

    // 2. UI контейнер
    const ui = new PIXI.Container();
    app.stage.addChild(ui);

    // 3. Какой-нибудь контейнер для объектов находящийся в world
    const container = new PIXI.Container();
    world.addChild(container);



    //createInfiniteBackground(app, world); // Бесконечный фон с эффектом параллакса (не работает)
    const inputController = new InputController(canvas, world); // Создаём контроллер ввода



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




    // Создаем UI панель с фиксированной высотой и автоматической шириной
    const uiPanel = new PIXI.Container();
    uiPanel.y = app.screen.height - 60; // Фиксированная позиция внизу
    ui.addChild(uiPanel);

    // Фон для панели (отдельный элемент для гибкости)
    const bg = new PIXI.Graphics()
        .beginFill(0x2a2a3a, 0.7)
        .drawRect(0, 0, app.screen.width, 60)
        .endFill();
    uiPanel.addChild(bg);

    // Текстовая подсказка
    const hintText = new PIXI.Text("Двойной клик для создания нового элемента", {
        fontFamily: 'Arial',
        fontSize: 18,
        fill: 0xffffff,
        align: 'center'
    });

    // Центрируем текст относительно панели
    hintText.anchor.set(0.5);
    hintText.position.set(bg.width / 2, bg.height / 2);
    uiPanel.addChild(hintText);

    // Единственный обработчик ресайза для всей панели
    const updateUIPanel = () => {
        // Обновляем размер фона
        bg.width = app.screen.width;
        bg.height = 60;

        // Позиционируем панель
        uiPanel.y = app.screen.height - bg.height;

        // Автоматическое центрирование текста
        hintText.position.set(bg.width / 2, bg.height / 2);
    };

    app.renderer.on('resize', updateUIPanel);
    updateUIPanel(); // Первоначальная настройка
})();




