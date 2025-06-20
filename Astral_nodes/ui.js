// ui.js
export function createUI(app, ui) {

    // Нижняя панель UI
    const uiPanel = new PIXI.Container();
    // Вместо anchor используем pivot для позиционирования
    uiPanel.pivot.set(0.5, 1); // Сбрасываем pivot (по умолчанию 0,0) // Якорь по центру-X и низу-Y
    uiPanel.position.set(app.screen.width / 2, app.screen.height);
    ui.addChild(uiPanel);

    // Создаем текстовый элемент с фоном
    const hintText = new PIXI.Text({
        text: "Двойной клик для создания нового элемента",
        style: {
            fontFamily: 'Arial',
            fontSize: 18,
            fill: 0xffffff,
            align: 'center',
            backgroundColor: 0xaaaaaa, // Цвет фона
            backgroundOpacity: 0.7,    // Прозрачность фона
            padding: 10                // Отступы вокруг текста
        }
    });

    // Привязываем якорь текста к якорю нижней панели
    hintText.anchor.copyFrom(uiPanel.pivot); // Копируем те же значения
    hintText.position.set(0, 0); // Относительно панели
    uiPanel.addChild(hintText);

    app.renderer.on('resize', updateUI);
    updateUI();

    function updateUI() {
        uiPanel.position.set(app.screen.width / 2, app.screen.height);
    }

}