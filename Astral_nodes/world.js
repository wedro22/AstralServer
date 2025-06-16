export class World extends PIXI.Container {
    constructor() {
        super();
        this.lastPosition = { x: 0, y: 0 }
        this.isDragging = false
        this.cursor = 'grab';
        this   //pointer = Mouse & touch, mouse = mouse-only, touch = touch-only
            .on('pointerdown', worldDown)
            .on('pointerup', worldUp)
            .on('pointermove', worldMove)
            .on('pointerleave', worldUp);
    }

    function pointerDown() {

    }

    function pointerUp() {

    }

    function pointerMove() {

    }

}