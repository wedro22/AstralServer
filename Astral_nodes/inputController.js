// inputController.js
export class InputController {
    constructor(canvas, world) {
        this.canvas = canvas;
        this.world = world;
        this.isDragging = false;
        this.lastPosition = { x: 0, y: 0 };

        // Настройки масштабирования
        this.scale = {
            value: 1,
            min: 0.05,
            max: 2,
            step: 0.1
        };

        // Настройка обработчиков событий
        this.setupEventListeners();
    }

    setupEventListeners() {
        // Обработчики на document для корректной работы при выходе за пределы canvas
        document.addEventListener('pointerdown', this.handlePointerDown.bind(this));
        document.addEventListener('pointermove', this.handlePointerMove.bind(this));
        document.addEventListener('pointerup', this.handlePointerUp.bind(this));
        document.addEventListener('pointerleave', this.handlePointerUp.bind(this)); // На случай, если курсор ушел за пределы окна
        window.addEventListener('blur', this.handlePointerUp.bind(this));   // Отмена перетаскивания при потере фокуса окна
        document.addEventListener('wheel', this.handleWheel.bind(this));    // Машстабирование
    }

    handlePointerDown(e) {
        if (e.target === this.canvas) {
            this.isDragging = true;
            this.lastPosition = { x: e.clientX, y: e.clientY };
            this.canvas.style.cursor = 'grabbing';
        }
    }

    handlePointerMove(e) {
        if (!this.isDragging) return;

        const dx = e.clientX - this.lastPosition.x;
        const dy = e.clientY - this.lastPosition.y;

        this.world.x += dx;
        this.world.y += dy;

        this.lastPosition = { x: e.clientX, y: e.clientY };
    }

    handlePointerUp() {
        if (this.isDragging) {
            this.isDragging = false;
            this.canvas.style.cursor = 'grab';
        }
    }

    // Можно добавить дополнительные методы для обработки кликов и наведения
    handleClick(e) {
        // Логика обработки клика
    }

    handleHover(e) {
        // Логика обработки наведения
    }

    handleWheel(e) {
        e.preventDefault();

        // Получаем позицию мыши относительно world ДО масштабирования
        const mouseWorldPos = {
            x: (e.clientX - this.world.x) / this.world.scale.x,
            y: (e.clientY - this.world.y) / this.world.scale.y
        };

        // Изменяем масштаб
        const delta = e.deltaY > 0 ? -this.scale.step : this.scale.step;
        this.scale.value = Math.min(
            Math.max(this.scale.value + delta, this.scale.min),
            this.scale.max
        );

        // Применяем масштаб
        this.world.scale.set(this.scale.value);

        // Корректируем позицию world чтобы масштабирование было от точки курсора
        this.world.x = e.clientX - mouseWorldPos.x * this.world.scale.x;
        this.world.y = e.clientY - mouseWorldPos.y * this.world.scale.y;
    }

    destroy() {
        // Очистка обработчиков при необходимости
        document.removeEventListener('pointerdown', this.handlePointerDown);
        document.removeEventListener('pointermove', this.handlePointerMove);
        document.removeEventListener('pointerup', this.handlePointerUp);
        document.removeEventListener('pointerleave', this.handlePointerUp);
        window.removeEventListener('blur', this.handlePointerUp);
        document.removeEventListener('wheel', this.handleWheel.bind(this), { passive: false });
    }
}